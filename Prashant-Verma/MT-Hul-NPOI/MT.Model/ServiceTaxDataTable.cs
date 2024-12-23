using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{

    public class ServiceTaxRateMasterDataTable : DataTableBaseMaster
    {
        public List<MtServiceTaxRateMaster> data { get; set; }
    }
}