angular.module("post.module").factory("PostConfig", function ($http) {
    return {
        apiUrl: 'api/post'
    };
});

angular.module("post.module").factory("LoginConfig", function () {
    return {
        apiUrl: 'api/auth'
    };
});