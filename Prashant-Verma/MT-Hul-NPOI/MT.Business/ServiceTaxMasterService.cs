using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class ServiceTaxMasterService : BaseService
    {
        public DataSet GetDataToDownload()
        {
            DataSet ds = new DataSet();
            SqlConnection connection = new SqlConnection(connectionString);

            DataTable dt1 = new DataTable();
            DataTable dt2 = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "Select ChainName,GroupName,Rate from mtServiceTaxRateMaster";
            dt1 = smartDataObj.GetData(request);
            dt2 = dt1.Copy();
            ds.Tables.Add(dt2);
            return ds;
        }

        public List<MtServiceTaxRateMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<MtServiceTaxRateMaster> list = new List<MtServiceTaxRateMaster>();
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
            //if (string.IsNullOrEmpty(search))
            //{
            //    //dt = Ado.GetDataTable("SELECT * FROM mtServiceTaxRateMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
            //    request.SqlQuery = "SELECT * FROM mtServiceTaxRateMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
            //    dt = smartDataObj.GetData(request);
            //}
            //else
            //{
            //    //dt = Ado.GetDataTable("SELECT * FROM mtServiceTaxRateMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
            //    request.SqlQuery = "SELECT * FROM mtServiceTaxRateMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
            //    dt = smartDataObj.GetData(request);
            //}

            int recordupto = start + length;
            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from mtServiceTaxRateMaster ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from mtServiceTaxRateMaster WHERE FREETEXT (*, '" + search + "')) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }

            foreach (DataRow dr in dt.Rows)
            {
                MtServiceTaxRateMaster obj = new MtServiceTaxRateMaster();

                obj.Id = Convert.ToInt32(dr["Id"]);
                obj.ChainName = dr["ChainName"].ToString();
                obj.GroupName = dr["GroupName"].ToString();
                obj.Rate = string.Format("{0:n2}", (Convert.ToDecimal(dr["Rate"]) * 100)) + " %";

                list.Add(obj);

            }
            return list;
        }


        public UploadFileResponse UploadServiceTaxFile(string path, string userId)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();
            // MasterResponse excelResult = new MasterResponse();


            MasterResponse excelResult = read.ValidateAndReadExcel(path, MasterConstants.ServiceTax_Excel_Column); // {
            if (excelResult.IsSuccess)
            {
                ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();

                excelResult.Data = read.RemoveDuplicates(excelResult.Data, new string[2] { MasterConstants.ServiceTax_Excel_Column[0], MasterConstants.ServiceTax_Excel_Column[1] }.ToList());
                //excelResult.Data = MapServiceTaxMaster(excelResult.Data, MasterConstants.ServiceTax_Excel_Column, MasterConstants.ServiceTax_DB_Column);
                excelResult.Data = obj.MapMaster(excelResult.Data, MasterConstants.ServiceTax_Excel_Column, MasterConstants.ServiceTax_DB_Column);

                DataTable table = new DataTable();
                table = excelResult.Data;
                table.TableName = MasterConstants.ServiceTax_Master_Table_Name;
                //dataService dataservices = new dataService();
                //dataservices.Insert(table);
                //smartDataObj.BulkInsert(table);
                //smartDataObj.Bulk_Update(table, MasterConstants.ServiceTax_Master_UpdateSP_Name, MasterConstants.ServiceTax_Master_UpdateSP_Param_Name);
                DbRequest request = new DbRequest();
                request.StoredProcedureName = MasterConstants.ServiceTax_Master_UpdateSP_Name;

                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter(MasterConstants.ServiceTax_Master_UpdateSP_Param_Name, table);
                Parameter userParam = new Parameter("user", userId);
                request.Parameters.Add(dtParam);
                request.Parameters.Add(userParam);
                smartDataObj.ExecuteStoredProcedure(request);
                response.IsSuccess = true;
                response.MessageText = MessageConstants.Success_Upload;
            }
            else
            {
                response.IsSuccess = excelResult.IsSuccess;
                //response.MessageText = MessageConstants.Invalid_FileData;
                response.MessageText = excelResult.MessageText;
            }

            return response;
        }


        //public DataTable MapServiceTaxMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        //{
        //    for (var j = 0; j < columnsInExcel.Count(); j++)
        //    {
        //        dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
        //    }

        //    System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
        //    newColumn1.DefaultValue = DateTime.Now;
        //    dt.Columns.Add(newColumn1);

        //    System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
        //    newColumn2.DefaultValue = "admin";
        //    dt.Columns.Add(newColumn2);

        //    System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
        //    newColumn3.DefaultValue = null;
        //    dt.Columns.Add(newColumn3);

        //    System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
        //    newColumn4.DefaultValue = null;
        //    dt.Columns.Add(newColumn4);

        //    System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
        //    newColumn5.DefaultValue = "I";
        //    dt.Columns.Add(newColumn5);

        //    return dt;
        //}
    }
}
