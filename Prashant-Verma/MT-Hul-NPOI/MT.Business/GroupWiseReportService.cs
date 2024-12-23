using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web;

namespace MT.Business
{
    public class GroupWiseReportService : ReportService
    {

        public ReportResponse GetGroupWiseReportData(ReportRequest reportRq, bool isCurrentMOC, string currentReportMOC)
        {
            var response = new ReportResponse();
            if (null == reportRq)
            {
                reportRq = new ReportRequest();

                reportRq.Columns = new List<ReportColumn>();
                //reportRq.Columns.Add(new ReportColumn { Sequence = 1, ColumnName = "MOC" });
                reportRq.Columns.Add(new ReportColumn { Sequence = 1, ColumnName = "QTR", DisplayName = "QTR" });
                reportRq.Columns.Add(new ReportColumn { Sequence = 2, ColumnName = "Month", DisplayName = "Month" });
                reportRq.Columns.Add(new ReportColumn { Sequence = 3, ColumnName = "GroupName", DisplayName = "Group Name" });
                reportRq.Columns.Add(new ReportColumn { Sequence = 4, ColumnName = "FirstLetterBrand", DisplayName = "Profit Center" });

                reportRq.Columns.Add(new ReportColumn { Sequence = 5, ColumnName = "OnInvoiceFinalValue", IsValueColumn = true, DisplayName = "On Invoice" });
                reportRq.Columns.Add(new ReportColumn { Sequence = 6, ColumnName = "OffInvoiceMthlyFinalValue", IsValueColumn = true, DisplayName = "Off Invoice" });
                reportRq.Columns.Add(new ReportColumn { Sequence = 7, ColumnName = "OffInvoiceQtrlyFinalValue", IsValueColumn = true, DisplayName = "Qtr Off Invoice" });


                //reportRq.TotalToBeShownColumns.Add(reportRq.Columns[1]);
                reportRq.TotalToBeShownColumns.Add(reportRq.Columns[0]);

                if (isCurrentMOC == true)
                    reportRq.TableOrViewName = "vwCustomerwiseReport_CurrentMOC";
                else
                    reportRq.TableOrViewName = "vwCustomerwiseReport_PrevMOC";


                response.ReportRequest = reportRq;

                foreach (var column in reportRq.Columns)
                {
                    if (!column.IsValueColumn)
                    {
                        reportRq.ExpandedColumns.Add(column);
                    }

                }
            }

            reportRq.ColumnsToFilter = new List<ReportColumn>();
            reportRq.ColumnsToFilter.Add(new ReportColumn { ColumnName = "MOC", ColumnValue = currentReportMOC });

            //response.ReportData = this.GetReportData(reportRq);


            var data = this.GetReportDataNewMethod(reportRq);

            //Shift Totals Down start

            //string nullSearchstring="";
            string isNullDelimiter = " is null and ";
            string isNotNullDelimiter = " is not null and ";
            foreach (var totalTobeShownCol in reportRq.TotalToBeShownColumns.OrderByDescending(c => c.Sequence).ToList())
            {
                var nullSearchstring = "";
                if (null != reportRq.ExpandedColumns.Where(c => c.ColumnName == totalTobeShownCol.ColumnName).FirstOrDefault())
                {
                    //var afterColumns = reportRq.Columns.Where(c => c.Sequence > totalTobeShownCol.Sequence && !c.IsValueColumn).ToList().OrderBy(o => o.Sequence).ToList();

                    var afterColumns = reportRq.Columns.Where(c => c.Sequence > totalTobeShownCol.Sequence && !c.IsValueColumn).ToList().OrderBy(o => o.Sequence).ToList();
                    var rollupColumns = reportRq.Columns.Where(c => c.Sequence <= totalTobeShownCol.Sequence && !c.IsValueColumn).ToList().OrderBy(o => o.Sequence).ToList();

                    //var rollupConcatenateString = rollupColumns.Select(i => i.ColumnName).Aggregate((i, j) => i + delimiter + j);
                    var rollupConcatenateString = "";
                    //if (rollupColumns.Count > 0) { rollupConcatenateString = "("; }
                    foreach (var afterCol in afterColumns)
                    {
                        if (afterCol.Sequence >= 2)
                        {
                            if (reportRq.ExpandedColumns.Where(c => c.ColumnName == reportRq.Columns[afterCol.Sequence - 2].ColumnName).Count() > 0)
                            {
                                rollupConcatenateString += afterCol.ColumnName + isNullDelimiter;
                            }
                        }
                        else
                        {
                            rollupConcatenateString += afterCol.ColumnName + isNullDelimiter;
                        }



                    }

                    //rollupConcatenateString = rollupConcatenateString.Substring(0, rollupConcatenateString.LastIndexOf("and"));

                    foreach (var rollupNotNull in rollupColumns)
                    {
                        if (rollupNotNull.Sequence >= 2)
                        {
                            if (reportRq.ExpandedColumns.Where(c => c.ColumnName == reportRq.Columns[rollupNotNull.Sequence - 2].ColumnName).Count() > 0)
                            {
                                rollupConcatenateString += rollupNotNull.ColumnName + isNotNullDelimiter;
                            }
                        }
                        else
                        {
                            rollupConcatenateString += rollupNotNull.ColumnName + isNotNullDelimiter;
                        }
                    }

                    rollupConcatenateString = rollupConcatenateString.Substring(0, rollupConcatenateString.LastIndexOf("and"));

                    //groupingSetString.Add(rollupConcatenateString);
                    nullSearchstring += "(" + rollupConcatenateString + ")  ";

                    //DataRow[] nullDataRows = data.Select("Basepackid is null");

                    DataRow[] nullDataRows = data.Select(nullSearchstring);

                    List<DataRow> newNullRows = new List<DataRow>();

                    foreach (DataRow row in nullDataRows)
                    {
                        DataRow newRow = data.NewRow();
                        newRow.ItemArray = row.ItemArray;
                        newNullRows.Add(newRow);
                    }

                    //DataRow[] nullDataRowsClone = data.Select("Basepackid is null");

                    var newDataTable = data.Clone();

                    foreach (DataRow tobeDelRow in nullDataRows)
                    {
                        data.Rows.Remove(tobeDelRow);
                    }

                    foreach (DataRow newnullRow in newNullRows)
                    {

                        var searchstring = "";
                        foreach (var rollupCol in rollupColumns)
                        {
                            searchstring += rollupCol.ColumnName + "='" + newnullRow[rollupCol.ColumnName] + "' and ";
                        }

                        searchstring = searchstring.Substring(0, searchstring.LastIndexOf("and"));
                        //var list = data.Select("MOC='" + newnullRow["MOC"] + "' and CustomerCode='" + newnullRow["CustomerCode"] + "' and PMHBrandCode='" + newnullRow["PMHBrandCode"] + "'"); // and  Basepackid is null

                        var list = data.Select(searchstring);
                        var lastRow = list[list.Count() - 1];
                        data.Rows.InsertAt(newnullRow, data.Rows.IndexOf(lastRow) + 1);
                    }
                }
            }

            response.ReportData = data;
            //Shift Totals Down end

            return response;
        }

