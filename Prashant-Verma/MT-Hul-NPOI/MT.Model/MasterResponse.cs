using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class MasterResponse:BaseResponse
    {
        public DataTable Data { get; set; }
    }
}
