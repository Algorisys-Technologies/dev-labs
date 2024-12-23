using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Models
{
    public class MailSendModel : MailConfig
    {
        public string Subject { get; set; }
        public string HTMLBody { get; set; }
        public List<HttpPostedFileBase> AttachmentFile { get; set; }
    }
    public class MailConfig
    {

        public string ConfigId { get; set; }
        public string Description { get; set; }
        public string From { get; set; }
        public string MailTo { get; set; }
        public string MailCC { get; set; }
        public bool Enable { get; set; }
        public string Password { get; set; }
    }
}