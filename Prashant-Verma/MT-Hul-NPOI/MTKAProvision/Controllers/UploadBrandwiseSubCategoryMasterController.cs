using MT.Business;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class UploadBrandwiseSubCategoryMasterController : AppController
    {
        SubcategoryMappingService subcategoryMappingService = new SubcategoryMappingService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();

        public ActionResult UploadBrandwiseSubCategoryFile()
        {
            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.SubCatMappingMaster_PageId) == true)
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

                            var uploadResponse = subcategoryMappingService.UploadBrandwiseSubCategoryFile(fullPath, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadProvisionMaster_StepId, UploadProvisionalMasterConstants.SUBCATMAPPING_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("SUBCATMAPPING", loggedUser.UserId);
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
        public ActionResult AjaxGetBrandWiseSubCategoryData(int draw, int start, int length)
        {
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "PMHBrandCode";
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
            BrandwiseSubCategoryMasterDataTable dataTableData = subcategoryMappingService.AjaxGetBrandWiseSubCategoryData(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }


        public void Download_BrandwiseSubCategoryMasterExcel()
        {

            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = MasterConstants.BrandWise_SubCategory_Excel_Column;
            string tableName = MasterConstants.BrandWise_SubCategory_Master_Table_Name;
            string[] columnsInDb = MasterConstants.BrandWise_SubCategory_DB_Column;

            download.Download_ToExcel(columnsInDb, columnsTodisplay, tableName);

        }
        public ActionResult DeleteBrandwiseSubCategory(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtBrandwiseSubCategoryMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }

    }
}


