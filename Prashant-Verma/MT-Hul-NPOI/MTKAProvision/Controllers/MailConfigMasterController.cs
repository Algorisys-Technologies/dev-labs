using MT.Business;
using MT.Model;
using MT.Models;
using MT.Services;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class MailConfigMasterController : AppController
    {

        MailConfigService mailConfigService = new MailConfigService();
        AssignAccessService assignAccessService = new AssignAccessService();
        //
        // GET: /PriceListMaster/
        public ActionResult Index()
        {
            return View();
        }


        public ActionResult GetMailConfigList()
        {
            List<MailConfig> list = new List<MailConfig>();
            //list = priceListService.GetPriceListData();
            //return Json(new { data = list }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

             try
                {
                    list = mailConfigService.GetMailConfigList();
                    isSuccess = true;


                }
                catch (Exception ex)
                {
                    isSuccess = false;
                    message = MessageConstants.Error_Occured + ex.Message;

                }
         
            return Json(new
            {
                data = list,
                isSuccess = isSuccess,
                msg = message
            }, JsonRequestBehavior.AllowGet);
           

        }

        public ActionResult GetMailConfigById(string configID)
        {
            MailConfig mailConfigDetail = new MailConfig();

            bool isSuccess = false;

            try
            {
                mailConfigDetail = mailConfigService.GetMailConfigSettingById(configID);
                isSuccess = true;


            }
            catch (Exception ex)
            {
                isSuccess = false;
            }

            return Json(new
            {
                data = mailConfigDetail,
                isSuccess = isSuccess
            }, JsonRequestBehavior.AllowGet);


        }
        [HttpPost]
        public ActionResult EditMailConfiguration(MailConfig mailConfig, string Enable)
        {
           
            if (Enable == "on")
            {
                mailConfig.Enable=true;
            }
            bool isSuccess = false;
            string message = string.Empty;

            string msg = "";
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.PriceList_PageId) == true)
            {
                try
                {
                    mailConfigService.EditMailConfig(mailConfig);
                    isSuccess = true;
                    message = msg;
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
                message = MessageConstants.InsufficientPermission;

            }
            return Json(new
            {
                isSuccess = isSuccess,
                msg = message
            }, JsonRequestBehavior.AllowGet);
            
           
        }
	}
}