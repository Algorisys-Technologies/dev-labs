using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class OnInvoiceJV 
    {

        public string MOC { get; set; }
        public string GLAccount { get; set; }
        public decimal Amount { get; set; }
        public string BranchCode { get; set; }
        public string InternalOrder { get; set; }
        public string GLItemText { get; set; }
        public string PMHBrandCode { get; set; }
        public string DistrChannel { get; set; }
        public string ProfitCenter { get; set; }
        public string COPACustomer { get; set; }
    }
}