angular.module("post.module").controller('auth.controller', function ($scope, $rootScope, $cookies, $location, AuthService, AuthSessionService) {
    $scope.message = "Welcome to the HdlpDoc CMS app!";

    init();

    function init() {
        var checkUserLoggedin = function () {
            if (AuthSessionService.isUserLoggedin()) {
                $scope.loginUserBtn = false;
            }
            else {
                $scope.loginUserBtn = true;
            }
        };
        checkUserLoggedin();

    }

    $rootScope.showLogout = AuthSessionService.isUserLoggedin();
    $rootScope.username = AuthSessionService.getUser();
    if ($rootScope.showLogout) {
        $location.path("/");
    }
    // AuthSessionService.deleteToken();

    $scope.login = function (username, password) {
       // debugger;
        if (username.toLowerCase() == "admin" && password.toLowerCase() == "123") {
            AuthService.doLogin(username, password).success(function (data) {
                console.log("on Login Token- ", data);
                AuthSessionService.setToken(data);
                AuthSessionService.setUser(username);
                $rootScope.loginUserBtn = false;
                $rootScope.showLogout = true;
                //debugger;
                $rootScope.username = username;
                $location.path("/");
                location.reload();
            });
        }
        else {
            $scope.errorText = "Enter correct credentials.";
        }
    }

    $scope.logout = function () {
        //debugger;
        AuthSessionService.deleteToken();
        $rootScope.showLogout = false;
        $rootScope.loginUserBtn = true;
        $rootScope.username = "";
        $location.path("/auth/login");
        location.reload();
    }

});








angular.module("post.module").controller('auth.controller1', function ($scope, $rootScope, $cookies, $location, AuthService, AuthSessionService) {
    //debugger;
    var checkUserLoggedin = function () {
        if (AuthSessionService.isUserLoggedin()) {
            $scope.visible = { 'visibility': 'visible' };
        }
        else {
            $scope.visible = { 'visibility': 'hidden' };
        }
    };
    checkUserLoggedin();
});



//angular.module("post.module").controller("appCtrl", ["$scope", function ($scope) {
//    $scope.treeName = 'sampleTree';
//    $scope.data = [];
//    var sampleData = null;
//    var getParentData = function () {
//        debugger;
//        var jsonData = [
//                        { "id": "1", "text": "Dairy", "expanded": false, "hasChildren": true },
//                        { "id": "11", "pid": "1", "text": "Milk" },
//                        { "id": "12", "pid": "1", "text": "Butter" },
//                        { "id": "13", "pid": "1", "text": "Cheese" },
//                        { "id": "14", "pid": "1", "text": "Yogurt" }]
//        $scope.data = jsonData;
//        //for (var i = 0; i < jsonData.length; i++) {
//        //    if (jsonData[i].pid === undefined)
//        //        $scope.data.push(getItem(i));            
//        //}
//        //// Update the TreeView layout and refresh its view
//        //$treeService.updateLayout($scope.treeName);
//        //        // At first only populate the TreeView with root items
//        //       // extractData();  
//        //function getItem(index) {
//        //    var item = {
//        //        id: sampleData[index].id,
//        //        pid: sampleData[index].pid,
//        //        text: sampleData[index].text,
//        //        expanded: sampleData[index].expanded,
//        //        hasChildren: sampleData[index].hasChildren
//        //    }
//        //    // In order to show the expand box, create a
//        //    // temporary item which will act as a child item
//        //    if (isThereChildItems(sampleData[index].id))
//        //        item.items = [{ text: "temp" }]; 
//        //    return item;
//        //}
//        //function isThereChildItems(parentId) {
//        //    for (var i = 0; i < sampleData.length; i++) {
//        //        if (sampleData[i].pid === parentId)
//        //            return true;
//        //    }
//        //    return false;
//        //}
//        //var getItem = function (index) {
//        //    var item = {
//        //        id: sampleData[index].id,
//        //        pid: sampleData[index].pid,
//        //        text: sampleData[index].text,
//        //        expanded: sampleData[index].expanded,
//        //        hasChildren: sampleData[index].hasChildren
//        //    }
//        //    // In order to show the expand box, create a
//        //    // temporary item which will act as a child item
//        //    if (isThereChildItems(sampleData[index].id))
//        //        item.items = [{ text: "temp" }];
//        //    return item;
//        //}
//        //var extractData = function () {
//        //    // Extract only root items
//        //    for (var i = 0; i < sampleData.length; i++) {
//        //        if (sampleData[i].pid === undefined)
//        //            $scope.data.push(getItem(i));
//        //    }
//        //    // Update the TreeView layout and refresh its view
//        //    $treeService.updateLayout($scope.treeName);
//        //}
//    };
//    getParentData();   
//}]);



