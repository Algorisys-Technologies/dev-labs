using MT.Business;
using MT.DataAccessLayer;
using MT.Model;
using MT.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace MTKAProvision.Controllers
{
    public class DashboardController : AppController
    {
        SmartData smartDataObj = new SmartData();
        DashboardService dashboardService = new DashboardService();
        AssignAccessService assignAccessService = new AssignAccessService();
        // GET: Dashboard
        public ActionResult Index()
        {
            
            DashBoardViewModel viewModel = new DashBoardViewModel();
            viewModel = dashboardService.GetDashboardModel(CurrentMOC);
            //int currentMonth = Convert.ToInt16(CurrentMOC.Split('.').FirstOrDefault());
            //ViewBag.currentMOC = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(currentMonth);
            //ViewBag.currentDateTime = DateTime.Now.ToShortDateString();
            List<int> thermoYears = new List<int>();
            thermoYears = dashboardService.GetYearsForThermometer();
            ViewBag.ThermoYears = thermoYears;
            ViewBag.currentMOC = CurrentMOC;
            return View("Dashboard", viewModel);
        }
        public ActionResult LoadHeader(string currentReportMOC)
        {
            var todaydatetime = DateTime.Now.ToString("d-MMM-yyyy hh.mm tt", CultureInfo.InvariantCulture);
            var result = new
            {
                titleMonth = "",
                currentdatetime = todaydatetime
            };

            // GlobalApp.CurrentReportMOC = CurrentMOC;
            if (!string.IsNullOrEmpty(currentReportMOC) && currentReportMOC != "undefined")
            {
                CurrentMOC = currentReportMOC;

                int currentMonth = Convert.ToInt16(CurrentMOC.Split('.').FirstOrDefault());
                string monthname = CultureInfo.CurrentCulture.DateTimeFormat.GetMonthName(currentMonth);

                result = new
                {
                    titleMonth = "for the month of " + monthname + " " + CurrentMOC.Split('.').Last(),
                    currentdatetime = todaydatetime
                };

            }

            return Json(result, JsonRequestBehavior.AllowGet);

        }
        public ActionResult GetMOCStatus()
        {
            List<MOCStatusModel> Listmocstat = new List<MOCStatusModel>();
            //viewModel = dashboardService.GetDashboardModel(CurrentMOC);
            //bool isValidMocPresent=bService.CheckMocStatus();
            for (int i = 1; i <= 12; i++)
            {
                DbRequest request = new DbRequest();

                request.SqlQuery = "SELECT * FROM " + DashBoardConstants.MOC_Status_Table_Name;
                DataTable dt = smartDataObj.GetData(request);

                List<MtMOCStatus> model = new List<MtMOCStatus>();
                if (dt != null)
                {
                    model = dt.DataTableToList<MtMOCStatus>();
                }
                var index = model.Where(item => item.MonthId == i).FirstOrDefault();

                MOCStatusModel viewModel = new MOCStatusModel();
                viewModel.MOCMonth = i;
                viewModel.MOCYear = DateTime.Now.Year;
                viewModel.MOCMonthName = CultureInfo.CurrentCulture.DateTimeFormat.GetAbbreviatedMonthName(i);
                if (index != null)
                {
                    viewModel.MOCStatus = index.Status;
                }
                else
                {
                    var openIndex = model.Where(item => item.Status.ToLower() == "open").FirstOrDefault();
                    if (openIndex != null)
                    {
                        if (i < openIndex.MonthId)
                        {
                            viewModel.MOCStatus = "close";
                        }
                        else
                        {
                            viewModel.MOCStatus = "";
                        }
                    }
                    else
                    {
                        viewModel.MOCStatus = "";
                    }
                }
                Listmocstat.Add(viewModel);
            }
            return PartialView("_mocStatus", Listmocstat);
        }
        [HttpGet]
        public JsonResult CheckForOpenMOC()
        {
            bool isOpenMOC = false;
            if (!string.IsNullOrEmpty(CurrentMOC))
            {
                isOpenMOC = true;
            }
            return Json(isOpenMOC, JsonRequestBehavior.AllowGet);
        }

        public ActionResult CreateNewMOC()
        {
            string msg = "";
            bool isSuceess = dashboardService.CreateNewMOC(out msg, loggedUser.UserId);
            if (isSuceess)
            {
                CurrentMOC = SetCurrentMOC();
            }
            //dashboardService.ArchiveData(CurrentMOC);

            return Json(new { success = isSuceess, msg = msg }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult GetThermometerData(int thermoYear)
        {
            List<ThermometerViewModel> mocMonthList = new List<ThermometerViewModel>();
            bool isSuccess;
            //try
            //{
            mocMonthList = dashboardService.GetSpecificYearMOCs(thermoYear);
            isSuccess = true;
            //}
            //catch (Exception ex)
            //{
            //    isSuccess = false;
            //}
            return Json(new { IsSuccess = isSuccess, mocList = mocMonthList }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult CloseMOC()
        {
            bool isSuccess;
            string msg = "";
            if (assignAccessService.CheckForStepExecuteRight(SecurityPageConstants.CloseMOC_PageId) == true)
            {
                try
                {
                    isSuccess = dashboardService.CloseMOC(CurrentMOC,loggedUser.UserId);
                    if (isSuccess)
                    {
                        dashboardService.Update_SingleStepStatus(DashBoardConstants.ExportJV_StepId, CurrentMOC);
                        dashboardService.Update_SingleStepStatus(DashBoardConstants.CloseMOC_StepId, CurrentMOC);

                        dashboardService.Queue(() =>
                        {
                            dashboardService.CallSPArchive();
                        }, null);
                    }
                    msg = "MOC Closed Successfully";
                }
                catch (Exception ex)
                {
                    isSuccess = false;
                    msg = ex.Message;
                }
            }
            else
            {
                isSuccess = false;
                msg = MessageConstants.InsufficientPermission;
            }
            return Json(new { IsSuccess = isSuccess, Msg = msg }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult ReopenMOC()
        {
            string msg = "";
            bool isSuceess = dashboardService.ReopenMOC(out msg);
            return Json(new { success = isSuceess, msg = msg }, JsonRequestBehavior.AllowGet);
        }

        public ActionResult ConfirmReopenMOC()
        {
            string msg = "";
            bool isSuceess = dashboardService.ConfirmReopenMOC(loggedUser.UserId);
            if (isSuceess)
            {
                CurrentMOC = SetCurrentMOC();
            }
            return Json(new { success = isSuceess, msg = msg }, JsonRequestBehavior.AllowGet);
        }
        
    }
}