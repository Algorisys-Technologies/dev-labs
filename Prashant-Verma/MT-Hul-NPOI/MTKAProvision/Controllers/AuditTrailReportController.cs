using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Dynamic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class AuditTrailReportController : AppController
    {
        //
        // GET: /AuditTrailReport/

        private int TOTAL_ROWS = 0;
        SmartData smartDataObj = new SmartData();
        DashboardService dashboardService = new DashboardService();
        SecSalesReportService secSalesReportService = new SecSalesReportService();
        AssignAccessService assignAccessService = new AssignAccessService();
        ReportService reportService = new ReportService();
        DownloadExcelFile download = new DownloadExcelFile();
        AuditTrailReportService auditTrailReportService = new AuditTrailReportService();
        public ActionResult GenerateAuditTrailReport(string reportName, string entityName)
        {
            ViewBag.ReportName = reportName;


            return PartialView("_AuditTrailReportFilter");
        }
        public ActionResult GenerateAuditTrailReportTableViewFilterByDate(string reportName, string entityName, string frmDate, string toDate, int pageNo)
        {
            ViewBag.ReportName = reportName;
            string search = "";
            if (string.IsNullOrEmpty(frmDate)|| string.IsNullOrEmpty(toDate))
            {
                search = "Entity='" + entityName + "'";
            }
            else
            {
                search = "Entity='" + entityName + "' AND UpdatedDate Between '" + BaseService.ParseDate(frmDate).ToString("yyyy-MM-dd") + "' AND '" + BaseService.ParseDate(toDate).AddDays(1).ToString("yyyy-MM-dd") + "'";
            }
            ViewBag.RowCount = auditTrailReportService.GetRecordCountofAuditTrail(search);

            ViewData["AuditTrailList"] = auditTrailReportService.AuditTrailData(search, pageNo);

            return PartialView("_AuditTrailReport");
        }
        public ActionResult GenerateAuditTrailReportTableView(string reportName, string entityName, int pageNo)
        {
            ViewBag.ReportName = reportName;

            string search = "";

            search = "Entity='" + entityName + "'";
            ViewData["AuditTrailList"] = auditTrailReportService.AuditTrailData(search, pageNo);


            ViewBag.RowCount = auditTrailReportService.GetRecordCountofAuditTrail(search);
            return PartialView("_AuditTrailReport");
        }
        public void Download_AuditTrailExcel(string reportName, string entityName, string frmDate, string toDate)
        {
            string search = "";

            DownloadExcelFile download = new DownloadExcelFile();
            if (string.IsNullOrEmpty(frmDate) || string.IsNullOrEmpty(toDate))
            {

                search = "Entity='" + entityName + "'";
            }
            else
            {
                search = "Entity='" + entityName + "' AND UpdatedDate Between '" + BaseService.ParseDate(frmDate).ToString("yyyy-MM-dd") + "' AND '" + BaseService.ParseDate(toDate).AddDays(1).ToString("yyyy-MM-dd") + "'";
            }
            DataTable data = new DataTable();

            var AuditTrailList = auditTrailReportService.AuditTrailGetAllData(search);
            data = auditTrailReportService.GetNewAuditTrailDataTable(AuditTrailList);
            data.TableName = "AuditReport";
            download.ExportDataTableToExcel(data, "AuditReport-" + reportName);
        }


        //public ActionResult GenerateAuditTrailReportTableHeadingView(string reportName, string entityName)
        //{
        //    ViewBag.ReportName = reportName;

        //    string search = "";

        //    search = "Entity='" + entityName + "'";
        //    ViewData["AuditTrailList"] = auditTrailReportService.AuditTrailGetHeading(search);


        //    return PartialView("_AuditTrailPageScroll");
        //}

        [HttpPost]
        public ActionResult AjaxGetAuditTrailPageData(int draw, int start, int length)
        {
            string search = "";// searchValue;//Request["search[value]"];

            search = "Entity='" + "" + "'";
            //int sortColumn = -1;
            string sortColumnName = "CustomerCode";
            string sortDirection = "asc";

            //// note: we only sort one column at a time
            //if (Request["order[0][column]"] != null)
            //{
            //    sortColumn = int.Parse(Request["order[0][column]"]);
            //    sortColumnName = Request["columns[" + sortColumn + "][data]"];
            //}
            //if (Request["order[0][dir]"] != null)
            //{
            //    sortDirection = Request["order[0][dir]"];
            //}
            DataTable dataTableData = auditTrailReportService.AuditTrailPageWiseData(search);//(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }



    }
}