


//angular.module("post.module").config(function ($httpProvider) {
//	$httpProvider.interceptors.push('AuthInterceptor');
//})

angular.module("post.module").factory('AuthInterceptor', function ($timeout, $q, $log, $injector,$location, AuthSessionService) {
	//var AuthService;

	//$timeout(function () {
	//	AuthService = $injector.get('AuthService');
	//});

    ////Uncaught Error: [$injector:cdep] Circular dependency found`
    //$timeout(function () {
    //    $state = $injector.get('$state');
    //    $commonUtility = $injector.get('commonUtility');
    //    $logService = $injector.get("logService");
    //});

    return {
        request: function (config) {
            // log(config);
            config.headers = config.headers || {};
           
            if (AuthSessionService.isTokenExist()) {
            	config.headers.Authorization = 'Bearer ' + AuthSessionService.getToken();
            }


            return config || $q.when(config);
        },
        response: function (response) {
          
            if (response.status === 401) {                
                alert("Redirect user to login page");
            }
            return response || $q.when(response);
        },
        responseError: function (rejection) {
            // Executed only when the XHR response 
            // has an error status code

            //debugger;
            console.log(rejection);
            $log.error(rejection);

            if (rejection.status === 401) {
            	alert("Redirect user to login page");
            	$location.path("/auth/login");
            }

            return $q.reject(rejection);
        }
    };
});
