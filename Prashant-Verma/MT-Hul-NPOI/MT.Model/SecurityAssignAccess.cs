using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class SecurityAssignAccess
    {
        public string PageId { get; set; }
        public string PageName { get; set; }
        public bool IsReadAvailable { get; set ; }
        public bool IsWriteAvailable { get; set; }
        public bool IsExtractAvailable { get; set; }
        public bool IsExecuteAvailable { get; set; }
    }
}
