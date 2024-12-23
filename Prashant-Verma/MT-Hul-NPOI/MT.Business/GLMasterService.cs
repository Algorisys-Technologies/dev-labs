using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
   public class GLMasterService
    {
        public void EditGLMaster(string final, string intial,string user)
        {
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            request.StoredProcedureName = MasterConstants.MTGL_Master_UpdateSP_Name;

            request.Parameters = new List<Parameter>();

            Parameter updatedBy = new Parameter("@updatedBy",user);
            Parameter newValue = new Parameter("@newRecord", final);
            Parameter oldValue = new Parameter("@oldRecord", intial);
            request.Parameters.Add(updatedBy);
            request.Parameters.Add(newValue);
            request.Parameters.Add(oldValue);
            smartDataObj.ExecuteStoredProcedure(request);


        }
        public List<MtGLMaster> AjaxGetGLData()        {

            List<MtGLMaster> list = new List<MtGLMaster>();



            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT DbCr,GLAccount FROM mtGLMaster ";

            dt = smartDataObj.GetData(request);



            foreach (DataRow dr in dt.Rows)
            {
                MtGLMaster obj = new MtGLMaster();

                obj.DbCr = dr["DbCr"].ToString();
                obj.GLAccount = dr["GLAccount"].ToString();

                list.Add(obj);

            }

            return list;
            



        }

    }
}
