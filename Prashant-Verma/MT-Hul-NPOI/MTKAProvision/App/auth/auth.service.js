angular.module("post.module").factory("AuthService", function ($http, LoginConfig) {
    
    return {
        doLogin: function (username, password) {
            var User = {
                Username: username,
                Password: password
            }
            //debugger;
            return $http.post(LoginConfig.apiUrl + "/token", User);
        }
    }
});