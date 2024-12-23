using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.DataAccessLayer
{
    public class DbRequest
    {
        public List<Parameter> Parameters { get; set; }

        public string SqlQuery { get; set; }

        public string StoredProcedureName { get; set; }
    }
}
