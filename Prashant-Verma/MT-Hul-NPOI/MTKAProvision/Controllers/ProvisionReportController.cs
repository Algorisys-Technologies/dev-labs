using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using MT.Model;
using MT.Business;
using MT.DataAccessLayer;
using MT.Utility;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Dynamic;
using System.Globalization;
using Newtonsoft.Json;
using System.Web.Script.Serialization;

namespace MTKAProvision.Controllers
{
    public class ProvisionReportController : AppController
    {
        ReportService reportService = new ReportService();
        BaseService baseService = new BaseService();
        DashboardService dashboardService = new DashboardService();
        ProvisionReportService provisionReportService = new ProvisionReportService();
        string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        private int TOTAL_ROWS = 0;
        // GET: ProvisionReport
        public ActionResult ZeroProvisionOutlet(string currentReportMOC)
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
            return Json(
             new
             {
                 PartialView = MvcHelper.PartialView(this, "_ZeroProvisionOutlet", null),
             }, JsonRequestBehavior.AllowGet);
        }
        public ActionResult ProvisionTrendAnalysisIndex(string currentReportMOC)
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
            var allmonth = DateTimeFormatInfo.CurrentInfo.MonthNames.Where(x => !String.IsNullOrEmpty(x)).Select((x, y) => new { Text = x, Value = (y + 1).ToString() + "." + currentReportMOC.Substring(currentReportMOC.Length - 4) });
            var selectedMonths = allmonth.Where(m => Convert.ToInt16(m.Value.Substring(0, m.Value.Length - 5)) <= Convert.ToInt16(currentReportMOC.Substring(0, currentReportMOC.Length - 5)));
            var monthlist = new SelectList(selectedMonths, "Value", "Text");
            ViewBag.MOCList = monthlist;

