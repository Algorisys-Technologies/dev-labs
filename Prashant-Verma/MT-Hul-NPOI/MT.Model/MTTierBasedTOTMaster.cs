using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MTTierBasedTOTMaster
    {
        public int Id { get; set; }
        public string ChainName { get; set; }
        public string GroupName { get; set; }
        public string OutletTier { get; set; }
        public string ColorNonColor { get; set; }
        public string PriceList { get; set; }
        public string OnInvoiceRate { get; set; }
        public string OffInvoiceMthlyRate { get; set; }
        public string OffInvoiceQtrlyRate { get; set; }
    }
}