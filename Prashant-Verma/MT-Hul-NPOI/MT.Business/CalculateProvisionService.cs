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
    public class CalculateProvisionService : BaseService
    {

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

                obj.ChainName = dr["ChainName"].ToString();
                obj.GroupName = dr["GroupName"].ToString();
                obj.ColorNonColor = dr["ColorNonColor"].ToString();
                obj.AdditionalMarginRate = dr["AdditionalMarginRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["AdditionalMarginRate"]);
                obj.AdditionalMargin = dr["AdditionalMargin"].ToString() == "" ? 0 : Convert.ToDecimal(dr["AdditionalMargin"]);
                obj.HuggiesPackPercentage = dr["HuggiesPackPercentage"].ToString() == "" ? 0 : Convert.ToDecimal(dr["HuggiesPackPercentage"]);
                obj.HuggiesPackMargin = dr["HuggiesPackMargin"].ToString() == "" ? 0 : Convert.ToDecimal(dr["HuggiesPackMargin"]);
                obj.TOTSubCategory = dr["TOTSubCategory"].ToString();
                obj.OnInvoiceRate = dr["OnInvoiceRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OnInvoiceRate"]);
                obj.OffInvoiceMthlyRate = dr["OffInvoiceMthlyRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceMthlyRate"]);
                obj.OffInvoiceQtrlyRate = dr["OffInvoiceQtrlyRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceQtrlyRate"]);
                obj.OnInvoiceValue = dr["OnInvoiceValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OnInvoiceValue"]);
                obj.OffInvoiceMthlyValue = dr["OffInvoiceMthlyValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceMthlyValue"]);
                obj.OffInvoiceQtrlyValue = dr["OffInvoiceQtrlyValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceQtrlyValue"]);
                obj.OnInvoiceFinalValue = dr["OnInvoiceFinalValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OnInvoiceFinalValue"]);
                obj.OffInvoiceMthlyFinalValue = dr["OffInvoiceMthlyFinalValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceMthlyFinalValue"]);
                obj.OffInvoiceQtrlyFinalValue = dr["OffInvoiceQtrlyFinalValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceQtrlyFinalValue"]);
                obj.Cluster = dr["Cluster"].ToString();
                obj.FirstLetterBrand = dr["FirstLetterBrand"].ToString();
                obj.ServiceTax = dr["ServiceTax"].ToString() == "" ? 0 : Convert.ToDecimal(dr["ServiceTax"]);
                obj.SalesTaxRate = dr["SalesTaxRate"].ToString() == "" ? "0.00" : string.Format("{0:n2}", (Convert.ToDecimal(dr["SalesTaxRate"]) * 100).ToString()) + " %";
                obj.ServiceTaxRate = dr["ServiceTaxRate"].ToString() == "" ? "0.00" : string.Format("{0:n2}", (Convert.ToDecimal(dr["ServiceTaxRate"]) * 100).ToString()) + " %";
                ////
                obj.TaxCode = dr["TaxCode"].ToString();
                obj.StateCode = dr["StateCode"].ToString();
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
                obj.OutletSecChannel = dr["OutletSecChannel"].ToString();
                obj.ClusterCode = dr["ClusterCode"].ToString();
                obj.ClusterName = dr["ClusterName"].ToString();
                obj.OutletTier = dr["OutletTier"].ToString();
                obj.TotalSalesValue = dr["TotalSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["TotalSalesValue"]);
                obj.SalesReturnValue = dr["SalesReturnValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["SalesReturnValue"]);
                obj.NetSalesValue = dr["NetSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesValue"]);
                obj.NetSalesQty = dr["NetSalesQty"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesQty"]);
                obj.GSV = dr["GSV"].ToString() == "" ? 0 : Convert.ToDecimal(dr["GSV"]);

                list.Add(obj);

            }
            return list;
        }

        public DataSet GetMOCCalculationData(string currentMOC, string currentReportMOC)
        {
            DataSet ds = new DataSet();
            SqlConnection connection = new SqlConnection(connectionString);

            DataTable dt1 = new DataTable();
            DataTable dt2 = new DataTable();
            DbRequest request = new DbRequest();

            if (currentMOC == currentReportMOC)
            {
                request.SqlQuery = "Select  CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName," +
                " PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName," +
                " MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue," +
                " NetSalesQty, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, " +
                "ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory," +
                " OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue," +
                " OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand from mtPrevProvision where MOC=" + currentMOC;
            }
            else
            {
                request.SqlQuery = "Select  CustomerCode, CustomerName, OutletCategoryMaster, BasepackCode, BasepackName," +
             " PMHBrandCode, PMHBrandName, SalesSubCat, PriceList, HulOutletCode, HulOutletCodeName, BranchCode, BranchName," +
             " MOC, OutletSecChannel, ClusterCode, ClusterName, OutletTier, TotalSalesValue, SalesReturnValue, NetSalesValue," +
             " NetSalesQty, ChainName, GroupName, ColorNonColor, TaxCode, StateCode, SalesTaxRate, GSV, ServiceTaxRate, " +
             "ServiceTax, AdditionalMarginRate, AdditionalMargin, HuggiesPackPercentage, HuggiesPackMargin, TOTSubCategory," +
             " OnInvoiceRate, OffInvoiceMthlyRate, OffInvoiceQtrlyRate, OnInvoiceValue, OffInvoiceMthlyValue, OffInvoiceQtrlyValue," +
             " OnInvoiceFinalValue, OffInvoiceMthlyFinalValue, OffInvoiceQtrlyFinalValue, Cluster, FirstLetterBrand from mtPrevProvision where MOC=" + currentMOC;
            }
            dt1 = smartDataObj.GetData(request);
            dt2 = dt1.Copy();
            ds.Tables.Add(dt2);
            return ds;
        }

        public string ExportSqlDataReaderToCsv(string CurrentMOC, string fileName)
        {

            string filePath = AppDomain.CurrentDomain.BaseDirectory + "FilesDownload/" + fileName + ".csv";
            string sqlselectQuery = "Select CustomerCode as Customer, CustomerName as Customer, OutletCategoryMaster as [Outlet Category - Master], BasepackCode as Basepack, BasepackName as Basepack, PMHBrandCode as [PMH Brand], PMHBrandName[PMH Brand], SalesSubCat as [Sales SubCategory], PriceList as [Price List], HulOutletCode as [HUL Outlet Code], HulOutletCodeName as [HUL Outlet Code], BranchCode as [Branch - Master], BranchName as [Branch - Master], MOC, OutletSecChannel as [Outlet Secondary Channel], ClusterCode as [Cluster Code], ClusterName as [Cluster Code], OutletTier as [Outlet Tier], TotalSalesValue as [Total Sales Value (INR)], SalesReturnValue as [Sales Return Value (INR)], NetSalesValue as [Net Sales Value (INR)], NetSalesQty as [Net Sales Qty (KGs)], TaxCode as [Tax Code], StateCode as [State Code], SalesTaxRate as [Sales Tax], GSV," +
            "ChainName as [Chain Name],GroupName as [Group Name],ColorNonColor as [Color / Non Color],OnInvoiceRate as [On Invoice %],OffInvoiceMthlyRate as [OFF INVOICE MONTHLY %], OffInvoiceQtrlyRate as [OFF INVOICE QTRLY %]," +
            "HuggiesPackPercentage as [HUGGIES PACKS %],ServiceTaxRate as [ST% on Qtrly],AdditionalMarginRate as [ADD MARGIN %]," +
            "HuggiesPackMargin as [HUGGIES PACKS],ServiceTax as [ST on Qtrly Provision Value],AdditionalMargin as [ADD MARGIN],OffInvoiceMthlyValue as [OFF INVOICE MONTHLY]," +
            "OffInvoiceQtrlyValue as [OFF INVOICE QTRLY],OnInvoiceValue as [ON INVOICE VALUE]," +
            "OnInvoiceFinalValue as [ON Invoice TOTAL],OffInvoiceMthlyFinalValue as [OFF INVOICE MONTHLY TOTAL]," +
            "OffInvoiceQtrlyFinalValue as [OFF INVOICE QTR TOTAL],Cluster as CLUSTER,FirstLetterBrand,TOTSubCategory from vwCalculatedProvision where MOC=" + CurrentMOC;

            WriteCSVFile(filePath, sqlselectQuery);
            return filePath;
        }



        public List<MtMOCCalculation> GetProvisionExceptionData(string currentMOC, int start, int length, string search, string sortColumnName, string sortDirection)
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

            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("moc", currentMOC);
            Parameter paramStart = new Parameter("start", start);
            Parameter paramRecordupto = new Parameter("recordupto", recordupto);
            Parameter paramSortColumnName = new Parameter("sortColumnName", orderByTxt);
            request.Parameters.Add(paramMoc);
            request.Parameters.Add(paramStart);
            request.Parameters.Add(paramRecordupto);
            request.Parameters.Add(paramSortColumnName);
            request.StoredProcedureName = "mtspGetProvisionExOnChainNmGrpNm";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);

            foreach (DataRow dr in dt.Rows)
            {
                MtMOCCalculation obj = new MtMOCCalculation();

                obj.ChainName = dr["ChainName"].ToString();
                obj.GroupName = dr["GroupName"].ToString();
                obj.ColorNonColor = dr["ColorNonColor"].ToString();
                obj.AdditionalMarginRate = dr["AdditionalMarginRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["AdditionalMarginRate"]);
                obj.AdditionalMargin = dr["AdditionalMargin"].ToString() == "" ? 0 : Convert.ToDecimal(dr["AdditionalMargin"]);
                obj.HuggiesPackPercentage = dr["HuggiesPackPercentage"].ToString() == "" ? 0 : Convert.ToDecimal(dr["HuggiesPackPercentage"]);
                obj.HuggiesPackMargin = dr["HuggiesPackMargin"].ToString() == "" ? 0 : Convert.ToDecimal(dr["HuggiesPackMargin"]);
                obj.TOTSubCategory = dr["TOTSubCategory"].ToString();
                obj.OnInvoiceRate = dr["OnInvoiceRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OnInvoiceRate"]);
                obj.OffInvoiceMthlyRate = dr["OffInvoiceMthlyRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceMthlyRate"]);
                obj.OffInvoiceQtrlyRate = dr["OffInvoiceQtrlyRate"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceQtrlyRate"]);
                obj.OnInvoiceValue = dr["OnInvoiceValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OnInvoiceValue"]);
                obj.OffInvoiceMthlyValue = dr["OffInvoiceMthlyValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceMthlyValue"]);
                obj.OffInvoiceQtrlyValue = dr["OffInvoiceQtrlyValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceQtrlyValue"]);
                obj.OnInvoiceFinalValue = dr["OnInvoiceFinalValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OnInvoiceFinalValue"]);
                obj.OffInvoiceMthlyFinalValue = dr["OffInvoiceMthlyFinalValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceMthlyFinalValue"]);
                obj.OffInvoiceQtrlyFinalValue = dr["OffInvoiceQtrlyFinalValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["OffInvoiceQtrlyFinalValue"]);
                obj.Cluster = dr["Cluster"].ToString();
                obj.FirstLetterBrand = dr["FirstLetterBrand"].ToString();
                obj.ServiceTax = dr["ServiceTax"].ToString() == "" ? 0 : Convert.ToDecimal(dr["ServiceTax"]);
                obj.SalesTaxRate = dr["SalesTaxRate"].ToString() == "" ? "0.00" : string.Format("{0:n2}", (Convert.ToDecimal(dr["SalesTaxRate"]) * 100).ToString()) + " %";
                obj.ServiceTaxRate = dr["ServiceTaxRate"].ToString() == "" ? "0.00" : string.Format("{0:n2}", (Convert.ToDecimal(dr["ServiceTaxRate"]) * 100).ToString()) + " %";
                ////
                obj.TaxCode = dr["TaxCode"].ToString();
                obj.StateCode = dr["StateCode"].ToString();
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
                obj.OutletSecChannel = dr["OutletSecChannel"].ToString();
                obj.ClusterCode = dr["ClusterCode"].ToString();
                obj.ClusterName = dr["ClusterName"].ToString();
                obj.OutletTier = dr["OutletTier"].ToString();
                obj.TotalSalesValue = dr["TotalSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["TotalSalesValue"]);
                obj.SalesReturnValue = dr["SalesReturnValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["SalesReturnValue"]);
                obj.NetSalesValue = dr["NetSalesValue"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesValue"]);
                obj.NetSalesQty = dr["NetSalesQty"].ToString() == "" ? 0 : Convert.ToDecimal(dr["NetSalesQty"]);
                obj.GSV = dr["GSV"].ToString() == "" ? 0 : Convert.ToDecimal(dr["GSV"]);


                list.Add(obj);
            }
            return list;
        }
        public List<MtMOCCalculation> GetProvisionExceptionDataByTOTSubCategory(string currentMOC, int start, int length, string search, string sortColumnName, string sortDirection)
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
            //Parameter paramMoc = new Parameter("moc", currentMOC);
            //Parameter paramStart = new Parameter("start", start);
            //Parameter paramRecordupto = new Parameter("recordupto", recordupto);
            //Parameter paramSortColumnName = new Parameter("sortColumnName", orderByTxt);
            //request.Parameters.Add(paramMoc);
            //request.Parameters.Add(paramStart);
            //request.Parameters.Add(paramRecordupto);
            //request.Parameters.Add(paramSortColumnName);
            //request.StoredProcedureName = "mtspGetProvisionExceptionOnTOTSubCategory";
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            string sqlQuery = "";
            if (search == "")
            {
                sqlQuery = " with TOTSubCategory as(select PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory ,SalesSubCat FROM vwCalculatedProvision v JOIN" +
 " (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName  " +
 " WHERE  v.MOC= " + currentMOC + " and v.TOTSubCategory is null group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat ) " +
 "SELECT *  FROM  (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from TOTSubCategory) a WHERE RowNumber BETWEEN  " + start + " AND  " + recordupto;

            }
            else
            {
                sqlQuery = " with TOTSubCategory as(select PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory ,SalesSubCat FROM vwCalculatedProvision v JOIN" +
  " (Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON v.ChainName = subcatRate.ChainName and v.GroupName = subcatRate.GroupName  " +
  " WHERE  v.MOC= " + currentMOC + " and v.TOTSubCategory is null  AND " + search +" group by PriceList,PMHBrandCode,PMHBrandName,TOTSubCategory,SalesSubCat )" +
  "SELECT *  FROM  (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from TOTSubCategory) a WHERE RowNumber BETWEEN  " + start + " AND  " + recordupto;
            }
            request.SqlQuery = sqlQuery;
            dt = smartDataObj.GetData(request);
            foreach (DataRow dr in dt.Rows)
            {
                MtMOCCalculation obj = new MtMOCCalculation();

                obj.TOTSubCategory = dr["TOTSubCategory"].ToString();
                obj.PMHBrandCode = dr["PMHBrandCode"].ToString();
                obj.PMHBrandName = dr["PMHBrandName"].ToString();
                obj.SalesSubCat = dr["SalesSubCat"].ToString();
                obj.PriceList = dr["PriceList"].ToString();
                list.Add(obj);
            }
            return list;
        }

        public List<MtMOCCalculation> GetProvisionExceptionDataByOutLetCode(string currentMOC, int start, int length, string search, string sortColumnName, string sortDirection)
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
            //Parameter paramMoc = new Parameter("moc", currentMOC);
            //Parameter paramStart = new Parameter("start", start);
            //Parameter paramRecordupto = new Parameter("recordupto", recordupto);
            //Parameter paramSortColumnName = new Parameter("sortColumnName", orderByTxt);
            //request.Parameters.Add(paramMoc);
            //request.Parameters.Add(paramStart);
            //request.Parameters.Add(paramRecordupto);
            //request.Parameters.Add(paramSortColumnName);
            //request.StoredProcedureName = "mtspGetProvisionExOnHulOutletCode";
            //dt = smartDataObj.GetdataExecuteStoredProcedure(request);
            string sqlQuery = "";
            if (search == "")
            {
                sqlQuery = " with TOTSubCategory as(select * FROM vwCalculatedProvision WHERE ChainName  is null OR  GroupName is null OR  ColorNonColor is null AND  MOC= " + currentMOC + ")" +
 " SELECT distinct(HulOutletCode)as HulOutletCode, HulOutletCodeName, ChainName,GroupName,ColorNonColor FROM  (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from " +
 " TOTSubCategory) a WHERE RowNumber  BETWEEN  " + start + " AND  " + recordupto + " group by HulOutletCode,HulOutletCodeName,ChainName,GroupName,ColorNonColor  ";

            }
            else
            {
                sqlQuery = " with TOTSubCategory as(select * FROM vwCalculatedProvision WHERE ChainName  is null OR  GroupName is null OR  ColorNonColor is null AND  MOC= " + currentMOC + " AND " + search + ")" +
" SELECT distinct(HulOutletCode)as HulOutletCode, HulOutletCodeName, ChainName,GroupName,ColorNonColor FROM  (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from " +
" TOTSubCategory) a WHERE RowNumber  BETWEEN  " + start + " AND  " + recordupto + " group by HulOutletCode,HulOutletCodeName,ChainName,GroupName,ColorNonColor  ";

            }
            request.SqlQuery = sqlQuery;
            dt = smartDataObj.GetData(request);
            foreach (DataRow dr in dt.Rows)
            {
                MtMOCCalculation obj = new MtMOCCalculation();

                obj.ChainName = dr["ChainName"].ToString();
                obj.GroupName = dr["GroupName"].ToString();
                obj.ColorNonColor = dr["ColorNonColor"].ToString();

                obj.HulOutletCode = dr["HulOutletCode"].ToString();
                obj.HulOutletCodeName = dr["HulOutletCodeName"].ToString();


                list.Add(obj);
            }
            return list;
        }

    }
}
