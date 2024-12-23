using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class OutletMasterDataTable:DataTableBaseMaster
    {
        public List<MtOutletMaster> data { get; set; }

    }
}