        public bool CheckForNullGroupName(string viewName, string currentReportMOC)
        {
            bool isGroupNameNull = false;
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT COUNT(*) FROM " + viewName + " WHERE MOC='" + currentReportMOC + "' AND (GroupName IS NULL OR GroupName = '')";
            dt = smartDataObj.GetData(request);
            int recordsCount = 0;

            foreach (DataRow dr in dt.Rows)
            {
                recordsCount = Convert.ToInt32(dr[0]);
            }

            isGroupNameNull = (recordsCount > 0) ? true : false;
            return isGroupNameNull;
        }

        public void UploadCustomerWiseReportData(string moc)
        {
            DbRequest request = new DbRequest();

            request.Parameters = new List<Parameter>();
            Parameter paramMoc = new Parameter("MOC", moc);
            request.Parameters.Add(paramMoc);
            request.StoredProcedureName = "sp_UploadCustomerWiseReportDataAync";
            smartDataObj.ExecuteStoredProcedure(request);

        }
        public void Queue(Action action, Action done)
        {
            ThreadPool.QueueUserWorkItem(_ =>
            {
                try
                {
                    action();
                }
                catch (ThreadAbortException) { }
                catch (Exception ex)
                {
                    Logger.LogError(ex);
                } // note: this will not be called if the thread is aborted        

                if (done != null) done();
            });
        }
        public void AsyncGenerateCustomerWiseReport(string moc)
        {
            var httpContext = HttpContext.Current;
            try
            {
                Queue(() =>
                  {
                      UploadCustomerWiseReportData(moc);

                  }, null);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex);
            }
        }
    }
}
