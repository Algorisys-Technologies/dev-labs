using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{

    public class SalesTaxMasterDataTable : DataTableBaseMaster
    {
        public List<MtSalesTaxMaster> data { get; set; }
    }
}