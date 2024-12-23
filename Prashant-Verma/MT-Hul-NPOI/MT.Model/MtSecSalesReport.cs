using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MtSecSalesReport
    {
        public string CustomerCode { get; set; }
        public string CustomerName { get; set; }
        public string OutletCategoryMaster { get; set; }
        public string BasepackCode { get; set; }
        public string BasepackName { get; set; }
        public string PMHBrandCode { get; set; }
        public string PMHBrandName { get; set; }
        public string SalesSubCat { get; set; }
        public string PriceList { get; set; }
        public string HulOutletCode { get; set; }
        public string HulOutletCodeName { get; set; }
        public string BranchCode { get; set; }
        public string BranchName { get; set; }
        public string MOC { get; set; }
        public string ClusterCode { get; set; }
        public string ClusterName { get; set; }
        public string OutletTier { get; set; }
        public decimal TotalSalesValue { get; set; }
        public decimal SalesReturnValue { get; set; }
        public decimal NetSalesValue { get; set; }
        public decimal NetSalesQty { get; set; }
        public string OutletSecChannel { get; set; }
    }
}