angular.module("post.module").controller('sections.controller',
   function ($scope, $route, $routeParams,$location, PostFactory, SectionService, AuthSessionService) {
    $scope.section = {
        title: "",
        body: "",
        postId: ""
    };

    $scope.message = "Section details";

    $scope.section.postId = $routeParams.id;

    PostFactory.getSectionsById($scope.section.postId).success(function (data) {
        $scope.sections = data;
    });

    $scope.sectionform = false;

    $scope.toggleAddSection = function () {
        if (AuthSessionService.isTokenExist()) {
            $scope.sectionform = !$scope.sectionform;
        }
        else {
            $location.path("/auth/login");
        }
    };

    $scope.addSection = function () {
        $scope.section.postId = $routeParams.id;
        SectionService.save($scope.section, function (data) {
            $scope.section.id = data.id;
            $scope.section.username = data.username;
            $scope.sections.push($scope.section);

            alert('Section saved!');

            $scope.clearForm();
        });

    };

    $scope.clearForm = function () {
        $scope.section = {
            title: "",
            body: "",
            postId: "",
            id: ""
        };
    }
});