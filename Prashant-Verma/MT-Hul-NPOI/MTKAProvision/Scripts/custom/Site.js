$(document).on('click', '#downloadAllFileFormat', function () {
    window.location = "/App/DownloadAllFileFormat"
});

$.ajaxSetup({
    error: function (xhr, textStatus, errorThrown) {
        callOnError(xhr, textStatus, errorThrown);
    }
});

function callOnError(xhr, textStatus, errorThrown) {
    console.log(xhr);
    if (xhr.responseText == "" || xhr.responseText == null) {
        return;
    }
    //alert("error");
    var err = eval("(" + xhr.responseText + ")");
    console.log(err);
    if (err == 'undefined')
    {
        return;
    }
    if (err.type) {
        if (err.type === "timeout") {
            window.location = "/login";
            return;
        }
    }
    else {
        bootbox.alert(err.Message);
    }


}
