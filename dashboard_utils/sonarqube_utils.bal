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

import ballerina/log;
import ballerina/math;
import sonarqube_6_7;

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
    //component list belong to the product specified by productName and sonar_project_key is not NULL
    json components = getComponents()[productName];
    int totalLines = 0;
    int totalUncoveredLines = 0;
    int compCount = 0;
    json[] componentDetails = [];
    json productLineCoverage = {};
    //Iterate through components in database
    foreach component in components {
        string projectName = component[PQD_COMPONENT_NAME].toString();
        string sonarProjectKey = component[SONAR_PROJECT_KEY].toString();
        map coverageDetails =? sonarqubeEndpoint -> getMeasures(sonarProjectKey, [sonarqube_6_7:LINES_TO_COVER, sonarqube_6_7:UNCOVERED_LINES]);
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
            componentDetails[compCount] = {name:projectName, coverage:lineCoverage};
            compCount = compCount + 1;
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


