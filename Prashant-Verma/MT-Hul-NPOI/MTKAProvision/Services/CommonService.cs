using MT.DataAccessLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Utility
{
   public class CommonService
    {
        SmartData smartDataObj = new SmartData();
        public string connectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;

        public int GetTotalRowsCount(string tableName, string search)
        {
            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            if (string.IsNullOrEmpty(search))
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtServiceTaxRateMaster", connection);
                request.SqlQuery = "Select Count(*) from " + tableName;
                dt = smartDataObj.GetData(request);

            }
            else
            {
                //dt = Ado.GetDataTable("Select Count(*) from mtServiceTaxRateMaster WHERE FREETEXT (*, '" + search + "')", connection);
                request.SqlQuery = "Select Count(*) from " + tableName + " WHERE FREETEXT (*, '" + search + "')";
                dt = smartDataObj.GetData(request);
            }
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            return recordsCount;
        }
    }
}
