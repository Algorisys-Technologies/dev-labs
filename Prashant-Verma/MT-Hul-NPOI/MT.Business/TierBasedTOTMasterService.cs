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
    public class TierBasedTOTMasterService : BaseService
    {

        public UploadFileResponse UploadTierBasedTOTMasterFile(string path, string userId)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();

            MasterResponse excelResult = read.ValidateAndReadExcel(path, MasterConstants.MTTierBasedTOT_Excel_Column);
            if (excelResult.IsSuccess)
            {
                ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
                excelResult.Data = read.RemoveDuplicates(excelResult.Data, new string[5] { MasterConstants.MTTierBasedTOT_Excel_Column[0], MasterConstants.MTTierBasedTOT_Excel_Column[1], MasterConstants.MTTierBasedTOT_Excel_Column[2], MasterConstants.MTTierBasedTOT_Excel_Column[3], MasterConstants.MTTierBasedTOT_Excel_Column[4] }.ToList());
                DataTable table = new DataTable();
                table = excelResult.Data;
                table.TableName = MasterConstants.MTTierBasedTOT_Master_Table_Name;
                //dataService dataservices = new dataService();
                //dataservices.Insert(table);
                //smartDataObj.BulkInsert(table);
                //table = MapTieBaseTOTMaster(table, MasterConstants.MTTierBasedTOT_Excel_Column, MasterConstants.MTTierBasedTOT_DB_Column);
                table = obj.MapMaster(excelResult.Data, MasterConstants.MTTierBasedTOT_Excel_Column, MasterConstants.MTTierBasedTOT_DB_Column);
                table = UpdateAllRows(table);
               
                //smartDataObj.Bulk_Update(table, MasterConstants.MTTierBasedTOT_Master_UpdateSP_Name, MasterConstants.MTTierBasedTOT_Master_UpdateSP_Param_Name);
                DbRequest request = new DbRequest();
                request.StoredProcedureName = MasterConstants.MTTierBasedTOT_Master_UpdateSP_Name;

                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter(MasterConstants.MTTierBasedTOT_Master_UpdateSP_Param_Name, table);
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
        public DataTable UpdateAllRows(DataTable dTable)
        {
            DataTable newDataTable = new DataTable();
            newDataTable = dTable.Clone();
            foreach (DataRow drow in dTable.Rows)
            {
                drow["PriceList"] = drow["PriceList"].ToString().Replace("-", "").Trim();
                var tierList = drow["OutletTier"].ToString().Split(',');
                foreach (var item in tierList)
                {
                    if (drow["PriceList"].ToString().Trim() == "All PC" || drow["PriceList"].ToString().Trim() == "All")
                    {
                        DbRequest request = new DbRequest();
                        request.SqlQuery = "select PriceList from mtPriceListMaster";
                        DataTable pricelist = smartDataObj.GetData(request);
                        foreach (DataRow rw in pricelist.Rows)
                        {
                            var desRow = newDataTable.NewRow();
                            desRow.ItemArray = drow.ItemArray.Clone() as object[];
                            desRow["PriceList"] = rw["PriceList"].ToString();
                            desRow["OutletTier"] = item.Trim();
                            newDataTable.Rows.Add(desRow);
                        }
                    }
                    else
                    {
                        var desRow = newDataTable.NewRow();
                        desRow.ItemArray = drow.ItemArray.Clone() as object[];
                        desRow["OutletTier"] = item.Trim();
                        newDataTable.Rows.Add(desRow);
                    }
                }
            }


            //Datatable which contains unique records will be return as output.
            return newDataTable;
        }

        public List<MTTierBasedTOTMaster> FilterData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            List<MTTierBasedTOTMaster> list = new List<MTTierBasedTOTMaster>();
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
            //    //dt = Ado.GetDataTable("SELECT * FROM MTTierBasedTOTRate " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
            //    request.SqlQuery = "SELECT * FROM MTTierBasedTOTRate " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
            //    dt = smartDataObj.GetData(request);
            //}
            //else
            //{
            //    //dt = Ado.GetDataTable("SELECT * FROM MTTierBasedTOTRate WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
            //    request.SqlQuery = "SELECT * FROM MTTierBasedTOTRate WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
            //    dt = smartDataObj.GetData(request);
            //}

            int recordupto = start + length;
            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from MTTierBasedTOTRate ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from MTTierBasedTOTRate WHERE FREETEXT (*, '" + search + "')) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }

            foreach (DataRow dr in dt.Rows)
            {
                MTTierBasedTOTMaster obj = new MTTierBasedTOTMaster();

                obj.Id = Convert.ToInt32(dr["Id"]);
                obj.ChainName = dr["ChainName"].ToString();
                obj.GroupName = dr["GroupName"].ToString();
                obj.OutletTier = dr["OutletTier"].ToString();
                obj.ColorNonColor = dr["ColorNonColor"].ToString();
                obj.PriceList = dr["PriceList"].ToString();
                obj.OnInvoiceRate = string.Format("{0:n2}", (Convert.ToDecimal(dr["OnInvoiceRate"]) * 100)) + " %";
                obj.OffInvoiceQtrlyRate = string.Format("{0:n2}", (Convert.ToDecimal(dr["OffInvoiceQtrlyRate"]) * 100)) + " %";
                obj.OffInvoiceMthlyRate = string.Format("{0:n2}", (Convert.ToDecimal(dr["OffInvoiceMthlyRate"]) * 100)) + " %";

                list.Add(obj);

            }
            return list;
        }

        //public DataTable MapTieBaseTOTMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
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

        //    //dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
        //    //for (int i = 0; i < dt.Rows.Count; i++)
        //    //{
        //    //    dt.Rows[i]["Id"] = i + 1;
        //    //}
        //    //dt.Columns["Id"].SetOrdinal(0);

        //    return dt;
        //}
    }
}
