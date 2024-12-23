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
    public class UploadGstMasterController : AppController
    {
        GstMasterService gstMasterService = new GstMasterService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();

        public ActionResult UploadGstFile()
        {

            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.GstMaster_PageId) == true)
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


                            var uploadResponse = gstMasterService.UploadGstFile(fullPath, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadMaster_StepId, UploadMasterConstants.GST_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("GST", loggedUser.UserId);
                            }


                            return Json(
                                  new
                                  {

                                      isSuccess = uploadResponse.IsSuccess,
                                      msg = uploadResponse.MessageText,
                                      consoleMsg = "UploadGstFile executed successfully."
                                  }, JsonRequestBehavior.AllowGet);
                        }

                    }
                    catch (Exception ex)
                    {
                        isSuccess = false;
                        message = MessageConstants.Error_Occured + ex.Message;
                        string exceptionDetails = $"Exception: {ex.Message}\nStack Trace: {ex.StackTrace}";
                        if (ex.InnerException != null)
                        {
                            exceptionDetails += $"\nInner Exception: {ex.InnerException.Message}\nInner Stack Trace: {ex.InnerException.StackTrace}";
                        }
                        System.Diagnostics.Debug.WriteLine(exceptionDetails);
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
                msg = message,
                consoleMsg = "UploadGstFile executed with errors."
            }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult AjaxGetGstData(int draw, int start, int length)
        {
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "BasepackCode";
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
            GstMasterDataTable dataTableData = gstMasterService.AjaxGetGstData(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        public void Download_GstMasterExcel()
        {

            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = MasterConstants.Gst_Excel_Column;
            string tableName = MasterConstants.Gst_Master_Table_Name;
            string[] columnsInDb = MasterConstants.Gst_Db_Column;

            download.Download_ToExcel(columnsInDb, columnsTodisplay, tableName);


        }

        public ActionResult DeleteGstMaster(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtGstMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }
    }
}