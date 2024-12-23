using MT.Business;
using MT.DataAccessLayer;
using MT.Logging;
using MT.Model;
using MT.SessionManager;
using MT.Utility;
using MTKAProvision.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Xml;

namespace MTKAProvision.Controllers
{
    public class SecSalesReportController : AppController
    {
        private int TOTAL_ROWS = 0;
        SmartData smartDataObj = new SmartData();
        DashboardService dashboardService = new DashboardService();
        SecSalesReportService secSalesReportService = new SecSalesReportService();
        AssignAccessService assignAccessService = new AssignAccessService();
        ReportService reportService = new ReportService();

        public ActionResult Index()
        {
            //Console.WriteLine("Index Action - Start");
          //  Logger.Log(LogLevel.INFO, "Index Action - Start");

            ViewBag.PageTitle = "Upload Secondary Sales";
            ViewBag.currentMOC = CurrentMOC;

         //   Console.WriteLine("Index Action - Setting Page Title and CurrentMOC");
         //   Logger.Log(LogLevel.INFO, "Index Action - Setting Page Title and CurrentMOC");

         //   Console.WriteLine("Index Action - End");
          //  Logger.Log(LogLevel.INFO, "Index Action - End");
            return View();
        }

        [HttpGet]
        public ActionResult CheckExistingData()
        {
            Console.WriteLine("CheckExistingData Action - Start");
            Logger.Log(LogLevel.INFO, "CheckExistingData Action - Start");

            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT count(*) FROM mtSecSalesReport WHERE MOC = '" + CurrentMOC + "'";
            Console.WriteLine("CheckExistingData - SQL Query: " + request.SqlQuery);
            Logger.Log(LogLevel.INFO, "CheckExistingData - SQL Query: " + request.SqlQuery);

            var existingData = smartDataObj.GetData(request);
            var result = new
            {
                recordExists = false
            };

            if (Convert.ToInt32(existingData.Rows[0].ItemArray[0]) > 0)
            {
                result = new { recordExists = true };
            }

            Console.WriteLine("CheckExistingData - Result: " + result.recordExists);
            Logger.Log(LogLevel.INFO, "CheckExistingData - Result: " + result.recordExists);

            Console.WriteLine("CheckExistingData Action - End");
            Logger.Log(LogLevel.INFO, "CheckExistingData Action - End");

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult UploadUploadSecondarySalesFile()
        {
            Console.WriteLine("UploadUploadSecondarySalesFile Action - Start");
            Logger.Log(LogLevel.INFO, "UploadUploadSecondarySalesFile Action - Start");

            bool isSuccess = false;
            string message = string.Empty;
            List<string> logMessages = new List<string>();

            logMessages.Add("Checking for master upload right");
            Logger.Log(LogLevel.INFO, "Checking for master upload right");

            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.SecSalesMaster_PageId) == true)
            {
                if (Request.Files.Count > 0)
                {
                    try
                    {
                        DbRequest request = new DbRequest();
                        DataTable dt = new DataTable();

                        foreach (string upload in Request.Files)
                        {
                            logMessages.Add("Processing uploaded file: " + Request.Files[upload].FileName);
                            Logger.Log(LogLevel.INFO, "Processing uploaded file: " + Request.Files[upload].FileName);

                            string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
                            string filename = Path.GetFileName(Request.Files[upload].FileName);
                            Request.Files[upload].SaveAs(Path.Combine(path, filename));

                            logMessages.Add("File saved at: " + Path.Combine(path, filename));
                            Logger.Log(LogLevel.INFO, "File saved at: " + Path.Combine(path, filename));

                            string fullPath = Path.Combine(path, filename);

                            Logger.Log(LogLevel.INFO, "Path Combine");

                            var fileValidation = secSalesReportService.FindCurrentMOCInExcelFile(fullPath, CurrentMOC);

                            Logger.Log(LogLevel.INFO, "Find MOC");

                            if (Convert.ToBoolean(fileValidation.IsvalidData) == false)
                            {
                                Logger.Log(LogLevel.INFO, "Convert Boolen");
                                isSuccess = false;
                                message = "Invalid data in Excel. Column must be: <br/>" + fileValidation.ValidColumnSequence;

                                logMessages.Add("Invalid data in Excel: " + message);
                                Logger.Log(LogLevel.ERROR, "Invalid data in Excel: " + message);

                            }
                            else if (Convert.ToBoolean(fileValidation.IsvalidFile) == false) {
                                Logger.Log(LogLevel.INFO, "File validate");
                                isSuccess = false;
                                int currentMonth = Convert.ToInt16(CurrentMOC.Split('.').FirstOrDefault());
                                string currentmonthname = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(currentMonth);
                                string actualMOC = fileValidation.MOC.ToString();
                                int actualDatatMonth = Convert.ToInt16(actualMOC.Split('.').FirstOrDefault());
                                string actualmonthname = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(actualDatatMonth);

                                message = "File does not contain " + currentmonthname + " MOC data, you are uploading " + actualmonthname + " MOC secondary sales report!";
                                logMessages.Add("File validation failed: " + message);
                                Logger.Log(LogLevel.ERROR, "File validation failed: " + message);
                            }
                            else
                            {

                                Logger.Log(LogLevel.INFO, "Deleting old Data from Secondary Sales Report - Start");

                                request.Parameters = new List<Parameter>();
                                Parameter paramMoc = new Parameter("Moc", CurrentMOC);
                                request.Parameters.Add(paramMoc);
                                request.StoredProcedureName = "sp_DeleteSecSalesReportInBatch";
                                smartDataObj.ExecuteStoredProcedure(request);

                                
                                Logger.Log(LogLevel.INFO, "Deleting old Data from Secondary Sales Report - End");

                                /////////----------validate----------////////

                                var uploadResponse = secSalesReportService.UploadSecSalesReportFile(fullPath);
                                if (uploadResponse.IsSuccess)
                                {
                                    var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.UploadSecSales_StepId, CurrentMOC);
                                    if (stepdetails.Status == "Done")
                                    {
                                        dashboardService.Update_StepsAfterUploadSecSalesReport(DashBoardConstants.UploadSecSales_StepId, CurrentMOC, loggedUser.UserId);
                                    }
                                    dashboardService.Update_SingleStepStatus(DashBoardConstants.UploadSecSales_StepId, CurrentMOC);
                                }

                                Logger.Log(LogLevel.INFO, "Upload Secondary Sales - End");

                                message = uploadResponse.MessageText;
                                isSuccess = uploadResponse.IsSuccess;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.LogError(ex);
                        isSuccess = false;
                        message = MessageConstants.Error_Occured + ex.Message;
                        logMessages.Add("Exception occurred: " + ex.Message);
                        Logger.Log(LogLevel.ERROR, "Exception occurred: " + ex.Message);
                    }
                }
                else
                {
                    isSuccess = false;
                    message = MessageConstants.No_Files_Selected;
                    logMessages.Add("No files selected for upload");
                    Logger.Log(LogLevel.ERROR, "No files selected for upload");
                }
            }
            else
            {
                isSuccess = false;
                message = MessageConstants.InsufficientPermission;
                logMessages.Add("Insufficient permissions to upload");
                Logger.Log(LogLevel.ERROR, "Insufficient permissions to upload");
            }

            logMessages.Add("UploadUploadSecondarySalesFile result: " + message);

            Logger.Log(LogLevel.INFO, "UploadUploadSecondarySalesFile result: " + message);

            return Json(new
            {
                isSuccess = isSuccess,
                msg = message,
                logs = logMessages // Include logs in the response
            }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult AjaxGetUploadSecondarySalesData(JQDTParams param)
        {

            Logger.Log(LogLevel.INFO, "AjaxGetUploadSecondarySalesData Action - Start");

            string search = "";
            int sortColumn = -1;
            string sortColumnName = "CustomerCode";
            string sortDirection = "asc";

            if (Request["order[0][column]"] != null)
            {
                sortColumn = int.Parse(Request["order[0][column]"]);
                sortColumnName = Request["columns[" + sortColumn + "][data]"];
            }
            if (Request["order[0][dir]"] != null)
            {
                sortDirection = Request["order[0][dir]"];
            }
            search = reportService.GetDataSearchText(param);

            Logger.Log(LogLevel.INFO, "Filtering data for MOC: " + CurrentMOC);

            SecSalesReportDataTable dataTableData = new SecSalesReportDataTable();
            dataTableData.draw = param.draw;
            TOTAL_ROWS = secSalesReportService.GetTotalRowsCountSecSalesReport(search, CurrentMOC);

            Logger.Log(LogLevel.INFO, "Total Rows: " + TOTAL_ROWS);

            if (param.length == -1)
            {
                param.length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;
            dataTableData.data = secSalesReportService.FilterData(ref recordsFiltered, param.start, param.length, search, sortColumnName, sortDirection, CurrentMOC);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            Logger.Log(LogLevel.INFO, "AjaxGetUploadSecondarySalesData result: recordsTotal = " + dataTableData.recordsTotal + ", recordsFiltered = " + recordsFiltered);

            Logger.Log(LogLevel.INFO, "AjaxGetUploadSecondarySalesData Action - End");
            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        public FileResult DownloadExcel()
        {
            Logger.Log(LogLevel.INFO, "DownloadExcel Action - Start");

            string filePath = secSalesReportService.ExportSqlDataReaderToCsv("Secondary Sales MOC(" + CurrentMOC.Replace('.', '-') + ")");

            Logger.Log(LogLevel.INFO, "DownloadExcel filePath: " + filePath);

            Response.BufferOutput = false;

            Logger.Log(LogLevel.INFO, "DownloadExcel Action - End");
            return File(filePath, "text/csv", filePath.Split('/').LastOrDefault());
        }
    }
}
