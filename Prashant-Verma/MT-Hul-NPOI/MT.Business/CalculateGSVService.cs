using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class CalculateGSVService : BaseService
    {
        public DataSet GetDataToDownload(string currentMOC, string currentReportMOC)
        {
            DataSet ds = new DataSet();
            SqlConnection connection = new SqlConnection(connectionString);

            DataTable dt1 = new DataTable();
            DataTable dt2 = new DataTable();
            DbRequest request = new DbRequest();
            if (currentMOC == currentReportMOC)
            {
                request.SqlQuery = "Select CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, BranchCode, MOC, ClusterCode, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, TaxCode, StateCode, SalesTaxRate, GSV from vwCalculatedProvision where MOC=" + currentMOC;
            }
            else
            {
                request.SqlQuery = "Select CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName, PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, BranchCode, MOC, ClusterCode, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue, NetSalesQty, TaxCode, StateCode, SalesTaxRate, GSV from mtPrevProvision where MOC=" + currentMOC;
            }
            dt1 = smartDataObj.GetData(request);
            dt2 = dt1.Copy();
            ds.Tables.Add(dt2);
            return ds;
        }
        public List<MtMOCCalculation> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection, string currentReportMOC, string tableView)
        {
            List<MtMOCCalculation> list = new List<MtMOCCalculation>();
            string orderByTxt = "";

            if (sortDirection == "asc")
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }
            else
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            int recordupto = start + length;

            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from " + tableView + " where moc='" + currentReportMOC + "') a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from " + tableView + " WHERE moc='" + currentReportMOC + "' and " + search + ") a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }


            foreach (DataRow dr in dt.Rows)
            {
                MtMOCCalculation obj = new MtMOCCalculation();

                obj.TaxCode = dr["TaxCode"].ToString();
                obj.StateCode = dr["StateCode"].ToString();
                obj.SalesTaxRate = dr["SalesTaxRate"].ToString() == "" ? "0.00" : string.Format("{0:n2}", (Convert.ToDecimal(dr["SalesTaxRate"]) * 100).ToString()) + " %";
                obj.CustomerCode = dr["CustomerCode"].ToString();
                obj.CustomerName = dr["CustomerName"].ToString();
                obj.OutletCategoryMaster = dr["OutletCategoryMaster"].ToString();
                obj.BasepackCode = dr["BasepackCode"].ToString();
                obj.BasepackName = dr["BasepackName"].ToString();
                obj.PMHBrandCode = dr["PMHBrandCode"].ToString();
                obj.PMHBrandName = dr["PMHBrandName"].ToString();
                obj.SalesSubCat = dr["SalesSubCat"].ToString();
                obj.PriceList = dr["PriceList"].ToString();
                obj.HulOutletCode = dr["HulOutletCode"].ToString();
                obj.HulOutletCodeName = dr["HulOutletCodeName"].ToString();
                obj.BranchCode = dr["BranchCode"].ToString();
                obj.BranchName = dr["BranchName"].ToString();
                obj.MOC = dr["MOC"].ToString();
                obj.ClusterCode = dr["ClusterCode"].ToString();
                obj.ClusterName = dr["ClusterName"].ToString();
                obj.OutletTier = dr["OutletTier"].ToString();
                obj.TotalSalesValue = dr["TotalSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["TotalSalesValue"]);
                obj.SalesReturnValue = dr["SalesReturnValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["SalesReturnValue"]);
                obj.NetSalesValue = dr["NetSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesValue"]);
                obj.NetSalesQty = dr["NetSalesQty"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesQty"]);
                obj.GSV = dr["GSV"].ToString() == "" ? 0 : Convert.ToDecimal(dr["GSV"]);
                obj.OutletSecChannel = dr["OutletSecChannel"].ToString(); ;

                list.Add(obj);
            }
            return list;
        }

        public string ExportSqlDataReaderToCsv(string CurrentMOC, string fileName)
        {
            string filePath = AppDomain.CurrentDomain.BaseDirectory + "FilesDownload/" + fileName + ".csv";
            string sqlselectQuery = "Select CustomerCode as Customer, CustomerName as Customer, OutletCategoryMaster as [Outlet Category - Master], BasepackCode as Basepack, BasepackName as Basepack, PMHBrandCode as [PMH Brand], PMHBrandName[PMH Brand], SalesSubCat as [Sales SubCategory], PriceList as [Price List], HulOutletCode as [HUL Outlet Code], HulOutletCodeName as [HUL Outlet Code], BranchCode as [Branch - Master], BranchName as [Branch - Master], MOC, OutletSecChannel as [Outlet Secondary Channel], ClusterCode as [Cluster Code], ClusterName as [Cluster Code], OutletTier as [Outlet Tier], TotalSalesValue as [Total Sales Value (INR)], SalesReturnValue as [Sales Return Value (INR)], NetSalesValue as [Net Sales Value (INR)], NetSalesQty as [Net Sales Qty (KGs)], TaxCode as [Tax Code], StateCode as [State Code], SalesTaxRate as [Sales Tax], GSV from vwCalculatedProvision where MOC=" + CurrentMOC;


            WriteCSVFile(filePath, sqlselectQuery);
            return filePath;
        }

        public List<MtMOCCalculation> GetExceptionData(string currentMOC, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<MtMOCCalculation> list = new List<MtMOCCalculation>();
            string orderByTxt = "";

            if (sortDirection == "asc")
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }
            else
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }


            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            int recordupto = start + length;

            //request.Parameters = new List<Parameter>();
            //Parameter paramMoc = new Parameter("moc", Convert.ToDecimal(currentMOC));
            //Parameter paramStart = new Parameter("start", start);
            //Parameter paramRecordupto = new Parameter("recordupto", recordupto);
            //Parameter paramSortColumnName = new Parameter("sortColumnName", orderByTxt);
            //Parameter paramsearch = new Parameter("search", search);
            //request.Parameters.Add(paramMoc);
            //request.Parameters.Add(paramStart);
            //request.Parameters.Add(paramRecordupto);
            //request.Parameters.Add(paramSortColumnName);
            //request.Parameters.Add(paramsearch);
            //request.StoredProcedureName = "mtspGetGSVException";
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            string sqlQuery = "";
            if (search == "")
            {
                sqlQuery = "with table1 as(select * from vwCalculatedProvision where ((statecode is null) or (TaxCode is null and " +
                    "statecode not in (select statecode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1))or(taxcode is null and statecode is null)) and MOC = "+ currentMOC +
                    " and isgstapplicable=0 union all select * from vwCalculatedProvision prov where BasepackCode not in (select BasepackCode from mtgstmaster) and MOC = " + currentMOC +" and IsGstApplicable = 1"+
                    " )"+ 
                    "SELECT * FROM  (select ROW_NUMBER()OVER(ORDER BY "+ sortColumnName + ") AS RowNumber, *from table1) a WHERE RowNumber BETWEEN  "+ start + " AND "+ recordupto;
            }
            else
            {
                sqlQuery = "with table1 as(select * from vwCalculatedProvision where ((statecode is null) or (TaxCode is null and " +
                "statecode not in (select statecode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1))or(taxcode is null and statecode is null)) and MOC = " + currentMOC +
                    " and isgstapplicable=0 union all select * from vwCalculatedProvision prov where BasepackCode not in (select BasepackCode from mtgstmaster) and MOC = " + currentMOC + " and IsGstApplicable = 1" +
                    " )" +
                "SELECT * FROM  (select ROW_NUMBER()OVER(ORDER BY " + sortColumnName + ") AS RowNumber, *from table1) a WHERE RowNumber BETWEEN  " + start + " AND " + recordupto + " AND " + search;
            }
            request.SqlQuery = sqlQuery;
            dt = smartDataObj.GetData(request);
            foreach (DataRow dr in dt.Rows)
            {
                MtMOCCalculation obj = new MtMOCCalculation();

                obj.TaxCode = dr["TaxCode"].ToString();
                obj.StateCode = dr["StateCode"].ToString();
                obj.SalesTaxRate = dr["SalesTaxRate"].ToString() == "" ? "0.00" : string.Format("{0:n2}", (Convert.ToDecimal(dr["SalesTaxRate"]) * 100).ToString()) + " %";
                obj.CustomerCode = dr["CustomerCode"].ToString();
                obj.CustomerName = dr["CustomerName"].ToString();
                obj.OutletCategoryMaster = dr["OutletCategoryMaster"].ToString();
                obj.BasepackCode = dr["BasepackCode"].ToString();
                obj.BasepackName = dr["BasepackName"].ToString();
                obj.PMHBrandCode = dr["PMHBrandCode"].ToString();
                obj.PMHBrandName = dr["PMHBrandName"].ToString();
                obj.SalesSubCat = dr["SalesSubCat"].ToString();
                obj.PriceList = dr["PriceList"].ToString();
                obj.HulOutletCode = dr["HulOutletCode"].ToString();
                obj.HulOutletCodeName = dr["HulOutletCodeName"].ToString();
                obj.BranchCode = dr["BranchCode"].ToString();
                obj.BranchName = dr["BranchName"].ToString();
                obj.MOC = dr["MOC"].ToString();
                obj.ClusterCode = dr["ClusterCode"].ToString();
                obj.ClusterName = dr["ClusterName"].ToString();
                obj.OutletTier = dr["OutletTier"].ToString();
                obj.TotalSalesValue = dr["TotalSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["TotalSalesValue"]);
                obj.SalesReturnValue = dr["SalesReturnValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["SalesReturnValue"]);
                obj.NetSalesValue = dr["NetSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesValue"]);
                obj.NetSalesQty = dr["NetSalesQty"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesQty"]);
                obj.GSV = dr["GSV"].ToString() == "" ? 0 : Convert.ToDecimal(dr["GSV"]);
                obj.OutletSecChannel = dr["OutletSecChannel"].ToString(); ;

                list.Add(obj);
            }
            return list;
        }


    }
}
