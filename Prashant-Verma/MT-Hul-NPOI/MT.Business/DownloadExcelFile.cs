using MT.DataAccessLayer;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class DownloadExcelFile : BaseService
    {

        SmartData smartDataObj = new SmartData();


        public void DownloadJV_ToExcel_WithName(string[] columnsToDisplay, string tableName, string excelName, string search)
        {

            DbRequest request = new DbRequest();

            if (string.IsNullOrEmpty(search))
                request.SqlQuery = "SELECT GLAccount, Amount, CrossCompanyCode, ValueDate, GLTaxCode, CostCenter, BranchCode, InternalOrder, TransactionType, GLAssignment, GLItemText,TradingPartner, Material, PONUMBER, PMHBrandCode, DistrChannel, Plant, Product, ProfitCenter, WBSElement, BusinessPlace, COPACustomer FROM " + tableName + "";
            else
                request.SqlQuery = "Select  GLAccount, Amount, CrossCompanyCode, ValueDate, GLTaxCode, CostCenter, BranchCode, InternalOrder, TransactionType, GLAssignment, GLItemText,TradingPartner, Material, PONUMBER, PMHBrandCode, DistrChannel, Plant, Product, ProfitCenter, WBSElement, BusinessPlace, COPACustomer from " + tableName + " where " + search;
            DataTable dt1 = new DataTable();
            dt1 = smartDataObj.GetData(request);
            dt1.TableName = excelName;
            int i = 0;
            foreach (var col in columnsToDisplay)
            {
                dt1.Columns[i].ColumnName = col;
                i++;

            }

            if (dt1 != null)
            {
                ExportDataTableToExcel(dt1, excelName);


            }
            else
            {

            }



        }
        public void Download_ToExcel(string[] columnsInDb, string[] columnsToDisplay, string tableName)
        {

            DbRequest request = new DbRequest();
            var columnString = "";
            var lastColumn = columnsInDb.Last();
            foreach (var col in columnsInDb)
            {
                if (col != lastColumn)
                {
                    columnString += "[" + col + "],";
                }
                else
                {
                    columnString += "[" + col + "]";
                }
            }


            request.SqlQuery = "SELECT " + columnString + "FROM " + tableName + "";
            DataTable dt1 = new DataTable();
            dt1 = smartDataObj.GetData(request);
            int i = 0;
            foreach (var col in columnsToDisplay)
            {
                dt1.Columns[i].ColumnName = col;
                i++;

            }

            if (dt1 != null)
            {
                ExportDataTableToExcel(dt1, tableName);


            }
            else
            {

            }



        }
        public void Download_ExcelMethod(string[] columnsInExcel, string tableName)
        {

            DbRequest request = new DbRequest();
            var columnString = "";
            var lastColumn = columnsInExcel.Last();
            foreach (var col in columnsInExcel)
            {
                if (col != lastColumn)
                {
                    columnString += "[" + col + "],";
                }
                else
                {
                    columnString += "[" + col + "]";
                }
            }

            request.SqlQuery = "SELECT " + columnString + "FROM " + tableName + "";
            DataTable dt1 = new DataTable();
            dt1 = smartDataObj.GetData(request);
            if (dt1 != null)
            {
                ExportDataTableToExcel(dt1, tableName);


            }
            else
            {

            }



        }
    }
}
