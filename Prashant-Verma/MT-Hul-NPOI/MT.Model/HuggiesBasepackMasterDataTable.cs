using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class HuggiesBasepackMasterDataTable:DataTableBaseMaster
    {
        public List<MtHuggiesBasepackMaster> data { get; set; }
    }
}