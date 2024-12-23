using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class DashBoardViewModel
    {
        public DashBoardViewModel()
        {
            DashboardSteps = new List<DashboardStepModel>();
        }
        public List<DashboardStepModel> DashboardSteps { get; set; }
    }

    public class DashboardStepModel
    {
        public string StepId { get; set; }
        public bool IsActive { get; set; }
    }
    public class MtStepMaster
    {
        public string StepId { get; set; }
        public int Sequence { get; set; }
        public string Name { get; set; }
        public string Type { get; set; }
    }

    public class MtMasterDetails
    {
        public string StepId { get; set; }
        public string DetailedStep { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public string CreatedBy { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string UpdatedBy { get; set; }
    }

    public class MtMOCStatus
    {
        public Guid Id { get; set; }
        public int MonthId { get; set; }
        public int Year { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public string CreatedBy { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string UpdatedBy { get; set; }
    }

    public class MtMOCWiseStepDetails
    {
        public Guid Id { get; set; }
        public int MonthId { get; set; }
        public int Year { get; set; }
        public string StepId { get; set; }
        public string Status { get; set; }
        public int ExecutionTimes { get; set; }
        public DateTime CreatedAt { get; set; }
        public string CreatedBy { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string UpdatedBy { get; set; }
    }
}
