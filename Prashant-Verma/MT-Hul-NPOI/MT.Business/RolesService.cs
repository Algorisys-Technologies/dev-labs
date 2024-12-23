using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web.Security;

namespace MT.Business
{
    public class RolesService
    {
        public List<Role> GetAllRole()
        {

            List<Role> list = new List<Role>();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            request.SqlQuery = "SELECT RoleName  FROM mtRole";
            dt = smartDataObj.GetData(request);

            foreach (DataRow dr in dt.Rows)
            {
                Role data = new Role();
                data.RoleName = dr[0].ToString();

                list.Add(data);
            }          

            return list;
        }


        public string CreateRoleName(string roleName)
        {
            DataTable dt = new DataTable();
            SmartData smartDataObj = new SmartData();
            DbRequest requestCount = new DbRequest();
            requestCount.SqlQuery = "select count(RoleName) from mtRole where RoleName='" + roleName+ "'";
            DbRequest request = new DbRequest();
            dt = smartDataObj.GetData(requestCount);
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }
            string jsonResult = "";


            if (roleName !="")
            {
                if (recordsCount == 0)
                {
                    request.SqlQuery = "insert into mtRole (Id,RoleName) values('"+Guid.NewGuid()+"','" + roleName + "')";
                    smartDataObj.ExecuteQuery(request);
                    jsonResult = "Roles created";

                }
                else
                {
                    jsonResult = "This roles already has been created";

                }

            }
            else
            {
                jsonResult = "Cant create users with null value";
            }
            

            return jsonResult;

        }


        public string DeleteRoleName(string roleName)
        {


            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            string jsonResult = "";
            if (roleName.ToLower() != "admin")
            {
                request.SqlQuery = "delete from mtRole where Rolename='" + roleName + "'";
                smartDataObj.ExecuteQuery(request);
                jsonResult = "Roles deleted";

            }
            else
            {
                jsonResult = "Can not delete current roles";

            }

            return jsonResult;

        }

    }
}
