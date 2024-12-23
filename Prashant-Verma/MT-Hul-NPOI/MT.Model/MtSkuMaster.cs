using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{
    public class MtSkuMaster
    {
        public int Id { get; set; }
        public string BasepackCode { get; set; }
        public string TaxCode { get; set; }
        public string CreatedAt { get; set; }
        public string CreatedBy { get; set; }
        public string UpdatedAt { get; set; }
        public string UpdatedBy { get; set; }
        public string Operation { get; set; }
    }
}