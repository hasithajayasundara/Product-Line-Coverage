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

package dashboard_utils;

import ballerina/config;
import ballerina/sql;

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
    _ = productDatabase -> close();
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


