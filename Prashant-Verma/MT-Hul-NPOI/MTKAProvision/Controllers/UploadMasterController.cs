using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using MTKAProvision.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class UploadMasterController : AppController
    {
        private int TOTAL_ROWS = 0;
        //public string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        //SmartData smartDataObj = new SmartData();
        // GET: UploadMaster
        public ActionResult Index()
        {
            ViewBag.currentMOC = CurrentMOC;           
            return View("UploadMaster");
        }

        //[HttpPost]
        //public ActionResult UploadCustomerGroupFile()
        //{
        //    if (Request.Files.Count > 0)
        //    {
        //        try
        //        {
        //            bool success = false;
        //            foreach (string upload in Request.Files)
        //            {
        //                string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
        //                string filename = Path.GetFileName(Request.Files[upload].FileName);
        //                Request.Files[upload].SaveAs(Path.Combine(path, filename));

        //                ReadExcel read = new ReadExcel();
        //                MasterResponse excelResult = read.ValidateAndReadExcel(Path.Combine(path, filename), MasterConstants.Cutomer_Group_Excel_Column);
        //                if (excelResult.IsSuccess)
        //                {
        //                    ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
        //                    excelResult.Data = obj.MapCustomerGroupMaster(excelResult.Data, MasterConstants.Cutomer_Group_Excel_Column, MasterConstants.Cutomer_Group_DB_Column);
        //                    DataTable table = new DataTable();
        //                    table = excelResult.Data;
        //                    table.TableName = MasterConstants.Customer_Group_Master_Table_Name;
        //                    //dataService dataservices = new dataService();
        //                    //dataservices.Insert(table);
        //                    smartDataObj.Bulk_Update(table, MasterConstants.Customer_Group_Master_UpdateSP_Name, MasterConstants.Customer_Group_Master_UpdateSP_Param_Name);
        //                    success = true;
        //                    return Json(
        //                        new
        //                        {
        //                            isSuccess = success,
        //                            msg = "File Uploaded Successfully!"
        //                        }, JsonRequestBehavior.AllowGet);
        //                }
        //                else
        //                {
        //                    return Json(
        //                        new
        //                        {
        //                            isSuccess = success,
        //                            msg = "File does not contains valid data!"
        //                        }, JsonRequestBehavior.AllowGet);
        //                }
        //            }
        //            return Json(
        //                       new
        //                       {
        //                           isSuccess = success,
        //                           msg = "File not selected!"
        //                       }, JsonRequestBehavior.AllowGet);
        //        }
        //        catch (Exception ex)
        //        {
        //            return Json(
        //                      new
        //                      {
        //                          isSuccess = false,
        //                          msg = "Error occurred. Error details: " + ex.Message
        //                      }, JsonRequestBehavior.AllowGet);
        //        }
        //    }
        //    else
        //    {
        //        return Json(
        //                     new
        //                     {
        //                         isSuccess = false,
        //                         msg = "No files selected."
        //                     }, JsonRequestBehavior.AllowGet);
        //    }
        //}

        //[HttpPost]
        //public ActionResult AjaxGetCustomerGroupData(int draw, int start, int length)
        //{
        //    string search = Request["search[value]"];
        //    int sortColumn = -1;
        //    string sortColumnName = "CustomerCode";
        //    string sortDirection = "asc";

        //    // note: we only sort one column at a time
        //    if (Request["order[0][column]"] != null)
        //    {
        //        sortColumn = int.Parse(Request["order[0][column]"]);
        //        sortColumnName = Request["columns[" + sortColumn + "][data]"];
        //    }
        //    if (Request["order[0][dir]"] != null)
        //    {
        //        sortDirection = Request["order[0][dir]"];
        //    }
        //    CustomerGroupMasterDataTable dataTableData = new CustomerGroupMasterDataTable();
        //    dataTableData.draw = draw;
        //    TOTAL_ROWS = GetTotalRowsCount(search, MasterConstants.Customer_Group_Master_Table_Name);
        //    if (length == -1)
        //    {
        //        length = TOTAL_ROWS;
        //    }
        //    dataTableData.recordsTotal = TOTAL_ROWS;
        //    int recordsFiltered = 0;
        //    dataTableData.data = FilterCustomerGroupData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
        //    dataTableData.recordsFiltered = TOTAL_ROWS;

        //    return Json(dataTableData, JsonRequestBehavior.AllowGet);
        //}

        //private List<MtCustomerGroupMaster> FilterCustomerGroupData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        //{
        //    var pageNo = (start / length) + 1;
        //    List<MtCustomerGroupMaster> list = new List<MtCustomerGroupMaster>();
        //    string orderByTxt = "";
        //    var columnNames = String.Join(",", MasterConstants.Cutomer_Group_DB_Column);

        //    if (sortDirection == "asc")
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }
        //    else
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }

        //    SqlConnection connection = new SqlConnection(connectionString);
        //    DataTable dt = new DataTable();
        //    DbRequest request = new DbRequest();

        //    int recordupto = start + length;
        //    if (string.IsNullOrEmpty(search))
        //    {
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        //dt = Ado.GetDataTable("SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;", connection);
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        //dt=smartDataObj.GetData(request);
 
        //        request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (ORDER BY id)  AS RowNumber,  * from mtCustomerGroupMaster ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
        //        dt = smartDataObj.GetData(request);
        //    }
        //    else
        //    {
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM mtCustomerGroupMaster WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
        //        dt = smartDataObj.GetData(request);
        //    }


        //    foreach (DataRow dr in dt.Rows)
        //    {
        //        MtCustomerGroupMaster obj = new MtCustomerGroupMaster();

        //        obj.CustomerCode = dr["CustomerCode"].ToString();
        //        obj.StateCode = dr["StateCode"].ToString();

        //        list.Add(obj);

        //    }
        //    return list;
        //}

        //[HttpPost]
        //public ActionResult UploadBrandwiseSubCategoryFile()
        //{
        //    if (Request.Files.Count > 0)
        //    {
        //        try
        //        {
        //            bool success = false;
        //            foreach (string upload in Request.Files)
        //            {
        //                string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
        //                string filename = Path.GetFileName(Request.Files[upload].FileName);
        //                Request.Files[upload].SaveAs(Path.Combine(path, filename));

        //                ReadExcel read = new ReadExcel();
        //                MasterResponse excelResult = read.ValidateAndReadExcel(Path.Combine(path, filename), MasterConstants.BrandWise_SubCategory_Excel_Column);
        //                if (excelResult.IsSuccess)
        //                {
        //                    ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
        //                    excelResult.Data = obj.MapBrandwiseSubcategoryMappingMaster(excelResult.Data, MasterConstants.BrandWise_SubCategory_Excel_Column, MasterConstants.BrandWise_SubCategory_DB_Column);
        //                    DataTable table = new DataTable();
        //                    table = excelResult.Data;
        //                    table.TableName = MasterConstants.BrandWise_SubCategory_Master_Table_Name;
        //                    smartDataObj.Bulk_Update(table, MasterConstants.BrandWise_SubCategory_Master_UpdateSP_Name, MasterConstants.BrandWise_SubCategory_Master_UpdateSP_Param_Name);
        //                    success = true;
        //                    return Json(
        //                        new
        //                        {
        //                            isSuccess = success,
        //                            msg = "File Uploaded Successfully!"
        //                        }, JsonRequestBehavior.AllowGet);
        //                }
        //                else
        //                {
        //                    return Json(
        //                        new
        //                        {
        //                            isSuccess = success,
        //                            msg = "File does not contains valid data!"
        //                        }, JsonRequestBehavior.AllowGet);
        //                }
        //            }
        //            return Json(
        //                       new
        //                       {
        //                           isSuccess = success,
        //                           msg = "File not selected!"
        //                       }, JsonRequestBehavior.AllowGet);
        //        }
        //        catch (Exception ex)
        //        {
        //            return Json(
        //                      new
        //                      {
        //                          isSuccess = false,
        //                          msg = "Error occurred. Error details: " + ex.Message
        //                      }, JsonRequestBehavior.AllowGet);
        //        }
        //    }
        //    else
        //    {
        //        return Json(
        //                     new
        //                     {
        //                         isSuccess = false,
        //                         msg = "No files selected."
        //                     }, JsonRequestBehavior.AllowGet);
        //    }
        //}

        //[HttpPost]
        //public ActionResult AjaxGetBrandWiseSubCategoryData(int draw, int start, int length)
        //{
        //    string search = Request["search[value]"];
        //    int sortColumn = -1;
        //    string sortColumnName = "PMHBrandCode";
        //    string sortDirection = "asc";

        //    // note: we only sort one column at a time
        //    if (Request["order[0][column]"] != null)
        //    {
        //        sortColumn = int.Parse(Request["order[0][column]"]);
        //        sortColumnName = Request["columns[" + sortColumn + "][data]"];
        //    }
        //    if (Request["order[0][dir]"] != null)
        //    {
        //        sortDirection = Request["order[0][dir]"];
        //    }
        //    BrandwiseSubCategoryMasterDataTable dataTableData = new BrandwiseSubCategoryMasterDataTable();
        //    dataTableData.draw = draw;
        //    TOTAL_ROWS = GetTotalRowsCount(search, MasterConstants.BrandWise_SubCategory_Master_Table_Name);
        //    if (length == -1)
        //    {
        //        length = TOTAL_ROWS;
        //    }
        //    dataTableData.recordsTotal = TOTAL_ROWS;
        //    int recordsFiltered = 0;
        //    dataTableData.data = FilterBrandwiseSubCategoryData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
        //    dataTableData.recordsFiltered = TOTAL_ROWS;

        //    return Json(dataTableData, JsonRequestBehavior.AllowGet);
        //}

        //private List<MtBrandwiseSubCategoryMaster> FilterBrandwiseSubCategoryData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        //{
        //    var pageNo = (start / length) + 1;
        //    List<MtBrandwiseSubCategoryMaster> list = new List<MtBrandwiseSubCategoryMaster>();
        //    string orderByTxt = "";
        //    var columnNames = String.Join(",", MasterConstants.BrandWise_SubCategory_DB_Column);

        //    if (sortDirection == "asc")
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }
        //    else
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }

        //    SqlConnection connection = new SqlConnection(connectionString);
        //    DataTable dt = new DataTable();
        //    DbRequest request = new DbRequest();
        //    if (string.IsNullOrEmpty(search))
        //    {
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.BrandWise_SubCategory_Master_Table_Name + " ) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";

        //        dt = smartDataObj.GetData(request);
        //    }
        //    else
        //    {
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.BrandWise_SubCategory_Master_Table_Name + " WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
        //        dt = smartDataObj.GetData(request);
        //    }


        //    foreach (DataRow dr in dt.Rows)
        //    {
        //        MtBrandwiseSubCategoryMaster obj = new MtBrandwiseSubCategoryMaster();

        //        obj.PMHBrandCode = dr["PMHBrandCode"].ToString();
        //        obj.PMHBrandName = dr["PMHBrandName"].ToString();
        //        obj.SalesSubCat = dr["SalesSubCat"].ToString();
        //        obj.PriceList = dr["PriceList"].ToString();
        //        obj.TOTSubCategory = dr["TOTSubCategory"].ToString();

        //        list.Add(obj);

        //    }
        //    return list;
        //}

        //[HttpPost]
        //public ActionResult UploadSubCategoryTOTFile()
        //{
        //    if (Request.Files.Count > 0)
        //    {
        //        try
        //        {
        //            bool success = false;
        //            foreach (string upload in Request.Files)
        //            {
        //                string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
        //                string filename = Path.GetFileName(Request.Files[upload].FileName);
        //                Request.Files[upload].SaveAs(Path.Combine(path, filename));

        //                ReadExcel read = new ReadExcel();
        //                MasterResponse excelResult = read.ValidateAndReadSubCategoryTOTExcel(Path.Combine(path, filename), MasterConstants.SubCategory_TOT_Excel_Column);
        //                if (excelResult.IsSuccess)
        //                {
        //                    ExcelToDbColumnMapping obj = new ExcelToDbColumnMapping();
        //                    excelResult.Data = obj.MapSubcategoryTOTMaster(excelResult.Data, MasterConstants.SubCategory_TOT_Excel_Column, MasterConstants.SubCategory_TOT_DB_Column);
        //                    DataTable table = new DataTable();
        //                    table = excelResult.Data;
        //                    table.TableName = MasterConstants.SubCategory_TOT_Table_Name;
        //                    smartDataObj.Bulk_Update(table, MasterConstants.SubCategory_TOT_Master_UpdateSP_Name, MasterConstants.SubCategory_TOT_Master_UpdateSP_Param_Name);
        //                    success = true;
        //                    return Json(
        //                        new
        //                        {
        //                            isSuccess = success,
        //                            msg = "File Uploaded Successfully!"
        //                        }, JsonRequestBehavior.AllowGet);
        //                }
        //                else
        //                {
        //                    return Json(
        //                        new
        //                        {
        //                            isSuccess = success,
        //                            msg = "File does not contains valid data!"
        //                        }, JsonRequestBehavior.AllowGet);
        //                }
        //            }
        //            return Json(
        //                       new
        //                       {
        //                           isSuccess = success,
        //                           msg = "File not selected!"
        //                       }, JsonRequestBehavior.AllowGet);
        //        }
        //        catch (Exception ex)
        //        {
        //            return Json(
        //                      new
        //                      {
        //                          isSuccess = false,
        //                          msg = "Error occurred. Error details: " + ex.Message
        //                      }, JsonRequestBehavior.AllowGet);
        //        }
        //    }
        //    else
        //    {
        //        return Json(
        //                     new
        //                     {
        //                         isSuccess = false,
        //                         msg = "No files selected."
        //                     }, JsonRequestBehavior.AllowGet);
        //    }
        //}

        //[HttpPost]
        //public ActionResult AjaxGetSubCategoryTOTData(int draw, int start, int length)
        //{
        //    string search = Request["search[value]"];
        //    int sortColumn = -1;
        //    string sortColumnName = "ChainName";
        //    string sortDirection = "asc";

        //    // note: we only sort one column at a time
        //    if (Request["order[0][column]"] != null)
        //    {
        //        sortColumn = int.Parse(Request["order[0][column]"]);
        //        sortColumnName = Request["columns[" + sortColumn + "][data]"];
        //    }
        //    if (Request["order[0][dir]"] != null)
        //    {
        //        sortDirection = Request["order[0][dir]"];
        //    }
        //    SubCategoryTOTMasterDataTable dataTableData = new SubCategoryTOTMasterDataTable();
        //    dataTableData.draw = draw;
        //    TOTAL_ROWS = GetTotalRowsCount(search, MasterConstants.SubCategory_TOT_Table_Name);
        //    if (length == -1)
        //    {
        //        length = TOTAL_ROWS;
        //    }
            
        //    int recordsFiltered = 0;
        //    dataTableData.data = FilterSubCategoryTOTData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
        //    TOTAL_ROWS = dataTableData.data.Count;
        //    dataTableData.recordsFiltered = TOTAL_ROWS;
        //    dataTableData.recordsTotal = TOTAL_ROWS;

        //    return Json(dataTableData, JsonRequestBehavior.AllowGet);
        //}

        //public ActionResult LoadSubCategoryTOTData()
        //{
        //    var list = new List<MtSubCategoryTOTMaster>();
        //    DataTable dt = new DataTable();
        //    DbRequest request = new DbRequest();
        //    var columnNames = String.Join(",", MasterConstants.SubCategory_TOT_DB_Column);

        //    request.SqlQuery = "SELECT " + columnNames + " FROM " + MasterConstants.SubCategory_TOT_Table_Name;
        //    dt = smartDataObj.GetData(request);

        //    foreach (DataRow dr in dt.Rows)
        //        list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName") })
        //                         .Select(x => new MtSubCategoryTOTMaster
        //                         {
        //                             ChainName = x.Key.ChainName,
        //                             GroupName = x.Key.GroupName,
        //                             Branch = String.Join(",", x.Select(z => z.Field<string>("Branch")).Distinct().ToArray()),
        //                             FaceNEye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face & Eye").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             LakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             LipNNail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip & Nail").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             PondsTopEnd = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             NailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             LipNLove = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip & Love").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             TNG = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             OtherItems = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             HaikoFaceNEye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 14% Face & Eye").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             HaikoLakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 14% Lakme skin").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             HaikoLipNNail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 18% Lip & Nail").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                             HaikoNailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 20% Nail Polish Remover").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%"
        //                         }).ToList();

        //    return Json(new { data = list }, JsonRequestBehavior.AllowGet);
        //}

        //private List<MtSubCategoryTOTMaster> FilterSubCategoryTOTData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection)
        //{
        //    var pageNo = (start / length) + 1;
        //    List<MtSubCategoryTOTMaster> list = new List<MtSubCategoryTOTMaster>();
        //    string orderByTxt = "";
        //    var columnNames = String.Join(",", MasterConstants.SubCategory_TOT_DB_Column);

        //    if (sortDirection == "asc")
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }
        //    else
        //    {
        //        orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
        //    }

        //    SqlConnection connection = new SqlConnection(connectionString);
        //    DataTable dt = new DataTable();
        //    DbRequest request = new DbRequest();
        //    if (string.IsNullOrEmpty(search))
        //    {
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";   //SQL 2012 and above
        //        //request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.SubCategory_TOT_Table_Name + " ) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";//SQL 2008
        //        request.SqlQuery = "SELECT " + columnNames + " FROM " + MasterConstants.SubCategory_TOT_Table_Name;
        //        dt = smartDataObj.GetData(request);
        //    }
        //    else
        //    {
        //        //request.SqlQuery = "SELECT * FROM mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "') " + orderByTxt + " OFFSET " + start + " ROWS FETCH NEXT " + length + " ROWS ONLY;";
        //        request.SqlQuery = "SELECT " + columnNames + " FROM ( SELECT " + columnNames + " , ROW_NUMBER() OVER (" + orderByTxt + ") AS RowNum FROM " + MasterConstants.SubCategory_TOT_Table_Name + " WHERE FREETEXT(*, '" + search + "')) AS SOD WHERE SOD.RowNum BETWEEN " + (start + 1) + " AND " + (start + length) + "";
        //        dt = smartDataObj.GetData(request);
        //    }


        //    //foreach (DataRow dr in dt.Rows)
        //    //{
        //    //mtSubCategoryTOTMaster obj = new mtSubCategoryTOTMaster();

        //    //obj.ChainName = dr["ChainName"].ToString();
        //    //obj.GroupName = dr["GroupName"].ToString();

        //    //list.Add(obj);

        //    list = dt.AsEnumerable().GroupBy(x => new { ChainName = x.Field<string>("ChainName"), GroupName = x.Field<string>("GroupName") })
        //                     .Select(x => new MtSubCategoryTOTMaster
        //                     {
        //                         ChainName = x.Key.ChainName,
        //                         GroupName = x.Key.GroupName,
        //                         Branch = String.Join(",", x.Select(z => z.Field<string>("Branch")).Distinct().ToArray()),
        //                         FaceNEye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Face & Eye").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2")+"%",
        //                         LakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lakme Skin").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         LipNNail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip & Nail").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         PondsTopEnd = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Ponds Top End ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         NailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Nail Polish Remover ").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         LipNLove = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Lip & Love").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         TNG = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "T&G").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         OtherItems = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Other Items").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         HaikoFaceNEye = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 14% Face & Eye").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         HaikoLakmeSkin = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 14% Lakme skin").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         HaikoLipNNail = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 18% Lip & Nail").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%",
        //                         HaikoNailPolishRemover = (Convert.ToDecimal(x.Where(z => z.Field<string>("TOTSubCategory") == "Haiko 20% Nail Polish Remover").Select(z => z.Field<decimal>("OnInvoiceRate")).FirstOrDefault()) * 100).ToString("N2") + "%"
        //                     }).ToList();

        //    //}
        //    return list;
        //}

        //private int GetTotalRowsCount(string search, string tableName)
        //{
        //    SqlConnection connection = new SqlConnection(connectionString);
        //    DataTable dt = new DataTable();
        //    DbRequest request = new DbRequest();
        //    if (string.IsNullOrEmpty(search))
        //    {
        //        //dt = Ado.GetDataTable("Select Count(*) from mtCustomerGroupMaster", connection);
        //        request.SqlQuery = "Select Count(*) from " + tableName + "";
        //        dt = smartDataObj.GetData(request);

        //    }
        //    else
        //    {
        //        //dt = Ado.GetDataTable("Select Count(*) from mtCustomerGroupMaster WHERE FREETEXT (*, '" + search + "')", connection);
        //        request.SqlQuery = "Select Count(*) from " + tableName + " WHERE FREETEXT (*, '" + search + "')";
        //        dt = smartDataObj.GetData(request);
        //    }
        //    int recordsCount = 0;

        //    foreach (DataRow dr in dt.Rows)
        //    {
        //        recordsCount = Convert.ToInt32(dr[0]);
        //    }

        //    return recordsCount;
        //}

        public ActionResult GetView(string tab)
        {
            string partialView = "";
            switch (tab)
            {
                case "tab1":
                    partialView = "_IntroductionTab";
                    break;
                case "CustomerGroupMaster":
                    partialView = "_CustomerGroupTab";
                    break;
                case "SkuMaster":
                    partialView = "_SKUDumpTab";
                    break;
                case "SalesTaxMaster":
                    partialView = "_SalesTaxRateTab";
                    break;
                case "GstMaster":
                    partialView = "_GSTTab";
                    break;
                default:
                    partialView = "_IntroductionTab";
                    break;
            }

            return PartialView(partialView);
        }


    }

    public static class test
    {
        public static DataTable PropertiesToDataTable<T>(this IEnumerable<T> source)
        {
            DataTable dt = new DataTable();
            var props = TypeDescriptor.GetProperties(typeof(T));
            foreach (PropertyDescriptor prop in props)
            {
                DataColumn dc = dt.Columns.Add(prop.Name, prop.PropertyType);
                dc.Caption = prop.DisplayName;
                dc.ReadOnly = prop.IsReadOnly;
            }
            foreach (T item in source)
            {
                DataRow dr = dt.NewRow();
                foreach (PropertyDescriptor prop in props)
                {
                    dr[prop.Name] = prop.GetValue(item);
                }
                dt.Rows.Add(dr);
            }
            return dt;
        }
    }
}