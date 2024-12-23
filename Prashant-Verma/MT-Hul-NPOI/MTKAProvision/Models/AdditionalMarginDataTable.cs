using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MTKAProvision.Models
{

    public class AdditionalMarginMasterDataTable : DataTableBaseMaster
    {
        public List<MtAdditionalMarginMaster> data { get; set; }
    }
}