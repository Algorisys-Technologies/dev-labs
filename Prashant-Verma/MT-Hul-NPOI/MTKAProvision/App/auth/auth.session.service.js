angular.module("post.module").factory("AuthSessionService", function ($window) {

    var setToken = function (token) {
        $window.localStorage.setItem('token', token);
    }

    var getToken = function () {
        var token = $window.localStorage.getItem('token');
        return token;
    }

    var deleteToken = function () {
        $window.localStorage.setItem('token', '');
    }

    var isTokenExist = function () {
        if ($window.localStorage.getItem('token')) {
            return true;
        }
        else {
            return false;
        }
    }

    var isUserLoggedin = function () {
        //debugger;
        return isTokenExist();
    }

    var setUser = function (username) {
        $window.localStorage.setItem('username', username);
    }

    var getUser = function () {
        var username = $window.localStorage.getItem('username');
        return username;
    }



    return {       
        setToken: setToken,
        getToken: getToken,
        isTokenExist: isTokenExist,
        deleteToken: deleteToken,
        isUserLoggedin: isUserLoggedin,
        setUser: setUser,
        getUser: getUser
    }
});