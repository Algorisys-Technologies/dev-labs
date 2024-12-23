using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{

    public class MTTierBasedTOTMasterDataTable : DataTableBaseMaster
    {
        public List<MTTierBasedTOTMaster> data { get; set; }
    }
}