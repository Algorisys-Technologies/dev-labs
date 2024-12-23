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
    public class SubcategoryTOTRateService:BaseService
    {
        public UploadFileResponse UploadSubCategoryTOTFile(string path, string totCategory, string userId)
        {
            var response = new UploadFileResponse();

            ReadExcel read = new ReadExcel();

            MasterResponse excelResult = read.ValidateAndReadSubCategoryTOTExcel(path, MasterConstants.SubCategory_TOT_Excel_Column, totCategory);
            if (excelResult.IsSuccess)
            {
                ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();

                excelResult.Data = obj.MapSubcategoryTOTMaster(excelResult.Data, MasterConstants.SubCategory_TOT_Excel_Column, MasterConstants.SubCategory_TOT_DB_Column,totCategory);

                excelResult.Data = read.RemoveDuplicates(excelResult.Data, MasterConstants.SubCategory_TOT_Unique_Column.ToList());

                DataTable table = new DataTable();
                table = excelResult.Data;

                table.TableName = MasterConstants.SubCategory_TOT_Table_Name;
                SmartData smartDataObj = new SmartData();
                DbRequest request = new DbRequest();
                request.StoredProcedureName = MasterConstants.SubCategory_TOT_Master_UpdateSP_Name;

                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter(MasterConstants.SubCategory_TOT_Master_UpdateSP_Param_Name, table);
                Parameter userParam = new Parameter("user", userId);
                Parameter totCategoryParam = new Parameter("totCategory", totCategory);
                request.Parameters.Add(dtParam);
                request.Parameters.Add(userParam);
                request.Parameters.Add(totCategoryParam);
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

        public SubCategoryTOTMasterDataTable AjaxGetSubCategoryTOTData(int draw, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            int totalRows = 0;
            SubCategoryTOTMasterDataTable dataTableData = new SubCategoryTOTMasterDataTable();
            dataTableData.draw = draw;
            totalRows = GetTotalRowsCountWithFreeTextSearch(search, MasterConstants.SubCategory_TOT_Table_Name);
            if (length == -1)
            {
                length = totalRows;
            }
            dataTableData.recordsTotal = totalRows;
            int recordsFiltered = 0;
            dataTableData.data = FilterSubCategoryTOTData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = totalRows;

            return dataTableData;
        }

        private List<MtSubCategoryTOTMaster> FilterSubCategoryTOTData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        {
            var pageNo = (start / length) + 1;
            List<MtSubCategoryTOTMaster> list = new List<MtSubCategoryTOTMaster>();
            string orderByTxt = "";
            var columnNames = String.Join(",", MasterConstants.SubCategory_TOT_DB_Column);

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
            if (string.IsNullOrEmpty(search))
            {
                //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";   //SQL 2012 and above
                //request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.SubCategory_TOT_Table_Name + " ) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";//SQL 2008
                request.SqlQuery = "SELECT * FROM " + MasterConstants.SubCategory_TOT_Table_Name;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
                request.SqlQuery = "SELECT * FROM ( SELECT * , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.SubCategory_TOT_Table_Name + " WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
                dt = smartDataObj.GetData(request);
            }

            //list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName") })
            //                 .Select(x => new MtSubCategoryTOTMaster
            //                 {
            //                     Id = Convert.ToInt32(x.Select(z => z.Field<string>("Id"))),
            //                     ChainName = x.Key.ChainName,
            //                     GroupName = x.Key.GroupName,
            //                     Branch = String.Join(",", x.Select(z => z.Field<string>("Branch")).Distinct().ToArray()),
            //                     Eye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Eye").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     Face = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     LakmeSkin  = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     Lip = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     Nail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     PondsTopEnd = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     NailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     OtherItems = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     LipNLove = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "LIP & LOVE").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
            //                     TNG = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%"
            //                 }).ToList();

            list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName"), Branch = x.Field<string>("Branch") })
                             .Select(x => new MtSubCategoryTOTMaster
                             {
                                 Id = Convert.ToInt32(x.Select(z => z.Field<string>("Id"))),
                                 ChainName = x.Key.ChainName,
                                 GroupName = x.Key.GroupName,
                                 Branch = x.Key.Branch,
                                 Eye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Eye").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 Face = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 LakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 Lip = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 Nail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 PondsTopEnd = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 NailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 OtherItems = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 LipNLove = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "LIP & LOVE").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
                                 TNG = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%"
                             }).ToList();

            //}
            return list;
        }


        public List<MtSubCategoryTOTMaster> LoadAllSubCategoryTOTData(string totCategory)
        {
            var list = new List<MtSubCategoryTOTMaster>();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            var columnNames = String.Join(",", MasterConstants.SubCategory_TOT_DB_Column);

            request.SqlQuery = "SELECT * FROM " + MasterConstants.SubCategory_TOT_Table_Name;
            dt = smartDataObj.GetData(request);

            string rateColumn = "";
            if (totCategory == "on")
            {
                rateColumn = "OnInvoiceRate";
            }
            else if (totCategory == "off")
            {
                rateColumn = "OffInvoiceMthlyRate";
            }
            else if (totCategory == "quarterly")
            {
                rateColumn = "OffInvoiceQtrlyRate";
            }

            //foreach (DataRow dr in dt.Rows)
                //list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName") })
                //                 .Select(x => new MtSubCategoryTOTMaster
                //                 {
                //                     Id=x.Select(z => z.Field<Int32>("Id")).FirstOrDefault(),
                //                     ChainName = x.Key.ChainName,
                //                     GroupName = x.Key.GroupName,
                //                     Branch = String.Join(",", x.Select(z => z.Field<string>("Branch")).Distinct().ToArray()),
                //                     Eye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Eye").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     Face = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     LakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     Lip = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     Nail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     PondsTopEnd = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     NailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     OtherItems = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     LipNLove = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "LIP & LOVE").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                //                     TNG = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%"
                //                 }).ToList();
            list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName"), Branch = x.Field<string>("Branch") })
                                 .Select(x => new MtSubCategoryTOTMaster
                                 {
                                     Id = x.Select(z => z.Field<Int32>("Id")).FirstOrDefault(),
                                     ChainName = x.Key.ChainName,
                                     GroupName = x.Key.GroupName,
                                     Branch = x.Key.Branch,
                                     Eye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Eye").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     Face = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     LakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     Lip = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     Nail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     PondsTopEnd = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     NailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     OtherItems = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     LipNLove = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "LIP & LOVE").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%",
                                     TNG = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault()) * 100).ToString("N2") + "%"
                                 }).ToList();

            return list;
        }

        public List<MtSubCategoryTOTMaster> LoadAllSubCategoryTOTDataForExcelDownload(string totCategory, out List<string> TOTSubCategorys)
        {
            var list = new List<MtSubCategoryTOTMaster>();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            var columnNames = String.Join(",", MasterConstants.SubCategory_TOT_DB_Column);

            request.SqlQuery = "SELECT " + columnNames + " FROM " + MasterConstants.SubCategory_TOT_Table_Name;
            dt = smartDataObj.GetData(request);

            string rateColumn = "";
            if (totCategory == "on")
            {
                rateColumn = "OnInvoiceRate";
            }
            else if (totCategory == "off")
            {
                rateColumn = "OffInvoiceMthlyRate";
            }
            else if (totCategory == "quarterly")
            {
                rateColumn = "OffInvoiceQtrlyRate";
            }

            foreach (DataRow dr in dt.Rows)
                list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName"), Branch = x.Field<string>("Branch") })
                                 .Select(x => new MtSubCategoryTOTMaster
                                 {
                                     ChainName = x.Key.ChainName,
                                     GroupName = x.Key.GroupName,
                                     Branch = x.Key.Branch,
                                     Eye = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Eye").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     Face = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     LakmeSkin = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     Lip = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     Nail = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     PondsTopEnd = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     NailPolishRemover = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     OtherItems = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     LipNLove = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "LIP & LOVE").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4"),
                                     TNG = (Math.Truncate(Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>(rateColumn)).FirstOrDefault())*1000)/1000).ToString("N4")
                                 }).ToList();

            TOTSubCategorys = dt.AsEnumerable().Select(r => r.Field<string>("TOTSubCategory")).Distinct().ToList();

            return list;
        }

        public DataTable GetSubCatTOTRateData(string totSubcategory)
        {
            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            string rateColumnName = "";
            if (totSubcategory == "on")
            {
                rateColumnName = "OnInvoiceRate";
            }
            else if (totSubcategory == "off")
            {
                rateColumnName = "OffInvoiceMthlyRate";
            }
            else if (totSubcategory == "quarterly")
            {
                rateColumnName = "OffInvoiceQtrlyRate";
            }

            request.Parameters = new List<Parameter>();
            Parameter paramRateColumn = new Parameter("rateColumn", rateColumnName);
            request.Parameters.Add(paramRateColumn);
            request.StoredProcedureName = "mtspGetSubCatTOTRateData";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);

            return dt;
        }
        public DataTable GetSubCatTOTRateDataForDowload(string totSubcategory)
        {
            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            string rateColumnName = "";
            if (totSubcategory == "on")
            {
                rateColumnName = "OnInvoiceRate";
            }
            else if (totSubcategory == "off")
            {
                rateColumnName = "OffInvoiceMthlyRate";
            }
            else if (totSubcategory == "quarterly")
            {
                rateColumnName = "OffInvoiceQtrlyRate";
            }

            request.Parameters = new List<Parameter>();
            Parameter paramRateColumn = new Parameter("rateColumn", rateColumnName);
            request.Parameters.Add(paramRateColumn);
            request.StoredProcedureName = "mtspGetSubCatTOTRateDataforDownload";
            dt = smartDataObj.GetdataExecuteStoredProcedure(request);

            return dt;
        }
    }
}
