﻿using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using MTKAProvision.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.OleDb;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class SalesTaxRateMasterController : AppController
    {
        private int TOTAL_ROWS = 0;
        // public string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        //  SmartData smartDataObj = new SmartData();
        CommonService commonService = new CommonService();
        SalesTaxRateService salesTaxRateService = new SalesTaxRateService();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        CommonMasterService commonMasterService = new CommonMasterService();
        MasterService masterService = new MasterService();
        [HttpPost]
        public ActionResult UploadSalesTaxFile()
        {
            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.SalesTaxRateMaster_PageId) == true)
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

                            var uploadResponse = salesTaxRateService.UploadSalesTaxRateFile(fullPath, loggedUser.UserId);
                            if (uploadResponse.IsSuccess)
                            {
                                dashboardService.Update_MultiStepStatus(DashBoardConstants.UploadMaster_StepId, UploadMasterConstants.SALESTAXRATE_DetailedStep, CurrentMOC);
                                masterService.SendMailOnMasterUpdate("SALESTAXRATE", loggedUser.UserId);
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

        public ActionResult AjaxGetSalesTaxData(int draw, int start, int length)
        {
            string search = Request["search[value]"];
            int sortColumn = -1;
            string sortColumnName = "TaxCode";
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
            SalesTaxMasterDataTable dataTableData = new SalesTaxMasterDataTable();
            dataTableData.draw = draw;
            TOTAL_ROWS = commonService.GetTotalRowsCount("mtSalesTaxMaster", search);
            if (length == -1)
            {
                length = TOTAL_ROWS;
            }
            dataTableData.recordsTotal = TOTAL_ROWS;
            int recordsFiltered = 0;
            dataTableData.data = salesTaxRateService.FilterData(ref recordsFiltered, start, length, search, sortColumnName, sortDirection);
            dataTableData.recordsFiltered = TOTAL_ROWS;

            return Json(dataTableData, JsonRequestBehavior.AllowGet);
        }
        public void Download_SalesTaxRateMasterExcel()
        {
            DownloadExcelFile download = new DownloadExcelFile();

            string[] columnsInExcel = MasterConstants.Sales_Tax_DB_Column;
            string tableName = MasterConstants.Sales_Tax_Master_Table_Name;
            salesTaxRateService.Download_SalesTaxExcel(columnsInExcel, tableName);
        }
        //[AcceptVerbs(HttpVerbs.Post)]
        public ActionResult DeleteSalesTaxRateMaster(string[] id)
        {
            BaseResponse response = commonMasterService.DeleteMasters(id, "Delete_mtSalesTaxRateMaster", loggedUser);
            return Json(new { data = response }, JsonRequestBehavior.AllowGet);
        }
    }
}