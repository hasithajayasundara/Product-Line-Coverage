//
// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import ballerina/collections;
import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/math;
import ballerina/sql;
import sonarqube_6_7;
import ballerina/io;

@Description {value:"Service Endpoint."}
endpoint http:ServiceEndpoint serviceEndpoint {
    port:9090
};

service<http:Service> LineCoverage bind serviceEndpoint {

    //get product list and send it to dashboard
    getProducts (endpoint conn, http:Request req) {
        http:Response res = {};
        json products = getAllProducts();
        res.setJsonPayload(products);
        _ = conn -> respond(res);
    }

    //get product coverage details and send it to dashboard
    getProductsLineCoverage (endpoint conn, http:Request req) {
        string productName = req.rawPath.split("=")[1].replace("_"," ");
        http:Response res = {};
        match getLineCoverage(productName) {
            json lineCoverage => {
                res.setJsonPayload(lineCoverage);
                _ = conn -> respond(res);
            }
            error conError => {
                log:printError("Error getting line coverage for product " + productName);
            }
        }
    }
}

//---------------------------------------------------------------------//
//-----------------------------Constants and functions-----------------//
//---------------------------------------------------------------------//
public const string QUERY_GET_PRODUCT_AREA = "select * from pqd_area";
public const string QUERY_GET_COMPONENTS = "select * from pqd_component where pqd_area_id=?";
public const string PQD_AREA_ID = "pqd_area_id";
public const string PQD_AREA_NAME = "pqd_area_name";
public const string PQD_COMPONENT_NAME = "pqd_component_name";
public const string NAME = "name";
public const string COMPONENTS = "components";
public const float THRESHOLD = 0.7;
public const string HOST = "host";
public const string PORT = "port";
public const string DATABASE_NAME = "database_name";
public const string USERNAME = "username";
public const string PASSWORD = "password";
public const string SONARQUBE_URI = "uri";
public const string SONARQUBE_TOKEN = "token";
public const string PRODUCTS = "products";
public const int TIMEOUT = 4000;
public const string PRODUCT_LINE_COVERAGES = "Product_Line_Coverages";

@Description {value:"Check whether a json is empty."}
@Return {value:"True if json is empty false otherwise."}
function isAnEmptyJson (json jsonValue) returns (boolean) {
    try {
        string stringVal = jsonValue.toString();
        if (stringVal == "{}") {
            return true;
        }
        return false;
    } catch (error e) {
        return true;
    }
    return false;
}

//---------------------------------------------------------------------//
//---------Functions to get data from SonarQube server-----------------//
//---------------------------------------------------------------------//
@Description {value:"Prepare a JSON of product to component mapping."}
@Param {value:"Name of the product."}
@Return {value:"JSON containing product to component mapping."}
@Return {value:"error if an error occured during the operation."}
function getLineCoverage (string productName) returns (json|error) {
    //SonarQube endpoint
    endpoint sonarqube_6_7:SonarQubeEndpoint sonarqubeEndpoint {
        token:getToken(),
        uri:getURI()
    };
    //component list belong to the product specified by productName
    json components = getComponents()[productName];
    var sonarqubeProjects =? sonarqubeEndpoint -> getAllProjects();
    //Prepare a vector from sonarqube projects json.
    collections:Vector vec = {vec:[]};
    foreach project in sonarqubeProjects {
        vec.add(project);
    }
    int totalLines = 0;
    int totalUncoveredLines = 0;
    int compCount = 0;
    json[] componentDetails = [];
    json productLineCoverage = {};
    //Iterate through components in database
    foreach component in components {
        string componentName = component[PQD_COMPONENT_NAME].toString();
        int count = 0;
        boolean found = false;
        while (count < vec.vectorSize) {
            sonarqube_6_7:Project project = {};
            try {
                project =? <sonarqube_6_7:Project>vec.get(count);
                if (project.name == componentName) {
                    found = true;
                    any element = vec.remove(count);
                    map coverageDetails =? sonarqubeEndpoint -> getMeasures(project.key, [sonarqube_6_7:LINES_TO_COVER, sonarqube_6_7:UNCOVERED_LINES]);
                    if (lengthof coverageDetails.keys() == 2) {
                        //get number of lines should be covered by unit tests
                        int lines =? <int>(<string>coverageDetails[sonarqube_6_7:LINES_TO_COVER]);
                        //get number of lines not covered by unit tests
                        int uncoveredLines =? <int>(<string>coverageDetails[sonarqube_6_7:UNCOVERED_LINES]);
                        totalLines = totalLines + lines;
                        //total uncovered
                        totalUncoveredLines = totalUncoveredLines + uncoveredLines;
                        //line coverage for the component
                        float lineCoverage = math:round((lines - uncoveredLines) * 10000.0 / lines) / 100.0;
                        //prepare json containing component name and coverage
                        componentDetails[compCount] = {name:project.name, coverage:lineCoverage};
                        compCount = compCount + 1;
                    }
                    break;
                }
            } catch (error castError) {
                componentDetails[compCount] = {name:project.name, coverage:"Not Defined."};
                compCount = compCount + 1;
                log:printDebug("Line coverage cannot be found for the project " + project.name);
            }
            count = count + 1;
        }
        //if project cannot be found in SonarQube server
        if (!found) {
            componentDetails[compCount] = {name:componentName, coverage:"Not Defined."};
            log:printDebug("Line coverage cannot be found for the project " + componentName);
            compCount = compCount + 1;
        } else {
            found = false;
        }
    }
    //calculate combined line coverage
    if (totalLines > 0) {
        float combinedLineCoverage = math:round((totalLines - totalUncoveredLines) * 10000.0 / totalLines) / 100.0;
        productLineCoverage = {name:productName, lineCoverage:combinedLineCoverage, threshold:THRESHOLD, components:componentDetails};
    } else {
        productLineCoverage = {name:productName, lineCoverage:"Not Defined.", threshold:THRESHOLD, components:componentDetails};
        log:printInfo("Line coverage for product " + productName + " cannot be found.");
    }
    return productLineCoverage;
}

