using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class SubcategoryMappingService:BaseService
    {

        public UploadFileResponse UploadBrandwiseSubCategoryFile(string path, string userId)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();

            MasterResponse excelResult = read.ValidateAndReadExcel(path, MasterConstants.BrandWise_SubCategory_Excel_Column);
            if (excelResult.IsSuccess)
            {
                ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();

                excelResult.Data = read.RemoveDuplicates(excelResult.Data, MasterConstants.BrandWise_SubCategory_Unique_Column.ToList());

                excelResult.Data = obj.MapMaster(excelResult.Data, MasterConstants.BrandWise_SubCategory_Excel_Column, MasterConstants.BrandWise_SubCategory_DB_Column);

                DataTable table = new DataTable();
                table = excelResult.Data;

                table.TableName = MasterConstants.BrandWise_SubCategory_Master_Table_Name;
                SmartData smartDataObj = new SmartData();
                //smartDataObj.Bulk_Update(table, MasterConstants.BrandWise_SubCategory_Master_UpdateSP_Name, MasterConstants.BrandWise_SubCategory_Master_UpdateSP_Param_Name);
                DbRequest request = new DbRequest();
                request.StoredProcedureName = MasterConstants.BrandWise_SubCategory_Master_UpdateSP_Name;

                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter(MasterConstants.BrandWise_SubCategory_Master_UpdateSP_Param_Name, table);
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
                //response.MessageText = "File does not contains valid data";
                response.MessageText = excelResult.MessageText;
            }

            return response;
        }
        
        public BrandwiseSubCategoryMasterDataTable AjaxGetBrandWiseSubCategoryData(int draw, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            int totalRows = 0;
            BrandwiseSubCategoryMasterDataTable dataTableData = new BrandwiseSubCategoryMasterDataTable();
            dataTableData.draw = draw;
            totalRows = GetTotalRowsCountWithFreeTextSearch(search, MasterConstants.BrandWise_SubCategory_Master_Table_Name);
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


        private List<MtBrandwiseSubCategoryMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<MtBrandwiseSubCategoryMaster> list = new List<MtBrandwiseSubCategoryMaster>();
            string orderByTxt = "";
            var columnNames = String.Join(",", MasterConstants.BrandWise_SubCategory_DB_Column);

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
                request.SqlQuery = "SELECT * FROM ( SELECT * , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.BrandWise_SubCategory_Master_Table_Name + " ) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";

                dt = smartDataObj.GetData(request);
            }
            else
            {
                //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                request.SqlQuery = "SELECT * FROM ( SELECT * , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.BrandWise_SubCategory_Master_Table_Name + " WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
                dt = smartDataObj.GetData(request);
            }


            foreach (DataRow dr in dt.Rows)
            {
                MtBrandwiseSubCategoryMaster obj = new MtBrandwiseSubCategoryMaster();

                obj.Id = Convert.ToInt32(dr["Id"]);
                obj.PMHBrandCode = dr["PMHBrandCode"].ToString();
                obj.PMHBrandName = dr["PMHBrandName"].ToString();
                obj.SalesSubCat = dr["SalesSubCat"].ToString();
                obj.PriceList = dr["PriceList"].ToString();
                obj.TOTSubCategory = dr["TOTSubCategory"].ToString();

                list.Add(obj);

            }
            return list;

        }


    }

      
      
}
