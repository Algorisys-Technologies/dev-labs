using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class ReportColumn
    {
        public int Sequence { get; set; }
        public string ColumnName { get; set; }
        public bool IsValueColumn { get; set; }
        public string DisplayName { get; set; }
        public string ColumnValue { get; set; }
    }
}
