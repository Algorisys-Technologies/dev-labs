
using Ionic.Zip;
using MT.DataAccessLayer;
using MT.Logging;
using MT.Utility;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web;

namespace MT.Business
{
    public class BaseService
    {
        public string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        public SmartData smartDataObj = new SmartData();

        public ILogger Logger = LoggerFactory.GetLogger();

        public int GetTotalRowsCountWithoutFreeText(string search, string tableName, string columnSearch)
        {
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            if (string.IsNullOrEmpty(search))
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtCustomerGroupMaster", connection);
                request.SqlQuery = "Select Count(*) from " + tableName;
                dt = smartDataObj.GetData(request);

            }
            else
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "')", connection);
                //                request.SqlQuery = "Select Count(*) from " + tableName + " WHERE FREETEXT (*, '" + search + "')";
                request.SqlQuery = "Select Count(*) from " + tableName + " WHERE " + search;
                //CustomerCode+CustomerName+OutletCategoryMaster+BasepackCode+BasepackName+PMHBrandCode+PMHBrandName+SalesSubCat+PriceList+HulOutletCode+BranchCode+ClusterCode+OutletTier like '%" + search + "%')
                dt = smartDataObj.GetData(request);
            }
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            return recordsCount;
        }

        public int GetTotalRowsCountWithFreeTextSearch(string search, string tableName)
        {
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            if (string.IsNullOrEmpty(search))
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtCustomerGroupMaster", connection);
                request.SqlQuery = "Select Count(*) from " + tableName;
                dt = smartDataObj.GetData(request);

            }
            else
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "')", connection);
                request.SqlQuery = "Select Count(*) from " + tableName + " WHERE FREETEXT (*, '" + search + "')";

                dt = smartDataObj.GetData(request);
            }
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            return recordsCount;
        }

        public int GetTotalRowsCount(string search, string tableName)
        {
            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            
            if (string.IsNullOrEmpty(search))
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtMOCCalculation", connection);
                request.SqlQuery = "Select Count(*) from " + tableName;
                dt = smartDataObj.GetData(request);

            }
            else
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtMOCCalculation WHERE FREETEXT (*, '" + search + "')", connection);
                request.SqlQuery = "Select Count(*) from " + tableName + " WHERE " + search;
                dt = smartDataObj.GetData(request);
            }
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            return recordsCount;
        }


        public void ExportDataTableToExcel(DataTable sourceDt, string tableName)
        {
            using (ExcelPackage xp = new ExcelPackage())
            {
                if (sourceDt != null)
                {

                    ExcelWorksheet ws = xp.Workbook.Worksheets.Add(sourceDt.TableName);
                    ws.Cells["A1"].LoadFromDataTable(sourceDt, true);


                    HttpContext.Current.Response.AddHeader("content-disposition", "attachment;filename=" + tableName + ".xlsx");
                    HttpContext.Current.Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

                    xp.SaveAs(HttpContext.Current.Response.OutputStream);

                    HttpContext.Current.Response.End();

                }

            }

        }

        public string SetCurrentMOC()
        {
            string currentMOC = string.Empty;
            try
            {
                DbRequest request = new DbRequest();
                request.SqlQuery = "SELECT * FROM " + DashBoardConstants.MOC_Status_Table_Name + " where Status='Open'";
                DataTable dt = smartDataObj.GetData(request);
                if (dt != null)
                {
                    currentMOC = dt.Rows[0]["MonthId"].ToString() + "." + dt.Rows[0]["Year"].ToString();
                }
            }
            catch (Exception ex)
            {
                currentMOC = string.Empty;
            }
            return currentMOC;
        }


        public void DownloadAllFileFormat()
        {

            ZipFile multipleFiles = new ZipFile();

            HttpContext.Current.Response.AddHeader("Content-Disposition", "attachment; filename=DownloadedFile.zip");

            HttpContext.Current.Response.ContentType = "application/zip";
            string[] fileNames = MasterConstants.DownloadAllFileFormatFileName;
            foreach (string fileName in fileNames)
            {

                string filePath = System.Web.HttpContext.Current.Server.MapPath("/App_Data/Temp/" + fileName);
                multipleFiles.AddFile(filePath, string.Empty);

            }

            multipleFiles.Save(HttpContext.Current.Response.OutputStream);

        }

        public void WriteCSVFile(string filePath, string sqlselectQuery)
        {

            StreamWriter CsvfileWriter = new StreamWriter(filePath);

            SqlCommand sqlcmd = new SqlCommand();

            SqlConnection spContentConn = new SqlConnection(connectionString);
            sqlcmd.Connection = spContentConn;
            sqlcmd.CommandTimeout = 0;
            sqlcmd.CommandType = CommandType.Text;
            sqlcmd.CommandText = sqlselectQuery;
            spContentConn.Open();
            using (spContentConn)
            {
                using (SqlDataReader sdr = sqlcmd.ExecuteReader())
                using (CsvfileWriter)
                {
                    //This Block of code for getting the Table Headers
                    //DataTable Tablecolumns = new DataTable();
                    List<string> Tablecolumns = new List<string>();

                    for (int i = 0; i < sdr.FieldCount; i++)
                    {
                        //Tablecolumns.Columns.Add(sdr.GetName(i));
                        Tablecolumns.Add(sdr.GetName(i));
                    }
                    //CsvfileWriter.WriteLine(string.Join(",", Tablecolumns.Columns.Cast<DataColumn>().Select(csvfile => csvfile.ColumnName)));
                    CsvfileWriter.WriteLine(string.Join(",", Tablecolumns));
                    //This block of code for getting the Table Headers
                    while (sdr.Read())
                    {
                        //based on your Table columns you can increase and decrese columns
                        var singlrRow = new StringBuilder();
                        for (int i = 0; i < sdr.FieldCount; i++)
                        {
                            var value = sdr[i].ToString();
                            if (value.IndexOfAny(new char[] { '"', ',' }) != -1)
                                singlrRow.AppendFormat("\"{0}\"", value.Replace("\"", "\"\""));
                            else
                                singlrRow.Append(value);

                            //singlrRow += sdr[i].ToString() + ",";
                            singlrRow.Append(",");
                        }
                        CsvfileWriter.WriteLine(singlrRow.ToString());
                    }

                }
            }
        }


        public static DateTime ParseDate(string s)
        {
            CultureInfo CultureInfo1 = (CultureInfo)CultureInfo.CurrentCulture.Clone();
            CultureInfo1.DateTimeFormat.ShortDatePattern = "dd/MM/yyyy";
            Thread.CurrentThread.CurrentCulture = CultureInfo1;
            DateTime result;
            if (!DateTime.TryParse(s, out result))
            {
                result = DateTime.ParseExact(s, "yyyy-MM-ddT24:mm:ssK", System.Globalization.CultureInfo.InvariantCulture);
                result = result.AddDays(1);
            }
            return result;
        }
        public void ExportDatasetToExcel(DataSet sourceDt, string tableName)
        {
            using (ExcelPackage xp = new ExcelPackage())
            {
                if (sourceDt != null)
                {
                    foreach (DataTable dt in sourceDt.Tables)
                    {
                        ExcelWorksheet ws = xp.Workbook.Worksheets.Add(dt.TableName);
                        ws.Cells["A1"].LoadFromDataTable(dt, true);

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
