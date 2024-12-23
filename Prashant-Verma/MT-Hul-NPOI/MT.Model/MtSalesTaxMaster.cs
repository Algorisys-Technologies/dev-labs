using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MtSalesTaxMaster
    {
        public int Id { get; set; }
        public string TaxCode { get; set; }
        public string StateCode { get; set; }
        public string SalesTaxRate { get; set; }
    }
}