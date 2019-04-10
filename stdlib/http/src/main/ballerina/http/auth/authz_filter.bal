// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/auth;
import ballerina/cache;
import ballerina/reflect;

# Representation of the Authorization filter
#
# + authzHandler - `AuthzHandler` instance for handling authorization
# + scopes - Array of scopes
public type AuthzFilter object {

    public AuthzHandler authzHandler;
    public string[]? scopes;

    public function __init(AuthzHandler authzHandler, string[]? scopes) {
        self.authzHandler = authzHandler;
        self.scopes = scopes;
    }

    # Filter function implementation which tries to authorize the request
    #
    # + caller - Caller for outbound HTTP responses
    # + request - `Request` instance
    # + context - `FilterContext` instance
    # + return - A flag to indicate if the request flow should be continued(true) or aborted(false), a code and a message
    public function filterRequest(Caller caller, Request request, FilterContext context) returns boolean {
        boolean authorized = true;
        var resourceAuthConfig = getResourceAuthConfig(context);
        var resourceInboundScopes = resourceAuthConfig["scopes"];
        if (resourceInboundScopes is string[]) {
            authorized = handleAuthzRequest(self.authzHandler, request, context, resourceInboundScopes);
        } else {
            // scopes are not defined, no need to authorize
            var scopes = self.scopes;
            if (scopes is string[]) {
                authorized = handleAuthzRequest(self.authzHandler, request, context, scopes);
            }
        }
        return isAuthzSuccessful(caller, authorized);
    }

    public function filterResponse(Response response, FilterContext context) returns boolean {
        return true;
    }
};

function handleAuthzRequest(AuthzHandler authzHandler, Request request, FilterContext context, string[] scopes) returns boolean {
    boolean authorized = true;
    if (scopes.length() > 0) {
        if (authzHandler.canHandle(request)) {
            authorized = authzHandler.handle(runtime:getInvocationContext().principal.username,
                context.serviceName, context.resourceName, request.method, scopes);
        } else {
            authorized = false;
        }
    } else {
        // scopes are not defined, no need to authorize
        authorized = true;
    }
    return authorized;
}

# Verifies if the authorization is successful. If not responds to the user.
#
# + caller - Caller for outbound HTTP responses
# + authorized - flag to indicate if authorization is successful or not
# + return - A boolean flag to indicate if the request flow should be continued(true) or
#            aborted(false)
function isAuthzSuccessful(Caller caller, boolean authorized) returns boolean {
    Response response = new;
    if (!authorized) {
        response.statusCode = 403;
        response.setTextPayload("Authorization failure");
        var err = caller->respond(response);
        if (err is error) {
            panic err;
        }
        return false;
    }
    return true;
}
