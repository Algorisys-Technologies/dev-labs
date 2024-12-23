using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class ZeroProvisionOutletDataTable : DataTableBaseMaster
    {
        public List<ZeroProvisionOutlet> data { get; set; }
    }

    public class ZeroProvisionOutlet
    {
        public string HulOutletCode { get; set; }
        public string HulOutletCodeName { get; set; }
        public string OutletCategoryMaster { get; set; }
        public string ChainName { get; set; }
        public string Groupname { get; set; }
        public decimal NetSalesValue { get; set; }
        public decimal ToTProvision { get; set; }
    }
}