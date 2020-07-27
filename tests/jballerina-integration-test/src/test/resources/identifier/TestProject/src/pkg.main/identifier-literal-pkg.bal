// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/io;
import pkg.variable;

const ASSERTION_ERR_REASON = "AssertionError";

function getVarsInOtherPkg() {
    string stringVar =  variable: 'get_String_\u2324\ 1\!\$\.\[\;\:\<_ƮέŞŢ();
    any anyVar = variable: 'get_Variable_\u2324\ 1\!\$\.\[\;\:\<_ƮέŞŢ();
    assertEquality("value", stringVar);
    assertEquality(<any>88343, anyVar);
}

function accessStructInOtherPkg() {
    string firstName = variable:'get_Person_\u2324\ 1\!\$\.\[\;\:\<_ƮέŞŢ().'1st_name ;
    string lastName =
    variable:'get_Person_\u2324\ 1\!\$\.\[\;\:\<_ƮέŞŢ().'\\\|\ \!\#\$\.\[\;\/\{\"\:\<\>\u2324_last_name;
    int age = variable:'get_Person_\u2324\ 1\!\$\.\[\;\:\<_ƮέŞŢ().'Ȧɢέ;
    assertEquality("Harry", firstName);
    assertEquality("potter", lastName);
    assertEquality(25, age);
}

public function main() {
    getVarsInOtherPkg();
    accessStructInOtherPkg();
    io:println("Values returned successfully");
}

function assertEquality(any|error expected, any|error actual) {
    if expected is anydata && actual is anydata && expected == actual {
        return;
    }
    if expected === actual {
        return;
    }
    panic error(ASSERTION_ERR_REASON,
                message = "expected '" + expected.toString() + "', found '" + actual.toString () + "'");
}