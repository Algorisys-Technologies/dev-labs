'use strict';

angular.module("post.module").directive('notification', function ($timeout) {
    return {
        restrict: 'EA',
        replace: true, // Replace with the template below
        transclude: true, // we want to insert custom content inside the directive
        link: function (scope, element, attrs) {
            console.log("link: ", scope.showNotification);
            scope.$watch('showNotification', function (newValue, oldValue) {
                if (newValue === true) {
                    // and after 3secs
                    $timeout(function () {
                        scope.$apply(function () {
                            scope.showNotification = false;
                        });
                    }, 2000);
                }
            });
        },
        templateUrl: 'app/common/directives/notification.directive.html'
    };
});
