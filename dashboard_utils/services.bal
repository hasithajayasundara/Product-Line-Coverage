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

import ballerina/http;
import ballerina/log;

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
    //rawPath - /LineCoverage/getProductLineCoverage?product=<product_name>
    getProductsLineCoverage (endpoint conn, http:Request req) {
        string productName = req.rawPath.split("=")[1].replace("_", " ");
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



