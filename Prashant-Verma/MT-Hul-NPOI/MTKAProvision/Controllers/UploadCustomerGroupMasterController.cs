
using MT.Business;
using MT.DataAccessLayer;
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
    public class UploadCustomerGroupMasterController : AppController
    {
        CustomerGroupService customerGroupService = new CustomerGroupService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();

        public ActionResult UploadCustomerGroupFile()
        {
            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.CustomerGrpMaster_PageId) == true)
            {
                if (Request.Files.Count > 0)
                {
                    try
                    {
                        //throw new Exception("Testing error log");
                        foreach (string upload in Request.Files)
                        {
                            //string path = AppDomain.CurrentDomain.BaseDirectory + "App_Data/";
                            string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
                            string filename = Path.GetFileName(Request.Files[upload].FileName);
                            Request.Files[upload].SaveAs(Path.Combine(path, filename));

                            string fullPath = Path.Combine(path, filename);

                            var uploadResponse = customerGroupService.UploadCustomerGroupFile(fullPath, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadMaster_StepId, UploadMasterConstants.CUSTGRP_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("CUSTGRP", loggedUser.UserId);
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
                        //logger.LogError(ex);
                        throw ex;
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
        public ActionResult AjaxGetCustomerGroupData(int draw, int start, int length)
        {
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "CustomerCode";
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
            CustomerGroupMasterDataTable dataTableData = customerGroupService.AjaxGetCustomerGroupData(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }


        public void Download_CustomerGroupMasterExcel()
        {
            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = MasterConstants.Cutomer_Group_Excel_Column;
            string tableName = MasterConstants.Customer_Group_Master_Table_Name;
            string[] columnsInDb = MasterConstants.Cutomer_Group_DB_Column;

            download.Download_ToExcel(columnsInDb, columnsTodisplay, tableName);


        }

        //[AcceptVerbs(HttpVerbs.Post)]
        public ActionResult DeleteCustomerGroup(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtCustomerGroupMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }

    }

}
