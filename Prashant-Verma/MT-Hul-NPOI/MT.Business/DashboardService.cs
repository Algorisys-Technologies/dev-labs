using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace MT.Business
{
    enum Months
    {
        Jan = 1,
        Feb,
        Mar,
        Apr,
        May,
        Jun,
        Jul,
        Aug,
        Sep,
        Oct,
        Nov,
        Dec
    }
    public class DashboardService
    {
        SmartData smartDataObj = new SmartData();

        public DashBoardViewModel GetDashboardModel(string currentMOC)
        {

            DashBoardViewModel model = new DashBoardViewModel();
            List<MtStepMaster> stepMasterObj = Import_MtStepMaster_FromDB();

            //bool isValidMocPresent = CheckMocStatus();
            //if (isValidMocPresent)
            //{
            if (!string.IsNullOrEmpty(currentMOC))
            {
                int MOC_MonthId = Convert.ToInt32(currentMOC.Split('.').ToArray()[0]);
                int MOC_Year = Convert.ToInt32(currentMOC.Split('.').ToArray()[1]);

                List<MtMOCWiseStepDetails> mocWiseStepDetails_List = new List<MtMOCWiseStepDetails>();
                mocWiseStepDetails_List = GetMocWiseStepDetails(MOC_MonthId, MOC_Year);

                if (mocWiseStepDetails_List.All(s => s.Status.Trim().ToLower() == "notstarted"))
                {
                    foreach (var step in stepMasterObj)
                    {
                        DashboardStepModel dashboardStepModel = new DashboardStepModel();
                        dashboardStepModel.StepId = step.StepId;
                        if (step.Sequence == 1)
                        {
                            dashboardStepModel.IsActive = true;
                        }
                        else
                        {
                            dashboardStepModel.IsActive = false;
                        }
                        model.DashboardSteps.Add(dashboardStepModel);
                    }
                }
                else if (mocWiseStepDetails_List.Any(m => m.Status.Trim().ToLower() == "started"))
                {
                    HashSet<string> startedStepIds = new HashSet<string>(mocWiseStepDetails_List.Where(m => m.Status.Trim().ToLower() == "started").Select(m => m.StepId));
                    var highestStarted_SequenceNo = stepMasterObj.Where(m => startedStepIds.Contains(m.StepId)).OrderByDescending(m => m.Sequence).FirstOrDefault().Sequence;

                    foreach (var step in stepMasterObj)
                    {
                        DashboardStepModel dashboardStepModel = new DashboardStepModel();
                        dashboardStepModel.StepId = step.StepId;
                        if (step.Sequence <= highestStarted_SequenceNo)
                        {
                            dashboardStepModel.IsActive = true;
                        }
                        else
                        {
                            dashboardStepModel.IsActive = false;
                        }

                        model.DashboardSteps.Add(dashboardStepModel);
                    }
                }
                else if (mocWiseStepDetails_List.Any(m => m.Status.Trim().ToLower() == "done"))
                {
                    HashSet<string> doneStepIds = new HashSet<string>(mocWiseStepDetails_List.Where(m => m.Status.Trim().ToLower() == "done").Select(m => m.StepId));
                    var highestDone_SequenceNo = stepMasterObj.Where(m => doneStepIds.Contains(m.StepId)).OrderByDescending(m => m.Sequence).FirstOrDefault().Sequence;
                    int nextSequenceNo = 0;
                    if ((highestDone_SequenceNo == 1 && doneStepIds.Count() == 2) || highestDone_SequenceNo > 1)
                    {
                        nextSequenceNo = highestDone_SequenceNo + 1;
                    }
                    else
                    {
                        nextSequenceNo = highestDone_SequenceNo;
                    }
                    foreach (var step in stepMasterObj)
                    {
                        DashboardStepModel dashboardStepModel = new DashboardStepModel();
                        dashboardStepModel.StepId = step.StepId;
                        if (step.Sequence <= nextSequenceNo)
                        {
                            dashboardStepModel.IsActive = true;
                        }
                        else
                        {
                            dashboardStepModel.IsActive = false;
                        }

                        model.DashboardSteps.Add(dashboardStepModel);
                    }

                }

            }
            else
            {
                foreach (var step in stepMasterObj)
                {
                    DashboardStepModel dashboardStepModel = new DashboardStepModel();
                    dashboardStepModel.StepId = step.StepId;
                    dashboardStepModel.IsActive = false;
                    model.DashboardSteps.Add(dashboardStepModel);
                }
            }
            return model;
        }
        public bool CheckMocStatus()
        {
            bool isValidMocPresent = false;
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT * FROM " + DashBoardConstants.MOC_Status_Table_Name;
            DataTable dt = smartDataObj.GetData(request);

            List<MtMOCStatus> model = new List<MtMOCStatus>();
            if (dt != null)
            {
                model = dt.DataTableToList<MtMOCStatus>();
                int index = model.FindIndex(item => item.Status.ToLower() == "open");
                if (index >= 0)
                {
                    // element exists, do what you need
                    isValidMocPresent = true;
                }
                else
                {
                    isValidMocPresent = false;
                }
            }
            else
            {
                isValidMocPresent = false;
            }
            return isValidMocPresent;
        }

        public List<MtStepMaster> Import_MtStepMaster_FromDB()
        {
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT * FROM " + DashBoardConstants.Step_Master_Table_Name;
            DataTable dt = smartDataObj.GetData(request);
            List<MtStepMaster> model = new List<MtStepMaster>();

            if (dt != null)
            {
                model = dt.DataTableToList<MtStepMaster>();
            }
            return model;
        }

        public List<MtMOCWiseStepDetails> GetMocWiseStepDetails(int MOC_MonthId, int MOC_Year)
        {
            List<MtMOCWiseStepDetails> list = new List<MtMOCWiseStepDetails>();
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT * FROM " + DashBoardConstants.MOC_Wise_StepDetails_Table_Name + " where MonthId=" + MOC_MonthId + " and Year=" + MOC_Year + "";
            DataTable dt = smartDataObj.GetData(request);
            if (dt != null)
            {
                list = dt.DataTableToList<MtMOCWiseStepDetails>();
            }
            return list;
        }

        public bool CreateNewMOC(out string msg, string userId)
        {
            msg = "";
            bool isSuccess = true;
            try
            {
                int mocCount = GetTotalRowsCount(null, DashBoardConstants.MOC_Status_Table_Name);

                DbRequest request = new DbRequest();
                request.Parameters = new List<Parameter>();

                if (mocCount == 0)
                {
                    request.StoredProcedureName = "mtCreate_newMOCDetails_FirstTime";
                    Parameter param1 = new Parameter("@mocMonthId", DateTime.Now.Month);
                    Parameter param2 = new Parameter("@mocYear", DateTime.Now.Year);
                    Parameter param3 = new Parameter("@createdAt", DateTime.Now);
                    Parameter param4 = new Parameter("@createdBy", userId);
                    request.Parameters.Add(param1);
                    request.Parameters.Add(param2);
                    request.Parameters.Add(param3);
                    request.Parameters.Add(param4);
                    smartDataObj.ExecuteStoredProcedure(request);
                }
                else
                {
                    int closedMOC_MonthId, closedMOC_Year;
                    GetLastClosedMOC(out closedMOC_MonthId, out closedMOC_Year);
                    int newMOC_monthId; int newMOC_Year;
                    var isValidMOCMonth = ValidateNewMOCMonth(closedMOC_MonthId, closedMOC_Year);

                    if (isValidMOCMonth)
                    {
                        if (closedMOC_MonthId == 12)
                        {
                            newMOC_Year = closedMOC_Year + 1;
                            newMOC_monthId = 1;
                        }
                        else
                        {
                            newMOC_Year = closedMOC_Year;
                            newMOC_monthId = closedMOC_MonthId + 1;
                        }

                        request.StoredProcedureName = "mtCreate_newMOCDetails";
                        Parameter param1 = new Parameter("@mocMonthId", newMOC_monthId);
                        Parameter param2 = new Parameter("@mocYear", newMOC_Year);
                        Parameter param3 = new Parameter("@createdAt", DateTime.Now);
                        Parameter param4 = new Parameter("@createdBy", userId);
                        Parameter param5 = new Parameter("@lastmocMonthId", closedMOC_MonthId);
                        Parameter param6 = new Parameter("@lastmocYear", closedMOC_Year);
                        request.Parameters.Add(param1);
                        request.Parameters.Add(param2);
                        request.Parameters.Add(param3);
                        request.Parameters.Add(param4);
                        request.Parameters.Add(param5);
                        request.Parameters.Add(param6);
                        smartDataObj.ExecuteStoredProcedure(request);

                    }
                    else
                    {
                        isSuccess = false;
                        msg = "Can not create new MOC";
                    }

                }


            }
            catch (Exception ex)
            {
                isSuccess = false;
                msg = ex.Message;
            }

            return isSuccess;
        }
        public void GetLastClosedMOC(out int closedMOC_MonthId, out int closedMOC_Year)
        {
            string lastClosedMOC = string.Empty;
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT TOP 1 * FROM " + DashBoardConstants.MOC_Status_Table_Name + " ORDER BY [Year] DESC, MonthId DESC";
            DataTable dt = smartDataObj.GetData(request);
            if (dt != null)
            {
                closedMOC_MonthId = Convert.ToInt32(dt.Rows[0]["MonthId"]);
                closedMOC_Year = Convert.ToInt32(dt.Rows[0]["Year"]);
            }
            else
            {
                closedMOC_MonthId = 0;
                closedMOC_Year = 0;
            }
        }

        public int GetTotalRowsCount(string search, string tableName)
        {
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();
            if (string.IsNullOrEmpty(search))
            {
                request.SqlQuery = "Select Count(*) from " + tableName + "";
                dt = smartDataObj.GetData(request);

            }
            else
            {
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

        public bool ValidateNewMOCMonth(int closedMOC_MonthId, int closedMOC_Year)
        {
            var isValid = true;
            int currentMonth = DateTime.Now.Month;
            //int maxValidMonth=currentMonth+1;    //Here user can create MOC till next month of the current month
            int maxValidMonth = currentMonth;      //Here user can create MOC till current month only
            if (maxValidMonth <= 13)
            {
                if (closedMOC_MonthId < maxValidMonth)
                {
                    isValid = true;
                }
                else if (closedMOC_MonthId > maxValidMonth && DateTime.Now.Year > closedMOC_Year)
                {
                    isValid = true;
                }
                else
                {
                    isValid = false;
                }
            }
            else
            {

            }


            //if (currentMonth == 12)
            //{
            //    maxValidMonth = 1;
            //}
            //else
            //{
            //    maxValidMonth = currentMonth + 1;
            //}




            return isValid;
        }

        public bool Update_SingleStepStatus(string stepId, string currentMOC)
        {
            bool isSuccess = true;
            try
            {
                int MOC_MonthId = Convert.ToInt32(currentMOC.Split('.').ToArray()[0]);
                int MOC_Year = Convert.ToInt32(currentMOC.Split('.').ToArray()[1]);


                DbRequest request = new DbRequest();
                request.StoredProcedureName = "Update_Dashboard_SingleStepStatus";

                request.Parameters = new List<Parameter>();
                Parameter mocMonthIdParam = new Parameter("@mocMonthId", MOC_MonthId);
                Parameter mocYearParam = new Parameter("@mocYear", MOC_Year);
                Parameter stepIdParam = new Parameter("@stepId", stepId);
                request.Parameters.Add(mocMonthIdParam);
                request.Parameters.Add(mocYearParam);
                request.Parameters.Add(stepIdParam);

                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch (Exception ex)
            {
                isSuccess = false;
            }
            return isSuccess;
        }
        public bool Update_StepsAfterUploadSecSalesReport(string stepId, string currentMOC, string user)
        {
            bool isSuccess = true;
            try
            {
                int MOC_MonthId = Convert.ToInt32(currentMOC.Split('.').FirstOrDefault());
                int MOC_Year = Convert.ToInt32(currentMOC.Split('.').LastOrDefault());


                DbRequest request = new DbRequest();
                request.StoredProcedureName = "Update_StepAfterUploadSecSalesReport";

                request.Parameters = new List<Parameter>();
                Parameter mocMonthIdParam = new Parameter("@mocMonthId", MOC_MonthId);
                Parameter mocYearParam = new Parameter("@mocYear", MOC_Year);
                Parameter stepIdParam = new Parameter("@stepId", stepId);
                Parameter userParam = new Parameter("@user", user);
                request.Parameters.Add(mocMonthIdParam);
                request.Parameters.Add(mocYearParam);
                request.Parameters.Add(stepIdParam);
                request.Parameters.Add(userParam);

                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch (Exception ex)
            {
                isSuccess = false;
            }
            return isSuccess;
        }

        public bool Update_SetNextStepsNotStarted(string stepId, string currentMOC, string user)
        {
            bool isSuccess = true;
            try
            {
                int MOC_MonthId = Convert.ToInt32(currentMOC.Split('.').FirstOrDefault());
                int MOC_Year = Convert.ToInt32(currentMOC.Split('.').LastOrDefault());


                DbRequest request = new DbRequest();
                request.StoredProcedureName = "Update_SetNextStepNotStarted";

                request.Parameters = new List<Parameter>();
                Parameter mocMonthIdParam = new Parameter("@mocMonthId", MOC_MonthId);
                Parameter mocYearParam = new Parameter("@mocYear", MOC_Year);
                Parameter stepIdParam = new Parameter("@stepId", stepId);
                Parameter userParam = new Parameter("@user", user);
                request.Parameters.Add(mocMonthIdParam);
                request.Parameters.Add(mocYearParam);
                request.Parameters.Add(stepIdParam);
                request.Parameters.Add(userParam);

                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch (Exception ex)
            {
                isSuccess = false;
            }
            return isSuccess;
        }

        public bool Update_MultiStepStatus(string stepId, string detailedStepId, string currentMOC)
        {
            bool isSuccess = true;
            try
            {
                int MOC_MonthId = Convert.ToInt32(currentMOC.Split('.').ToArray()[0]);
                int MOC_Year = Convert.ToInt32(currentMOC.Split('.').ToArray()[1]);


                DbRequest request = new DbRequest();
                request.StoredProcedureName = "Update_Dashboard_MultipleStepStatus";

                request.Parameters = new List<Parameter>();
                Parameter mocMonthIdParam = new Parameter("@mocMonthId", MOC_MonthId);
                Parameter mocYearParam = new Parameter("@mocYear", MOC_Year);
                Parameter stepIdParam = new Parameter("@stepId", stepId);
                Parameter detailedStepIdParam = new Parameter("@detailedStepId", detailedStepId);
                request.Parameters.Add(mocMonthIdParam);
                request.Parameters.Add(mocYearParam);
                request.Parameters.Add(stepIdParam);
                request.Parameters.Add(detailedStepIdParam);

                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch (Exception ex)
            {
                isSuccess = false;
            }
            return isSuccess;
        }

        public List<ThermometerViewModel> GetSpecificYearMOCs(int year)
        {
            List<ThermometerViewModel> mocMonthList = new List<ThermometerViewModel>();
            //int currentYear = DateTime.Now.Year;
            SmartData smartDataObj = new SmartData();
            DataTable dt = new DataTable();
            DbRequest request = new DbRequest();

            request.SqlQuery = "SELECT [Id],[MonthId],[Year],[Status] from mtMOCStatus WHERE Year=" + year + " ORDER BY MonthId";
            dt = smartDataObj.GetData(request);

            foreach (Months month in Enum.GetValues(typeof(Months)))
            {
                ThermometerViewModel mocMonth = new ThermometerViewModel();
                mocMonth.MonthId = (int)month;
                mocMonth.Month = month.ToString();

                bool contains = dt.AsEnumerable().Any(row => mocMonth.MonthId == row.Field<int>("MonthId"));
                if (contains)
                {
                    mocMonth.Status = (from r in dt.AsEnumerable()
                                       where r.Field<int>("MonthId") == mocMonth.MonthId
                                       select r.Field<string>("Status")).First<string>();
                }
                else
                {
                    mocMonth.Status = "NotPresent";
                }
                mocMonth.Year = year;
                mocMonthList.Add(mocMonth);
            }

            return mocMonthList;
        }

        public bool CloseMOC(string CurrentMOC, string userId)
        {
            bool isSuccess = true;
            try
            {
                int currentMOC_MonthId = Convert.ToInt32(CurrentMOC.Split('.').ToArray()[0]);
                int currentMOC_Year = Convert.ToInt32(CurrentMOC.Split('.').ToArray()[1]);

                DbRequest request = new DbRequest();
                request.StoredProcedureName = "Dashboard_CloseMOC";

                request.Parameters = new List<Parameter>();
                Parameter mocMonthIdParam = new Parameter("@mocMonthId", currentMOC_MonthId);
                Parameter mocYearParam = new Parameter("@mocYear", currentMOC_Year);
                Parameter updatedAtParam = new Parameter("@updatedAt", DateTime.Now);
                Parameter updatedByParam = new Parameter("@updatedBy", userId);
                request.Parameters.Add(mocMonthIdParam);
                request.Parameters.Add(mocYearParam);
                request.Parameters.Add(updatedAtParam);
                request.Parameters.Add(updatedByParam);

                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch (Exception ex)
            {
                isSuccess = false;
            }
            return isSuccess;
        }

        public MtMOCWiseStepDetails GetStepStatus(string step, string moc)
        {
            DbRequest request = new DbRequest();
            request.SqlQuery = "SELECT * FROM MtMOCWiseStepDetails where MonthId=" + moc.Split('.').FirstOrDefault() + " AND Year=" + moc.Split('.').LastOrDefault() + " AND  StepId='" + step + "'";
            DataTable dt = smartDataObj.GetData(request);
            List<MtMOCWiseStepDetails> model = new List<MtMOCWiseStepDetails>();

            if (dt != null)
            {
                model = dt.DataTableToList<MtMOCWiseStepDetails>();
            }
            return model.FirstOrDefault();
        }

        public bool ReopenMOC(out string msg)
        {
            msg = "";
            bool isSuccess = true;
            try
            {
                int mocCount = GetTotalRowsCount(null, DashBoardConstants.MOC_Status_Table_Name);
                if (mocCount == 0)
                {
                    isSuccess = false;
                    msg = "No any MOC available to reopen";
                }
                else
                {
                    int closedMOC_MonthId, closedMOC_Year;
                    GetLastClosedMOC(out closedMOC_MonthId, out closedMOC_Year);
                    int currentMonth = DateTime.Now.Month;
                    int currentYear = DateTime.Now.Year;

                    if (closedMOC_Year == currentYear && currentMonth== closedMOC_MonthId)
                    {
                        string month = DateTime.Now.ToString("MMMM");
                        isSuccess = true;
                        msg = "Latest closed MOC is "+month+"-"+ closedMOC_Year+".Are you sure to reopen this MOC?";
                    }
                    else
                    {
                        isSuccess = false;
                        msg = "No any latest MOC available to reopen";
                    }
                }
            }
            catch (Exception ex)
            {
                isSuccess = false;
                msg = ex.Message;
            }
            return isSuccess;
        }

        public bool ConfirmReopenMOC(string userId)
        {
            bool isSuccess = true;
            try
            {
                int currentMonth = DateTime.Now.Month;
                int currentYear = DateTime.Now.Year;
                DbRequest request = new DbRequest();
                request.StoredProcedureName = "Dashboard_ReopenMOC";

                request.Parameters = new List<Parameter>();
                Parameter mocMonthIdParam = new Parameter("@mocMonthId", currentMonth);
                Parameter mocYearParam = new Parameter("@mocYear", currentYear);
                Parameter updatedAtParam = new Parameter("@updatedAt", DateTime.Now);
                Parameter updatedByParam = new Parameter("@updatedBy", userId);
                request.Parameters.Add(mocMonthIdParam);
                request.Parameters.Add(mocYearParam);
                request.Parameters.Add(updatedAtParam);
                request.Parameters.Add(updatedByParam);

                smartDataObj.ExecuteStoredProcedure(request);
            }
            catch (Exception ex)
            {
                isSuccess = false;
            }
            return isSuccess;
        }
        public List<int> GetYearsForThermometer()
        {
            List<int> thermoYears = new List<int>();
            DbRequest request = new DbRequest();
            request.SqlQuery = "select distinct top 3 [Year] from mtMOCStatus order by [Year] desc";
            DataTable dt = smartDataObj.GetData(request);
            if (dt != null && dt.Rows.Count > 0)
            {
                foreach (DataRow dr in dt.Rows)
                {
                    thermoYears.Add(Convert.ToInt32(dr["Year"]));
                }
            }
            else
            {
                thermoYears.Add(DateTime.Now.Year);
            }

            return thermoYears;
        }


        #region ArchiveSP Pankaj
        public async Task ArchiveData(string currentMOC)
        {
            await Task.Run(() => ArchiveDataAsync(currentMOC));

        }

        async Task<int> ArchiveDataAsync(string currentMOC)
        {

            DbRequest request = new DbRequest();
            request.StoredProcedureName = "spArchiveData";

            var result = smartDataObj.ExecuteStoredProcedure(request);
            return result;
        }
        #endregion


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
                    //log error
                } // note: this will not be called if the thread is aborted        

                if (done != null) done();
            });
        }

        public void CallSPArchive()
        {
            DbRequest request = new DbRequest();
            request.StoredProcedureName = "spArchiveData";
            Parameter param = new Parameter("@NoOfYears",ConfigConstants.ArchiveYears);
            request.Parameters.Add(param);
            smartDataObj.ExecuteStoredProcedure(request);
        }
    }
}
