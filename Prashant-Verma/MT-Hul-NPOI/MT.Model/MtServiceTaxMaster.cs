using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MtServiceTaxRateMaster
    {
        public int Id { get; set; }
        public string ChainName { get; set; }
        public string GroupName { get; set; }
        public string Rate { get; set; }
    }
}