using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Formatting;
using System.Web;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using MT.Logging;
using System.Configuration;

namespace MTKAProvision
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            WebApiConfig.Register(GlobalConfiguration.Configuration);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            var jsonFormatter = GlobalConfiguration.Configuration.Formatters.OfType<JsonMediaTypeFormatter>().First();
            jsonFormatter.SerializerSettings.ContractResolver = new CamelCasePropertyNamesContractResolver();
            jsonFormatter.SerializerSettings.DateFormatHandling = DateFormatHandling.IsoDateFormat;
            jsonFormatter.SerializerSettings.NullValueHandling = NullValueHandling.Ignore;

        }
        protected void Application_Error(object sender, EventArgs e)
        {
            // Get the exception object
            Exception exception = Server.GetLastError();

            // Log the exception (you can use any logging library)
            LogExceptionToFile(exception);
            

            // Clear the error from the server
            Server.ClearError();

        }

        private void LogExceptionToFile(Exception exception)
        {
            // Set the log file path (update path as per your requirement)
            string logFilePath = Server.MapPath(ConfigurationSettings.AppSettings["ExceptionFile"]);

            // Log the details of the exception
            using (System.IO.StreamWriter writer = new System.IO.StreamWriter(logFilePath, true))
            {
                writer.WriteLine("--------- Error Log ---------");
                writer.WriteLine("Date/Time: " + DateTime.Now.ToString());
                writer.WriteLine("Message: " + exception.Message);
                writer.WriteLine("Stack Trace: " + exception.StackTrace);
                writer.WriteLine("Source: " + exception.Source);

                // Log inner exception details if available
                if (exception.InnerException != null)
                {
                    writer.WriteLine("Inner Exception Message: " + exception.InnerException.Message);
                    writer.WriteLine("Inner Exception Stack Trace: " + exception.InnerException.StackTrace);
                }

                writer.WriteLine("------------------------------");
                writer.WriteLine();
            }
        }
    }
}
