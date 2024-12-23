using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Model
{
    public class ToTProvisionTrendModel
    {
        public string SubCategory { get; set; }
        public List<MonthlyToTProvisionTrend> MonthlyToTProvisionTrend { get; set; }
    }
    public class MonthlyToTProvisionTrend
    {

        public string UniqueMonthName { get; set; }
        public decimal SalesTUR { get; set; }
        public decimal ToTProvision { get; set; }
        public decimal ToTPercentage { get; set; }
    }
}
