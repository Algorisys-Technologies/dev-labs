using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class ReportRequest
    {
        public List<ReportColumn> Columns { get; set; }
        //public List<string> ValueColumns { get; set; }

        public List<ReportColumn> ExpandedColumns { get; set; }

        public List<ReportColumn> CollapsedColumns { get; set; }

        public List<ReportColumn> TotalToBeShownColumns { get; set; }

        public List<ReportColumn> ColumnsToFilter { get; set; }

        public string TableOrViewName { get; set; }

        public int CollapseCol { get; set; }

        public ReportRequest()
        {
            CollapseCol = -1;
            ExpandedColumns = new List<ReportColumn>();
            CollapsedColumns = new List<ReportColumn>();
            TotalToBeShownColumns = new List<ReportColumn>();
            ColumnsToFilter = new List<ReportColumn>();
        }


    }
}
