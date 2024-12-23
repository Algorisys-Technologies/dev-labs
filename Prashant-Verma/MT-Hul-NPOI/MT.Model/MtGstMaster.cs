using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class MtGstMaster
    {
        public Guid Id { get; set; }
        public string BasepackCode { get; set; }
        public decimal GstRate { get; set; }
        public string CreatedAt { get; set; }
        public string CreatedBy { get; set; }
        public string UpdatedAt { get; set; }
        public string UpdatedBy { get; set; }
        public string Operation { get; set; }
    }
}
