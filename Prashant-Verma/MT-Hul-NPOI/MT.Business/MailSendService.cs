using MT.Business;
using MT.DataAccessLayer;
using MT.Logging;
using MT.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Threading;
using System.Web;

namespace MT.Services
{
    public class MailConfigService : BaseService
    {
        public ILogger Logger = LoggerFactory.GetLogger();

        public bool SendMail(MailSendModel model)
        {
            bool success = false;
            MailMessage message = new MailMessage();
            message.To.Add(model.MailTo);
            if (model.MailCC != "")
            {
                message.CC.Add(model.MailCC);
            }
            string HTMLBody = model.HTMLBody;
            message.Subject = model.Subject;
            message.From = new MailAddress(model.From);
            //message.From = new MailAddress("manas.mukherjee@unilever.com");
            message.Body = HTMLBody.Replace("`", "'");
            message.IsBodyHtml = true;
            System.Net.Mail.Attachment attachment;
            //attachment = new System.Net.Mail.Attachment(@"E:\HUL-Projects\TravelMIS\Reports.xlsx");
            if (model.AttachmentFile != null)
            {
                foreach (HttpPostedFileBase file in model.AttachmentFile)
                {
                    attachment = new System.Net.Mail.Attachment(file.FileName);
                    message.Attachments.Add(attachment);
                }
            }
            SmtpClient smtp = new SmtpClient();
            smtp.Host = ConfigurationManager.AppSettings["smtpHost"];
            //smtp.Host = \"156.5.190.201";
            smtp.Port = Convert.ToInt32(ConfigurationManager.AppSettings["smtpPort"]);
            smtp.EnableSsl = Convert.ToBoolean(ConfigurationManager.AppSettings["EnableSSL"]);
            //DataTable dt = new DataTable();
            //dt = dOper.return_dt("select MailPassword from SenderMailId where EmailId = '" + ddlFrom.SelectedValue + "'");

            //var getKeyForDecryption = ConfigurationManager.AppSettings["EncryptionKey"];
            //Utilises utilises = new Utilises();
            //var getDecryptedPass = utilises.Decrypt(dt.Rows[0]["MailPassword"].ToString(), getKeyForDecryption);
            //var getPass = dt.Rows[0]["MailPassword"].ToString()

            smtp.Credentials = new NetworkCredential(model.From, model.Password);
            try
            {
                smtp.Send(message);
                success = true;
            }
            catch (Exception exc)
            {

                Logger.LogError(exc);
            }
            return success;
        }

        public void UpdateMailSendDetail(MailSendModel model, string status)
        {
            DbRequest request = new DbRequest();
            request.Parameters = new List<Parameter>();
            request.StoredProcedureName = "Insert_MailSendDetail";
            Parameter param1 = new Parameter("Subject", model.Subject);
            Parameter param2 = new Parameter("MailFrom", model.From);
            Parameter param3 = new Parameter("MailTo", model.MailTo);
            Parameter param4 = new Parameter("MailCC", model.MailCC);
            Parameter param5 = new Parameter("MsgBody", model.HTMLBody);
            Parameter param6 = new Parameter("Status", status);
            request.Parameters.Add(param1);
            request.Parameters.Add(param2);
            request.Parameters.Add(param3);
            request.Parameters.Add(param4);
            request.Parameters.Add(param5);
            request.Parameters.Add(param6);
            smartDataObj.ExecuteStoredProcedure(request);
        }

        public MailConfig GetMailConfigSettingById(string configId)
        {
            PasswordService passwordService = new PasswordService();
            DbRequest request = new DbRequest();
            MailConfig MailConfig = new MailConfig();
            request.SqlQuery = "select Top(1) * from mtMailConfig where ConfigId= '" + configId + "'";
            var data = smartDataObj.GetData(request);
            if (data.Rows.Count > 0)
            {
                MailConfig.ConfigId = data.Rows[0]["ConfigId"].ToString();
                MailConfig.Description = data.Rows[0]["Description"].ToString();
                MailConfig.From = data.Rows[0]["MailFrom"] == null ? "" : data.Rows[0]["MailFrom"].ToString();
                MailConfig.MailTo = data.Rows[0]["MailTo"] == null ? "" : data.Rows[0]["MailTo"].ToString();
                MailConfig.MailCC = data.Rows[0]["MailCC"] == null ? "" : data.Rows[0]["MailCC"].ToString();
                MailConfig.Enable = Convert.ToBoolean(data.Rows[0]["Enable"].ToString()) == null ? false : Convert.ToBoolean(data.Rows[0]["Enable"].ToString());
                string pass = data.Rows[0]["SenderPassword"] == null ? "" : data.Rows[0]["SenderPassword"].ToString();
                if (pass != "")
                {
                    string decriptpass = passwordService.Decrypt(data.Rows[0]["SenderPassword"].ToString(), "MAKV2SPBNI9921212");
                    MailConfig.Password = decriptpass;
                }
            }
            return MailConfig;
        }

        public List<MailConfig> GetMailConfigList()
        {

            List<MailConfig> list = new List<MailConfig>();


            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT * FROM mtMailConfig";

            dt = smartDataObj.GetData(request);

            foreach (DataRow dr in dt.Rows)
            {
                MailConfig obj = new MailConfig();

                obj.ConfigId = dr["ConfigId"].ToString();
                obj.Description = dr["Description"].ToString();
                obj.Enable = Convert.ToBoolean(dr["Enable"].ToString());
                list.Add(obj);
            }

            return list;



        }



        public void EditMailConfig(MailConfig mailconfigdetail)
        {
            PasswordService passwordService = new PasswordService();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            string encriptpass = "";
            if (!string.IsNullOrEmpty(mailconfigdetail.Password))
            {
                encriptpass = passwordService.Encrypt(mailconfigdetail.Password, "MAKV2SPBNI9921212");
            }
            string changeField = "Description = '" + mailconfigdetail.Description + "'";
            changeField += ",MailFrom = '" + mailconfigdetail.From + "'";
            changeField += ",MailTo = '" + mailconfigdetail.MailTo + "'";
            changeField += ",MailCC = '" + mailconfigdetail.MailCC + "'";
            changeField += ",Enable = '" + mailconfigdetail.Enable + "'";
            changeField += ",SenderPassword = '" + encriptpass + "'";

            request.SqlQuery = "Update mtMailConfig set " + changeField + " where ConfigId='" + mailconfigdetail.ConfigId + "'";
            smartDataObj.ExecuteNonQuery(request);

        }

    }

}