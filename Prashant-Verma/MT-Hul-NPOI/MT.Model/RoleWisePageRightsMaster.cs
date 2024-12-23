using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class RoleWisePageRightsMaster
    {
        public Guid RoleId { get; set; }
        public string PageId { get; set; }
        public bool Read { get; set; }
        public bool Write { get; set; }
        public bool Extract { get; set; }
        public bool Execute { get; set; }
    }
}
