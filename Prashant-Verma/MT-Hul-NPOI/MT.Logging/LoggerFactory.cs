using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace MT.Logging
{
    /// <summary>
    /// Factory class to get the appropriate ILogger based on what is specified in
    /// the App.Config file
    /// </summary>
    public class LoggerFactory
    {

        #region Member Variables

        // reference to the ILogger object.  Get a reference the first time then keep it
        private static ILogger logger;

        // This variable is used as a lock for thread safety
        private static object lockObject = new object();

        #endregion


        public static ILogger GetLogger()
        {
            lock (lockObject)
            {
                if (logger == null)
                {
                    string asm_name = ConfigurationManager.AppSettings["Logger.AssemblyName"];
                    string class_name = ConfigurationManager.AppSettings["Logger.ClassName"];

                    if (String.IsNullOrEmpty(asm_name) || String.IsNullOrEmpty(class_name))
                        throw new ApplicationException("Missing config data for Logger");

                    //Assembly assembly = Assembly.LoadFrom(asm_name);
                    Assembly assembly = Assembly.GetExecutingAssembly();
                    logger = assembly.CreateInstance(class_name) as ILogger;

                    if (logger == null)
                        throw new ApplicationException(
                            string.Format("Unable to instantiate ILogger class {0}/{1}",
                            asm_name, class_name));
                }
                return logger;
            }
        }
    }
}
