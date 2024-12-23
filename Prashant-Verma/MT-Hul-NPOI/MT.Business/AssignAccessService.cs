using MT.DataAccessLayer;
using MT.Model;
using MT.SessionManager;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class AssignAccessService:BaseService
    {
        public List<SecurityAssignAccess> GetPageRightMaster()
        {
            List<SecurityAssignAccess> pageList = new List<SecurityAssignAccess>();
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "select * from " + SecurityPageConstants.PageRightMaster_TableName + "";
            dt = smartDataObj.GetData(request);
            pageList = Fill_SecurityAssignAccessModel(dt);
            return pageList;
        }


        private List<SecurityAssignAccess> Fill_SecurityAssignAccessModel(DataTable sourceDt)
        {
            List<SecurityAssignAccess> pageList = new List<SecurityAssignAccess>();
            foreach (DataRow dr in sourceDt.Rows)
            {
                SecurityAssignAccess obj = new SecurityAssignAccess();

                obj.PageId = dr["PageId"].ToString();
                obj.PageName = dr["PageName"].ToString();

                string[] pageRights = dr["Rights"].ToString().Split('/');
                obj.IsReadAvailable = (pageRights.Contains("read")) ? true : false;
                obj.IsWriteAvailable = (pageRights.Contains("write")) ? true : false;
                obj.IsExecuteAvailable = (pageRights.Contains("execute")) ? true : false;
                obj.IsExtractAvailable = (pageRights.Contains("extract")) ? true : false;

                pageList.Add(obj);

            }
            return pageList;
        }

        public List<Role> GetRoleList()
        {
            List<Role> roleList = new List<Role>();
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "select * from mtRole";
            dt = smartDataObj.GetData(request);
            roleList = dt.DataTableToList<Role>();
            return roleList;
        }

        public List<RoleWisePageRightsMaster> GetRoleWisePageRights(Guid roleId)
        {
            List<RoleWisePageRightsMaster> roleList = new List<RoleWisePageRightsMaster>();
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "select * from RoleWisePageRightsMaster where RoleId='" + roleId + "'";
            dt = smartDataObj.GetData(request);
            roleList = dt.DataTableToList<RoleWisePageRightsMaster>();
            return roleList;
        }

        public bool UpdateAccessRights(List<RoleWisePageRightsMaster> pageRightList)
        {
            bool isSucces = true;
            try 
            {
                DataTable dt = pageRightList.PropertiesToDataTable();

                SmartData smartDataObj = new SmartData();
                DbRequest request = new DbRequest();
                request.StoredProcedureName = SecurityPageConstants.UpdateRights_SpName;

                request.Parameters = new List<Parameter>();
                Parameter dtParam = new Parameter("@tblPageRightMaster", dt);
                request.Parameters.Add(dtParam);
                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch(Exception ex)
            {
                isSucces = false;
                //throw ex;
            }
            return isSucces;
        }

        public bool CheckForMasterUploadRight(string pageId)
        {
            UserRoleRights userRights = SessionManager<UserRoleRights>.Get("UserData");
            bool isUploadRight = userRights.UserRights.Where(u => u.PageId == pageId).FirstOrDefault().Write;

            return isUploadRight;
        }

        public bool CheckForStepExecuteRight(string pageId)
        {
            UserRoleRights userRights = SessionManager<UserRoleRights>.Get("UserData");
            bool isExecuteRight = userRights.UserRights.Where(u => u.PageId == pageId).FirstOrDefault().Execute;

            return isExecuteRight;
        }

        public bool CheckForStepExtractRight(string pageId)
        {
            UserRoleRights userRights = SessionManager<UserRoleRights>.Get("UserData");
            bool isExtractRight = userRights.UserRights.Where(u => u.PageId == pageId).FirstOrDefault().Extract;

            return isExtractRight;
        }
    }
}
