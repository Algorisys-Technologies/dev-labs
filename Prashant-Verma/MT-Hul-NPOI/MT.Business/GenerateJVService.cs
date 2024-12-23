using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class GenerateJVService : BaseService
    {

        //public DataSet GetJVToDownload(string currentMOC, string tableView)
        //{
        //    DataSet ds = new DataSet();
        //    SqlConnection connection = new SqlConnection(connectionString);

        //    DataTable dt1 = new DataTable();
        //    DataTable dt2 = new DataTable();
        //    DbRequest request = new DbRequest();

        //    request.SqlQuery = "Select * from " + tableView + " where MOC=" + currentMOC;
        //    dt1 = smartDataObj.GetData(request);
        //    dt2 = dt1.Copy();
        //    ds.Tables.Add(dt2);
        //    return ds;
        //}


        public List<OnInvoiceJV> FilterJVData(ref int recordFiltered, int start, int length, string search, string sortColumnName, string sortDirection, string currentReportMOC, string tableView)
        {
            List<OnInvoiceJV> list = new List<OnInvoiceJV>();
            string orderByTxt = "";

            if (sortDirection == "asc")
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }
            else
            {
                orderByTxt = "ORDER BY " + sortColumnName + " " + sortDirection;
            }

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            int recordupto = start + length;
            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from " + tableView + " where MOC='" + currentReportMOC + "') a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM (select ROW_NUMBER()OVER (" + orderByTxt + ") AS RowNumber,* from " + tableView + " WHERE FREETEXT (*, '" + search + "') AND MOC='" + currentReportMOC + "') a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            foreach (DataRow dr in dt.Rows)
            {
                OnInvoiceJV obj = new OnInvoiceJV();

                obj.MOC = dr["MOC"].ToString();
                obj.GLAccount = dr["GLAccount"].ToString();
                obj.Amount = dr["Amount"].ToString() == "" ? 0 : Convert.ToDecimal(dr["Amount"]);
                obj.BranchCode = dr["BranchCode"].ToString();
                obj.InternalOrder = dr["InternalOrder"].ToString();
                obj.GLItemText = dr["GLItemText"].ToString();
                obj.PMHBrandCode = dr["PMHBrandCode"].ToString();
                obj.DistrChannel = dr["DistrChannel"].ToString();
                obj.ProfitCenter = dr["ProfitCenter"].ToString();
                obj.COPACustomer = dr["COPACustomer"].ToString();


                list.Add(obj);

            }
            return list;
        }

       
    }
}
