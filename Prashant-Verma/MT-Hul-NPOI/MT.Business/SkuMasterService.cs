﻿using MT.DataAccessLayer;
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
    public class SkuMasterService:BaseService
    {


        public UploadFileResponse UploadSkuFile(string path, string userId)
         {
             
             var response = new UploadFileResponse();

             ReadExcel read = new ReadExcel();

             MasterResponse excelResult = read.ValidateAndReadExcel(path, MasterConstants.Sku_Excel_Column);
             if (excelResult.IsSuccess)
             {
                 ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
                 string columnName = MasterConstants.Sku_Excel_Column.First();
                 
                
                 excelResult.Data = read.RemoveDuplicates(excelResult.Data, new string[1] { columnName }.ToList());
                 
                // DataTable uniqueCols = excelResult.Data.DefaultView.ToTable(true, "BasepackCode", "TaxCode");
                // excelResult.Data = uniqueCols;
                // excelResult.Data = obj.MapCustomerGroupMaster(excelResult.Data, MasterConstants.Sku_Excel_Column, MasterConstants.Sku_Db_Column);
                 
                 excelResult.Data = obj.MapMaster(excelResult.Data, MasterConstants.Sku_Excel_Column, MasterConstants.Sku_Db_Column);
                 
                 DataTable table = new DataTable();
                 table = excelResult.Data;

                 table.TableName = MasterConstants.Sku_Master_Table_Name;                
                 SmartData smartDataObj = new SmartData();
             
                 DbRequest request = new DbRequest();
                 request.StoredProcedureName = MasterConstants.Sku_Master_UpdateSP_Name;

                 request.Parameters = new List<Parameter>();
                 Parameter dtParam = new Parameter(MasterConstants.Sku_Master_UpdateSP_Param_Name, table);
                 Parameter userParam = new Parameter("@user", userId);
                 request.Parameters.Add(dtParam);
                 request.Parameters.Add(userParam);
                 
                 smartDataObj.ExecuteStoredProcedure(request);
                
           

                
                // smartDataObj.Bulk_Update(table, MasterConstants.Sku_Master_UpdateSP_Name, MasterConstants.Sku_Master_UpdateSP_Param_Name);
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

         public SkuMasterDataTable AjaxGetSkuData(int draw, int start, int length, string search, string sortColumnName, string sortDirection)
         {
             int totalRows = 0;             
             SkuMasterDataTable dataTableData = new SkuMasterDataTable();
             dataTableData.draw = draw;
             totalRows = GetTotalRowsCountWithFreeTextSearch(search, MasterConstants.Sku_Master_Table_Name);
             if (length == -1)
             {
                 length = totalRows;
             }
             dataTableData.recordsTotal = totalRows;
             int recordsFiltered = 0;
             dataTableData.data = FilterData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
             dataTableData.recordsFiltered = totalRows;

             return dataTableData;
         }

         private List<MtSkuMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
         {
             List<MtSkuMaster> list = new List<MtSkuMaster>();
             string orderByTxt = "";
             var columnNames = String.Join(",", MasterConstants.Sku_Db_Column);

             if (sortDirection == "asc")
             {
                 orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
             }
             else
             {
                 orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
             }

             SmartData smartDataObj = new SmartData();
             DataTable dt = new DataTable();
             DbRequest request = new DbRequest();
             int recordupto = start + length;
             if (string.IsNullOrEmpty(search))
             {
                 //dt = Ado.GetDataTable("SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
                 //request.SqlQuery = "SELECT * FROM mtSkuMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                 request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (ORDER BY Id)  AS RowNumber,  * from mtSkuMaster ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                 dt = smartDataObj.GetData(request);
             }
             else
             {
                 //dt = Ado.GetDataTable("SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
                 //request.SqlQuery = "SELECT * FROM mtSkuMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                 //
                 request.SqlQuery = "SELECT * FROM ( SELECT * , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM mtSkuMaster WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
                 dt = smartDataObj.GetData(request);
             }


             foreach (DataRow dr in dt.Rows)
             {
                 MtSkuMaster obj = new MtSkuMaster();

                 obj.BasepackCode = dr["BasepackCode"].ToString();
                 obj.TaxCode = dr["TaxCode"].ToString();
                 obj.Id = Convert.ToInt32(dr["Id"]);
               
                 list.Add(obj);

             }
             return list;
         }
        
    }
}
