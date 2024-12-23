angular.module("post.module").directive("postList", function () {
    return {
        restrict: "E",
        replace: true,
        scope: true,
        templateUrl: "app/post/views/directives/post-list.html"
    };
});