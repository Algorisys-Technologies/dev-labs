using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
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
    public class ExceptionReportGSVController : AppController
    {
        CalculateGSVService calculateGSVService = new CalculateGSVService();
        AssignAccessService assignAccessService = new AssignAccessService();
        ReportService reportService = new ReportService();
        BaseService baseService = new BaseService();
        DashboardService dashboardService = new DashboardService();
        private int TOTAL_ROWS = 0;

        public ActionResult Report()
        {
            //return PartialView("Index");
            return Json(
              new
              {
                  PartialView = MvcHelper.PartialView(this, "Index", null),
              }, JsonRequestBehavior.AllowGet);
        }
        public ActionResult GSVException(string currentReportMOC)
        {
            var stepdetails = dashboardService.GetStepStatus(DashBoardConstants.CalculateGSV_StepId, currentReportMOC);
            if (stepdetails.Status != "Done")
            {
                ViewBag.IsProcessComplete = false;
            }
            else
            {
                ViewBag.IsProcessComplete = true;
            }
            return PartialView("_GSVException");
        }

        [HttpPost]
        public ActionResult AjaxGetGSVExceptionData(JQDTParams param)
        {
            string search = "";//Request["search[value]"];
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
            MOCCalculationDataTable dataTableData = new MOCCalculationDataTable();
            dataTableData.draw = param.draw;
            search = reportService.GetDataSearchText(param);

            DbRequest request = new DbRequest();

            //request.StoredProcedureName = "mtspGetRowCountGSVException";
            //request.Parameters = new List<Parameter>();
            //Parameter paramMoc = new Parameter("moc", Convert.ToDecimal(CurrentMOC));
            //Parameter paramsearch = new Parameter("search", search);
            //request.Parameters.Add(paramMoc);
            //request.Parameters.Add(paramsearch);
            DataTable dt = new DataTable();
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            string sqlQuery = "";
            //if (search == "")
            //{
            //    sqlQuery = "select COUNT(*) from vwCalculatedProvision where((statecode is null) or(TaxCode is null and statecode not in (select statecode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1))or(taxcode is null and statecode is null))and MOC = " + CurrentMOC;
            //}
            //else
            //{
            //    sqlQuery = "select COUNT(*) from vwCalculatedProvision where((statecode is null) or(TaxCode is null and statecode not in (select statecode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1))or(taxcode is null and statecode is null))and MOC = " + CurrentMOC + " AND " + search;
            //}

            if (search == "")
            {
                sqlQuery = "with table1 as(select * from vwCalculatedProvision where ((statecode is null) or (TaxCode is null and " +
                    "statecode not in (select statecode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1))or(taxcode is null and statecode is null)) and MOC = " + CurrentMOC +
                    " and isgstapplicable=0 union all select * from vwCalculatedProvision prov where BasepackCode not in (select BasepackCode from mtgstmaster) and MOC = " + CurrentMOC + " and IsGstApplicable = 1" +
                    " )" +
                    "SELECT COUNT(*) FROM  table1";
            }
            else
            {
                sqlQuery = "with table1 as(select * from vwCalculatedProvision where ((statecode is null) or (TaxCode is null and " +
               "statecode not in (select statecode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1))or(taxcode is null and statecode is null)) and MOC = " + CurrentMOC +
                   " and isgstapplicable=0 union all select * from vwCalculatedProvision prov where BasepackCode not in (select BasepackCode from mtgstmaster) and MOC = " + CurrentMOC + " and IsGstApplicable = 1" +
                   " )" +
               "SELECT COUNT(*) FROM  table1 WHERE  " + search;
            }

            request.SqlQuery = sqlQuery;
            dt = smartDataObj.GetData(request);
            TOTAL_ROWS = Convert.ToInt32(dt.Rows[0][0].ToString());
            if (param.length == -1)
            {
                param.length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;

            dataTableData.data = calculateGSVService.GetExceptionData(CurrentMOC, param.start, param.length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        public void DownloadGSVExpeption()
        {
            DataTable dt1 = new DataTable();
            DbRequest request = new DbRequest();

            request.StoredProcedureName = "mtspGetAllGSVException";
            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", CurrentMOC);
            request.Parameters.Add(paramMoc);
            dt1 = smartDataObj.GetdataExecuteStoredProcedure(request);
            if (dt1 != null)
            {
                ExportDataTableToExcel(dt1, "gsvException");
            }
        }
    }
}