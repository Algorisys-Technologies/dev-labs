using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class AuditTrailReportService : BaseService
    {
       
        public DataTable GetNewAuditTrailDataTable(List<AuditTrailModel> AuditTrailData)
        {
            int count = 1;
            DataTable dt = new DataTable();
            dt.Clear();
            dt.Columns.Add("SrNo");

            var ColumnDetailsList = AuditTrailData[0].ListColumnDetails;
            foreach (var columnItem in ColumnDetailsList)
            {
                dt.Columns.Add(columnItem.ColumnName);
            }
            dt.Columns.Add("Operation");
            dt.Columns.Add("Updated By");
            dt.Columns.Add("Updated Date");

            foreach (var recordItem in AuditTrailData)
            {
                dynamic auditTrailObject = new ExpandoObject();
                IDictionary<string, object> auditTrailxUnderlyingObject = auditTrailObject;

                auditTrailxUnderlyingObject.Add("SrNo", count);
                foreach (var colItem in recordItem.ListColumnDetails)
                {
                    if (colItem.IsUnique == false)
                    {
                        auditTrailxUnderlyingObject.Add(colItem.ColumnName, "Old Value: " + colItem.OldValue + "\r\n" + " New Value: " + colItem.NewValue);
                    }
                    else
                    {
                        auditTrailxUnderlyingObject.Add(colItem.ColumnName, colItem.OldValue);
                    }
                }
                auditTrailxUnderlyingObject.Add("Operation", recordItem.Operation);
                auditTrailxUnderlyingObject.Add("Updated By", recordItem.UpdatedBy);
                auditTrailxUnderlyingObject.Add("Updated Date", recordItem.UpdatedDate);
                dt.Rows.Add(auditTrailxUnderlyingObject.Values.ToArray());
                count++;
            }
            return dt;
        }
        public List<AuditTrailModel> AuditTrailData(string search, int pageNo)
        {

            List<AuditTrailModel> list = new List<AuditTrailModel>();

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            int start = 0;
            if (pageNo > 1)
            {
                start = ((pageNo - 1) * 50) + 1;
            }
            int recordupto = pageNo * 50;
            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT * FROM   (select ROW_NUMBER()OVER( order by UpdatedDate desc )  AS RowNumber, * from mtAuditTrailMasterData ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM   (select ROW_NUMBER()OVER( order by UpdatedDate desc )  AS RowNumber, * from mtAuditTrailMasterData  WHERE " + search + " ) a WHERE RowNumber BETWEEN " + start + " AND " + recordupto;
                //request.SqlQuery = "SELECT * FROM  mtAuditTrailMasterData  WHERE " + search + " order by UpdatedDate desc";
                dt = smartDataObj.GetData(request);
            }

            foreach (DataRow dr in dt.Rows)
            {
                AuditTrailModel obj = new AuditTrailModel();
                string oprvalue = "";
                if (dr["Operation"].ToString() == "D")
                    oprvalue = "Delete";
                else
                    oprvalue = "Update";
                obj.Operation = oprvalue;
                obj.UpdatedBy = dr["UpdatedBy"].ToString();
                obj.UpdatedDate = Convert.ToDateTime(dr["UpdatedDate"]);
                obj.ListColumnDetails = columnDetailList(dr["Data"].ToString());

                list.Add(obj);
            }
            return list;
        }
        public List<AuditTrailModel> AuditTrailGetAllData(string search)
        {

            List<AuditTrailModel> list = new List<AuditTrailModel>();

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT * FROM  mtAuditTrailMasterData  WHERE " + search + " order by UpdatedDate desc";
            dt = smartDataObj.GetData(request);


            foreach (DataRow dr in dt.Rows)
            {
                AuditTrailModel obj = new AuditTrailModel();
                string oprvalue = "";
                if (dr["Operation"].ToString() == "D")
                    oprvalue = "Delete";
                else
                    oprvalue = "Update";
                obj.Operation = oprvalue;
                obj.UpdatedBy = dr["UpdatedBy"].ToString();
                obj.UpdatedDate = Convert.ToDateTime(dr["UpdatedDate"]);
                obj.ListColumnDetails = columnDetailList(dr["Data"].ToString());

                list.Add(obj);
            }
            return list;
        }
        public int AuditTrailGetCountAllData(string search)
        {

            List<AuditTrailModel> list = new List<AuditTrailModel>();

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT * FROM  mtAuditTrailMasterData  WHERE " + search + " order by UpdatedDate desc";
            dt = smartDataObj.GetData(request);


            return dt.Rows.Count;
        }

        public List<ColumnDetail> columnDetailList(string columndata)
        {
            List<ColumnDetail> columnlist = new List<ColumnDetail>();

            var listofcol = columndata.Split('^');
            foreach (var colitem in listofcol)
            {
                ColumnDetail cellValueDetail = new ColumnDetail();
                var celldata = colitem.Split(':');
                var cellvalue = celldata[1].Split('|');

                if (cellvalue.Length > 1)
                {
                    cellValueDetail.NewValue = cellvalue[1];
                    cellValueDetail.IsUnique = false;
                }
                else
                {
                    cellValueDetail.IsUnique = true;
                }
                cellValueDetail.ColumnName = celldata[0];
                cellValueDetail.OldValue = cellvalue[0];
                columnlist.Add(cellValueDetail);
            }
            return columnlist;
        }
        public AuditTrailModel AuditTrailGetHeading(string search)
        {

            AuditTrailModel list = new AuditTrailModel();

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT top(1)* FROM  mtAuditTrailMasterData ";
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT  top(1)* FROM   mtAuditTrailMasterData WHERE " + search + " order by UpdatedDate desc";
                dt = smartDataObj.GetData(request);
            }
            AuditTrailModel obj = new AuditTrailModel();
            if (dt.Rows.Count != 0)
            {
                string oprvalue = "";
                if (dt.Rows[0]["Operation"].ToString() == "D")
                    oprvalue = "Delete";
                else
                    oprvalue = "Update";
                obj.Operation = oprvalue;
                obj.UpdatedBy = dt.Rows[0]["UpdatedBy"].ToString();
                obj.UpdatedDate = Convert.ToDateTime(dt.Rows[0]["UpdatedDate"]);
                obj.ListColumnDetails = columnDetailList(dt.Rows[0]["Data"].ToString());

            }
            return obj;
        }
        public DataTable AuditTrailPageWiseData(string search)
        {

            List<AuditTrailModel> list = new List<AuditTrailModel>();

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT * FROM  mtAuditTrailMasterData ";
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT * FROM   mtAuditTrailMasterData WHERE " + search + " order by UpdatedDate desc";
                dt = smartDataObj.GetData(request);
            }

            foreach (DataRow dr in dt.Rows)
            {
                AuditTrailModel obj = new AuditTrailModel();
                string oprvalue = "";
                if (dr["Operation"].ToString() == "D")
                    oprvalue = "Delete";
                else
                    oprvalue = "Update";
                obj.Operation = oprvalue;
                obj.UpdatedBy = dr["UpdatedBy"].ToString();
                obj.UpdatedDate = Convert.ToDateTime(dr["UpdatedDate"]);
                obj.ListColumnDetails = columnDetailList(dr["Data"].ToString());

                list.Add(obj);
            }
            return dt;
        }
        public int GetRecordCountofAuditTrail(string search)
        {
            int recount = 0;
            AuditTrailModel list = new AuditTrailModel();

            SqlConnection connection = new SqlConnection(connectionString);
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "SELECT count(*) FROM  mtAuditTrailMasterData ";
                dt = smartDataObj.GetData(request);
            }
            else
            {
                request.SqlQuery = "SELECT  count(*) FROM   mtAuditTrailMasterData WHERE " + search ;
                dt = smartDataObj.GetData(request);
            }
            if (dt.Rows[0] != null)
            {
                recount = Convert.ToInt32(dt.Rows[0][0]);
            }
            return recount;
        }
    }
}
