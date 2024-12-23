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
    public class SecurityController : AppController
    {
        RolesService rolesService = new RolesService();
        UserService usersService = new UserService();
        AssignAccessService assignAccessService = new AssignAccessService();
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult AjaxGetRoleName()
        {


            List<Role> list = new List<Role>();
            list = rolesService.GetAllRole();

            return Json(new { data = list }, JsonRequestBehavior.AllowGet);

        }

        public ActionResult AjaxCreateRoleName(string roleName)
        {

            var jsonResult = rolesService.CreateRoleName(roleName);



            return Json(new { data = jsonResult }, JsonRequestBehavior.AllowGet);

        }
        public ActionResult AjaxDeleteRoleName(string roleName)
        {


            var jsonResult = rolesService.DeleteRoleName(roleName);

            return Json(new { data = jsonResult }, JsonRequestBehavior.AllowGet);

        }


        public ActionResult AjaxGetUserName()
        {


            List<UserRole> list = new List<UserRole>();
            list = usersService.GetAllUser();

            return Json(new { data = list }, JsonRequestBehavior.AllowGet);

        }

        public ActionResult AjaxCreateUserName(string userName, int isLocalUser)
        {

            var jsonResult = usersService.CreateUserName(userName, Convert.ToInt32(isLocalUser));



            return Json(new { data = jsonResult }, JsonRequestBehavior.AllowGet);

        }
        public ActionResult AjaxDeleteUserName(string userName)
        {


            var jsonResult = usersService.DeleteUserName(userName);

            return Json(new { data = jsonResult }, JsonRequestBehavior.AllowGet);

        }
        public ActionResult AssignRole()
        {
            return null;
        }
        public ActionResult AjaxSaveUserRoleName(string roleName, string userName)
        {

            string result = usersService.SaveUserRoleName(userName, roleName);

            return Json(new { data = result }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult DisplayAssignAccessTable()
        {
            List<SecurityAssignAccess> pageList = new List<SecurityAssignAccess>();
            List<Role> roleList = new List<Role>();
            bool isSuccess = true;
            try
            {
                pageList = assignAccessService.GetPageRightMaster();
                roleList = assignAccessService.GetRoleList();

            }
            catch (Exception ex)
            {
                isSuccess = false;
                pageList = new List<SecurityAssignAccess>();
            }



            //return PartialView("", pageList);
            return Json(
                new
                {
                    IsSuccess = isSuccess,
                    PartialView = MvcHelper.PartialView(this, "_SecurityAssignAccess", pageList),
                    RoleList = roleList
                }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult GetRoleWisePageRights(Guid roleId)
        {
            List<RoleWisePageRightsMaster> roleWisePageRights = new List<RoleWisePageRightsMaster>();
            try
            {
                roleWisePageRights = assignAccessService.GetRoleWisePageRights(roleId);
            }
            catch (Exception ex)
            {

            }

            return Json(
              new
              {
                  RoleWisePageRightsList = roleWisePageRights
              }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult UpdateAccessRights(List<RoleWisePageRightsMaster> pageRightList)
        {
            bool isSuccees = true;
            try
            {
                isSuccees = assignAccessService.UpdateAccessRights(pageRightList);
            }
            catch (Exception ex)
            {
                isSuccees = false;
            }

            return Json(
              new
              {
                  IsSuccess = isSuccees
              }, JsonRequestBehavior.AllowGet);
        }
    }
}