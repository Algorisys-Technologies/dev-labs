using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class ReportResponse:BaseResponse
    {

        public DataTable  ReportData { get; set; }

        public ReportRequest  ReportRequest { get; set; }
    }
}
