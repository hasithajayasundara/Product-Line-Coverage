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

//SQL_QUARIES
public const string QUERY_GET_PRODUCT_AREA = "select * from pqd_area";
public const string QUERY_GET_COMPONENTS = "select * from pqd_component where sonar_project_key IS NOT NULL and pqd_area_id=?";

//SQL tables and fields
public const string PQD_AREA_ID = "pqd_area_id";
public const string PQD_AREA_NAME = "pqd_area_name";
public const string PQD_COMPONENT_NAME = "pqd_component_name";

//Endpoint configuration constants
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
public const string SONAR_PROJECT_KEY = "sonar_project_key";
public const int TIMEOUT = 4000;
public const string PRODUCT_LINE_COVERAGES = "Product_Line_Coverages";



