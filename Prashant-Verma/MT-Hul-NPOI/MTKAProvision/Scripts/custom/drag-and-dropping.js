var isUploadUserRight;
$(document).ready(function () {
    isUploadUserRight = $("#dropAreaDiv").data("isuploadright");
});

var dropArea = $("#dropAreaDiv");
var newFile;

// Providing handlers three events to the drop area
dropArea.on({
    "drop": makeDrop,
    "dragenter": ignoreDrag,
    "dragover": ignoreDrag
});


$('#dropAreaDiv').on('click', function () {
    if (isUploadUserRight.toLowerCase() == "true") {
        $('#fileInput').trigger('click');
    }
    else {
        bootbox.alert("You don't have permission to upload file");
    }
});


//Stop default behavior 
function ignoreDrag(e) {
    e.stopPropagation();
    e.preventDefault();
}

//Handling drop event
function makeDrop(e) {
    if (isUploadUserRight.toLowerCase() == "true") {
        var ele = document.getElementById("fileInput");
        clearInputFile(ele);

        //
        var fileList = e.originalEvent.dataTransfer.files, fileReader;
        e.stopPropagation();
        e.preventDefault();
        if (fileList.length > 0) {

            newFile = fileList[0];


            //$("#validateDroppedImage").hide();
            fileReader = new FileReader();
            fileReader.onloadend = handleReaderOnLoadEnd();
            fileReader.readAsDataURL(fileList[0]);

        }
    }
    else {
        bootbox.alert("You don't have permission to upload file");
    }
}

//Setting the image source
function handleReaderOnLoadEnd() {
    return function (event) {
        //
        var extension = newFile.name.replace(/^.*\./, '');

        if (extension == "xls" || extension == "xlsx") {
            var p = "<p>Are you sure.you want to upload:</p><p style='color:darkorange;'>" + newFile.name + "</p>";

            $("#confirmModal div.modal-body").html(p);

            var currentTab = $("#activeTabMaster");
            if (currentTab.val() == "SubCategoryTOTMaster") {
                var radioHtml = '<div><label class="radio-inline"><input type="radio" name="optradio" value="on" checked="checked"><span class="lh2_2em">On Invoice</span></label>' +
                                '<label class="radio-inline"><input type="radio" name="optradio" value="off"><span class="lh2_2em">Off Invoice Monthly</span></label>' +
                                '<label class="radio-inline"><input type="radio" name="optradio" value="quarterly"><span class="lh2_2em">Off Invoice Quarterly</span></label></div>';
                $("#confirmModal div.modal-body").append(radioHtml);
            }

            $('#confirmModal').modal('show');

        }
        else {
            bootbox.alert("File should be in .xlsx or .xls  format only");
            var ele = document.getElementById("fileInput");
            clearInputFile(ele);
        }


    };
}

