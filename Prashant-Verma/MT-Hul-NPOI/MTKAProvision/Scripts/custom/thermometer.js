$(document).ready(function () {
    var year = $("#thermoYearDropdown").val();
    SetThermometer(year);
});

function SetThermometer(year) {
    $.ajax({
        url: '/Dashboard/GetThermometerData',
        data: { thermoYear: year },
        dataType: "json",
        type: "GET",
        contentType: 'application/json; charset=utf-8',
        async: true,
        cache: false,
        success: function (data) {
            var htmlString = '<div class=" col-sm-8 col-sm-offset-4">' +
                            '<div class="donation-meter ">' +
                                '<span class="glass">' +
                                    '<h6 class="vertical">' +
                                        'Click on the month in <span class="green"> green color</span> to open reports or export JV' +
                                    '</h6>';
            var strongEle_BottomPerc = 1;
            var spanEle_BottomPerc = 0;
            $.each(data.mocList, function (index, value) {
                var colorCode = '';
                var className = '';
                if (value.Status == "Open") {
                    colorCode = "#F7FE2E";
                    className = "closedMoc";
                }
                else if (value.Status == "Close") {
                    colorCode = "#04B404";
                    className = "closedMoc";
                }
                else if (value.Status == "NotPresent") {
                    colorCode = "#808080";
                }

                htmlString += '<a href="javascript:void(0);" class="' + className + '" data-moc="' + value.MonthId + '.' + value.Year + '">' +
                                        '<strong class="total" style="bottom: ' + strongEle_BottomPerc + '%">' + value.Month + '</strong>' +
                                        '<span class="amount" style="background: ' + colorCode + '; bottom: ' + spanEle_BottomPerc + '%;">' +
                                        '</span>' +
                                        '</a>';

                strongEle_BottomPerc = strongEle_BottomPerc + 8;
                spanEle_BottomPerc = spanEle_BottomPerc + 8;
            });

            htmlString += '</span>' +
                                '<div class="bulb">' +
                                    '<span class="red-circle"></span>' +
                                    '<span class="filler"><span></span></span>' +
                                '</div>' +
                            '</div>' +
                            '<h6 class="thermo-title">MOC Provision Status - ' + data.mocList[0].Year + '</h6>' +
                        '</div>';


            $("#thermometerDiv").html(htmlString);
        }
    });
}