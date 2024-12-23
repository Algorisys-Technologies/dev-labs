using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using MTKAProvision.Models;
using System;
using System.Collections;
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
    public class UploadSkuMasterController : AppController
    {
        SkuMasterService skuMasterService = new SkuMasterService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();
        public ActionResult UploadSkuFile()
        {

            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.SkuMaster_PageId) == true)
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


                            var uploadResponse = skuMasterService.UploadSkuFile(fullPath, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadMaster_StepId, UploadMasterConstants.SKU_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("SKU", loggedUser.UserId);
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
        public ActionResult AjaxGetSkuData(int draw, int start, int length)
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
            SkuMasterDataTable dataTableData = skuMasterService.AjaxGetSkuData(draw, start, length, search, sortColumnName, sortDirection);

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }

        public ActionResult AjaxGetSkuAllData()
        {


            List<MtSkuMaster> list = new List<MtSkuMaster>();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            var columnNames = String.Join(",", MasterConstants.Sku_Db_Column);
            SmartData smartDataObj = new SmartData();
            request.SqlQuery = "SELECT * FROM " + MasterConstants.Sku_Master_Table_Name;
            dt = smartDataObj.GetData(request);
            MtSkuMaster data = new MtSkuMaster();
            foreach (DataRow dr in dt.Rows)
            {
                data.Id = Convert.ToInt32(dr["Id"]);
                data.BasepackCode = dr["BasepackCode"].ToString();
                data.TaxCode = dr["TaxCode"].ToString();
                list.Add(data);
            }
            // var result = new { skumaster = list };
            var jsonResult = Json(new { data = list }, JsonRequestBehavior.AllowGet);
            jsonResult.MaxJsonLength = int.MaxValue;
            return jsonResult;

            // return Json(new { data = jsonResult }, JsonRequestBehavior.AllowGet);

        }

        public void Download_SkuMasterExcel()
        {

            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsTodisplay = MasterConstants.Sku_Excel_Column;
            string tableName = MasterConstants.Sku_Master_Table_Name;
            string[] columnsInDb = MasterConstants.Sku_Db_Column;

            download.Download_ToExcel(columnsInDb, columnsTodisplay, tableName);


        }
        //[AcceptVerbs(HttpVerbs.Post)]
        public ActionResult DeleteSkuMaster(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtSkuMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }


    }

}
