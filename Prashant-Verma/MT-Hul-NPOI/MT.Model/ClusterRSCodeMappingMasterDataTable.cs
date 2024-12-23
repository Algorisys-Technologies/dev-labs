using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class ClusterRSCodeMappingMasterDataTable:DataTableBaseMaster
    {
        public List<MtClusterRSCodeMappingMaster> data { get; set; }
    }
}