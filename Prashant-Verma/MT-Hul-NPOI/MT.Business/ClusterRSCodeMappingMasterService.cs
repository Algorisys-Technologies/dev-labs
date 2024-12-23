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
     public class ClusterRSCodeMappingMasterService:BaseService
    {



         public UploadFileResponse UploadClusterRSCodeMappingFile(string path, string userId)
         {
             var response = new UploadFileResponse();

             ReadExcel read = new ReadExcel();

             MasterResponse excelResult = read.ValidateAndReadExcelWithoutHeader(path, MasterConstants.ClusterRSCodeMapping_Excel_Column);
             if (excelResult.IsSuccess)
             {
                 ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
                 string columnName = MasterConstants.ClusterRSCodeMapping_Excel_Column.First();

                 excelResult.Data = read.RemoveDuplicates(excelResult.Data, new string[1] { columnName }.ToList());


                 excelResult.Data = obj.MapMaster(excelResult.Data, MasterConstants.ClusterRSCodeMapping_Excel_Column, MasterConstants.ClusterRSCodeMapping_Db_Column);

                 DataTable table = new DataTable();
                 table = excelResult.Data;

                 table.TableName = MasterConstants.ClusterRSCodeMapping_Master_Table_Name;

                 SmartData smartDataObj = new SmartData();


                 DbRequest request = new DbRequest();
                 request.StoredProcedureName = MasterConstants.ClusterRSCodeMapping_Master_UpdateSP_Name;

                 request.Parameters = new List<Parameter>();
                 Parameter dtParam = new Parameter(MasterConstants.ClusterRSCodeMapping_Master_UpdateSP_Param_Name, table);
                 Parameter userParam = new Parameter("@user", userId);
                 request.Parameters.Add(dtParam);
                 request.Parameters.Add(userParam);
                 smartDataObj.ExecuteStoredProcedure(request);


                 response.IsSuccess = true;
                 response.MessageText = "File Uploaded Successfully!";
             }
             else
             {
                 response.IsSuccess = excelResult.IsSuccess;
                 //response.MessageText = "File does not contains valid data";
                 response.MessageText = excelResult.MessageText;
             }

             return response;
         }



        //public ClusterRSCodeMappingMasterDataTable AjaxGetClusterRSCodeMappingData(int draw, int start, int length, string search, string sortColumnName, string sortDirection)
        //{
        //    int totalRows = 0;
        //    ClusterRSCodeMappingMasterDataTable dataTableData = new ClusterRSCodeMappingMasterDataTable();
        //    dataTableData.draw = draw;
        //    totalRows = GetTotalRowsCount(search, MasterConstants.ClusterRSCodeMapping_Master_Table_Name);
        //    if (length == -1)
        //    {
        //        length = totalRows;
        //    }
        //    dataTableData.recordsTotal = totalRows;
        //    int recordsFiltered = 0;
        //    dataTableData.data = FilterData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
        //    dataTableData.recordsFiltered = totalRows;
        //    return dataTableData;
        //}



        //private List<MtClusterRSCodeMappingMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        //{
            
        //    List<MtClusterRSCodeMappingMaster> list = new List<MtClusterRSCodeMappingMaster>();
        //    string orderByTxt = "";
        //    var columnNames = String.Join(",", MasterConstants.ClusterRSCodeMapping_Db_Column);

        //    if (sortDirection == "asc")
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }
        //    else
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }

        //     SmartData smartDataObj = new SmartData();
        //    DataTable dt = new DataTable();
        //    DbRequest request = new DbRequest();
        //    int recordupto = start + length;
        //    if (string.IsNullOrEmpty(search))
        //    {
        //        //dt = Ado.GetDataTable("SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
        //        //request.SqlQuery = "SELECT * FROM mtClusterRSCodeMappingMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (ORDER BY Id)  AS RowNumber,  * from mtClusterRSCodeMappingMaster ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
        //        dt = smartDataObj.GetData(request);
        //    }
        //    else
        //    {
        //        //dt = Ado.GetDataTable("SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
        //        //request.SqlQuery = "SELECT * FROM mtClusterRSCodeMappingMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM mtClusterRSCodeMappingMaster WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
        //        dt = smartDataObj.GetData(request);
        //    }


        //    foreach (DataRow dr in dt.Rows)
        //    {
        //        MtClusterRSCodeMappingMaster obj = new MtClusterRSCodeMappingMaster();

        //        obj.ClusterCode = dr["ClusterCode"].ToString();
        //        obj.RSCode = dr["RSCode"].ToString();

        //        list.Add(obj);

        //    }
        //    return list;
        //}

        public List<MtClusterRSCodeMappingMaster> LoadAllClusterRSCodeMappingData()
        {


            List<MtClusterRSCodeMappingMaster> list = new List<MtClusterRSCodeMappingMaster>();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            var columnNames = String.Join(",", MasterConstants.ClusterRSCodeMapping_Db_Column);
            SmartData smartDataObj = new SmartData();
            request.SqlQuery = "SELECT * FROM " + MasterConstants.ClusterRSCodeMapping_Master_Table_Name;
            dt = smartDataObj.GetData(request);
            
            foreach (DataRow dr in dt.Rows)
            {
                MtClusterRSCodeMappingMaster data = new MtClusterRSCodeMappingMaster();
                data.ClusterCode = dr["ClusterCode"].ToString();
                data.RSCode = dr["RSCode"].ToString();
                data.Id = Convert.ToInt32(dr["Id"]);
                list.Add(data);
            }
            return list;
          
        }


    }
}
