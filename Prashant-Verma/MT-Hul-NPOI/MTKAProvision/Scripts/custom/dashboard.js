//$(document).ready(function () {
//    SetThermometer();
//});

//function SetThermometer() {
//    $.ajax({
//        url: '/Dashboard/GetThermometerData',
//        dataType: "json",
//        type: "GET",
//        contentType: 'application/json; charset=utf-8',
//        async: true,
//        cache: false,
//        success: function (data) {
//            var htmlString = '<div class=" col-sm-8 col-sm-offset-4">'+
//                            '<div class="donation-meter ">'+
//                                '<span class="glass">'+
//                                    '<h6 class="vertical">'+
//                                        'Click on the month in <span class="green"> green color</span> to open reports or export JV'+
//                                    '</h6>';
//            var strongEle_BottomPerc = 1;
//            var spanEle_BottomPerc = 0;
//            $.each(data.mocList, function (index, value) {
//                var colorCode = '';
//                var className = '';
//                if(value.Status=="Open"){
//                    colorCode = "#F7FE2E";
//                    className = "closedMoc";
//                }
//                else if (value.Status == "Close") {
//                    colorCode = "#04B404";
//                    className = "closedMoc";
//                }
//                else if (value.Status == "NotPresent") {
//                    colorCode = "#808080";
//                }

//                htmlString += '<a href="javascript:void(0);" class="' + className + '" data-moc="' + value.MonthId + '.' + value.Year + '">' +
//                                        '<strong class="total" style="bottom: ' + strongEle_BottomPerc + '%">' + value.Month + '</strong>' +
//                                        '<span class="amount" style="background: '+colorCode+'; bottom: ' + spanEle_BottomPerc + '%;">' +
//                                        '</span>'+
//                                        '</a>';

//                strongEle_BottomPerc = strongEle_BottomPerc + 8;
//                spanEle_BottomPerc = spanEle_BottomPerc + 8;
//            });

//            htmlString += '</span>' +
//                                '<div class="bulb">'+
//                                    '<span class="red-circle"></span>'+
//                                    '<span class="filler"><span></span></span>'+
//                                '</div>'+
//                            '</div>'+
//                            '<h6 class="thermo-title">MOC Provision Status - ' + data.mocList[0].Year + '</h6>' +
//                        '</div>';


//            $("#thermometerDiv").html(htmlString);
//        },
//        error: function (xhr) {

//        }
//    });
//}

function ShowAlert(msg) {
    $("#commonAlertModal div.modal-body p").html(msg);
    $('#commonAlertModal').modal('show');
}

$(document).on("click", "#btn_NewMOC", function (e) {
    e.preventDefault();
    var mocAction = $(this).data("mocaction");
    CheckForOpenMOC(mocAction);
});

function CheckForOpenMOC(mocAction) {
    /*GET*/
    $.ajax({
        url: '/Dashboard/CheckForOpenMOC',
        dataType: "json",
        type: "GET",
        contentType: 'application/json; charset=utf-8',
        async: true,
        cache: false,
        success: function (data) {
            if (data == true) {
                ShowAlert("One MOC is already in progress");
            }
            else {
                if (mocAction == "new") {
                    CreateNewMOC();
                }
                else if (mocAction == "reopen") {
                    ReopenMOC();
                }
            }
        }
    });
}

function CreateNewMOC() {
    /*GET*/
    $.ajax({
        url: '/Dashboard/CreateNewMOC',
        dataType: "json",
        type: "GET",
        contentType: 'application/json; charset=utf-8',
        async: true,
        cache: false,
        success: function (data) {
            if (data.success == true) {
                window.location = "/Dashboard/Index";
            }
            else {
                ShowAlert(data.msg);
            }
        }
    });
}

$(document).on("click", "#CloseMOC", function (e) {
    e.preventDefault();
    $('#closeMOCConfirmModal').modal('show');
});
$(document).off("click", ".closedMoc").on("click", ".closedMoc", function (e) {

    window.location = "/Reports/Index?moc=" + $(this).data('moc');
});

$(document).on("click", "#btnCloseMOC", function (e) {
    
    $.ajax({
        url: '/Dashboard/CloseMOC',
        dataType: "json",
        type: "GET",
        contentType: 'application/json; charset=utf-8',
        async: true,
        cache: false,
        beforeSend: function () {
            $('#loading').show();
        },
        success: function (data) {
            $('#closeMOCConfirmModal').modal('hide');
            if (data.IsSuccess) {
                $('#loading').hide();
                bootbox.alert({
                    message: data.Msg
                });
                window.location = "/Dashboard/Index";
            }
            else {
                $('#loading').hide();
                bootbox.dialog({
                    message: data.Msg,
                    title: "Error!"
                });
            }
        },
        error: function (xhr, textStatus, errorThrown) {
            $('#loading').hide();
            callOnError(xhr, textStatus, errorThrown);
        }
    });
});


$(document).on("click", "#btn_ReopenMOC", function (e) {
    e.preventDefault();
    var mocAction = $(this).data("mocaction");
    CheckForOpenMOC(mocAction);
});

function ReopenMOC() {
    $.ajax({
        url: '/Dashboard/ReopenMOC',
        dataType: "json",
        type: "GET",
        contentType: 'application/json; charset=utf-8',
        async: true,
        cache: false,
        success: function (data) {
            if (data.success == true) {
                //window.location = "/Dashboard/Index";
                bootbox.confirm(data.msg, function (result) {
                    if (result == true) {
                        ConfirmReopenMOC();
                    }
                })
            }
            else {
                ShowAlert(data.msg);
            }
        }
    });
}

function ConfirmReopenMOC() {
    $.ajax({
        url: '/Dashboard/ConfirmReopenMOC',
        dataType: "json",
        type: "GET",
        contentType: 'application/json; charset=utf-8',
        async: true,
        cache: false,
        success: function (data) {
            if (data.success == true) {
                window.location = "/Dashboard/Index";
            }
            else {
                ShowAlert(data.msg);
            }
        }
    });
}
