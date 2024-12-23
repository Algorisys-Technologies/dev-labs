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
   public class ChainNameService
    {
       public List<MtChainNameMaster> GetChainNameData()
       {

           List<MtChainNameMaster> list = new List<MtChainNameMaster>();



           SmartData smartDataObj = new SmartData();
           DataTable dt = new DataTable();
           DbRequest request = new DbRequest();

           request.SqlQuery = "SELECT ChainName,IsHuggiesAppl FROM mtChainNameMaster";

           dt = smartDataObj.GetData(request);



           foreach (DataRow dr in dt.Rows)
           {
               MtChainNameMaster obj = new MtChainNameMaster();

               obj.ChainName = dr["ChainName"].ToString();
               //obj.IsHuggiesAppl = Convert.ToBoolean(dr["IsHuggiesAppl"].ToString())=="True"?"Yes":"NO";
               obj.IsHuggiesAppl = dr["IsHuggiesAppl"].ToString()=="True" ? "YES" : "NO";

               list.Add(obj);

           }

           return list;
            


       }


       public BaseResponse AddChainName(string chainName,bool IsHuggiesAppl,string user)
       {
          
           var response = new BaseResponse();

           bool isSuccess = false;
           string message = string.Empty;
           DbRequest requestCount = new DbRequest();
           DataTable dt = new DataTable();
           try
           {
               requestCount.SqlQuery = "select count(ChainName) from mtChainNameMaster where ChainName='" + chainName + "'";
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
                   message = "Data already exist with " + chainName + " ChainName";
               }
               else
               {
                   DbRequest request1 = new DbRequest();
                   //request1.SqlQuery = "insert into mtChainNameMaster values('" + chainName + "','" + IsHuggiesAppl + "','" + DateTime.Now + "','admin',NULL,NULL,'I')";
                    
                    request1.SqlQuery = "insert into mtChainNameMaster values('" + chainName + "','" + IsHuggiesAppl + "','" + Convert.ToDateTime(DateTime.Now).ToString("yyyy-MM-dd")+ "','"+user+"',NULL,NULL,'I')";
                    SmartData smartDataObj1 = new SmartData();
                   smartDataObj1.ExecuteNonQuery(request1);
                   message = "Added new ChainName successfully";

               }
               isSuccess = true;
              
           }
           catch(Exception ex)
           {

               isSuccess = false;
               message = MessageConstants.Error_Occured + ex.Message;

           }

           response.IsSuccess =isSuccess;
           response.MessageText = message;
           return response;

           
       }

       public string DeleteChainName(string chainName,string user)
       {
           string msg = "";
           DbRequest request = new DbRequest();
           SmartData smartDataObj = new SmartData();

           request.StoredProcedureName = MasterConstants.ChainName_Master_DleteSP_Name;

           request.Parameters = new List<Parameter>();

           Parameter updatedBy = new Parameter("@updatedBy",user);
           Parameter chainNameToDelete = new Parameter("@chainName", chainName);
          
           request.Parameters.Add(updatedBy);
           request.Parameters.Add(chainNameToDelete);
          
           smartDataObj.ExecuteStoredProcedure(request);

           msg = "ChainName Deleted  successfully";
           return msg;


       }


       public void EditChainNameMaster(string oldChainName, string newChainName,string isHuggiesAppl,string user)
       {

           //string isHuggiesAppl1 = "";
           //isHuggiesAppl1 = isHuggiesAppl=="Yes" ? "TRUE" : "FALSE";
           DbRequest request = new DbRequest();
           SmartData smartDataObj = new SmartData();

           request.StoredProcedureName = MasterConstants.MTChainName_Master_UpdateSP_Name;
           request.Parameters = new List<Parameter>();

           Parameter updatedBy = new Parameter("@updatedBy",user);
           Parameter newValue = new Parameter("@newChainName",newChainName);
           Parameter oldValue = new Parameter("@oldChainName",oldChainName);
           Parameter huggies= new Parameter("@isHuggiesAppl", isHuggiesAppl);
           request.Parameters.Add(updatedBy);
           request.Parameters.Add(newValue);
           request.Parameters.Add(oldValue);
           request.Parameters.Add(huggies);
           smartDataObj.ExecuteStoredProcedure(request);


       }
    }
}
