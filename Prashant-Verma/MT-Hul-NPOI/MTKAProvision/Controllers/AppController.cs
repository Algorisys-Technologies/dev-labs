using Ionic.Zip;
using MT.Business;
using MT.Model;
using MT.SessionManager;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using MT.Logging;
using MT.Exceptions;
using System.Web.Security;
using MT.DataAccessLayer;
using System.Text;

namespace MTKAProvision.Controllers
{
    public class AppController : Controller
    {
        public ILogger Logger = LoggerFactory.GetLogger();
        BaseService serviceObj = new BaseService();
        public string CurrentMOC = string.Empty;
        public SmartData smartDataObj = new SmartData();
        public UserRoleRights loggedUser = new UserRoleRights();

        public AppController()
        {
            CurrentMOC = SetCurrentMOC();
        }

        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            base.OnActionExecuting(filterContext);
            UserRoleRights LoggedInUserRights = SessionManager<UserRoleRights>.Get("UserData");
            loggedUser = LoggedInUserRights;
            if (filterContext.ActionDescriptor.ControllerDescriptor.ControllerName.ToLower() != "login" )
            {
                //Check Session Expiry
                if (LoggedInUserRights == null)
                {
                    if (filterContext.RequestContext.HttpContext.Request.IsAjaxRequest())
                    {
                        throw new AuthenticationTimeoutException("Authentication ticket expired.");
                    }
                    else
                    {
                        SessionManager<UserRoleRights>.Abandon();
                        Response.Redirect("~/Login/Index");
                        return;
                    }
                }              
            }

            //if (LoggedInUserRights == null)
            //{
            //    SessionManager<UserRoleRights>.Abandon();
            //    filterContext.Result = new RedirectToRouteResult(
            //    new RouteValueDictionary { { "controller", "Login" }, { "action", "Index" } });
            //}

            ViewBag.UserName = (LoggedInUserRights == null) ? "" : LoggedInUserRights.UserId;
            ViewBag.LoggedInUserRights = LoggedInUserRights;
        }

        public string SetCurrentMOC()
        {
            return serviceObj.SetCurrentMOC();
        }
        public void ExportDataTableToExcel(DataTable sourceDt, string tableName)
        {
            using (ExcelPackage xp = new ExcelPackage())
            {
                if (sourceDt != null)
                {

                    ExcelWorksheet ws = xp.Workbook.Worksheets.Add(sourceDt.TableName);
                    ws.Cells["A1"].LoadFromDataTable(sourceDt, true);


                    Response.AddHeader("content-disposition", "attachment;filename=" + tableName + ".xlsx");
                    Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

                    xp.SaveAs(Response.OutputStream);
                    Response.End();

                }

            }

        }

        [HttpPost]
        public void ExportHtmlToExcel(string fileName, string exportData)
        {

            var data = HttpContext.Server.UrlDecode(exportData);

            HttpContext.Response.Clear();
            HttpContext.Response.AddHeader("Content-Disposition", "attachment;filename=" + fileName + ".xls");
            HttpContext.Response.Charset = "";
            HttpContext.Response.Cache.SetCacheability(HttpCacheability.NoCache);
            //HttpContext.Response.ContentType = "application/vnd.ms-excel";
            HttpContext.Response.ContentType = "application/x-msexcel";
            HttpContext.Response.ContentEncoding = Encoding.UTF8; 

            HttpContext.Response.Write(data);

            HttpContext.Response.Flush();
            HttpContext.Response.End();

//            Response.ContentType = "application/x-msexcel"; 
//Response.AddHeader("Content-Disposition", "attachment;
//filename=ExcelFile.xls");
//Response.ContentEncoding = Encoding.UTF8; 
//StringWriter tw = new StringWriter();
//HtmlTextWriter hw = new HtmlTextWriter(tw);
//tbl.RenderControl(hw);
//Response.Write(tw.ToString());
//Response.End();

        }

        public ActionResult DownloadAllFileFormat()
        {

            serviceObj.DownloadAllFileFormat();
           return null;

        }
        protected override void OnException(ExceptionContext filterContext)
        {


            if (filterContext.Exception is AuthenticationTimeoutException)
            {
                filterContext.HttpContext.Response.StatusCode = (int)System.Net.HttpStatusCode.InternalServerError;
                string type = "timeout";
                filterContext.Result = new JsonResult()
                {
                    JsonRequestBehavior = JsonRequestBehavior.AllowGet,
                    Data = new
                    {
                        type,
                        filterContext.Exception.Message
                    }

                };
                filterContext.ExceptionHandled = true;
            }            
            else
            {
                filterContext.HttpContext.Response.StatusCode = (int)System.Net.HttpStatusCode.InternalServerError;
                Logger.LogError(filterContext.Exception);

                //ToDo: Log the Error
                string Message = string.Empty;
                //Message = filterContext.Exception.Message;

                Message = "There is some error processing your request.  Please try again. ";
                //if (filterContext.Exception is XMLFileNotFoundException)
                //{
                //    Message = filterContext.Exception.Message;
                //}
                //else
                //{
                //    Message = "There is some error processing your request.  Please try again. ";
                //}

                //filterContext.Result = new JsonResult()
                //{
                //    JsonRequestBehavior = JsonRequestBehavior.AllowGet,
                //    Data = new
                //    {
                //        Message
                //    }
                //};
                //filterContext.ExceptionHandled = true;

                if (filterContext.RequestContext.HttpContext.Request.IsAjaxRequest())
                {

                    filterContext.HttpContext.Response.StatusCode = (int)System.Net.HttpStatusCode.InternalServerError;                    
                    filterContext.Result = new JsonResult()
                    {
                        JsonRequestBehavior = JsonRequestBehavior.AllowGet,
                        Data = new
                        {                           
                            //filterContext.Exception.Message
                            Message
                        }

                    };
                    filterContext.ExceptionHandled = true;
                }
                else
                {
                    Response.Redirect("~/Error");
                }
            }
        }

    }
}