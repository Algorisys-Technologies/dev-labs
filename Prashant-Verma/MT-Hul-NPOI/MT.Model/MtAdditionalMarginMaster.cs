using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MtAdditionalMarginMaster
    {
        public int Id { get; set; }
        public string RSCode { get; set; }
        public string RSName { get; set; }
        public string ChainName { get; set; }
        public string GroupName { get; set; }
        public string PriceList { get; set; }
        public string Percentage { get; set; }
    }
}