using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using MTKAProvision.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class UploadHuggiesBasepackController : AppController
    {
        HuggiesBasepackMasterService huggiesBasepackMasterService = new HuggiesBasepackMasterService();

        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();

        public ActionResult UploadHuggiesBasepackFile()
        {
            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.HuggiesBasePackMaster_PageId) == true)
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

                            var uploadResponse = huggiesBasepackMasterService.UploadHuggiesBasepackFile(fullPath,loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadProvisionMaster_StepId, UploadProvisionalMasterConstants.HUGGIESBAEPACK_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("HUGGIESBAEPACK", loggedUser.UserId);
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
        public ActionResult AjaxGetHuggiesBasepackData(int draw, int start, int length)
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
            HuggiesBasepackMasterDataTable dataTableData = huggiesBasepackMasterService.AjaxGetHuggiesBasepackData(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }


        public void Download_HuggiesBasepackMasterExcel()
        {


            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = MasterConstants.HuggiesBasepack_Excel_Column;
            string tableName = MasterConstants.HuggiesBasepack_Master_Table_Name;
            string[] columnsInDb = MasterConstants.HuggiesBasepack_Db_Column;

            download.Download_ToExcel(columnsInDb, columnsTodisplay, tableName);

        }

        public ActionResult DeleteHuggiesBasepack(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtHuggiesBasepackMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }
	}
}