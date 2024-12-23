using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Data;
using System.DirectoryServices;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MT.Utility;
using MT.SessionManager;
using System.DirectoryServices.AccountManagement;

namespace MT.Business
{
    public class LoginService:BaseService
    {
        public bool AuthenticateUser(string domain, string username, string password, string LdapPath, out string Errmsg)
        {

            Errmsg = "";

            string domainAndUsername = domain + @"\" + username;

            DirectoryEntry entry = new DirectoryEntry(LdapPath, domainAndUsername, password);

            try
            {

                // Bind to the native AdsObject to force authentication.

                Object obj = entry.NativeObject;

                //--------------------------ByPass This Code as search is not working---------------------------------Start

                ////DirectorySearcher search = new DirectorySearcher(entry);

                ////search.Filter = "(SAMAccountName=" + username + ")";

                ////search.PropertiesToLoad.Add("cn");

                ////SearchResult result = search.FindOne();

                ////if (null == result)
                ////{

                ////    return false;

                ////}
                
                ////// Update the new path to the user in the directory

                ////LdapPath = result.Path;

                ////string _filterAttribute = (String)result.Properties["cn"][0];

                //--------------------------ByPass This Code as search is not working---------------------------------End


            }

            catch (Exception ex)
            {

                Errmsg = ex.Message;

                return false;

                throw new Exception("Error authenticating user." + ex.Message);

            }

            return true;

        }

        public bool DoesUserExist(string userName)
        {
            using (var domainContext = new PrincipalContext(ContextType.Domain, "s1.ms.unilever.com"))
            {
                using (var foundUser = UserPrincipal.FindByIdentity(domainContext, IdentityType.SamAccountName, userName))
                {
                    return foundUser != null;
                }
            }
        }

        public bool AuthenticateLocalUser(string userName,string password)
        {
            bool isValidUser = false;
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT TOP 1 UserName FROM mtUser WHERE IsLocalUser='true' AND UserName = '" + userName + "' AND Password='" + password + "'";
            dt = smartDataObj.GetData(request);
            if (dt.Rows.Count > 0) 
            {
                isValidUser = true;
            }
            return isValidUser;
        }

        public void SaveUserSession(string userName)
        {
            UserRoleRights userRoleRightsModel = new UserRoleRights();
            userRoleRightsModel.UserId = userName;
            userRoleRightsModel.UserRole = GetUserRoleByUserName(userName);
            userRoleRightsModel.UserRights = GetRightsByRoleId(userRoleRightsModel.UserRole.Id);

            SessionManager<UserRoleRights>.Add("UserData", userRoleRightsModel);


            
        }

        private Role GetUserRoleByUserName(string userName)
        {
            Role userRole = new Role();
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT r.Id, r.RoleName FROM [mtRole] r JOIN mtUserRole I ON r.Id = I.RoleId JOIN mtUser P ON p.Id = I.UserId where p.UserName='" + userName + "'";
            dt = smartDataObj.GetData(request);
            if(dt!=null)
            {
                userRole = dt.DataTableToList<Role>().FirstOrDefault();
            }
            return userRole;
        }

        private List<RoleWisePageRightsMaster> GetRightsByRoleId(Guid roleId)
        {
            List<RoleWisePageRightsMaster> pageRights = new List<RoleWisePageRightsMaster>();
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT * from RoleWisePageRightsMaster where RoleID='" + roleId + "'";
            dt = smartDataObj.GetData(request);
            if (dt != null)
            {
                pageRights = dt.DataTableToList<RoleWisePageRightsMaster>();
            }
            return pageRights;
        }

        private DirectoryEntry GetDirectoryObject(string domain, string username, string password, string LdapPath)
        {
            string domainAndUsername = domain + @"\" + username;
            DirectoryEntry oDE;
            oDE = new DirectoryEntry(LdapPath, domainAndUsername, password, AuthenticationTypes.Secure);
            return oDE;
        }

        public DirectoryEntry GetUser(string domain, string username, string password, string LdapPath)
        {
            DirectoryEntry de = GetDirectoryObject(domain, username, password, LdapPath);
            DirectorySearcher deSearch = new DirectorySearcher();
            deSearch.SearchRoot = de;

            deSearch.Filter = "(&(objectClass=user)(SAMAccountName=" + username + "))";
            deSearch.SearchScope = SearchScope.Subtree;
            SearchResult results = deSearch.FindOne();

            if (!(results == null))
            {
                de = new DirectoryEntry(results.Path, "radhika.pillai@unilever.com", "Unilever@1234", AuthenticationTypes.Secure);
                return de;
            }
            else
            {
                return null;
            }
        }

        public bool DoesLdapUserExistOnLocalServer(string userName)
        {
            bool isValidUser = false;
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT TOP 1 UserName FROM mtUser WHERE IsLocalUser='false' AND UserName = '" + userName + "'";
            dt = smartDataObj.GetData(request);
            if (dt.Rows.Count > 0)
            {
                isValidUser = true;
            }
            return isValidUser;
        }
    }
}
