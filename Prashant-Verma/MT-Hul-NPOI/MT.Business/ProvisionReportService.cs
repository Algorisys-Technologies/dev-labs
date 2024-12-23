using MT.DataAccessLayer;
using MT.Model;
using MT.SessionManager;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Dynamic;
using System.Threading.Tasks;
using OfficeOpenXml;
using System.Web;

namespace MT.Business
{
    public class ProvisionReportService : BaseService
    {

        public List<ZeroProvisionOutlet> GetZeroProvisionOutletData(string currentMOC, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<ZeroProvisionOutlet> list = new List<ZeroProvisionOutlet>();
            string orderByTxt = "";

            if (sortDirection == "asc")
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }
            else
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }

            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            int recordupto = start + length;

            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", currentMOC);
            Parameter paramStart = new Parameter("start", start);
            Parameter paramRecordupto = new Parameter("recordupto", recordupto);
            Parameter paramSortColumnName = new Parameter("sortColumnName", orderByTxt);
            Parameter paramSearch = new Parameter("search", search);
            request.Parameters.Add(paramMoc);
            request.Parameters.Add(paramStart);
            request.Parameters.Add(paramRecordupto);
            request.Parameters.Add(paramSortColumnName);
            request.Parameters.Add(paramSearch);
            request.StoredProcedureName = "sp_GetZeroProvisionOutlet";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);

            foreach (DataRow dr in dt.Rows)
            {
                ZeroProvisionOutlet obj = new ZeroProvisionOutlet();

                obj.ChainName = dr["ChainName"].ToString();
                obj.Groupname = dr["GroupName"].ToString();
                obj.HulOutletCode = dr["HulOutletCode"].ToString();
                obj.HulOutletCodeName = dr["HulOutletCodeName"].ToString();
                obj.OutletCategoryMaster = dr["OutletCategoryMaster"].ToString();
                obj.NetSalesValue = dr["NetSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesValue"]);
                obj.ToTProvision = dr["ToTProvision"].ToString() == "" ? 0 : Convert.ToDecimal(dr["ToTProvision"]);


                list.Add(obj);
            }
            return list;
        }

        public DataTable GetAllZeroProvisionOutletData(string currentMOC)
        {
            List<ZeroProvisionOutlet> list = new List<ZeroProvisionOutlet>();
            
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            

            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", currentMOC);
            request.Parameters.Add(paramMoc);
            request.StoredProcedureName = "sp_GetAllZeroProvisionOutlet";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            
            return dt;
        }

        public List<MonthlyToTProvisionTrend> GetMonthlyToTProvisionTrend(string moc)
        {
            List<MonthlyToTProvisionTrend> monthlyToTProvTrendList = new List<MonthlyToTProvisionTrend>();

            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.Parameters = new List<Parameter>();
            Parameter paramMocYEAR = new Parameter("MocYEAR", moc.Substring(moc.Length - 4));
            Parameter paramMocMonthId = new Parameter("MocMonthId", moc.Substring(0, (moc.Length - 5)));
            request.Parameters.Add(paramMocYEAR);
            request.Parameters.Add(paramMocMonthId);
            request.StoredProcedureName = "sp_GetMonthlyToTProvisionTrend";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);

            foreach (DataRow dr in dt.Rows)
            {
                MonthlyToTProvisionTrend obj = new MonthlyToTProvisionTrend();

                obj.UniqueMonthName = dr["UniqueMonthName"].ToString();
                obj.SalesTUR = dr["NetSalesTUR"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesTUR"]);
                obj.ToTPercentage = dr["ToTPercentage"].ToString() == "" ? 0 : Convert.ToDecimal(dr["ToTPercentage"]);
                obj.ToTProvision = dr["ToTProvision"].ToString() == "" ? 0 : Convert.ToDecimal(dr["ToTProvision"]);


                monthlyToTProvTrendList.Add(obj);
            }
            return monthlyToTProvTrendList;
        }

        public List<ToTProvisionTrendModel> GeCetegoryWiseToTProvisionTrend(string moc)
        {
            List<ToTProvisionTrendModel> categoryToTProvTrendList = new List<ToTProvisionTrendModel>();

            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.Parameters = new List<Parameter>();
            Parameter paramMocYEAR = new Parameter("MocYEAR", moc.Substring(moc.Length - 4));
            Parameter paramMocMonthId = new Parameter("MocMonthId", moc.Substring(0, (moc.Length - 5)));
            request.Parameters.Add(paramMocYEAR);
            request.Parameters.Add(paramMocMonthId);
            request.StoredProcedureName = "sp_GetCategoryWiseToTProvisionTrend";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            var uniqueMonth = (from r in dt.AsEnumerable()
                               select r["MonthName"]).Distinct().ToList();

            var uniqueCategoryList = (from r in dt.AsEnumerable()
                                      select r["SubCategory"]).Distinct().ToList();
            uniqueCategoryList = uniqueCategoryList.Where(r => !string.IsNullOrEmpty(r.ToString())).ToList();
            foreach (string dr in uniqueCategoryList)
            {
                ToTProvisionTrendModel obj = new ToTProvisionTrendModel();
                List<MonthlyToTProvisionTrend> monthlyToTProvTrendList = new List<MonthlyToTProvisionTrend>();
                obj.SubCategory = dr;
                foreach (string month in uniqueMonth)
                {

                    var data = (from r in dt.AsEnumerable()
                                where r["SubCategory"].ToString() == dr && r["MonthName"].ToString() == month
                                select r).FirstOrDefault();

                    MonthlyToTProvisionTrend monthlyObj = new MonthlyToTProvisionTrend();
                    monthlyObj.UniqueMonthName = month;
                    if (data == null)
                    {
                        monthlyObj.SalesTUR = 0;
                        monthlyObj.ToTPercentage = 0;
                        monthlyObj.ToTProvision = 0;
                    }
                    else
                    {
                        monthlyObj.SalesTUR = string.IsNullOrEmpty(data["NetSalesTUR"].ToString()) ? 0 : Convert.ToDecimal(data["NetSalesTUR"]);
                        monthlyObj.ToTPercentage = string.IsNullOrEmpty(data["ToTPercentage"].ToString()) ? 0 : Convert.ToDecimal(data["ToTPercentage"]);
                        monthlyObj.ToTProvision = string.IsNullOrEmpty(data["ToTProvision"].ToString()) ? 0 : Convert.ToDecimal(data["ToTProvision"]);
                    }
                    monthlyToTProvTrendList.Add(monthlyObj);
                }
                obj.MonthlyToTProvisionTrend = monthlyToTProvTrendList;

                categoryToTProvTrendList.Add(obj);
            }
            return categoryToTProvTrendList;
        }


        public DataTable GetToTProvisionTrendDataTable(List<MonthlyToTProvisionTrend> totProvTrendList)
        {
            DataTable dt = new DataTable();
            dt.Clear();
            dt.Columns.Add("Category");

            foreach (var columnItem in totProvTrendList)
            {
                dt.Columns.Add(columnItem.UniqueMonthName);
            }


            dynamic auditTrailObject = new ExpandoObject();
            IDictionary<string, object> auditTrailxUnderlyingObject = auditTrailObject;

            auditTrailxUnderlyingObject.Add("Category", "Sales (TUR)");
            foreach (var colItem in totProvTrendList)
            {
                auditTrailxUnderlyingObject.Add(colItem.UniqueMonthName, colItem.SalesTUR);
            }
            dt.Rows.Add(auditTrailxUnderlyingObject.Values.ToArray());

            auditTrailObject = new ExpandoObject();
            auditTrailxUnderlyingObject = auditTrailObject;
            auditTrailxUnderlyingObject.Add("Category", "ToT Value");
            foreach (var colItem in totProvTrendList)
            {
                auditTrailxUnderlyingObject.Add(colItem.UniqueMonthName, colItem.ToTProvision);
            }
            dt.Rows.Add(auditTrailxUnderlyingObject.Values.ToArray());


            auditTrailObject = new ExpandoObject();
            auditTrailxUnderlyingObject = auditTrailObject;
            auditTrailxUnderlyingObject.Add("Category", "ToT %");
            foreach (var colItem in totProvTrendList)
            {
                auditTrailxUnderlyingObject.Add(colItem.UniqueMonthName, colItem.ToTPercentage);
            }
            dt.Rows.Add(auditTrailxUnderlyingObject.Values.ToArray());
            return dt;
        }

        public DataTable GetToTProvisionTrendCategoryWiseDataTable(List<ToTProvisionTrendModel> totProvTrendList)
        {
            DataTable dt = new DataTable();
            dt.Clear();
            dt.Columns.Add("Sub-Category");

            foreach (var columnItem in totProvTrendList[0].MonthlyToTProvisionTrend)
            {
                dt.Columns.Add("Sales (TUR)");
                dt.Columns.Add("ToT Provision");
                dt.Columns.Add("% ToT");
            }

            foreach (var columnItem in totProvTrendList)
            {
                dynamic auditTrailObject = new ExpandoObject();
                IDictionary<string, object> auditTrailxUnderlyingObject = auditTrailObject;

                auditTrailxUnderlyingObject.Add("Sub-Category", columnItem.SubCategory);
                foreach (var monthtot in columnItem.MonthlyToTProvisionTrend)
                {
                    auditTrailxUnderlyingObject.Add("Sales (TUR)", monthtot.SalesTUR);
                    auditTrailxUnderlyingObject.Add("ToT Provision", monthtot.ToTProvision);
                    auditTrailxUnderlyingObject.Add("% ToT", monthtot.ToTPercentage);
                }

                dt.Rows.Add(auditTrailxUnderlyingObject.Values.ToArray());
            }
            return dt;
        }

        public DataTable GetToTProvisionTrendCategoryWiseDataTableForDownload(List<ToTProvisionTrendModel> totProvTrendList)
        {
            DataTable dt = new DataTable();
            dt.Clear();
            dt.Columns.Add("Sub-Category");
            int monthcount = 1;
            foreach (var columnItem in totProvTrendList[0].MonthlyToTProvisionTrend)
            {
                dt.Columns.Add("Sales (TUR)"+ monthcount);
                dt.Columns.Add("ToT Provision" + monthcount);
                dt.Columns.Add("% ToT" + monthcount);
                monthcount++;
            }

            foreach (var columnItem in totProvTrendList)
            {
                dynamic auditTrailObject = new ExpandoObject();
                IDictionary<string, object> auditTrailxUnderlyingObject = auditTrailObject;

                auditTrailxUnderlyingObject.Add("Sub-Category", columnItem.SubCategory);
                 monthcount = 1;
                foreach (var monthtot in columnItem.MonthlyToTProvisionTrend)
                {
                    auditTrailxUnderlyingObject.Add("Sales (TUR)" + monthcount, monthtot.SalesTUR);
                    auditTrailxUnderlyingObject.Add("ToT Provision" + monthcount, monthtot.ToTProvision);
                    auditTrailxUnderlyingObject.Add("% ToT" + monthcount, monthtot.ToTPercentage + "%");
                    monthcount++;
                }

                dt.Rows.Add(auditTrailxUnderlyingObject.Values.ToArray());
            }
            return dt;
        }

        public void ExportDataTableToExcelTOTProvision(DataTable sourceDt, string tableName,List<string> MonthList)
        {
            using (ExcelPackage xp = new ExcelPackage())
            {
                if (sourceDt != null)
                {

                    ExcelWorksheet ws = xp.Workbook.Worksheets.Add(sourceDt.TableName);
                    int headerstart = 2;

                    //ws.Cells[2, 3].Value = "the report has been given";
                    foreach (var item in MonthList)
                    {
                        ws.Cells[2, headerstart].Value = item;
                        ws.Cells[2, headerstart, 2, headerstart+2].Merge = true;

                        headerstart = headerstart + 3;
                       
                    }
                  

                    int secheader = 2;
                    
                    //ws.Cells[4, 4].Value = "jan 15";
                    //ws.Cells[4, 4, 4, 6].Merge = true;
                    //ws.Cells[4, 7].Value = "feb 15";
                    //ws.Cells[4, 7, 4, 9].Merge = true;
                    ws.Cells[3, 1].LoadFromDataTable(sourceDt, true);
                    foreach (var item in MonthList)
                    {

                        ws.Cells[3, secheader++].Value = "Sales (TUR)";
                        ws.Cells[3, secheader++].Value = "ToT Provision";
                        ws.Cells[3, secheader++].Value = "% ToT";

                    }
                    HttpContext.Current.Response.AddHeader("content-disposition", "attachment;filename=" + tableName + ".xlsx");
                    HttpContext.Current.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

                    xp.SaveAs(HttpContext.Current.Response.OutputStream);

                    HttpContext.Current.Response.End();


                }

            }

        }
    }
}
