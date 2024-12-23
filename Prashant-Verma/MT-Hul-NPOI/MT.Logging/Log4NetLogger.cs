using log4net;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace MT.Logging
{
    internal class Log4NetLogger : ILogger
    {
        public Log4NetLogger()
        {
            // Configures log4net by using log4net's XMLConfigurator class
            log4net.Config.XmlConfigurator.Configure();
            //log4net.Config.BasicConfigurator.Configure();
        }

        /// <summary>
        /// Writes messages to the log4net backend.
        /// </summary>
        /// <remarks>
        /// This method is responsible for converting the WriteMessage call of
        /// the interface into something log4net can understand.  It does this
        /// by doing a switch/case on the log level and then calling the
        /// appropriate log method
        /// </remarks>
        /// <param name="category">A string of the category to log to</param>
        /// <param name="level">A LogLevel value of the level of the log</param>
        /// <param name="message">A String of the message to write to the log</param>
        public void Log(string category, LogLevel level, string message)
        {
            // Get the Log we are going to write this message to           
            ILog log = LogManager.GetLogger(typeof(Log4NetLogger));
            FillRequestId();

            switch (level)
            {
                case LogLevel.FATAL:
                    if (log.IsFatalEnabled) log.Fatal(message);
                    break;
                case LogLevel.ERROR:
                    if (log.IsErrorEnabled) log.Error(message);
                    break;
                case LogLevel.WARN:
                    if (log.IsWarnEnabled) log.Warn(message);
                    break;
                case LogLevel.INFO:
                    if (log.IsInfoEnabled) log.Info(message);
                    break;
                case LogLevel.DEBUG:
                    if (log.IsDebugEnabled) log.Debug(message);
                    break;
            }
        }

        public void Log(LogLevel level, string message)
        {
            // Get the Log we are going to write this message to           
            ILog log = LogManager.GetLogger(typeof(Log4NetLogger));
            FillRequestId();

            switch (level)
            {
                case LogLevel.FATAL:
                    if (log.IsFatalEnabled) log.Fatal(message);
                    break;
                case LogLevel.ERROR:
                    if (log.IsErrorEnabled) log.Error(message);
                    break;
                case LogLevel.WARN:
                    if (log.IsWarnEnabled) log.Warn(message);
                    break;
                case LogLevel.INFO:
                    if (log.IsInfoEnabled) log.Info(message);
                    break;
                case LogLevel.DEBUG:
                    if (log.IsDebugEnabled) log.Debug(message);
                    break;
            }
        }

        public void LogError(Exception ex)
        {
            // Get the Log we are going to write this message to           
            ILog log = LogManager.GetLogger(typeof(Log4NetLogger));
            FillRequestId();
            if (log.IsErrorEnabled) log.Error(ex);
        }

        private void FillRequestId()
        {
            //var reqId = HttpContext.Current.Request.Headers.Get("ReqId");
            //log4net.LogicalThreadContext.Properties["ReqId"] = reqId;

            //log4net.LogicalThreadContext.Properties["ReqId"] = Guid.NewGuid().ToString();
        }
    }
}
