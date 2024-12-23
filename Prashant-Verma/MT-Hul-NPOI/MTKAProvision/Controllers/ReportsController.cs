using MT.Business;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class ReportsController : AppController
    {
        public ActionResult Index(string moc)
        {
            ViewBag.ReportMOC = moc;
            ViewBag.CurrentMOC = CurrentMOC;
            ViewBag.PageTitle = "Reports";
            return View();
        }
        //public ActionResult ChangeReporteMOC(string moc)
        //{
        //    ViewBag.ReportMOC = moc;
        //    return Json(true, JsonRequestBehavior.AllowGet);
        //}
        public ActionResult Commingsoon()
        {
            return PartialView("_commingSoon");
        }

        [HttpGet]
        public ActionResult GetGroupWiseReport(string currentReportMOC)
        {
            var groupWiseReportService = new GroupWiseReportService();
            ReportResponse reportResponse = new ReportResponse();
            bool isCurrentMOC = true;
            string TableOrViewName = string.Empty;
            if (CurrentMOC != currentReportMOC)
                isCurrentMOC = false;

            if (isCurrentMOC == true)
                TableOrViewName = "vwCustomerwiseReport_CurrentMOC";
            else
                TableOrViewName = "vwCustomerwiseReport_PrevMOC";

            bool isGroupNameNull = groupWiseReportService.CheckForNullGroupName(TableOrViewName, currentReportMOC);
            // if (isGroupNameNull == false)
            // {
            reportResponse = groupWiseReportService.GetGroupWiseReportData(null, isCurrentMOC, currentReportMOC);
            ViewBag.DataForReport = reportResponse.ReportData;

            Session["GroupWiseReportRequest"] = reportResponse.ReportRequest;

            return Json(
           new
           {
               IsGroupNameNull = isGroupNameNull,
               PartialView = MvcHelper.PartialView(this, "_ReportView", reportResponse.ReportRequest),
           }, JsonRequestBehavior.AllowGet);
            // }
            //else
            //{
            //    return Json(
            //                 new
            //                 {
            //                     IsGroupNameNull = isGroupNameNull,
            //                 }, JsonRequestBehavior.AllowGet);
            //}
            ////return PartialView("_ReportView", reportResponse.ReportRequest);

        }


        public ActionResult GetReportOnAction(ReportAction request, string currentReportMOC)
        {
            ReportRequest reportRq = Session["GroupWiseReportRequest"] as ReportRequest;

            if (request.CurrentState == "expand")
            {
                //Collapse Request
                reportRq.ExpandedColumns = new List<ReportColumn>();
                reportRq.CollapsedColumns = new List<ReportColumn>();

                foreach (var col in reportRq.Columns.OrderBy(o => o.Sequence).ToList())
                {
                    if (col.Sequence < request.ColSeq)
                    {
                        reportRq.ExpandedColumns.Add(col);
                    }
                    else
                    {
                        reportRq.CollapsedColumns.Add(col);
                    }
                }
            }
            else
            {
                //Expand Request
                foreach (var col in reportRq.Columns.OrderBy(o => o.Sequence).ToList())
                {
                    if (col.Sequence >= request.ColSeq)
                    {
                        reportRq.ExpandedColumns.Add(col);
                    }
                }
            }

            var groupWiseReportService = new GroupWiseReportService();
            bool isCurrentMOC = true;
            if (CurrentMOC != currentReportMOC)
                isCurrentMOC = false;
            var reportResponse = groupWiseReportService.GetGroupWiseReportData(reportRq, isCurrentMOC, currentReportMOC);

            ViewBag.DataForReport = reportResponse.ReportData;
            return PartialView("_ReportView", reportRq);
        }

        public void Download_CustomerwiseReport(string currentReportMOC)
        {
            DownloadExcelFile download = new DownloadExcelFile();

            var groupWiseReportService = new GroupWiseReportService();
            bool isCurrentMOC = true;
            if (CurrentMOC != currentReportMOC)
                isCurrentMOC = false;
            var reportResponse = groupWiseReportService.GetGroupWiseReportData(null, isCurrentMOC, currentReportMOC);

            string tableName = "CustomerWiseReport";

            download.ExportDataTableToExcel(reportResponse.ReportData, tableName);


        }

    }
}