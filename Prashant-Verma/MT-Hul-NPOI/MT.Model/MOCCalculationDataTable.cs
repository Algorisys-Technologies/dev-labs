using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MT.Model
{

    public class MOCCalculationDataTable : DataTableBaseMaster
    {
        public List<MtMOCCalculation> data { get; set; }
    }
}