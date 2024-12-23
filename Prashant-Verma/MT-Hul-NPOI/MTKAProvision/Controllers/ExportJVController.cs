using MT.Business;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class ExportJVController : AppController
    {
        AssignAccessService assignAccessService = new AssignAccessService();
        string searchtext = "";
        //
        // GET: /ExportJV/
        string tableName = "";
        public ActionResult Index()
        {
            return View();
        }



        public ActionResult ExportOffInvoiceQtrly(string currentReportMOC)
        {
            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = ExportJVMasterConstants.ColumnsToDisplay;
            string excelNameToDisplay = ExportJVMasterConstants.OffInVoiceQtrlyExcelNameToDisplay + "(" + currentReportMOC.Replace('.', '-') + ")";
            //string tableName = ExportJVMasterConstants.OffInVoiceQtrlyViewName;
            searchtext = "TYPE='OFFQ' AND MOC=" + currentReportMOC;
            if (currentReportMOC != CurrentMOC)
            {
                tableName = "vwPrevMOCJV";
            }
            else
            {
                tableName = "vwCurrentMOCJV";
            }
            download.DownloadJV_ToExcel_WithName(columnsTodisplay, tableName, excelNameToDisplay, searchtext);
            return null;
        }
        public ActionResult ExportOffInvoice(string currentReportMOC)
        {
            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = ExportJVMasterConstants.ColumnsToDisplay;
            string excelNameToDisplay = ExportJVMasterConstants.OffInVoiceExcelNameToDisplay + "(" + currentReportMOC.Replace('.', '-') + ")";
            //string tableName = ExportJVMasterConstants.OffInvoiceViewName;
            searchtext = "TYPE='OFFM' AND MOC=" + currentReportMOC;
            if (currentReportMOC != CurrentMOC)
            {
                tableName = "vwPrevMOCJV";
            }
            else
            {
                tableName = "vwCurrentMOCJV";
            }
            download.DownloadJV_ToExcel_WithName(columnsTodisplay, tableName, excelNameToDisplay, searchtext);
            return null;
        }
        public ActionResult ExportOnInvoice(string currentReportMOC)
        {

            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = ExportJVMasterConstants.ColumnsToDisplay;
            string excelNameToDisplay = ExportJVMasterConstants.OnInVoiceExcelNameToDisplay + "(" + currentReportMOC.Replace('.', '-') + ")";
            //string tableName = ExportJVMasterConstants.OnInVoiceViewName;
            searchtext = "TYPE='ON' AND MOC=" + currentReportMOC;
            if (currentReportMOC != CurrentMOC)
            {
                tableName = "vwPrevMOCJV";
            }
            else
            {
                tableName = "vwCurrentMOCJV";
            }
            download.DownloadJV_ToExcel_WithName(columnsTodisplay, tableName, excelNameToDisplay, searchtext);
            return null;
        }

        public ActionResult CheckExportJVRight()
        {
            bool error = false;
            string msg = "";
            try
            {
                if (assignAccessService.CheckForStepExtractRight(SecurityPageConstants.ExportJV_PageId) == true)
                {
                    error = false;
                }
                else
                {
                    error = true;
                    msg = MessageConstants.InsufficientPermission;
                }
            }
            catch (Exception ex)
            {
                error = true;
                msg = ex.Message;
            }
            var data = new
           {
               error = error,
               msg = msg
           };
            return Json(data, JsonRequestBehavior.AllowGet);
        }




    }
}