            ViewBag.currentMOC = monthlist.Where(a => a.Value == currentReportMOC).Select(b => b.Text).FirstOrDefault();
            ViewBag.selectedMOC = currentReportMOC;
            return Json(
             new
             {
                 PartialView = MvcHelper.PartialView(this, "_ProvisionTrendAnalysisIndex", null),
             }, JsonRequestBehavior.AllowGet);
        }


        public ActionResult ProvisionTrendAnalysis(string currentReportMOC)
        {

            //var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.CalculateProvision_StepId, currentReportMOC);
            //if (stepdetails.Status != "Done")
            //{
            //    ViewBag.IsProcessComplete = false;
            //}
            //else
            //{
            ViewBag.IsProcessComplete = true;
            //}
            ViewData["MonthlyToTProvisionTrendList"] = provisionReportService.GetMonthlyToTProvisionTrend(currentReportMOC);
            return Json(
             new
             {
                 PartialView = MvcHelper.PartialView(this, "_ProvisionTrendAnalysis", null),
             }, JsonRequestBehavior.AllowGet);
        }


        public ActionResult ProvisionTrendCategoryWiseIndex(string currentReportMOC)
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
            var allmonth = DateTimeFormatInfo.CurrentInfo.MonthNames.Where(x => !String.IsNullOrEmpty(x)).Select((x, y) => new { Text = x, Value = (y + 1).ToString() + "." + currentReportMOC.Substring(currentReportMOC.Length - 4) });
            var selectedMonths = allmonth.Where(m => Convert.ToInt16(m.Value.Substring(0, m.Value.Length - 5)) <= Convert.ToInt16(currentReportMOC.Substring(0, currentReportMOC.Length - 5)));
            var monthlist = new SelectList(selectedMonths, "Value", "Text");
            ViewBag.MOCList = monthlist;

            ViewBag.currentMOC = monthlist.Where(a => a.Value == currentReportMOC).Select(b => b.Text).FirstOrDefault();
            ViewBag.selectedMOC = currentReportMOC;
            return Json(
             new
             {
                 PartialView = MvcHelper.PartialView(this, "_ProvisionTrendCategoryWiseIndex", null),
             }, JsonRequestBehavior.AllowGet);
        }


        public ActionResult ProvisionTrendCategoryWise(string currentReportMOC)
        {

            //var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.CalculateProvision_StepId, currentReportMOC);
            //if (stepdetails.Status != "Done")
            //{
            //    ViewBag.IsProcessComplete = false;
            //}
            //else
            //{
            ViewBag.IsProcessComplete = true;
            //}
            ViewData["CategoryWiseToTProvisionTrendList"] = provisionReportService.GeCetegoryWiseToTProvisionTrend(currentReportMOC);
            return Json(
             new
             {
                 PartialView = MvcHelper.PartialView(this, "_ProvisionTrendCategoryWise", null),
             }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult AjaxGetZeroProvisionOutletData(JQDTParams param)
        {
            string search = "";//Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "HulOutletCode";
            string sortDirection = "asc";

            // note: we only sort one column at a time
            if (Request["order[0][column]"] != null)
            {
                sortColumn = int.Parse(Request["order[0][column]"]);
                sortColumnName = Request["columns[" + sortColumn + "][data]"];
            }
            if (Request["order[0][dir]"] != null)
            {
                sortDirection = Request["order[0][dir]"];
            }
            ZeroProvisionOutletDataTable dataTableData = new ZeroProvisionOutletDataTable();
            dataTableData.draw = param.draw;
            search = reportService.GetDataSearchText(param);


            DbRequest request = new DbRequest();

            request.StoredProcedureName = "sp_GetZeroProvisionOutletRowCount";
            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", CurrentMOC);
            request.Parameters.Add(paramMoc);
            if (TOTAL_ROWS == 0)
            {
                DataTable dt = new DataTable();
                dt = smartDataObj.GetdataExecuteStoredProcedure(request);

                TOTAL_ROWS = Convert.ToInt32(dt.Rows[0][0].ToString());
            }
            if (param.length == -1)
            {
                param.length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            dataTableData.data = provisionReportService.GetZeroProvisionOutletData(CurrentMOC, param.start, param.length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        public void Download_ToTProvisionTrendExcel(string moc)
        {
            DownloadExcelFile download = new DownloadExcelFile();
            DataTable data = new DataTable();

            var ToTProvisionTrendList = provisionReportService.GetMonthlyToTProvisionTrend(moc);
            data = provisionReportService.GetToTProvisionTrendDataTable(ToTProvisionTrendList);
            data.TableName = "ToT Provision Trend Analysis";
            download.ExportDataTableToExcel(data, "MonthlyToTProvisionTrendAnalysis");
        }

        public void DownloadZeroProvisionOutlet(string moc)
        {
            DownloadExcelFile download = new DownloadExcelFile();
            DataTable data = new DataTable();
            
            data = provisionReportService.GetAllZeroProvisionOutletData(moc);
            data.TableName = "Zero Provision Outlet";
            download.ExportDataTableToExcel(data, "ZeroProvisionOutlet");
        }
        public void Download_ToTProvisionTrendCategaoryWiseExcel(string moc)
        {
            DownloadExcelFile download = new DownloadExcelFile();
            DataTable data = new DataTable();

            var ToTProvisionTrendList = provisionReportService.GeCetegoryWiseToTProvisionTrend(moc);
            data = provisionReportService.GetToTProvisionTrendCategoryWiseDataTableForDownload(ToTProvisionTrendList);
            data.TableName = "ToT Provision Trend Category Wise";
            provisionReportService.ExportDataTableToExcelTOTProvision(data, "ToTProvisionTrendCategoryWise", ToTProvisionTrendList.Select(w=>w.MonthlyToTProvisionTrend).FirstOrDefault().Select(q=>q.UniqueMonthName).ToList());
        }
        public ActionResult RenderChartData(string currentReportMOC)
        {
            
            DataTable data = new DataTable();
            var ToTProvisionTrendList = provisionReportService.GetMonthlyToTProvisionTrend(currentReportMOC);
            //data = provisionReportService.GetToTProvisionTrendDataTable(ToTProvisionTrendList);

            var UniqueMonthName = ToTProvisionTrendList.Select(s=>s.UniqueMonthName).ToArray();
            var SalesTUR = ToTProvisionTrendList.Select(s => s.SalesTUR).ToArray();
            var TotProvision = ToTProvisionTrendList.Select(s => s.ToTProvision).ToArray();
            var ToTPercentage = ToTProvisionTrendList.Select(s => s.ToTPercentage).ToArray();

            return Json(new { UniqueMonthName = UniqueMonthName, SalesTUR = SalesTUR, TotProvision = TotProvision, ToTPercentage = ToTPercentage }, JsonRequestBehavior.AllowGet);
        }

       
    }
}