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
    public class PriceListMasterController : AppController
    {

        PriceListMasterService priceListService = new PriceListMasterService();
        AssignAccessService assignAccessService = new AssignAccessService();
        //
        // GET: /PriceListMaster/
        public ActionResult Index()
        {
            return View();
        }


        public ActionResult GetPriceListData()
        {
            List<MtPriceListMaster> list = new List<MtPriceListMaster>();
            //list = priceListService.GetPriceListData();
            //return Json(new { data = list }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

             try
                {
                    list = priceListService.GetPriceListData();
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

        public ActionResult AddPriceList(string priceList)
        {

            //string message = priceListService.AddPriceList(priceList);
            //return Json(new { data = message }, JsonRequestBehavior.AllowGet);


            bool isSuccess = false;
            string message = string.Empty;

            string msg = "";
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.PriceList_PageId) == true)
            {
                try
                {
                    msg = priceListService.AddPriceList(priceList,loggedUser.UserId);
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

        public ActionResult DeletePriceList(string PriceListTODelete)
        {

            //string msg = "";
            //msg = priceListService.DeletePriceList(PriceListTODelete);
            //return Json(new { data = msg }, JsonRequestBehavior.AllowGet);

            bool isSuccess = false;
            string message = string.Empty;

            string msg = "";
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.PriceList_PageId) == true)
            {
                try
                {
                    msg = priceListService.DeletePriceList(PriceListTODelete,loggedUser.UserId);
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



        public ActionResult EditPriceListMaster(string oldPriceList, string newPriceList)
        {

            //priceListService.EditPriceListMaster(oldPriceList, newPriceList);
            //return null;

            bool isSuccess = false;
            string message = string.Empty;

            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.PriceList_PageId) == true)
            {
                try
                {
                    priceListService.EditPriceListMaster(oldPriceList, newPriceList,loggedUser.UserId);
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