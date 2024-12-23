using ClosedXML.Excel;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using MTKAProvision.Models;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClosedXML;
using MT.Business;

namespace MTKAProvision.Controllers
{
    public class ServiceTaxRateMasterController : AppController
    {
        private int TOTAL_ROWS = 0;
        //SmartData smartDataObj = new SmartData();
        //// GET: UploadMaster
        ServiceTaxMasterService serviceTaxMasterService = new ServiceTaxMasterService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();

        [HttpPost]
        public ActionResult UploadServiceTaxFile()
        {
            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.ServiceTaxMaster_PageId) == true)
            {
                if (Request.Files.Count > 0)
                {
                    try
                    {
                        foreach (string upload in Request.Files)
                        {
                            string path = AppDomain.CurrentDomain.BaseDirectory + "FilesUploaded/";
                            string filename = Path.GetFileName(Request.Files[upload].FileName);
                            Request.Files[upload].SaveAs(Path.Combine(path, filename));

                            string fullPath = Path.Combine(path, filename);

                            var uploadResponse = serviceTaxMasterService.UploadServiceTaxFile(fullPath, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadProvisionMaster_StepId, UploadProvisionalMasterConstants.SERVICETAX_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("SERVICETAX", loggedUser.UserId);
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
        public ActionResult AjaxGetServiceTaxData(int draw, int start, int length)
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
            ServiceTaxRateMasterDataTable dataTableData = new ServiceTaxRateMasterDataTable();
            dataTableData.draw = draw;
            TOTAL_ROWS = serviceTaxMasterService.GetTotalRowsCountWithFreeTextSearch(search, MasterConstants.ServiceTax_Master_Table_Name);
            if (length == -1)
            {
                length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;
            dataTableData.data = serviceTaxMasterService.FilterData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }
        public void Download_ServiceTaxRateExcel()
        {
            DownloadExcelFile download = new DownloadExcelFile();
            string[] columnsInExcel = MasterConstants.ServiceTax_Excel_Column;
            string[] columnsInDB = MasterConstants.ServiceTax_DB_Column;
            string tableName = MasterConstants.ServiceTax_Master_Table_Name;
            //download.Download_ExcelMethod(columnsInExcel, tableName);
            download.Download_ToExcel(columnsInDB, columnsInExcel, tableName);
        }
        public ActionResult DeleteServiceTaxRate(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtServiceTaxRateMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }
    }



}