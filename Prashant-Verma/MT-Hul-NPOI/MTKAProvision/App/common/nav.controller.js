angular.module("post.module").controller("nav.controller", function ($scope, $location, $state, AuthSessionService) {
    $scope.loadAddView = function () {
        //$location.url("/posts/create");
        $state.go('posts.create');       
    };

    var checkAdmin = function()
    {
        $scope.IsAdmin = false;
        //debugger;
        if ($scope.IsAdmin == false) {
            $scope.visible = { 'visibility': 'hidden' };
            //$scope.visible = true;
        }
    }
    //checkAdmin();

    var checkUserLoggedin = function () {
        if (AuthSessionService.isUserLoggedin()) {
            $scope.visible = { 'visibility': 'visible' };
        }
        else {
            $scope.visible = { 'visibility': 'hidden' };
        }
    };
    checkUserLoggedin();

    $scope.loadHomePage = function () {
        $location.url("/home");
    };
});