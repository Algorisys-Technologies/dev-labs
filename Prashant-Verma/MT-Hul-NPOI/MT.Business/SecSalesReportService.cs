using MT.DataAccessLayer;
using MT.Logging;
using MT.Model;
using MT.Utility;
using OfficeOpenXml.FormulaParsing.Excel.Functions.Information;
using OfficeOpenXml.FormulaParsing.Excel.Functions.RefAndLookup;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using NPOI.HSSF.UserModel;

namespace MT.Business
{
    public class SecSalesReportService : BaseService
    {

        public DataTable MapSecSalesReport(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        {
            for (var j = 0; j < columnsInExcel.Count(); j++)
            {
                dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
            }

            System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
            newColumn1.DefaultValue = DateTime.Now;
            dt.Columns.Add(newColumn1);

            System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
            newColumn2.DefaultValue = "admin";
            dt.Columns.Add(newColumn2);

            System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
            newColumn3.DefaultValue = null;
            dt.Columns.Add(newColumn3);

            System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
            newColumn4.DefaultValue = null;
            dt.Columns.Add(newColumn4);

            System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
            newColumn5.DefaultValue = "I";
            dt.Columns.Add(newColumn5);

            dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Guid")));
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                dt.Rows[i]["Id"] = Guid.NewGuid();
            }
            dt.Columns["Id"].SetOrdinal(0);

            return dt;
        }
        public List<MtSecSalesReport> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection, string moc)
        {
            List<MtSecSalesReport> list = new List<MtSecSalesReport>();
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
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from mtSecSalesReport WHERE MOC=" + moc + ") a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {

                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from mtSecSalesReport WHERE MOC=" + moc + " AND " + search + ") a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }

            foreach (DataRow dr in dt.Rows)
            {
                MtSecSalesReport obj = new MtSecSalesReport();

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
                obj.OutletSecChannel = dr["OutletSecChannel"].ToString();

                list.Add(obj);

            }
            return list;
        }



        public int GetTotalRowsCountSecSalesReport(string search, string moc)
        {
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "Select Count(*) from mtSecSalesReport where MOC=" + moc;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "Select Count(*) from mtSecSalesReport where MOC = " + moc + " AND " + search;
                dt = smartDataObj.GetData(request);
            }
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            return recordsCount;
        }

        public UploadFileResponse UploadSecSalesReportFile(string path)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();

            //////Validate//////

            var excelResult = ValidateAndReadExcelWithoutHeaderUsingNPOI(path, "Customer Code");
            if (excelResult.IsSuccess)
            {
                response.IsSuccess = true;
                response.MessageText = "File Uploaded Successfully!";
            }
            else
            {
                response.IsSuccess = excelResult.IsSuccess;
                response.MessageText = "File does not contains valid data";
            }

            return response;
        }

        ///-------------validate---------------///
        public MasterResponse ValidateAndReadExcelWithoutHeaderUsingNPOI(string path, string firstColumnName)
        {
            MasterResponse response = new MasterResponse();

            var columnsInExcel = (ConfigConstants.GstCheck == true)
                                    ? MasterConstants.UploadSecondarySales_Excel_Column_WithGst.ToArray()
                                    : MasterConstants.UploadSecondarySales_Excel_Column.ToArray();

            try
            {
                // Open the Excel file
                using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
                {
                    IWorkbook workbook = new XSSFWorkbook(fs); // Assuming XLSX format. Use HSSFWorkbook for XLS.
                    ISheet sheet = workbook.GetSheetAt(0); // Get the first sheet

                    if (sheet == null)
                    {
                        return null;
                    }

                    List<IRow> validRows = new List<IRow>();

                    // Loop through the rows
                    for (int rowIndex = 0; rowIndex <= sheet.LastRowNum; rowIndex++)
                    {
                        IRow row = sheet.GetRow(rowIndex);

                        if (row != null && row.GetCell(0) != null)
                        {
                            // Read the first cell value (F1)
                            string firstCellValue = row.GetCell(0).ToString();

                            if (!string.IsNullOrWhiteSpace(firstCellValue) &&
                                firstCellValue != firstColumnName && firstCellValue != "Customer")
                            {
                                validRows.Add(row);
                            }
                        }
                    }

                    var columnsInDB = (ConfigConstants.GstCheck == true)
                                        ? MasterConstants.UploadSecondarySales_DB_Column_WithGst.ToArray()
                                        : MasterConstants.UploadSecondarySales_DB_Column.ToArray();

                    ///-------insert-------///
                    smartDataObj.InsertDataUsingDataTable(validRows, columnsInExcel, columnsInDB, "mtTempSecSalesReport");

                    var dbReq = new DbRequest();
                    dbReq.StoredProcedureName = "mtspMoveSecSalesData"; // ToDo MOC input parameter

                    // ToDo: Uncomment when you want to execute the procedure
                    smartDataObj.ExecuteStoredProcedure(dbReq);

                    Logger.Log(LogLevel.INFO, "Secondary sales Uploaded Successfully!  Time: " + DateTime.Now);
                    response.IsSuccess = true;
                }
            }
            catch (Exception ex)
            {
                Logger.Log(LogLevel.ERROR, "Error reading Excel file: " + ex.Message + ex.Data);
                response.IsSuccess = false;
                response.MessageText = "Error reading Excel file.";
            }

            return response;
        }
        public string ExportSqlDataReaderToCsv(string fileName)
        {
            string filePath = AppDomain.CurrentDomain.BaseDirectory + "FilesDownload/" + fileName + ".csv";
            string sqlselectQuery = "select CustomerCode as Customer, CustomerName as Customer, OutletCategoryMaster as [Outlet Category - Master], BasepackCode as Basepack, BasepackName as Basepack, PMHBrandCode as [PMH Brand], PMHBrandName[PMH Brand], SalesSubCat as [Sales SubCategory], PriceList as [Price List], HulOutletCode as [HUL Outlet Code], HulOutletCodeName as [HUL Outlet Code], BranchCode as [Branch - Master], BranchName as [Branch - Master], MOC, OutletSecChannel as [Outlet Secondary Channel], ClusterCode as [Cluster Code], ClusterName as [Cluster Code], OutletTier as [Outlet Tier], TotalSalesValue as [Total Sales Value (INR)], SalesReturnValue as [Sales Return Value (INR)], NetSalesValue as [Net Sales Value (INR)], NetSalesQty as [Net Sales Qty (KGs)],IsGstApplicable as [GST Applicable] from mtSecSalesReport";
            Logger.Log(LogLevel.INFO, "Download Secondary Sales Start Time: " + DateTime.Now);
            WriteCSVFile(filePath, sqlselectQuery);
            Logger.Log(LogLevel.INFO, "Download Secondary Sales End Time: " + DateTime.Now);

            return filePath;
        }

        public FileValidation FindCurrentMOCInExcelFile(string path, string curMOC)
        {
            try
            {
                Logger.Log(LogLevel.INFO, "FindCurrentMOCInExcelFileUsingNPOI " + path);
                string columnStringInExcel = "";
                string validSecondarySalesColumnString = "";
                FileValidation fileValidation = new FileValidation();
                bool result = false;
                string newMOC = "";

                // Get the columns depending on the GST check
                var columnsInExcel = (ConfigConstants.GstCheck == true) ? MasterConstants.UploadSecondarySales_Excel_Column_WithGst.ToArray() : MasterConstants.UploadSecondarySales_Excel_Column.ToArray();

                Logger.Log(LogLevel.INFO, "FindCurrentMOCInExcelFileUsingNPOI - Preparing valid column sequence");
                foreach (var item in columnsInExcel)
                {
                    validSecondarySalesColumnString += item + ",";
                }

                fileValidation.ValidColumnSequence = validSecondarySalesColumnString;

                // Open the Excel file using NPOI
                using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
                {
                    IWorkbook workbook = WorkbookFactory.Create(fs);
                    ISheet sheet = workbook.GetSheetAt(0);  // Get the first sheet

                    if (sheet == null)
                    {
                        fileValidation.IsvalidData = false;
                        Logger.Log(LogLevel.INFO, "No sheet found.");
                        return fileValidation;
                    }

                    Logger.Log(LogLevel.INFO, "Sheet found - Processing");

                    // Reading the first two rows
                    IRow headerRow = sheet.GetRow(0);   // First row (header)
                    IRow dataRow = sheet.GetRow(1);     // Second row (data)

                    // Read the header and compare with valid columns
                    foreach (ICell cell in headerRow)
                    {
                        if (cell == null || string.IsNullOrEmpty(cell.ToString()))
                            break;

                        columnStringInExcel += cell.ToString() + ",";
                    }

                    Logger.Log(LogLevel.INFO, "Comparing header with valid column sequence.");
                    if (validSecondarySalesColumnString != columnStringInExcel)
                    {
                        fileValidation.IsvalidData = false;
                        Logger.Log(LogLevel.INFO, "Invalid column sequence.");
                        return fileValidation;
                    }
                    else
                    {
                        fileValidation.IsvalidData = true;
                    }

                    // Check if the data row contains the expected MOC value (assuming column index 13)
                    string mocValue = dataRow.GetCell(13)?.ToString();
                    Logger.Log(LogLevel.INFO, "Extracted MOC from Excel: " + mocValue);

                    if (mocValue == curMOC)
                    {
                        result = true;
                    }

                    newMOC = mocValue;
                    fileValidation.MOC = newMOC;
                    fileValidation.IsvalidFile = result;

                    Logger.Log(LogLevel.INFO, "File processing complete. MOC: " + newMOC);
                }

                return fileValidation;
            }
            catch (Exception ex)
            {
                Logger.Log(LogLevel.ERROR, "FindCurrentMOCInExcelFileUsingNPOI Exception: " + ex.Message);
                Logger.Log(LogLevel.ERROR, "FindCurrentMOCInExcelFileUsingNPOI StackTrace: " + ex.StackTrace);
                throw ex;
            }
        }

        public class FileValidation
        {
            public string MOC { get; set; }
            public bool IsvalidFile { get; set; }
            public bool IsvalidData { get; set; }
            public string ValidColumnSequence { get; set; }
        }

        public void GetColumnStringFromExcel(string path)
        {
            string columnstring = "";
            using (OleDbConnection conn = new OleDbConnection())
            {
                DataTable dt1 = new DataTable();
                DataTable dt = new DataTable();
                string Import_FileName = path;
                string fileExtension = Path.GetExtension(Import_FileName);

                if (fileExtension == ".xls")
                    conn.ConnectionString = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + Import_FileName + @";Extended Properties=""Excel 8.0;IMEX=1;HDR=NO;TypeGuessRows=0;ImportMixedTypes=Text""";
                if (fileExtension == ".xlsx" || fileExtension == ".xlsb")
                    conn.ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + Import_FileName + @";Extended Properties=""Excel 8.0;IMEX=1;HDR=NO;TypeGuessRows=0;ImportMixedTypes=Text""";


                conn.Open();
                dt1 = conn.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, null);

                if (dt1 == null)
                {
                    //
                }

                String[] excelSheets = new String[dt1.Rows.Count];
                int i = 0;
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
                    comm.CommandText = "Select * from [" + excelSheets[0] + "]";
                    comm.Connection = conn;


                    using (OleDbDataAdapter da = new OleDbDataAdapter())
                    {
                        da.SelectCommand = comm;
                        da.Fill(dt);

                        var headRW = dt.Rows[0];
                        foreach (var item in headRW.ItemArray)
                        {
                            if (string.IsNullOrEmpty(item.ToString()))
                            {
                                break;
                            }
                            else
                            {
                                columnstring += item + ";";
                            }
                        }
                    }
                }

                conn.Close();
            }
        }

    }
}