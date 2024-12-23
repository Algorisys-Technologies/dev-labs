angular.module("post.module").directive("postDocument", function () {
    return {
        restrict: "E",
        replace: true,
        scope: true,
        templateUrl: "app/post/views/directives/post-document.html"
    };
});