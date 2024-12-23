using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class SkuMasterDataTable : DataTableBaseMaster
    {
        public List<MtSkuMaster> data { get; set; }
    }
}