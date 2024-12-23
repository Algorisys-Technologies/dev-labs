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
   public class OnInVoiceConfigService
    {
        public List<MTOnInVoiceConfigMaster> GetOnInVoiceConfigData()
        {

            List<MTOnInVoiceConfigMaster> list = new List<MTOnInVoiceConfigMaster>();



            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT StateCode,IsNetSalesValueAppl FROM mtOnInvoiceValueConfig";

            dt = smartDataObj.GetData(request);

            

            foreach (DataRow dr in dt.Rows)
            {
                MTOnInVoiceConfigMaster obj = new MTOnInVoiceConfigMaster();

                obj.StateCode = dr["StateCode"].ToString();
                //obj.IsHuggiesAppl = Convert.ToBoolean(dr["IsHuggiesAppl"].ToString())=="True"?"Yes":"NO";
                obj.IsNetSaleAppl = dr["IsNetSalesValueAppl"].ToString() == "True" ? "YES" : "NO";

                list.Add(obj);

            }

            return list;



        }


        public string AddOnInVoiceConfig(string stateCode, bool isNetSaleAppl,string user)
        {
            string msg = "";


            DbRequest requestCount = new DbRequest();
            DataTable dt = new DataTable();

            requestCount.SqlQuery = "select count(StateCode) from mtOnInvoiceValueConfig where StateCode='" + stateCode + "'";
            SmartData smartDataObj = new SmartData();
            DbRequest request = new DbRequest();
            dt = smartDataObj.GetData(requestCount);
            int recordsCount = 0;
            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }
            if (recordsCount != 0)
            {
                msg = "Data already exist with " + stateCode + " ChainName";
            }
            else
            {
                DbRequest request1 = new DbRequest();
                //request1.SqlQuery = "insert into mtOnInvoiceValueConfig values('" + stateCode + "','" + isNetSaleAppl + "','" + DateTime.Now + "','admin',NULL,NULL,'I')";
                
                request1.SqlQuery = "insert into mtOnInvoiceValueConfig values('" + stateCode + "','" + isNetSaleAppl + "','" + Convert.ToDateTime(DateTime.Now).ToString("yyyy-MM-dd") + "','"+user+"',NULL,NULL,'I')";
                SmartData smartDataObj1 = new SmartData();
                smartDataObj1.ExecuteNonQuery(request1);
                msg = "Added new ChainName successfully";


            }
            return msg;
        }

        public string DeleteOnInVoiceConfig(string stateCode,string user)
        {
            string msg = "";
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            request.StoredProcedureName = MasterConstants.OnInVoiceConfig_Master_DleteSP_Name;

            request.Parameters = new List<Parameter>();

            Parameter updatedBy = new Parameter("@updatedBy",user);
            Parameter stateCodeToDelete = new Parameter("@stateCode", stateCode);

            request.Parameters.Add(updatedBy);
            request.Parameters.Add(stateCodeToDelete);

            smartDataObj.ExecuteStoredProcedure(request);

            msg = "StateCode Deleted  successfully";
            return msg;


        }


        public void EditOnInVoiceConfigMaster(string oldStateCode, string newStateCode, string isNetSaleAppl,string user)
        {

            //string isHuggiesAppl1 = "";
            //isHuggiesAppl1 = isHuggiesAppl=="Yes" ? "TRUE" : "FALSE";
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            request.StoredProcedureName = MasterConstants.MTOnINnVoiceConfig_Master_UpdateSP_Name;
            request.Parameters = new List<Parameter>();

            Parameter updatedBy = new Parameter("@updatedBy", user);
            Parameter newValue = new Parameter("@newStateCode", newStateCode);
            Parameter oldValue = new Parameter("@oldStateCode", oldStateCode);
            Parameter netSale = new Parameter("@isNetSaleAppl", isNetSaleAppl);
            request.Parameters.Add(updatedBy);
            request.Parameters.Add(newValue);
            request.Parameters.Add(oldValue);
            request.Parameters.Add(netSale);
            smartDataObj.ExecuteStoredProcedure(request);


        }
    }
}
