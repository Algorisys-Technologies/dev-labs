angular.module("post.module").controller('posts.controller',
    function ($scope, $anchorScroll, $location, $routeParams, $stateParams, $cookies, $locale, PostFactory, AuthSessionService) {
        /*
         * NOTES:  posts is injected from 'route resolve'
         */
        $scope.message = "Welcome to the HelpDoc";
        $scope.orderBy = 'publishedOn';
        $scope.reverse = true;
        $scope.showNotification = false;


        $scope.filterTag = $stateParams.tag || $routeParams.tag;

        $scope.notifySuccess = function (msg) {
            $scope.notificationMessage = msg;
            $scope.showNotification = true;
        };

        init();

        function init() {
            $scope.layout = $cookies.get('myLayout');
            $scope.sortOn = $cookies.get('mySort');
        }

        var tag = $stateParams.tag;
        if (tag === undefined || tag === null || tag.trim() == '') {
            PostFactory.getAll().success(function (data) {
                //debugger;
                $scope.posts = data;
                //for (var i = 0; i < data.length;i++)
                //{
                //    if(data[i].id == data[i].parentId)
                //    {
                //        console.log(data[i]);
                //    }
                //}
                console.log('data: ', data);
                //initMenu();

                $scope.menu   = initMenu1();
              
            });
        }
        else {
            PostFactory.getByTag(tag).success(function (data) {
                $scope.posts = data;
                
                initMenu();

                
            })
        }

        function initMenu1() {
            //debugger;
            var newData = { name: "root", children: [] },
                 levels = ["parentId", "title"];
            var menu = [];

            // For each data row, loop through the expected levels traversing the output tree
            $scope.posts.forEach(function (d) {
               // debugger;
                if (d.id == d.parentId || d.parentId  == null) {
                    menu.push({ obj: d, children: [], expanded:false });
                }
                else
                {
                    //Menu.search for d.parntId
                    //push in its chilren property
                    var parent = getParent(menu, d.parentId);
                    if (parent) {
                        parent.children.push({ obj: d, children: [], expanded: false })
                    }
                }
            })

            console.log("menu-", menu);
            return menu;
        }

        //function getNestedChildren(arr, parentId) {
        //    var out = [];
        //    for (var i in arr) {
        //        if (arr[i].parentId == parentId) {
        //            var children = getNestedChildren(arr, arr[i].id);

        //            if (children.length) {
        //                arr[i].children = children;
        //            }
        //            out.push(arr[i]);
        //        }
        //    }
        //    return out
        //}

        function getParent(arr, parentId) {
            //var out = [];
            for (var i in arr) {
                if (arr[i].obj.id == parentId) {
                    return arr[i];
                 }
                //else {
                //    var children = getNestedChildren(arr, parentId);
                //    for (var j in children) {
                //        if (children[j].obj.id == parentId) {
                //            return children[j];
                //        }                        
                //    }

                //}                
            }
            return null;
        }






       
        // todo: for menus
        function initMenu() {
            //debugger;
            var newData = { name: "root", children: [] },
                 levels = ["parentId", "title"];

            // For each data row, loop through the expected levels traversing the output tree
            $scope.posts.forEach(function (d) {
                //debugger;
                // Keep this as a reference to the current level
                var depthCursor = newData.children;
                // Go down one level at a time
                levels.forEach(function (property, depth) {

                    // Look to see if a branch has already been created
                    var index;
                    depthCursor.forEach(function (child, i) {
                        if (d[property] == child.name) index = i;
                    });
                    // Add a branch if it isn't there
                    if (isNaN(index)) {
                        depthCursor.push({ name: d[property], children: [] });
                        index = depthCursor.length - 1;
                    }
                    // Now reference the new child array as we go deeper into the tree
                    depthCursor = depthCursor[index].children;
                    // This is a leaf, so add the last element to the specified branch
                    if (depth === levels.length - 1) depthCursor.push({ name: d.model, size: d.size });
                });
            });
           // debugger;
            //$scope.posts = newData.children;
            
            
            console.log('Menus: ', newData);
        }

        $scope.$on("onNewPost", function (event, post) {
            $scope.posts.push(post);
        });


        $scope.expandCollapse = function (m) {
            m.expanded = !m.expanded;
        }

        $scope.$on("onRemovePost", function (event, post) {
            var index = $scope.posts.indexOf(post);
            $scope.posts.splice(index);
        });


        PostFactory.tags().success(function (data) {
            $scope.tags = data;
        });


        // custom sort function
        $scope.sortFn = function (post) {
            if ($scope.sortOn == "publishedOn") {
                $scope.orderBy = 'publishedOn';
                return "-publishedOn";
            } else if ($scope.sortOn == "sectionCount") {
                $scope.orderBy = 'sections.length';
                return -post.sections.length;
            }
        }

        // enable add form
        $scope.toggleAdd = function (post) {
            if (AuthSessionService.isTokenExist()) {
                $scope.showAdd = !$scope.showAdd;
            }
            else {
                $location.path("/auth/login");
            }
        };

        // Radio button layout changes.
        $scope.layoutChange = function () {
            // Setting a cookie
            $scope.showAlert = true;
            //$scope.alertMessage = "Your new selection " + $scope.layout + ", has been saved!";

            $scope.notifySuccess("Your new selection " + $scope.layout + ", has been saved!");

            $cookies.put('myLayout', $scope.layout);
        }

        // Radio button layout changes.
        $scope.sortChange = function () {
            // Setting a cookie
            $scope.showAlert = true;
            $scope.alertMessage = "Your new sorting " + $scope.sortOn + ", has been saved!";
            $cookies.put('mySort', $scope.sortOn);
        }

        // show post
        $scope.showPost = function (post) {
            $scope.currentPost = post;
        };

        $scope.closeAlert = function (index) {
            $scope.showAlert = false;
        };

        $scope.delete = function (post) {
            //debugger;
            //var IdList = "";
            //var IdList = [];
            //IdList.push(post.obj.id);
            //var checkChild = false;
            //$scope.posts.forEach(function (d) {
            //    if(post.obj.id  == d.parentId)
            //    {
            //        //IdList += d.id
            //        //IdList.push(d.id );
            //        checkChild = true;
            //    }
            //})
            
            //var result = "";
            //if (checkChild == true)
            //{
                 result = confirm("You are about to delete document " + post.obj.title + ". This  might  have child document.  Are you sure?");
            //} else {
            //    result = confirm("You are about to delete document " + post.obj.title + ".  Are you sure?");
            //}
            if (result === true) {
                PostFactory.remove(post.obj.id);
                $scope.$emit('onRemovePost', post);
                
            }
            if (result === true) {
                location.reload();
            }
        }
    });