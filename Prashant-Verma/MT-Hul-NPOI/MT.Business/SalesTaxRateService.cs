using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web;

namespace MT.Business
{
    public class SalesTaxRateService : BaseService
    {
        public List<MtSalesTaxMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<MtSalesTaxMaster> list = new List<MtSalesTaxMaster>();
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
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ")  AS RowNumber, * from mtSalesTaxMaster ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ")  AS RowNumber,* from mtSalesTaxMaster WHERE FREETEXT (*, '" + search + "')) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }

            foreach (DataRow dr in dt.Rows)
            {
                MtSalesTaxMaster obj = new MtSalesTaxMaster();

                obj.TaxCode = dr["TaxCode"].ToString();
                obj.StateCode = dr["StateCode"].ToString();
                obj.SalesTaxRate = string.Format("{0:n2}", (Convert.ToDecimal(dr["SalesTaxRate"]) * 100)) + " %";
                obj.Id = Convert.ToInt32(dr["Id"]);
                list.Add(obj);

            }
            return list;
        }


        public UploadFileResponse UploadSalesTaxRateFile(string path, string userId)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();
            // MasterResponse excelResult = new MasterResponse();
            MasterResponse excelResult = ReadSalesTaxRateExcel(path);
            if (excelResult.IsSuccess)
            {
                ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
                //excelResult.Data = read.RemoveDuplicates(excelResult.Data, new string[2] { MasterConstants.Sales_Tax_Excel_Column[0], MasterConstants.Sales_Tax_Excel_Column[1] }.ToList());
                excelResult.Data = obj.MapMaster(excelResult.Data, MasterConstants.Sales_Tax_Excel_Column, MasterConstants.Sales_Tax_DB_Column);

                DataTable table = new DataTable();
                table = excelResult.Data;
                table.TableName = MasterConstants.Sales_Tax_Master_Table_Name;
                //smartDataObj.Bulk_Update(table, MasterConstants.Sales_Tax_Master_Master_UpdateSP_Name, MasterConstants.Sales_Tax_Master_Master_UpdateSP_Param_Name);
                DbRequest request = new DbRequest();
                request.StoredProcedureName = MasterConstants.Sales_Tax_Master_Master_UpdateSP_Name;

                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter(MasterConstants.Sales_Tax_Master_Master_UpdateSP_Param_Name, table);
                Parameter userParam = new Parameter("user", userId);
                request.Parameters.Add(dtParam);
                request.Parameters.Add(userParam);
                smartDataObj.ExecuteStoredProcedure(request);
                response.IsSuccess = true;
                response.MessageText = MessageConstants.Success_Upload;
            }
            else
            {
                //response.MessageText = excelResult.MessageText;
                response.IsSuccess = excelResult.IsSuccess;
                response.MessageText = MessageConstants.Invalid_FileData;
            }

            return response;
        }

        public MasterResponse ReadSalesTaxRateExcel(string path)
        {
            MasterResponse response = new MasterResponse();
            using (OleDbConnection conn = new OleDbConnection())
            {
                DataTable dt1 = new DataTable();
                DataTable dt = new DataTable();
                string Import_FileName = path;
                string fileExtension = Path.GetExtension(Import_FileName);

                if (fileExtension == ".xls")
                    // conn.ConnectionString = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + Import_FileName + ";" + "Extended Properties='Excel 8.0;HDR=YES;'";
                    conn.ConnectionString = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + Import_FileName + @";Extended Properties=""Excel 8.0;IMEX=1;HDR=NO;TypeGuessRows=0;ImportMixedTypes=Text""";
                if (fileExtension == ".xlsx" || fileExtension == ".xlsb")
                    // conn.ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + Import_FileName + ";" + "Extended Properties='Excel 12.0 Xml;HDR=YES;'";
                    conn.ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + Import_FileName + @";Extended Properties=""Excel 8.0;IMEX=1;HDR=NO;TypeGuessRows=0;ImportMixedTypes=Text""";


                conn.Open();
                dt1 = conn.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, null);

                if (dt1 == null)
                {
                    return null;
                }

                String[] excelSheets = new String[dt1.Rows.Count];
                int i = 0;

                // Add the sheet name to the string array.
                foreach (DataRow row in dt1.Rows)
                {
                    if (!row["TABLE_NAME"].ToString().Contains("FilterDatabase"))
                    {
                        excelSheets[i] = row["TABLE_NAME"].ToString();
                        i++;
                    }
                }



                using (OleDbCommand comm = new OleDbCommand())
                {

                    // comm.CommandText = "Select * from [" + sheetName + "$]";
                    var columnString = "";



                    comm.CommandText = "Select * from [" + excelSheets[0] + "]";
                    comm.Connection = conn;


                    using (OleDbDataAdapter da = new OleDbDataAdapter())
                    {
                        da.SelectCommand = comm;
                        da.Fill(dt);
                        DataTable dt2 = new DataTable();
                        dt2.Clear();
                        dt2.Columns.Add("TaxCode");
                        dt2.Columns.Add("StateCode");
                        dt2.Columns.Add("SalesTaxRate");
                        var headRW = dt.Rows[2];
                        if (!Regex.IsMatch(headRW[4].ToString().Split('-').FirstOrDefault(), "[a-zA-Z]"))
                        {
                            response.Data = null;
                            response.MessageText = "Can't find State Code at 4th Row in Excel!";
                            return response;
                        }
                        int colCount = headRW.ItemArray.Where(s => s.ToString().Trim() != "").Count();
                        for (int a = 4; a < colCount + 4; a++)
                        {
                            for (int b = 4; b < dt.Rows.Count; b++)
                            {
                                var curRow = dt.Rows[b];
                                try
                                {
                                    //if (curRow.ItemArray[2].ToString() == "AF" && headRW.ItemArray[a].ToString() == "14.00%")
                                    //{ 
                                    //curRow.ItemArray[2].ToString().Trim().Substring(0,2)
                                    //}
                                    decimal rate = Convert.ToDecimal(curRow.ItemArray[a].ToString().Replace("%", "")) / 100;
                                    object[] o = { curRow.ItemArray[2].ToString().Trim(), headRW.ItemArray[a].ToString().Trim().Substring(0,3), rate };
                                    dt2.Rows.Add(o);
                                }
                                catch
                                {
                                }
                            }
                        }
                        response.IsSuccess = true;
                        if (response.IsSuccess)
                        {

                            response.Data = dt2;
                            response.MessageText = "success";
                        }
                        else
                        {
                            response.Data = null;
                            response.MessageText = "fail";
                        }

                        return response;
                    }

                }
            }
        }


        public void Download_SalesTaxExcel(string[] columnsInExcel, string tableName)
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

            DataTable newTable = GetNewSalesTaxData(dt1);
            newTable.TableName = "SalesTaxRateMaster";
            if (dt1 != null)
            {
                ExportSalesTaxDataTableToExcel(newTable, tableName);


            }
            else
            {

            }



        }
        public void ExportSalesTaxDataTableToExcel(DataTable sourceDt, string tableName)
        {
            using (ExcelPackage xp = new ExcelPackage())
            {
                if (sourceDt != null)
                {

                    ExcelWorksheet ws = xp.Workbook.Worksheets.Add(sourceDt.TableName);
                    ws.Cells["A1"].Value="";
                    ws.Cells["A2"].Value = "";
                    ws.Cells["A3"].LoadFromDataTable(sourceDt, true);


                    HttpContext.Current.Response.AddHeader("content-disposition", "attachment;filename=" + tableName + ".xlsx");
                    HttpContext.Current.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

                    xp.SaveAs(HttpContext.Current.Response.OutputStream);

                    HttpContext.Current.Response.End();

                }

            }

        }
        public DataTable GetNewSalesTaxData(DataTable salesdata)
        {
            DataTable dt = new DataTable();
            dt.Clear();
            dt.Columns.Add("PC");
            dt.Columns.Add("PC Description");
            dt.Columns.Add("SAP Tax Code");
            dt.Columns.Add("Tax Code Description");

            var stateCodeList = salesdata.AsEnumerable().Select(row => new{StateCode = row.Field<string>("StateCode")}).Distinct();
            foreach (var StateItem in stateCodeList)
            {
                dt.Columns.Add(StateItem.StateCode);
            }
            var allSalesTaxData = salesdata.AsEnumerable()
                    .Select(row => new
                    {
                        TaxCode = row.Field<string>("TaxCode"),
                        StateCode = row.Field<string>("StateCode"),
                        SalesTaxRate = row.Field<decimal>("SalesTaxRate")
                    });


            var taxCodeList = salesdata.AsEnumerable()
                    .Select(row => new{TaxCode = row.Field<string>("TaxCode")}).Distinct();

            foreach (var taxCodeItem in taxCodeList)
            {
                dynamic salesTaxobject = new ExpandoObject();
                IDictionary<string, object> salesTaxUnderlyingObject = salesTaxobject;
                salesTaxUnderlyingObject.Add("PC", taxCodeItem.TaxCode.Substring(0, 1));
                salesTaxUnderlyingObject.Add("PC Description", "");
                salesTaxUnderlyingObject.Add("SAP Tax Code", taxCodeItem.TaxCode);
                salesTaxUnderlyingObject.Add("Tax Code Description", "");
                //object[] o = { taxCodeItem.TaxCode.Substring(0, 1), "", taxCodeItem.TaxCode, "" };

                var taxList = allSalesTaxData.Where(a => a.TaxCode == taxCodeItem.TaxCode).ToList();
                foreach (var statItem in stateCodeList)
                {
                    if (!taxList.Select(s=>s.StateCode).ToList().Contains(statItem.StateCode))
                    {
                        salesTaxUnderlyingObject.Add(statItem.StateCode, "NA");
              
                    }
                    else {
                        salesTaxUnderlyingObject.Add(statItem.StateCode, Math.Round((taxList.Single(s => s.StateCode==statItem.StateCode).SalesTaxRate * 100), 3).ToString() + "%");
                    }
                }
                dt.Rows.Add(salesTaxUnderlyingObject.Values.ToArray());
            }
            return dt;
        }
    }
}