$(document).off("click", "#btnUpload").on("click", "#btnUpload", function () {
    ////
    var currentTab = $("#activeTabMaster");

    var url = $(currentTab).data("uploadurl");


    // $('#loading').show();
    
    if (newFile != undefined) {
        var formData = new FormData();
        var totalFiles = 1;
        var dropedFile = newFile;
        formData.append("FileUpload", dropedFile);
        formData.append("FileName", newFile.name);

        if (currentTab.val() == "SubCategoryTOTMaster") {
            var radioVal = $("input[name=TOTCategory]:checked").val();
            formData.append("TOTCategory", radioVal);
        }

        $.ajax({
            type: "POST",
            url: url, //'/UploadMaster/' + actionName + '',
            data: formData,
            dataType: "json",
            contentType: false,
            processData: false,
            beforeSend: function () {
                $('#loading').show();
            },
            success: function (result) {
                $('#confirmModal').modal('hide');
                if (result.isSuccess == false) {
                    bootbox.dialog({
                        message: result.msg,
                        title: "Error!",
                        buttons: {
                            danger: {
                                label: "OK",
                                className: "btn-danger",
                                callback: function () {
                                    //Example.show("uh oh, look out!");
                                }
                            }
                        }
                    });
                }
                else {
                    bootbox.alert(result.msg);
                }
                if (result.isSuccess) {
                    if (currentTab.val() == "SecSalesReport") {
                        FillUploadSecondarySalesDataTable();
                    } else if (currentTab.val() == "ServiceTaxRateMaster") {
                        FillServiceTaxDataTable();
                    } else if (currentTab.val() == "SalesTaxMaster") {
                        FillSalesTaxRateDataTable();
                    }
                    else if (currentTab.val() == "ClusterRSCodeMappingMaster") {
                        FillClusterDataTable();
                    }
                    else if (currentTab.val() == "HuggiesBasepackMaster") {
                        FillHuggiesDataTable();
                    }
                    else if (currentTab.val() == "OutletMaster") {
                        FillOutletDataTable();
                    }
                    else if (currentTab.val() == "SkuMaster") {
                        FillSkuDataTable();
                    }
                    else if (currentTab.val() == "GstMaster") {
                        FillGstDataTable();
                    }
                    else if (currentTab.val() == "CustomerGroupMaster") {
                        FillCustomerGroupDataTable();
                    }
                    else if (currentTab.val() == "MTTierBasedTOTMaster") {
                        FillMTTierBasedTOTDataTable();
                    }
                    else if (currentTab.val() == "AdditionalMarginMaster") {
                        FillAdditonalMarginMasterDataTable();
                    }
                    else if (currentTab.val() == "BrandWiseSubCategoryMaster") {
                        FillBrandWiseSubCategoryDataTable();
                    }
                    else if (currentTab.val() == "SubCategoryTOTMaster") {
                        //FillSubCategoryTOTDataTable();
                        var radioVal_table = $("input[name=TOTCategory_tableDisplay]:checked").val();
                        if (radioVal_table.toLowerCase().trim() == radioVal.toLowerCase().trim()) {
                            //FillSubCategoryTOTDataTable();
                            UpdateTOTDataTable();
                        }
                        else {
                            $("input[type=radio][name=TOTCategory_tableDisplay][value=" + radioVal + "]").trigger('click');
                        }
                    }
                }
            },
            complete: function () {
                $('#loading').hide();
            }
        });
    }
    else if (document.getElementById("fileInput").files.length > 0) {
        var browsedFile = document.getElementById("fileInput").files[0];
        var imageName = browsedFile.name;
        //

        var formData = new FormData();
        formData.append("FileUpload", browsedFile);
        formData.append("ImageName", imageName);

        if (currentTab.val() == "SubCategoryTOTMaster") {
            var radioVal = $("input[name=TOTCategory]:checked").val();
            formData.append("TOTCategory", radioVal);
        }
        $.ajax({
            type: "POST",
            url: url,
            data: formData,
            dataType: "json",
            contentType: false,
            processData: false,
            beforeSend: function () {
                $('#loading').show();
            },
            success: function (result) {
                console.log("sdsd");
                $('#confirmModal').modal('hide');
                bootbox.alert(result.msg);
                if (result.isSuccess) {
                    if (currentTab == "SecSalesReport") {
                        FillUploadSecondarySalesDataTable();
                    }
                    else if (currentTab.val() == "ServiceTaxRateMaster") {
                        FillServiceTaxDataTable();
                    }
                    else if (currentTab.val() == "SalesTaxMaster") {
                        FillSalesTaxRateDataTable();
                    }
                    else if (currentTab.val() == "ClusterRSCodeMappingMaster") {
                        FillClusterDataTable();
                    }
                    else if (currentTab.val() == "SkuMaster") {
                        FillSkuDataTable();
                    }
                    else if (currentTab.val() == "GstMaster") {
                        FillGstDataTable();
                    }
                    else if (currentTab.val() == "OutletMaster") {
                        FillOutletDataTable();
                    }
                    else if (currentTab.val() == "HuggiesBasepackMaster") {
                        FillHuggiesDataTable();
                    }
                    else if (currentTab.val() == "CustomerGroupMaster") {
                        FillCustomerGroupDataTable();
                    }
                    else if (currentTab.val() == "BrandWiseSubCategoryMaster") {
                        FillBrandWiseSubCategoryDataTable();
                    }
                    else if (currentTab.val() == "MTTierBasedTOTMaster") {
                        FillMTTierBasedTOTDataTable();
                    }
                    else if (currentTab.val() == "AdditionalMarginMaster") {
                        FillAdditonalMarginMasterDataTable();
                    }
                    else if (currentTab.val() == "SubCategoryTOTMaster") {
                        //FillSubCategoryTOTDataTable();
                        var radioVal_table = $("input[name=TOTCategory_tableDisplay]:checked").val();
                        if (radioVal_table.toLowerCase().trim() == radioVal.toLowerCase().trim()) {
                            //FillSubCategoryTOTDataTable();
                            UpdateTOTDataTable();
                        }
                        else {
                            $("input[type=radio][name=TOTCategory_tableDisplay][value=" + radioVal + "]").trigger('click');
                        }
                        
                    }

                }
            },
            complete: function () {
                $('#loading').hide();
            }

        });
    }
    else {
        //$("#validateDroppedImage").show();

        $('#loading').hide();
    }
});



$("#fileInput").change(function (e) {
    //
    var browsedFile = document.getElementById("fileInput").files[0];
    var extension = browsedFile.name.replace(/^.*\./, '');
    newFile = browsedFile;
    if (extension == "xls" || extension == "xlsx") {
        var p = "<p>Are you sure.you want to upload:</p><p style='color:darkorange;'>" + browsedFile.name + "</p>";

        $("#confirmModal div.modal-body").html(p);

        var currentTab = $("#activeTabMaster");
        if (currentTab.val() == "SubCategoryTOTMaster") {
            var radioHtml = '<div><label class="radio-inline"><input type="radio" name="TOTCategory" value="on" checked="checked"><span class="lh2_2em">On Invoice</span></label>' +
                            '<label class="radio-inline"><input type="radio" name="TOTCategory" value="off"><span class="lh2_2em">Off Invoice Monthly</span></label>' +
                            '<label class="radio-inline"><input type="radio" name="TOTCategory" value="quarterly"><span class="lh2_2em">Off Invoice Quarterly</span></label></div>';
            $("#confirmModal div.modal-body").append(radioHtml);
        }

        $('#confirmModal').modal('show');

    }
    else {
        bootbox.alert("File should be in  .xls or .xlsx format only");
        var ele = document.getElementById("fileInput");
        clearInputFile(ele);
    }


});

$('#confirmModal').on('hidden.bs.modal', function () {
    //
    var ele = document.getElementById("fileInput");
    clearInputFile(ele);


})

function clearInputFile(f) {
    //
    if (f.value) {
        try {
            f.value = ''; //for IE11, latest Chrome/Firefox/Opera...
        } catch (err) {
        }
        if (f.value) { //for IE5 ~ IE10
            var form = document.createElement('form'), ref = f.nextSibling;
            form.appendChild(f);
            form.reset();
            ref.parentNode.insertBefore(f, ref);
        }
    }
}








