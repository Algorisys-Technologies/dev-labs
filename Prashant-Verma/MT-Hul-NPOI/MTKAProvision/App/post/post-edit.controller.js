angular.module("post.module").controller('post-edit.controller', function ($scope, $sce, $route, $location, $stateParams, $state,  PostFactory) {
    $scope.message = "Post details";

    // todo: ngRoute has to be replaced with ui-router

    var id = $stateParams.id;

    $scope.tinymceOptions = {
        onChange: function (e) {
            // put logic here for keypress and cut/paste changes
        },
        inline: false,
        plugins: 'autolink link lists charmap fullscreen code',
        toolbar: 'code | undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link ',
        skin: 'lightgray',
        theme: 'modern',
        menubar: false,
        images_upload_url: "/api/post/uploadimage",
    };
    
    PostFactory.getById(id).success(function (data) {
        $scope.post = data;
        
        PostFactory.getAll().success(function (all) {
            //debugger;
            $scope.menus = all;
        });
    });

    // addnew post
    $scope.update = function () {
        var post = this.post;
        PostFactory.update(this.post).success(function (id) {
            post.id = id;
            $state.go('posts');
            location.reload();
        });
    };
});