using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class UserRoleRights
    {
        public UserRoleRights()
        {
            UserRights = new List<RoleWisePageRightsMaster>();
        }
        public string UserId { get; set; }
        public Role UserRole { get; set; }
        public List<RoleWisePageRightsMaster> UserRights { get; set; }
    }
}
