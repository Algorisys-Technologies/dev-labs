using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.DataAccessLayer
{
    public enum DatabaseType
    {
        Access,
        SQLServer,
        Oracle
        // any other data source type
    }

    public enum ParameterType
    {
        Integer,
        Char,
        VarChar
        // define a common parameter type set
    }
}
