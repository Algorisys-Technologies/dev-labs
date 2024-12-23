using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{

    public class SecSalesReportDataTable : DataTableBaseMaster
    {
        public List<MtSecSalesReport> data { get; set; }
    }
}