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
    public class ChainNameController : AppController
    {
        ChainNameService chainNameService = new ChainNameService();
        AssignAccessService assignAccessService = new AssignAccessService();
        public ActionResult GetChainNameData()
        {
            List<MtChainNameMaster> list = new List<MtChainNameMaster>();
            //list = chainNameService.GetChainNameData();
            //return Json(new { data = list }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

              try
                {
                    list = chainNameService.GetChainNameData();
                    isSuccess = true;
                    
                   
                }
                catch (Exception ex)
                {
                    isSuccess = false;
                    message = MessageConstants.Error_Occured + ex.Message;

                }
           
            return Json(new
            {
                data=list,
                isSuccess = isSuccess,
                msg = message
            }, JsonRequestBehavior.AllowGet);
           
        }

        public ActionResult AddChainName(string chainName,bool isHuggiesAppl)
        {
            bool isSuccess = false;
            string message = string.Empty;

            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.ChainName_PageId) == true)
            {
               
                var response = chainNameService.AddChainName(chainName, isHuggiesAppl,loggedUser.UserId);
                //var response = chainNameService.AddChainName(chainName, isHuggiesAppl);
                isSuccess = true;
                message = response.MessageText;
                //return Json(new { isSuccess = response.IsSuccess, msg = response.MessageText }, JsonRequestBehavior.AllowGet);
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

        public ActionResult DeleteChainName(string chainNameTODelete)
        {
            bool isSuccess = false;
            string message = string.Empty;

            string msg = "";
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.ChainName_PageId) == true)
            {
                try
                {
                    msg = chainNameService.DeleteChainName(chainNameTODelete,loggedUser.UserId);
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

        public ActionResult EditChainNameMaster(string oldChainName, string newChainName,string isHuggiesAppl)
        {

            //chainNameService.EditChainNameMaster(oldChainName, newChainName, isHuggiesAppl);
            //return null;

            bool isSuccess = false;
            string message = string.Empty;

            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.ChainName_PageId) == true)
            {
                try
                {
                    chainNameService.EditChainNameMaster(oldChainName, newChainName, isHuggiesAppl,loggedUser.UserId);
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