@Description {value:"Get SonarQube server URI."}
@Return {value:"returns SonarQube server URI."}
function getURI () returns string {
    var config = config:getAsString(SONARQUBE_URI);
    match config {
        string uri => {
            return uri;
        }
        int| null => { return ""; }
    }
}

@Description {value:"Get SonarQube server token."}
@Return {value:"returns SonarQube server token."}
function getToken () returns string {
    var config = config:getAsString(SONARQUBE_TOKEN);
    match config {
        string token => {
            return token;
        }
        int| null => { return ""; }
    }
}

//---------------------------------------------------------------------//
//---------------Functions to get data from SQL server-----------------//
//---------------------------------------------------------------------//
@Description {value:"Get the details of components."}
@Return {value:"Returns a json which contains product to component mapping."}
public function getComponents () returns json {
    //SQL endpoint
    endpoint sql:Client productDatabase {
        database:sql:DB.MYSQL,
        host:getHost(),
        port:getPort(),
        name:getDatabaseName(),
        username:getUser(),
        password:getPassword(),
        options:{maximumPoolSize:5}
    };
    json componentList = {};
    table tableProductAreas =? productDatabase -> select(QUERY_GET_PRODUCT_AREA, null, null);
    var productAreas =? <json>tableProductAreas;
    //iterate through product areas in pqd_area table and prepare a product_area to component mapping.
    foreach area in productAreas {
        sql:Parameter[] params = [];
        int id =? <int>(area[PQD_AREA_ID].toString());
        sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:id};
        params = [para1];
        table tableComponents =? productDatabase -> select(QUERY_GET_COMPONENTS, params, null);
        var components =? <json>tableComponents;
        componentList[area[PQD_AREA_NAME].toString()] = components;
    }
    _ = productDatabase -> close();
    return componentList;
}

@Description {value:"Get product areas."}
@Return {value:"Returns a json which contains product areas."}
public function getAllProducts () returns json {
    //SQL endpoint
    endpoint sql:Client productDatabase {
        database:sql:DB.MYSQL,
        host:getHost(),
        port:getPort(),
        name:getDatabaseName(),
        username:getUser(),
        password:getPassword(),
        options:{maximumPoolSize:5}
    };
    json[] products = [];
    int count = 0;
    table tableProducts =? productDatabase -> select(QUERY_GET_PRODUCT_AREA, null, null);
    json areas =? <json>tableProducts;
    foreach area in areas {
        products[count] = area[PQD_AREA_NAME].toString();
        count = count + 1;
    }
    return {products:products};
}

@Description {value:"Get sql server host name."}
@Return {value:"returns sql server host name."}
function getHost () returns string {
    var config = config:getAsString(HOST);
    match config {
        string username => {
            return username;
        }
        int| null => { return ""; }
    }
}

@Description {value:"Get sql server port."}
@Return {value:"returns sql server port."}
function getPort () returns int {
    var config = config:getAsString(PORT);
    match config {
        string port => {
            int value =? <int>port;
            return value;
        }
        int| null => { return 0; }
    }
}

@Description {value:"Get sql server database name."}
@Return {value:"returns sql server database name."}
function getDatabaseName () returns string {
    var config = config:getAsString(DATABASE_NAME);
    match config {
        string databaseName => {
            return databaseName;
        }
        int| null => { return ""; }
    }
}

@Description {value:"Get sql server username."}
@Return {value:"returns sql server username."}
function getUser () returns string {
    var config = config:getAsString(USERNAME);
    match config {
        string username => {
            return username;
        }
        int| null => { return ""; }
    }
}

@Description {value:"Get sql server password."}
@Return {value:"returns sql server password."}
function getPassword () returns string {
    var config = config:getAsString(PASSWORD);
    match config {
        string password => {
            return password;
        }
        int| null => { return ""; }
    }
}
