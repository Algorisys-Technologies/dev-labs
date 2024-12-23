using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
   public class UserService
    {

        public List<UserRole> GetAllUser()
        {

            List<UserRole> list = new List<UserRole>();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            request.SqlQuery = "SELECT UserName FROM mtUser";
            dt = smartDataObj.GetData(request);

            foreach (DataRow dr in dt.Rows)
            {
                DbRequest request1 = new DbRequest();
                request1.SqlQuery = "select RoleName from mtRole where Id=(select RoleId from mtUserRole where UserId=(select Id from mtUser where UserName='" + dr[0].ToString() + "'))";
               // select RoleName from mtRole where Id=(select RoleId from mtUserRole where UserId=(select Id from mtUser where UserName='Abhi123'
                UserRole data = new UserRole();
                data.UserName = dr[0].ToString();
                data.RoleName = smartDataObj.ExecuteScalarGetString(request1);
              
                list.Add(data);
            }

            return list;
        }


        public string CreateUserName(string userName,int isLocalUser)
        {
            DataTable dt = new DataTable();
            SmartData smartDataObj = new SmartData();
            DbRequest requestCount = new DbRequest();
            requestCount.SqlQuery = "select count(UserName) from mtUser where UserName='" + userName + "'";
            DbRequest request = new DbRequest();
            dt = smartDataObj.GetData(requestCount);
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }
            string jsonResult = "";

            string pwd = (isLocalUser == 1) ? "123" : "";

            if (userName != "")
            {
                if (recordsCount == 0)
                {
                    request.SqlQuery = "insert into mtUser (Id,UserName,IsActive,IsLocalUser,Password) values('" + Guid.NewGuid() + "','" + userName + "',1," + isLocalUser + ",'"+ pwd + "')";
                    smartDataObj.ExecuteQuery(request);
                    jsonResult = "Users created";

                }
                else
                {
                    jsonResult = "This Users already has been created";

                }

            }
            else
            {
                jsonResult = "Cant create users with null value";
            }


            return jsonResult;

        }


        public string DeleteUserName(string userName)
        {


            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            string jsonResult = "";
            if (userName.ToLower() != "admin")
            {
                request.SqlQuery = "delete from mtUser where UserName='" + userName + "'";
                smartDataObj.ExecuteQuery(request);
                jsonResult = "Users deleted"; 

            }
            else
            {
                jsonResult = "Can not delete current user";

            }

            return jsonResult;

        }


       public string SaveUserRoleName(string userName,string roleName)
        {


            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();
            string jsonResult = "";
            DbRequest requestCount = new DbRequest();
            requestCount.SqlQuery = "select COUNT(UserId) from mtUserRole where UserId=(select Id from mtUser where UserName='"+userName+"')";
            DataTable dt = new DataTable();
            dt = smartDataObj.GetData(requestCount);
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }
            if (userName!= "undefined"||roleName!="undefined")
            {

                   if(recordsCount==0)
                   {
                       //request.SqlQuery = "insert into mtUserRole (RoleName,UserName) values('"+roleName+"','"+userName+"') ";
                       request.SqlQuery = "insert into mtUserRole (Id,RoleId,UserId) values('" + Guid.NewGuid() + "',(select Id from mtRole where RoleName='" + roleName + "'),(select Id from mtUser where UserName='" + userName + "'))";
                       smartDataObj.ExecuteQuery(request);
                      
                   }
                   else
                   {
                      
                      // request.SqlQuery = "update  mtUserRole Set RoleName='"+roleName+"' where UserName='"+userName+"'";
                       request.SqlQuery = "update mtUserRole set RoleId=(select Id from mtRole where RoleName='"+roleName+"') where UserId=(select Id from mtUser where UserName='"+userName+"')";
                       smartDataObj.ExecuteQuery(request);
                     

                   }
                   jsonResult = "RolesUpdated";
           
            }
            else
            {
                jsonResult = "Can not Update roles";

            }

            return jsonResult;
        }
    }
}
