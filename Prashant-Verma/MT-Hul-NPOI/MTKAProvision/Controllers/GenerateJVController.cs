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
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class GenerateJVController : AppController
    {
        GenerateJVService generateJVService = new GenerateJVService();
        //
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        private int TOTAL_ROWS = 0;
        public string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        SmartData smartDataObj = new SmartData();
        string tableView = "";
        public ActionResult OnInvoice(string currentReportMOC)
        {
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.GenerateJV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                ViewBag.IsProcessComplete = false;
            }
            else
            {
                ViewBag.IsProcessComplete = true;
            }
            //return PartialView("OnInvoice");
            return Json(
              new
              {
                  PartialView = MvcHelper.PartialView(this, "OnInvoice", null),
              }, JsonRequestBehavior.AllowGet);
        }
        public ActionResult OffInvoiceMthly(string currentReportMOC)
        {
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.GenerateJV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                ViewBag.IsProcessComplete = false;
            }
            else
            {
                ViewBag.IsProcessComplete = true;
            }
            //return PartialView("OffInvoiceMthly");
            return Json(
              new
              {
                  PartialView = MvcHelper.PartialView(this, "OffInvoiceMthly", null),
              }, JsonRequestBehavior.AllowGet);
        }
        public ActionResult OffInvoiceQtrly(string currentReportMOC)
        {
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.GenerateJV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                ViewBag.IsProcessComplete = false;
            }
            else
            {
                ViewBag.IsProcessComplete = true;
            }
            //return PartialView("OffInvoiceQtrly");
            return Json(
             new
             {
                 PartialView = MvcHelper.PartialView(this, "OffInvoiceQtrly", null),
             }, JsonRequestBehavior.AllowGet);
        }
        public void GenarateCategoryWiseTotProvisionTrend(string moc)
        {

            DbRequest request = new DbRequest();

            DataTable dt = new DataTable();

            request.Parameters = new List<Parameter>();
            Parameter paramMocYEAR = new Parameter("MocYEAR", moc.Substring(moc.Length - 4));
            Parameter paramMocMonthId = new Parameter("MocMonthId", moc.Substring(0, (moc.Length - 5)));
            request.Parameters.Add(paramMocYEAR);
            request.Parameters.Add(paramMocMonthId);
            request.StoredProcedureName = "sp_UploadDataCategoryWiseToTProvisionTrend";
            smartDataObj.ExecuteStoredProcedure(request);


        }
        [HttpGet]
        public ActionResult Calculate()
        {
            Logger.Log(LogLevel.INFO, "Generate JV Start Time: " + DateTime.Now);
            string msg = "";
            bool errorstatus;
            if (assignAccessService.CheckForStepExecuteRight(SecurityPageConstants.GenerateJV_PageId) == true)
            {
                DbRequest request = new DbRequest();
                request.Parameters = new List<Parameter>();
                request.StoredProcedureName = "mtspGenerateJV";
                Parameter param = new Parameter("MOC", CurrentMOC);
                Parameter paramuser = new Parameter("user", "Admin");
                request.Parameters.Add(param);
                request.Parameters.Add(paramuser);
                try
                {
                    smartDataObj.ExecuteStoredProcedure(request);
                    errorstatus = false;
                    dashboardService.Update_SingleStepStatus(DashBoardConstants.GenerateJV_StepId, CurrentMOC);
                    GenarateCategoryWiseTotProvisionTrend(CurrentMOC);
                    msg = "Generate JV done Sucessfully!";
                }
                catch (Exception ex)
                {
                    msg = ex.Message;
                    errorstatus = true;
                }
            }
            else
            {
                errorstatus = true;
                msg = MessageConstants.InsufficientPermission;
            }
            var data = new
            {
                error = errorstatus,
                msg = msg
            };
            Logger.Log(LogLevel.INFO, "Generate JV End Time: " + DateTime.Now);
            return Json(data, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult AjaxGetOnInvoiceJVData(int draw, int start, int length, string currentReportMOC)
        {
            OnInvoiceJVDataTable dataTableData = new OnInvoiceJVDataTable();
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.GenerateJV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                return Json(dataTableData, JsonRequestBehavior.AllowGet);
            }
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "CustomerCode";
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
            dataTableData.draw = draw;

            if (currentReportMOC == CurrentMOC)
            {
                tableView = "vwCurrentMOCJV";
            }
            else
            {
                tableView = "vwPrevMOCJV";
            }
            TOTAL_ROWS = GetTotalRowsCountByMOC(tableView, search, currentReportMOC);
            if (length == -1)
            {
                length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;
            dataTableData.data = generateJVService.FilterJVData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection, currentReportMOC, tableView);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public ActionResult AjaxGetOffInvoiceQrtlyJVData(int draw, int start, int length, string currentReportMOC)
        {
            OnInvoiceJVDataTable dataTableData = new OnInvoiceJVDataTable();
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.GenerateJV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                return Json(dataTableData, JsonRequestBehavior.AllowGet);
            }
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "CustomerCode";
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
            dataTableData.draw = draw;
            if (currentReportMOC == CurrentMOC)
            {
                tableView = "vwCurrentMOCJV";
            }
            else
            {
                tableView = "vwPrevMOCJV";
            }
            TOTAL_ROWS = GetTotalRowsCountByMOC(tableView, search, currentReportMOC);
            if (length == -1)
            {
                length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;
            dataTableData.data = generateJVService.FilterJVData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection, currentReportMOC, tableView);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public ActionResult AjaxGetOffInvoiceMonthlyJVData(int draw, int start, int length, string currentReportMOC)
        {
            OnInvoiceJVDataTable dataTableData = new OnInvoiceJVDataTable();
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.GenerateJV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                return Json(dataTableData, JsonRequestBehavior.AllowGet);
            }
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "CustomerCode";
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
            dataTableData.draw = draw;
            if (currentReportMOC == CurrentMOC)
            {
                tableView = "vwCurrentMOCJV";
            }
            else
            {
                tableView = "vwPrevMOCJV";
            }
            TOTAL_ROWS = GetTotalRowsCountByMOC(tableView, search, currentReportMOC);
            if (length == -1)
            {
                length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;
            dataTableData.data = generateJVService.FilterJVData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection, currentReportMOC, tableView);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        //public void DownloadONInvoiceJVExcel(string currentReportMOC)
        //{
        //    string tableView = "";
        //    if (currentReportMOC == CurrentMOC)
        //    {
        //        tableView = "vwOnInvoiceJV";
        //    }
        //    else
        //    {
        //        tableView = "vwPrevOnInvoiceJV";
        //    }
        //    using (DataSet ds = generateJVService.GetJVToDownload(CurrentMOC, tableView))
        //    {
        //        if (ds != null && ds.Tables.Count > 0)
        //        {

        //            foreach (DataTable dt in ds.Tables)
        //            {

        //                ExportDataTableToExcel(dt, "ON Invoice JV");
        //            }

        //        }
        //    }

        //}

        //public void DownloadOffInvoiceMonthlyJVExcel(string currentReportMOC)
        //{
        //    string tableView = "";
        //    if (currentReportMOC == CurrentMOC)
        //    {
        //        tableView = "vwOffInvoiceMthlyJV";
        //    }
        //    else
        //    {
        //        tableView = "vwPrevOffInvoiceMthlyJV";
        //    }
        //    using (DataSet ds = generateJVService.GetJVToDownload(CurrentMOC, tableView))
        //    {
        //        if (ds != null && ds.Tables.Count > 0)
        //        {

        //            foreach (DataTable dt in ds.Tables)
        //            {

        //                ExportDataTableToExcel(dt, "ON Invoice JV");
        //            }

        //        }
        //    }

        //}

        //public void DownloadOffInvoiceQrtlyJVExcel(string currentReportMOC)
        //{
        //    string tableView = "";
        //    if (currentReportMOC == CurrentMOC)
        //    {
        //        tableView = "vwOffInvoiceQtrlyJV";
        //    }
        //    else
        //    {
        //        tableView = "vwPrevOffInvoiceQtrlyJV";
        //    }
        //    using (DataSet ds = generateJVService.GetJVToDownload(CurrentMOC, tableView))
        //    {
        //        if (ds != null && ds.Tables.Count > 0)
        //        {

        //            foreach (DataTable dt in ds.Tables)
        //            {

        //                ExportDataTableToExcel(dt, "ON Invoice JV");
        //            }

        //        }
        //    }

        //}

        public int GetTotalRowsCountByMOC(string tableView, string search, string currentReportMOC)
        {
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            if (currentReportMOC == CurrentMOC)
            {
                if (string.IsNullOrEmpty(search))
                {
                    request.SqlQuery = "Select Count(*) from " + tableView + " where MOC='" + currentReportMOC +"'";
                }
                else
                {
                    request.SqlQuery = "Select Count(*) from " + tableView + " WHERE FREETEXT (*, '" + search + "') AND MOC='" + currentReportMOC + "'";
                }
            }
            else
            {
                if (string.IsNullOrEmpty(search))
                {
                    request.SqlQuery = "Select Count(*) from " + tableView + " where MOC='" + currentReportMOC + "'";
                }
                else
                {
                    request.SqlQuery = "Select Count(*) from " + tableView + " WHERE FREETEXT (*, '" + search + "') AND MOC='" + currentReportMOC + "'";
                }
            }

            dt = smartDataObj.GetData(request);

            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            return recordsCount;
        }

    }
}