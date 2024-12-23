using MT.Business;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class OnInVoiceConfigMasterController : AppController
    {
        OnInVoiceConfigService onInVoiceConfigService = new OnInVoiceConfigService();
        AssignAccessService assignAccessService = new AssignAccessService();
        public ActionResult GetOnInVoiceConfigData()
        {
            List<MTOnInVoiceConfigMaster> list = new List<MTOnInVoiceConfigMaster>();
            //list = onInVoiceConfigService.GetOnInVoiceConfigData();
            //return Json(new { data = list }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

             try
                {
                    list = onInVoiceConfigService.GetOnInVoiceConfigData();
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

        public ActionResult AddOnInVoiceConfig(string stateCode, bool isNetSaleAppl)
        {

            //string message = onInVoiceConfigService.AddOnInVoiceConfig(stateCode, isNetSaleAppl);
            //return Json(new { data = message }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

            string msg = "";
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.OnInvoiceConfig_PageId) == true)
            {
                try
                {
                    message = onInVoiceConfigService.AddOnInVoiceConfig(stateCode, isNetSaleAppl,loggedUser.UserId);
                    isSuccess = true;
                  
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

        public ActionResult DeleteOnInVoiceConfig(string stateCodeTODelete)
        {

            //string msg = "";
            //msg = onInVoiceConfigService.DeleteOnInVoiceConfig(stateCodeTODelete);
            //return Json(new { data = msg }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

            string msg = "";
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.OnInvoiceConfig_PageId) == true)
            {
                try
                {
                    msg = onInVoiceConfigService.DeleteOnInVoiceConfig(stateCodeTODelete,loggedUser.UserId);
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



        public ActionResult EditOnInVoiceConfigMaster(string oldStateCode, string newStateCode, string isNetSaleAppl)
        {

            //onInVoiceConfigService.EditOnInVoiceConfigMaster(oldStateCode, newStateCode, isNetSaleAppl);
            //return null;
            bool isSuccess = false;
            string message = string.Empty;

            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.OnInvoiceConfig_PageId) == true)
            {
                try
                {
                    onInVoiceConfigService.EditOnInVoiceConfigMaster(oldStateCode, newStateCode, isNetSaleAppl,loggedUser.UserId);
                    isSuccess = true;
                    message = "Record changed successfully";


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