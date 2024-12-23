using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class CustomerGroupMasterDataTable : DataTableBaseMaster
    {
        public List<MtCustomerGroupMaster> data { get; set; }
    }
}