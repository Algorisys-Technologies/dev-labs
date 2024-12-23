using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.DataAccessLayer
{
    public class Parameter
    {
        public Parameter(string name, object value)
        {
            this.ParameterName = name;
            this.ParameterValue = value;
        }
        public string ParameterName { get; set; }

        public object ParameterValue { get; set; }

    }
}
