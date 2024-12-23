using MT.DataAccessLayer;
using MT.Model;
using MT.SessionManager;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class CustomerGroupService : BaseService
    {

        public UploadFileResponse UploadCustomerGroupFile(string path, string userId)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();

            MasterResponse excelResult = read.ValidateAndReadExcel(path, MasterConstants.Cutomer_Group_Excel_Column);
            if (excelResult.IsSuccess)
            {
                ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();

                excelResult.Data = read.RemoveDuplicates(excelResult.Data, MasterConstants.Customer_Group_Unique_Column.ToList());

                // DataTable uniqueCols = excelResult.Data.DefaultView.ToTable(true, "BasepackCode", "TaxCode");
                // excelResult.Data = uniqueCols;
                // excelResult.Data = obj.MapCustomerGroupMaster(excelResult.Data, MasterConstants.Sku_Excel_Column, MasterConstants.Sku_Db_Column);
                excelResult.Data = obj.MapMaster(excelResult.Data, MasterConstants.Cutomer_Group_Excel_Column, MasterConstants.Cutomer_Group_DB_Column);

                DataTable table = new DataTable();
                table = excelResult.Data;

                table.TableName = MasterConstants.Customer_Group_Master_Table_Name;
                //smartDataObj.BulkInsert(table);
                SmartData smartDataObj = new SmartData();
                //smartDataObj.Bulk_Update(table, MasterConstants.Customer_Group_Master_UpdateSP_Name, MasterConstants.Customer_Group_Master_UpdateSP_Param_Name);
                DbRequest request = new DbRequest();
                request.StoredProcedureName = MasterConstants.Customer_Group_Master_UpdateSP_Name;
                
                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter(MasterConstants.Customer_Group_Master_UpdateSP_Param_Name, table);
                Parameter userParam = new Parameter("user", userId);
                request.Parameters.Add(dtParam);
                request.Parameters.Add(userParam);
                smartDataObj.ExecuteStoredProcedure(request);

                response.IsSuccess = true;
                response.MessageText = "File Uploaded Successfully!";
            }
            else
            {
                response.IsSuccess = excelResult.IsSuccess;
                response.MessageText = excelResult.MessageText;
            }

            return response;
        }

        public CustomerGroupMasterDataTable AjaxGetCustomerGroupData(int draw, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            int totalRows = 0;
            CustomerGroupMasterDataTable dataTableData = new CustomerGroupMasterDataTable();
            dataTableData.draw = draw;
            totalRows = GetTotalRowsCountWithFreeTextSearch(search, MasterConstants.Customer_Group_Master_Table_Name);
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

        private List<MtCustomerGroupMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<MtCustomerGroupMaster> list = new List<MtCustomerGroupMaster>();
            string orderByTxt = "";
            var columnNames = String.Join(",", MasterConstants.Cutomer_Group_DB_Column);

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
                //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                //dt = Ado.GetDataTable("SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
                //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                //dt=smartDataObj.GetData(request);

                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (ORDER BY id)  AS RowNumber,  * from mtCustomerGroupMaster ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                request.SqlQuery = "SELECT * FROM ( SELECT * , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM mtCustomerGroupMaster WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
                dt = smartDataObj.GetData(request);
            }


            foreach (DataRow dr in dt.Rows)
            {
                MtCustomerGroupMaster obj = new MtCustomerGroupMaster();

                obj.CustomerCode = dr["CustomerCode"].ToString();
                obj.StateCode = dr["StateCode"].ToString();
                obj.Id = Convert.ToInt32(dr["Id"]);
                list.Add(obj);

            }
            return list;

        }
     

    }

}
