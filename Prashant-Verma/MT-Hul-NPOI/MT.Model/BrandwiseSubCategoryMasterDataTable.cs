using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class BrandwiseSubCategoryMasterDataTable : DataTableBaseMaster
    {
        public List<MtBrandwiseSubCategoryMaster> data { get; set; }
    }
}