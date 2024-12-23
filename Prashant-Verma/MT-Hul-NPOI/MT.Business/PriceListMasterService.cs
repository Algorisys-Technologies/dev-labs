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
   public class PriceListMasterService
    {

        public List<MtPriceListMaster> GetPriceListData()
        {

            List<MtPriceListMaster> list = new List<MtPriceListMaster>();



            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT PriceList FROM mtPriceListMaster";

            dt = smartDataObj.GetData(request);



            foreach (DataRow dr in dt.Rows)
            {
                MtPriceListMaster obj = new MtPriceListMaster();

                obj.PriceList = dr["PriceList"].ToString();
                list.Add(obj);

            }

            return list;



        }


        public string AddPriceList(string priceList,string user)
        {
            string msg = "";


            DbRequest requestCount = new DbRequest();
            DataTable dt = new DataTable();

            requestCount.SqlQuery = "select count(PriceList) from mtPriceListMaster where PriceList='" + priceList + "'";
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
                msg = "Data already exist with " + priceList + " PriceList";
            }
            else
            {
                DbRequest request1 = new DbRequest();
                //request1.SqlQuery = "insert into mtPriceListMaster values('" + priceList + "','" + DateTime.Now + "','admin',NULL,NULL,'I')";
               
                 request1.SqlQuery = "insert into mtPriceListMaster values('" + priceList + "','" + Convert.ToDateTime(DateTime.Now).ToString("yyyy-MM-dd") + "','"+user+"',NULL,NULL,'I')";
                SmartData smartDataObj1 = new SmartData();
                smartDataObj1.ExecuteNonQuery(request1);
                msg = "Added new PriceList successfully";


            }
            return msg;
        }

        public string DeletePriceList(string priceList,string user)
        {
            string msg = "";
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            request.StoredProcedureName = MasterConstants.PriceList_Master_DleteSP_Name;

            request.Parameters = new List<Parameter>();

            Parameter updatedBy = new Parameter("@updatedBy",user);
            Parameter priceListToDelete = new Parameter("@priceList", priceList);

            request.Parameters.Add(updatedBy);
            request.Parameters.Add(priceListToDelete);

            smartDataObj.ExecuteStoredProcedure(request);

            msg = "PriceList Deleted  successfully";
            return msg;


        }


        public void EditPriceListMaster(string oldPriceList, string newPriceList,string user)
        {

            //string isHuggiesAppl1 = "";
            //isHuggiesAppl1 = isHuggiesAppl=="Yes" ? "TRUE" : "FALSE";
            DbRequest request = new DbRequest();
            SmartData smartDataObj = new SmartData();

            request.StoredProcedureName = MasterConstants.MTPriceList_Master_UpdateSP_Name;
            request.Parameters = new List<Parameter>();

            Parameter updatedBy = new Parameter("@updatedBy",user);
            Parameter newValue = new Parameter("@newPriceList", newPriceList);
            Parameter oldValue = new Parameter("@oldPriceList", oldPriceList);
            
            request.Parameters.Add(updatedBy);
            request.Parameters.Add(newValue);
            request.Parameters.Add(oldValue);
            
            smartDataObj.ExecuteStoredProcedure(request);


        }

    }
}
