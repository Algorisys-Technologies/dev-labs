using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class ColumnDetail
    {
        public string ColumnName { get; set; }
        public string OldValue { get; set; }
        public string NewValue { get; set; }
        public bool IsUnique { get; set; }
    }
    public class AuditTrailModel
    {
        public List<ColumnDetail> ListColumnDetails { get; set; }
        public DateTime UpdatedDate { get; set; }
        public string UpdatedBy { get; set; }
        public string Operation { get; set; }
    }
}
