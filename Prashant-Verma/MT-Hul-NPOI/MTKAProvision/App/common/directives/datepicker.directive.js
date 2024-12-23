'use strict';

angular.module("post.module").directive('datePicker', function () {
    return {
        restrict: 'A',
        link: function (scope, element) {
            element.datepicker();
        }
    }
});
