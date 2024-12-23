using Microsoft.Extensions.Logging;
using MT.Business;
using MT.Model;
using MT.SessionManager;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.DirectoryServices;
using System.Linq;
using System.Web.Mvc;
using System.Web.Security;
using MT.Logging;

namespace MTKAProvision.Controllers
{
    public class LoginController : Controller
    {

        private readonly MT.Logging.ILogger Logger = LoggerFactory.GetLogger();
        private readonly LoginService loginService = new LoginService();

        // GET: Login
        public ActionResult Index()
        {
            /// Logger.Log(MT.Logging.LogLevel.INFO, "Login Index action triggered.");
            // Console.WriteLine("Login Index action triggered.");

            return View("Login");
        }

        [HttpPost]
        public ActionResult Login(UserLogin model)
        {
           /// Logger.Log(MT.Logging.LogLevel.INFO, "Login action triggered.");
           /// Console.WriteLine("Login action triggered.");

            if (ModelState.IsValid)
            {
                string dominName = string.Empty;
                string adPath = string.Empty;
                string userName = model.UserName;
                string pwd = model.Password;
                string strError = string.Empty;

              ///  Logger.Log(MT.Logging.LogLevel.INFO, $"Attempting login for user: {userName}");

                if (ConfigConstants.IsLdapLoginEnabled && userName != "admin@unilever.com")
                {
                    dominName = ConfigConstants.DirectoryDomain;
                    adPath = ConfigConstants.DirectoryPath;

                    if (loginService.AuthenticateUser(dominName, userName, pwd, adPath, out strError))
                    {
                       // Logger.Log(MT.Logging.LogLevel.INFO, "LDAP authentication successful.");

                        var isUserExist = loginService.DoesLdapUserExistOnLocalServer(userName);
                        if (isUserExist)
                        {
                       ///     Logger.Log(MT.Logging.LogLevel.INFO, "User exists on local server.");
                            loginService.SaveUserSession(userName);
                            return RedirectToAction("Index", "Dashboard", null);
                        }
                        else
                        {
                        ///    Logger.Log(MT.Logging.LogLevel.WARN, "User does not exist on local server.");
                            ModelState.AddModelError("", "User does not exist");
                        }
                    }
                    else
                    {
                    ///    Logger.Log(MT.Logging.LogLevel.ERROR, $"LDAP authentication failed: {strError}");
                        ModelState.AddModelError("", strError);
                    }
                }
                else
                {
                    if (loginService.AuthenticateLocalUser(userName, pwd))
                    {
                     ///   Logger.Log(MT.Logging.LogLevel.INFO, "Local authentication successful.");
                        FormsAuthentication.SetAuthCookie(userName, false);
                        loginService.SaveUserSession(userName);
                        return RedirectToAction("Index", "Dashboard", null);
                    }
                    else
                    {
                    //    Logger.Log(MT.Logging.LogLevel.ERROR, "Local authentication failed.");
                        ModelState.AddModelError("", "The user name or password provided is incorrect.");
                    }
                }
            }
            else
            {
               // Logger.Log(MT.Logging.LogLevel.WARN, "Model state is invalid.");
            }

            return View("Login");
        }

        public ActionResult Logout()
        {
           // Logger.Log(MT.Logging.LogLevel.INFO, "Logout action triggered.");
          //  Console.WriteLine("Logout action triggered.");

            FormsAuthentication.SignOut();
            SessionManager<UserRoleRights>.Abandon();
            return RedirectToAction("Index", "Login");
        }
    }
}
