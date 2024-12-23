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
    public class UploadProvisionMasterController : AppController
    {
        private int TOTAL_ROWS = 0;
        SubcategoryTOTRateService subcategoryTOTService = new SubcategoryTOTRateService();
        //public string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        //SmartData smartDataObj = new SmartData();
        
        public ActionResult Introduction()
        {
            return PartialView();
        }
        public ActionResult UploadIndex()
        {
            ViewBag.currentMOC = CurrentMOC;
            ViewBag.PageTitle = "Upload Provision Master";
            return View();
        }

        public ActionResult Report()
        {
            return PartialView("Index");
        }

        public ActionResult GetView(string tabid)
        {
            string partialView = "";
            switch (tabid)
            {
                case "ServiceTaxRateMaster":
                    partialView = "_ServiceTaxRateMasterTab";
                    break;
                case "AdditionalMarginMaster":
                    partialView = "_AdditionalMarginMasterTab";
                    break;
                case "MTTierBasedTOTMaster":
                    partialView = "_MTTierBasedTOTMasterTab";
                    break;
                case "OutletMaster":
                    partialView = "_OutletMasterTab";
                    break;
                case "HuggiesBasepackMaster":
                    partialView = "_HuggiesBasepackMasterTab";
                    break;
                case "ClusterRsCodeMappingMaster":
                    partialView = "_ClusterRsCodeMappingMasterTab";
                    break;
                case "SubcategoryMappingMaster":
                    partialView = "_SubcategoryMappingTab";
                    break;
                case "SubcategoryTOTRatesMaster":
                    partialView = "_SubcategoryTOTRatesTab";
                    DataTable dt = subcategoryTOTService.GetSubCatTOTRateData("on");
                    ViewBag.SubCatTOTRateData = dt;
                    break;
                case "GLMaster":
                    partialView = "_GLMaster";
                    break;
                case "ChainNameMaster":
                    partialView = "_ChainNameMaster";
                    break;
                case "PriceListMaster":
                    partialView = "_PriceListMaster";
                    break;
                case "OnInVoiceConfigMaster":
                    partialView = "_OnInVoiceConfig";
                    break;
                default:
                    partialView = "UploadIndex";
                    break;
                case "MailConfigMaster":
                    partialView = "_MailConfigMaster";
                    break;
            }

            return PartialView(partialView);
        }

        public ActionResult UpdateTOTTable(string totCategory)
        {
            DataTable dt = subcategoryTOTService.GetSubCatTOTRateData(totCategory);
            ViewBag.SubCatTOTRateData = dt;
            return PartialView("_SubcategoryTOTRatesTabTable");
        }

    }
}