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
    public class ReportService : BaseService
    {
        protected DataTable GetReportData(ReportRequest reportRq)
        {



            SmartData smartData = new SmartData();
            DbRequest dbReq = new DbRequest();

            string groupByString = "";

            List<string> groupingSetString = new List<string>();

            string selectString = "";
            int reqColIndex = 0;
            foreach (var col in reportRq.Columns)
            {
                if (col.IsValueColumn)
                {
                    selectString += "sum(" + col.ColumnName + ") " + col.ColumnName + ",";
                }
                else
                {
                    //If expanded in then take current column 

                    if (reqColIndex == 0)
                    {
                        //if (col.ColumnName == "FirstLetterBrand") { selectString += "CONCAT(" + col.ColumnName + ",'XXX',null) FirstLetterBrand" + ","; }
                        //else { selectString += col.ColumnName + ","; }
                        selectString += col.ColumnName + ",";

                        //CONCAT(FirstLetterBrand,'XXX',null) ProfitCenter
                        groupByString += col.ColumnName + ",";
                    }
                    else
                    {
                        //if previous column is collapsed then do not take this column
                        if (reportRq.ExpandedColumns.Where(c => c.ColumnName == reportRq.Columns[reqColIndex - 1].ColumnName).Count() > 0)
                        {
                            //if (col.ColumnName == "FirstLetterBrand") { selectString += "CONCAT(" + col.ColumnName + ",'XXX',null) FirstLetterBrand" + ","; }
                            //else { selectString += col.ColumnName + ","; }
                            selectString += col.ColumnName + ",";
                            groupByString += col.ColumnName + ",";
                        }
                    }
                }

                reqColIndex++;
            }
            groupByString = groupByString.Substring(0, groupByString.LastIndexOf(","));


            groupingSetString.Add(groupByString);
            string delimiter = ",";

            if (reportRq.TotalToBeShownColumns.Count > 0)
            {
                foreach (var totalCol in reportRq.TotalToBeShownColumns.OrderBy(c => c.Sequence).ToList())
                {
                    if (null != reportRq.ExpandedColumns.Where(c => c.ColumnName == totalCol.ColumnName).FirstOrDefault())
                    {
                        var rollupColumns = reportRq.Columns.Where(c => c.Sequence <= totalCol.Sequence).ToList().OrderBy(o => o.Sequence).ToList();
                        var rollupConcatenateString = rollupColumns.Select(i => i.ColumnName).Aggregate((i, j) => i + delimiter + j);
                        groupingSetString.Add(rollupConcatenateString);
                    }
                }
            }


            //Important -start
            dbReq.SqlQuery = "WITH CTE AS (" +
        "SELECT    " + selectString +
       //"ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) RN " +
       "ROW_NUMBER() OVER (ORDER BY " + groupByString + ") RN " +
       " from  " + reportRq.TableOrViewName;
            var lastFilterCol = reportRq.ColumnsToFilter.LastOrDefault();
            foreach (var filterColumn in reportRq.ColumnsToFilter)
            {
                if (filterColumn == lastFilterCol)
                {
                    dbReq.SqlQuery += " Where " + filterColumn.ColumnName + "='" + filterColumn.ColumnValue + "'";
                }
                else
                {
                    dbReq.SqlQuery += " Where " + filterColumn.ColumnName + "='" + filterColumn.ColumnValue + "' AND ";
                }
            }
            dbReq.SqlQuery += " Group by GROUPING SETS(";

            foreach (var groupSet in groupingSetString)
            {
                dbReq.SqlQuery += "(" + groupSet + "),";
            }

            dbReq.SqlQuery = dbReq.SqlQuery.Substring(0, dbReq.SqlQuery.LastIndexOf(","));

            dbReq.SqlQuery += ")) SELECT * FROM CTE "; //WHERE RN Between 1 and 100

            //Important -end

            // dbReq.SqlQuery = "WITH CTE AS (" +
            // "SELECT    " + selectString +
            //"ROW_NUMBER() OVER (ORDER BY " + groupByString + " ) RN " +
            //" from " + reportRq.TableOrViewName + 
            //" Group by " + groupByString +
            // ")" +  "SELECT * FROM CTE WHERE RN Between 1 and 50";


            return smartData.GetData(dbReq);

        }
        public string GetDataSearchText(JQDTParams param)
        {
            string search = "";
            Dictionary<string, string> columnSearch = new Dictionary<string, string>();

            foreach (var item in param.columns)
            {
                var filterText = item.search.value;

                if (!String.IsNullOrEmpty(filterText))
                {
                    columnSearch.Add(item.data, filterText);


                }
            }
            var lastItem = columnSearch.LastOrDefault();
            foreach (var item in columnSearch)
            {
                if (item.Key == lastItem.Key)
                {
                    search += item.Key + " like '%" + item.Value + "%'";
                }
                else
                {
                    search += item.Key + " like '%" + item.Value + "%' AND ";
                }
            }
            return search;
        }


        protected DataTable GetReportDataNewMethod(ReportRequest reportRq)
        {

            SmartData smartData = new SmartData();
            DbRequest dbReq = new DbRequest();

            string groupByString = "";

            List<string> groupingSetString = new List<string>();

            string selectString = "";
            int reqColIndex = 0;
            foreach (var col in reportRq.Columns)
            {
                if (col.IsValueColumn)
                {
                    selectString += "sum(" + col.ColumnName + ") " + col.ColumnName + ",";
                }
                else
                {
                    //If expanded in then take current column 

                    if (reqColIndex == 0)
                    {
                        //if (col.ColumnName == "FirstLetterBrand") { selectString += "CONCAT(" + col.ColumnName + ",'XXX',null) FirstLetterBrand" + ","; }
                        //else { selectString += col.ColumnName + ","; }
                        selectString += col.ColumnName + ",";

                        //CONCAT(FirstLetterBrand,'XXX',null) ProfitCenter
                        groupByString += col.ColumnName + ",";
                    }
                    else
                    {
                        //if previous column is collapsed then do not take this column
                        if (reportRq.ExpandedColumns.Where(c => c.ColumnName == reportRq.Columns[reqColIndex - 1].ColumnName).Count() > 0)
                        {
                            //if (col.ColumnName == "FirstLetterBrand") { selectString += "CONCAT(" + col.ColumnName + ",'XXX',null) FirstLetterBrand" + ","; }
                            //else { selectString += col.ColumnName + ","; }
                            selectString += col.ColumnName + ",";
                            groupByString += col.ColumnName + ",";
                        }
                    }
                }

                reqColIndex++;
            }
            groupByString = groupByString.Substring(0, groupByString.LastIndexOf(","));


            groupingSetString.Add(groupByString);
            string delimiter = ",";

            if (reportRq.TotalToBeShownColumns.Count > 0)
            {
                foreach (var totalCol in reportRq.TotalToBeShownColumns.OrderBy(c => c.Sequence).ToList())
                {
                    if (null != reportRq.ExpandedColumns.Where(c => c.ColumnName == totalCol.ColumnName).FirstOrDefault())
                    {
                        var rollupColumns = reportRq.Columns.Where(c => c.Sequence <= totalCol.Sequence).ToList().OrderBy(o => o.Sequence).ToList();
                        var rollupConcatenateString = rollupColumns.Select(i => i.ColumnName).Aggregate((i, j) => i + delimiter + j);
                        groupingSetString.Add(rollupConcatenateString);
                    }
                }
            }


            //Important -start
            dbReq.SqlQuery = "WITH CTE AS (" +
        "SELECT    " + selectString +
       //"ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) RN " +
       "ROW_NUMBER() OVER (ORDER BY " + groupByString + ") RN " +
       " from  mtCutomerWiseReport";// + reportRq.TableOrViewName;
            var lastFilterCol = reportRq.ColumnsToFilter.LastOrDefault();
            foreach (var filterColumn in reportRq.ColumnsToFilter)
            {
                if (filterColumn == lastFilterCol)
                {
                    dbReq.SqlQuery += " Where " + filterColumn.ColumnName + "='" + filterColumn.ColumnValue + "'";
                }
                else
                {
                    dbReq.SqlQuery += " Where " + filterColumn.ColumnName + "='" + filterColumn.ColumnValue + "' AND ";
                }
            }
            dbReq.SqlQuery += " Group by GROUPING SETS(";

            foreach (var groupSet in groupingSetString)
            {
                dbReq.SqlQuery += "(" + groupSet + "),";
            }

            dbReq.SqlQuery = dbReq.SqlQuery.Substring(0, dbReq.SqlQuery.LastIndexOf(","));

            dbReq.SqlQuery += ")) SELECT * FROM CTE "; //WHERE RN Between 1 and 100

            //Important -end

            // dbReq.SqlQuery = "WITH CTE AS (" +
            // "SELECT    " + selectString +
            //"ROW_NUMBER() OVER (ORDER BY " + groupByString + " ) RN " +
            //" from " + reportRq.TableOrViewName + 
            //" Group by " + groupByString +
            // ")" +  "SELECT * FROM CTE WHERE RN Between 1 and 50";


            return smartData.GetData(dbReq);

        }
    }
}
