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
    public class ExceptionReportProvisionController : AppController
    {
        CalculateProvisionService calculateProvisionService = new CalculateProvisionService();
        AssignAccessService assignAccessService = new AssignAccessService();
        ReportService reportService = new ReportService();
        BaseService baseService = new BaseService();
        DashboardService dashboardService = new DashboardService();
        private int TOTAL_ROWS = 0;

        public ActionResult ProvisionException(string currentReportMOC)
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
            return PartialView("_ProvisionException");
        }

        public ActionResult ExceptionDataOutLetCode(string currentReportMOC)
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
            return PartialView("_ExceptionDataOutLetCode");
        }
        public ActionResult TOTSubCategoryException(string currentReportMOC)
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
            return PartialView("_TOTSubCategoryException");
        }
        [HttpPost]
        public ActionResult AjaxGetProvisionExceptionData(JQDTParams param)
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

            request.StoredProcedureName = "mtspGetRowCountProExChainNmGrpNm";
            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", CurrentMOC);
            request.Parameters.Add(paramMoc);

            DataTable dt = new DataTable();
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);

            TOTAL_ROWS = Convert.ToInt32(dt.Rows[0][0].ToString());
            if (param.length == -1)
            {
                param.length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            dataTableData.data = calculateProvisionService.GetProvisionExceptionData(CurrentMOC, param.start, param.length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }


        //public FileResult DownloadExcel(string currentReportMOC)
        //{
        //    string filePath = calculateProvisionService.ExportSqlDataReaderToCsv(currentReportMOC, "GSV Calculation MOC(" + CurrentMOC.Replace('.', '-') + ")");

        //    Response.BufferOutput = false;
        //    return File(filePath, "text/csv", filePath.Split('/').LastOrDefault());
        //}
        [HttpPost]
        public ActionResult AjaxGetProvisionExceptionOnTOTSubCategory(JQDTParams param)
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

            //request.StoredProcedureName = "mtspGetRowCountProvExOnTOTSubCategory";
            //request.Parameters = new List<Parameter>();
            //Parameter paramMoc = new Parameter("moc", CurrentMOC);
            //request.Parameters.Add(paramMoc);

            //DataTable dt = new DataTable();
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            DataTable dt = new DataTable();
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            string sqlQuery = "";
            if (search == "")
            {
                sqlQuery = "with recCount as (select COUNT(*) as RecCount FROM vwCalculatedProvision v JOIN " +
                 " (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName " +
                " WHERE v.MOC = " + CurrentMOC + " and v.TOTSubCategory is null group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat)  select COUNT(*) from RecCount";
            }
            else
            {
                sqlQuery = "with recCount as (select COUNT(*) as RecCount FROM vwCalculatedProvision v JOIN " +
               " (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName " +
              " WHERE v.MOC = " + CurrentMOC + " and v.TOTSubCategory is null AND " + search + " group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat)  select COUNT(*) from RecCount ";
            }
            request.SqlQuery = sqlQuery;
            dt = smartDataObj.GetData(request);
            TOTAL_ROWS = Convert.ToInt32(dt.Rows[0][0].ToString());
            if (param.length == -1)
            {
                param.length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
           

            dataTableData.data = calculateProvisionService.GetProvisionExceptionDataByTOTSubCategory(CurrentMOC, param.start, param.length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }
        [HttpPost]
        public ActionResult AjaxGetExceptionDataOutLetCode(JQDTParams param)
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
            MOCCalculationDataTable dataTableData = new MOCCalculationDataTable();
            dataTableData.draw = param.draw;
            search = reportService.GetDataSearchText(param);


            DbRequest request = new DbRequest();

            //request.StoredProcedureName = "mtspGetRowCountProExOnOutLetCode";
            //request.Parameters = new List<Parameter>();
            //Parameter paramMoc = new Parameter("moc", CurrentMOC);
            //request.Parameters.Add(paramMoc);

            //DataTable dt = new DataTable();
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            DataTable dt = new DataTable();
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            string sqlQuery = "";
            if (search == "")
            {
                sqlQuery = "select COUNT(distinct(HulOutletCode)) from vwCalculatedProvision where ChainName  is null OR  GroupName is null OR  ColorNonColor is null and  MOC= " + CurrentMOC;
            }
            else
            {
                sqlQuery = "select COUNT(distinct(HulOutletCode)) from vwCalculatedProvision where ChainName  is null OR  GroupName is null OR  ColorNonColor is null and  MOC= " + CurrentMOC + " AND " + search;
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


            dataTableData.data = calculateProvisionService.GetProvisionExceptionDataByOutLetCode(CurrentMOC, param.start, param.length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }
        public void DownloadTOTSubCategoryExpeption()
        {
            DataTable dt1 = new DataTable();
            DbRequest request = new DbRequest();

            request.StoredProcedureName = "sp_GetAllProvisionExceptionOnTOTSubCategory";//"mtspGetAllProvExOnTOTSubCategory";
            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", CurrentMOC);
            request.Parameters.Add(paramMoc);
            dt1 = smartDataObj.GetdataExecuteStoredProcedure(request);
            if (dt1 != null)
            {
                ExportDataTableToExcel(dt1, "ProvExceptionOnTOTSubCategory");
            }
        }
        public void DownloadProvisionChainNmGrpNmExpeption()
        {
            DataTable dt1 = new DataTable();
            DbRequest request = new DbRequest();

            request.StoredProcedureName = "sp_GetAllProvisionExOnHulOutletCode";//"mtspGetAllProvChainNmGrpNmEx";
            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", CurrentMOC);
            request.Parameters.Add(paramMoc);
            dt1 = smartDataObj.GetdataExecuteStoredProcedure(request);
            if (dt1 != null)
            {
                ExportDataTableToExcel(dt1, "ProvExceptionOnChainNameGrpName");
            }
        }
    }
}