using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{

    public class AuditTrailReportDataTable : DataTableBaseMaster
    {
        public List<AuditTrailModel> data { get; set; }
    }
}