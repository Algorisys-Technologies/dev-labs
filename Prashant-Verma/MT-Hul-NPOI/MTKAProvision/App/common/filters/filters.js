'use strict';
angular.module("post.module").filter('durations', function () {
    return function (duration) {
        switch (duration) {
            case 1:
                return "1 Hour";
            case 2:
                return "2 Hour";
            case 3:
                return "3 Day";
            case 4:
                return "Half Day";
            default:
                return "Long hours"
        }
    }
});