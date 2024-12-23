using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class BaseResponse
    {
        public bool IsSuccess { get; set; }

        public string MessageText { get; set; }
    }
}
