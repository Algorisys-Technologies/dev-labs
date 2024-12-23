using MT.Business;
using MT.DataAccessLayer;
using MT.Logging;
using MT.Model;
using MT.Utility;
using MTKAProvision.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class CalculateProvisionController : AppController
    {
        CalculateProvisionService calculateProvisionService = new CalculateProvisionService();
        DashboardService dashboardService = new DashboardService();
        ReportService reportService = new ReportService();
        AssignAccessService assignAccessService = new AssignAccessService();
        GroupWiseReportService groupWiseReportService = new GroupWiseReportService();
        private int TOTAL_ROWS = 0;

        public ActionResult Index()
        {
            Logger.Log(LogLevel.INFO, "Index function started.");
            try
            {
                ViewBag.IsProcessComplete = true;
                ViewBag.currentMOC = CurrentMOC;
                ViewBag.PageTitle = "Calculated Provision";
                return View();
            }
            catch (Exception ex)
            {
                Logger.Log(LogLevel.ERROR, "Exception in Index function: " + ex.Message);
                throw;
            }
            finally
            {
                Logger.Log(LogLevel.INFO, "Index function completed.");
            }
        }

        public ActionResult Report(string currentReportMOC)
        {
            Logger.Log(LogLevel.INFO, "Report function started with MOC: " + currentReportMOC);
            try
            {
                var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.CalculateProvision_StepId, currentReportMOC);
                if (stepdetails.Status != "Done")
                {
                    ViewBag.IsProcessComplete = false;
                }
                else
                {
                    ViewBag.IsProcessComplete = true;
                }
                ViewBag.currentMOC = currentReportMOC;
                return Json(
                  new
                  {
                      PartialView = MvcHelper.PartialView(this, "Index", null),
                  }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Log(LogLevel.ERROR, "Exception in Report function: " + ex.Message);
                throw;
            }
            finally
            {
                Logger.Log(LogLevel.INFO, "Report function completed.");
            }
        }

        [HttpGet]
        public ActionResult Calculate()
        {
            Logger.Log(LogLevel.INFO, "Calculate function started.");
            string msg = "";
            bool errorstatus;
            try
            {
                if (assignAccessService.CheckForStepExecuteRight(SecurityPageConstants.CalculateProvision_PageId) == true)
                {
                    DbRequest request = new DbRequest
                    {
                        Parameters = new List<Parameter>(),
                        StoredProcedureName = "mtspCalculateProvision"
                    };
                    Parameter param = new Parameter("MOC", CurrentMOC);
                    request.Parameters.Add(param);

                    smartDataObj.ExecuteStoredProcedure(request);
                    errorstatus = false;
                    var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.CalculateProvision_StepId, CurrentMOC);
                    if (stepdetails.Status == "Done")
                    {
                        dashboardService.Update_SetNextStepsNotStarted(DashBoardConstants.CalculateProvision_StepId, CurrentMOC, loggedUser.UserId);
                    }
                    dashboardService.Update_SingleStepStatus(DashBoardConstants.CalculateProvision_StepId, CurrentMOC);
                    msg = "Provision Calculation done Sucessfully!";
                    groupWiseReportService.AsyncGenerateCustomerWiseReport(CurrentMOC);
                }
                else
                {
                    errorstatus = true;
                    msg = MessageConstants.InsufficientPermission;
                }
            }
            catch (Exception ex)
            {
                msg = ex.Message;
                errorstatus = true;
                Logger.Log(LogLevel.ERROR, "Exception in Calculate function: " + ex.Message);
            }
            finally
            {
                Logger.Log(LogLevel.INFO, "Calculate function completed.");
            }

            var data = new
            {
                error = errorstatus,
                msg = msg
            };
            Logger.Log(LogLevel.INFO, "Calculate Provision End Time: " + DateTime.Now);
            return Json(data, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult AjaxGetMOCCalculationData(JQDTParams param, string currentReportMOC)
        {
            Logger.Log(LogLevel.INFO, "AjaxGetMOCCalculationData function started with MOC: " + currentReportMOC);
            MOCCalculationDataTable dataTableData = new MOCCalculationDataTable();
            try
            {
                var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.CalculateProvision_StepId, currentReportMOC);
                if (stepdetails.Status != "Done")
                {
                    return Json(dataTableData, JsonRequestBehavior.AllowGet);
                }
                string search = Request["search[value]"];
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
                dataTableData.draw = param.draw;
                search = reportService.GetDataSearchText(param);
                string tableView = "";
                if (currentReportMOC == CurrentMOC)
                {
                    tableView = "vwCalculatedProvision";
                }
                else
                {
                    tableView = "mtPrevProvision";
                    if (search == "")
                    {
                        search = " MOC=" + currentReportMOC;
                    }
                    else
                    {
                        search += " AND MOC=" + currentReportMOC;
                    }
                }
                TOTAL_ROWS = calculateProvisionService.GetTotalRowsCount(search, tableView);
                if (param.length == -1)
                {
                    param.length = TOTAL_ROWS;
                }
                dataTableData.recordsTotal = TOTAL_ROWS;
                int recordsFiltered = 0;

                dataTableData.data = calculateProvisionService.FilterData(ref recordsFiltered, param.start, param.length, search, sortColumnName, sortDirection, currentReportMOC, tableView);

                dataTableData.recordsFiltered = TOTAL_ROWS;
                return Json(dataTableData, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                Logger.Log(LogLevel.ERROR, "Exception in AjaxGetMOCCalculationData function: " + ex.Message);
                throw;
            }
            finally
            {
                Logger.Log(LogLevel.INFO, "AjaxGetMOCCalculationData function completed.");
            }
        }

        public FileResult DownloadExcel(string currentReportMOC)
        {
            Logger.Log(LogLevel.INFO, "DownloadExcel function started with MOC: " + currentReportMOC);
            try
            {
                string filePath = calculateProvisionService.ExportSqlDataReaderToCsv(currentReportMOC, "Provision Calculation MOC(" + CurrentMOC + ")");
                Response.BufferOutput = false;
                return File(filePath, "text/csv", filePath.Split('/').LastOrDefault());
            }
            catch (Exception ex)
            {
                Logger.Log(LogLevel.ERROR, "Exception in DownloadExcel function: " + ex.Message);
                throw;
            }
            finally
            {
                Logger.Log(LogLevel.INFO, "DownloadExcel function completed.");
            }
        }
    }
}
