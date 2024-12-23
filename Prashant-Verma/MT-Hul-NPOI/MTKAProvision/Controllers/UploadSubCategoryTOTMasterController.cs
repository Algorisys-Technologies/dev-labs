using MT.Business;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class UploadSubCategoryTOTMasterController : AppController
    {
        SubcategoryTOTRateService subcategoryTOTService = new SubcategoryTOTRateService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();

        public ActionResult UploadSubCategoryTOTFile()
        {
            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.SubCatTOTMaster_PageId) == true)
            {
                if (Request.Files.Count > 0)
                {
                    try
                    {
                        foreach (string upload in Request.Files)
                        {
                            //string path = AppDomain.CurrentDomain.BaseDirectory + "App_Data/";
                            string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
                            string filename = Path.GetFileName(Request.Files[upload].FileName);
                            Request.Files[upload].SaveAs(Path.Combine(path, filename));

                            string fullPath = Path.Combine(path, filename);

                            string totCategory = Request.Form["TOTCategory"];

                            var uploadResponse = subcategoryTOTService.UploadSubCategoryTOTFile(fullPath, totCategory, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadProvisionMaster_StepId, UploadProvisionalMasterConstants.SUBCATBASEDTOT_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("SUBCATBASEDTOT", loggedUser.UserId);
                            }
                            return Json(
                                  new
                                  {
                                      isSuccess = uploadResponse.IsSuccess,
                                      msg = uploadResponse.MessageText
                                  }, JsonRequestBehavior.AllowGet);
                        }

                    }
                    catch (Exception ex)
                    {
                        isSuccess = false;
                        message = MessageConstants.Error_Occured + ex.Message;
                    }
                }
                else
                {
                    isSuccess = false;
                    message = MessageConstants.No_Files_Selected;

                }
            }
            else
            {
                isSuccess = false;
                message = MessageConstants.InsufficientPermission;
            }
            return Json(new
            {
                isSuccess = isSuccess,
                msg = message
            }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult AjaxGetSubCategoryTOTData(int draw, int start, int length)
        {
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "ChainName";
            string sortDirection = "asc";

            // note: we only sort one column at a time
            if (Request["order[0][column]"] != null)
            {
                sortColumn = int.Parse(Request["order[0][column]"]);
                sortColumnName = Request["columns[" + sortColumn + "][data]"];
            }
            if (Request["order[0][dir]"] != null)
            {
                sortDirection = Request["order[0][dir]"];
            }
            SubCategoryTOTMasterDataTable dataTableData = subcategoryTOTService.AjaxGetSubCategoryTOTData(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        public ActionResult LoadSubCategoryTOTData(string totCategory)
        {
            var list = subcategoryTOTService.LoadAllSubCategoryTOTData(totCategory);

            return Json(new { data = list }, JsonRequestBehavior.AllowGet);
        }

        public void Download_SubCategoryTOTMasterExcel(string totCategory, string sheetName)
        {
            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = MasterConstants.SubCategory_TOT_Excel_Column;
            string tableName = MasterConstants.SubCategory_TOT_Table_Name;
            string[] columnsInDb = MasterConstants.SubCategory_TOT_DB_Column;

            List<string> TOTSubCategorys = new List<string>();

            // var list = subcategoryTOTService.LoadAllSubCategoryTOTDataForExcelDownload(totCategory, out TOTSubCategorys);
            DataSet ds = new DataSet();
            DataTable dt = new DataTable();
            dt = subcategoryTOTService.GetSubCatTOTRateDataForDowload("on");
            dt.TableName = "DIRECT-ECOMM-HAIKO-TOT (On)";

            DataTable dt2 = new DataTable();
            dt2 = subcategoryTOTService.GetSubCatTOTRateDataForDowload("quarterly");
            dt2.TableName = "DIRECT-ECOMM-HAIKO-TOT (OffQtr)";

            DataTable dt3 = new DataTable();
            dt3 = subcategoryTOTService.GetSubCatTOTRateDataForDowload("off");
            dt3.TableName = "DIRECT-ECOMM-HAIKO-TOT (Off)";

            DataTable dtCopy = dt.Copy();
            DataTable dtCopy2 = dt2.Copy();
            DataTable dtCopy3 = dt3.Copy();
            ds.Tables.Add(dtCopy);
            ds.Tables.Add(dtCopy2);
            ds.Tables.Add(dtCopy3);
            //dt = list.PropertiesToDataTable<MtSubCategoryTOTMaster>();

            //dt.Columns.Remove("Id");
            //dt.TableName = sheetName;

            //dt.Columns["ChainName"].Caption = "Chain Name";
            //dt.Columns["GroupName"].Caption = "Group name (as per the base file)";
            //dt.Columns["Branch"].Caption = "BRANCH1";

            //dt.Columns["ChainName"].ColumnName = "Chain Name";
            //dt.Columns["GroupName"].ColumnName = "Group name (as per the base file)";
            //dt.Columns["Branch"].ColumnName = "BRANCH1";

            //DataTable dtCloned = dt.Clone();

            //for (var i = 3; i < dtCloned.Columns.Count; i++)
            //{
            //    dtCloned.Columns[i].DataType = typeof(Double);

            //}



            //foreach (DataRow row in dt.Rows)
            //{
            //    dtCloned.ImportRow(row);
            //}

            //for (var i = 3; i < dtCloned.Columns.Count; i++)
            //{
            //    dtCloned.Columns[i].Caption = TOTSubCategorys[i - 3];
            //    dtCloned.Columns[i].ColumnName = TOTSubCategorys[i - 3];
            //}
            //dtCloned.Columns["BRANCH1"].Caption = "BRANCH";
            //dtCloned.Columns["BRANCH1"].ColumnName = "BRANCH";

            //download.ExportDataTableToExcel(dt, tableName);
            download.ExportDatasetToExcel(ds, tableName);


        }
        public ActionResult DeleteSubCategoryTOT(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtSubCategoryTOTMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
	}
       
    }
}