
using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class GLMasterController : AppController
    {
        //
        // GET: /GLMaster/
        GLMasterService gLMasterService = new GLMasterService();
        AssignAccessService assignAccessService = new AssignAccessService();
        public ActionResult EditGLMaster(string final,string intial)
        {

            //gLMasterService.EditGLMaster(final, intial);
            //return null;


            bool isSuccess = false;
            string message = string.Empty;
            if (assignAccessService.CheckForMasterUploadRight(SecurityPageConstants.GLMaster_PageId) == true)
            {

                try
                {
                    gLMasterService.EditGLMaster(final, intial,loggedUser.UserId);
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
        public ActionResult AjaxGetGLData()
        {
           
            List<MtGLMaster> list = new List<MtGLMaster>();

           // list = gLMasterService.AjaxGetGLData();            
            //return Json(new {data=list}, JsonRequestBehavior.AllowGet);


            bool isSuccess = false;
            string message = string.Empty;

              try
                {
                    list = gLMasterService.AjaxGetGLData();            
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
	}
}