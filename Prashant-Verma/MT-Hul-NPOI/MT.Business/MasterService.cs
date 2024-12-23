using MT.DataAccessLayer;
using MT.Model;
using MT.Models;
using MT.Services;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class MasterService : BaseService
    {
        public MailConfigService mailSendService = new MailConfigService();

        public async Task SendMailOnMasterUpdate(string configId, string username)
        {
            await Task.Run(() => SendMailOnUpdateMaster(configId, username));
        }
        public void SendMailOnUpdateMaster(string configId, string username)
        {
            MailSendModel model = new MailSendModel();
            var mailconfig = mailSendService.GetMailConfigSettingById(configId);
            if (mailconfig != null)
            {
                if (mailconfig.Enable == true)
                {
                    {
                        model.Subject = "Update " + mailconfig.Description;
                        model.HTMLBody = "Hi, <br/> <br/> " + mailconfig.Description + " has been " + " updated by " + username + " on " + DateTime.Now + ".";
                        model.MailCC = mailconfig.MailCC;
                        model.MailTo = mailconfig.MailTo;
                        model.From = mailconfig.From;
                        model.Password = mailconfig.Password;
                        var mailsendstatus = mailSendService.SendMail(model);
                        string mailStatus = "";
                        if (mailsendstatus == true)
                            mailStatus = "S";
                        else
                            mailStatus = "F";
                        mailSendService.UpdateMailSendDetail(model, mailStatus);
                    }
                }
            }

        }

    }
}
