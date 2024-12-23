angular.module("post.module",
    ['ngRoute',
     'ngSanitize',
     'ngResource',
     'ngAnimate',
     'ngCookies',
     'ui.router',
     'ui.tinymce'
    ]
);



angular.module("post.module").config(function ($stateProvider, $urlRouterProvider) {
    //
    // For any unmatched url, redirect to /state1
    $urlRouterProvider.otherwise("posts");
    //
    // Now set up the states
    $stateProvider
        .state("posts", {
            url: "/posts/:tag?",
            templateUrl: "index.html",
            controller: "posts.controller"
        })
        .state('posts.show', {
            url: '/show/:id',
            templateUrl: "app/post/views/show-post.html",
            controller: "post.controller"
        })
        .state('posts.create', {
            url: "/posts/create",
            templateUrl: "app/post/views/post-editor.html",
            controller: "post.controller"
        })
         .state('posts.edit', {
             url: "/edit/:id",
             templateUrl: "app/post/views/post-editor.html",
             controller: "post-edit.controller"
         }).state('login', {
             url: '/login',
             templateUrl: "app/auth/views/login.html",
             controller: "auth.controller"
         });
}).run(function ($state) {
    $state.go('posts'); //make a transition to posts state when app starts
});

angular.module("post.module").config(function ($routeProvider, $locationProvider, $httpProvider) {
    //$routeProvider
    //.when("/home/:tag?", {
    //    templateUrl: "index.html",
    //    controller: "posts.controller",
    //    resolve: {
    //        posts: function ($route, PostFactory) {
    //            alert('why');
    //            var tag = $route.current.params.tag;
    //            if (tag == undefined) {
    //                return PostFactory.getAll();
    //            }
    //            else {
    //                return PostFactory.getByTag(tag);
    //            }
                
    //        }
    //    }
    //})
    //.when("/auth/login", {
    //    templateUrl: "app/auth/views/login.html",
    //    controller: "auth.controller",
    //})
    //.when("/posts/create", {
    //    templateUrl: "app/post/views/createpost.html",
    //    controller: "post.controller"
    //})
    //.when("/posts/show/:id", {
    //    templateUrl: "app/post/views/show.html",
    //    controller: "post.controller"
    //})
    //.when("/posts/section/:id", {
    //    templateUrl: "app/post/views/sections.html",
    //    controller: "sections.controller"
    //});

    //$locationProvider.html5Mode(true);

    //$httpProvider.interceptors.push('AuthInterceptor');

});

/*
angular.module("post.module").config(function ($provide) {
    $provide.decorator("$exceptionHandler",
        ["$delegate",
            function ($delegate) {
                return function (exception, cause) {
                    exception.message = "Please contact the support! \n Message: " +
                        exception.message;
                    $delegate(exception, cause);

                    alert(exception.message);

                    // log the exception on the server using $http
                }
            }
        ]
        );
});
*/


//angular.module("post.module").run(function ($rootScope, $templateCache) {
//    $rootScope.$on('$viewContentLoaded', function () {
//        $templateCache.removeAll();
//    });
//});