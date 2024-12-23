using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Utility
{
    public class ExcelToDbColumnMapping
    {

        //public DataTable MapXcelColumnToDB(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        //{
        //    for (var j = 0; j < columnsInExcel.Count(); j++)
        //    {
        //        dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
        //    }

        //    //System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
        //    //newColumn1.DefaultValue = DateTime.Now;
        //    //dt.Columns.Add(newColumn1);

        //    //System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
        //    //newColumn2.DefaultValue = "admin";
        //    //dt.Columns.Add(newColumn2);

        //    //System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
        //    //newColumn3.DefaultValue = null;
        //    //dt.Columns.Add(newColumn3);

        //    //System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
        //    //newColumn4.DefaultValue = null;
        //    //dt.Columns.Add(newColumn4);

        //    //System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
        //    //newColumn5.DefaultValue = null;
        //    //dt.Columns.Add(newColumn5);

        //    //dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
        //    //for (int i = 0; i < dt.Rows.Count; i++)
        //    //{
        //    //    dt.Rows[i]["Id"] = i + 1;
        //    //}
        //    //dt.Columns["Id"].SetOrdinal(0);

        //    return dt;
        //}

        //public DataTable MapCustomerGroupMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        //{
        //    for (var j = 0; j < columnsInExcel.Count(); j++)
        //    {
        //        dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
        //    }

        //    System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
        //    newColumn1.DefaultValue = DateTime.Now;
        //    dt.Columns.Add(newColumn1);

        //    System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
        //    newColumn2.DefaultValue = "admin";
        //    dt.Columns.Add(newColumn2);

        //    System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
        //    newColumn3.DefaultValue = null;
        //    dt.Columns.Add(newColumn3);

        //    System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
        //    newColumn4.DefaultValue = null;
        //    dt.Columns.Add(newColumn4);

        //    System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
        //    newColumn5.DefaultValue = "I";
        //    dt.Columns.Add(newColumn5);

        //    //dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
        //    //for (int i = 0; i < dt.Rows.Count; i++)
        //    //{
        //    //    dt.Rows[i]["Id"] = i + 1;
        //    //}
        //    //dt.Columns["Id"].SetOrdinal(0);

        //    return dt;
        //}

        //public DataTable MapBrandwiseSubcategoryMappingMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        //{
        //    for (var j = 0; j < columnsInExcel.Count(); j++)
        //    {
        //        dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
        //    }

        //    System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
        //    newColumn1.DefaultValue = DateTime.Now;
        //    dt.Columns.Add(newColumn1);

        //    System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
        //    newColumn2.DefaultValue = "admin";
        //    dt.Columns.Add(newColumn2);

        //    System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
        //    newColumn3.DefaultValue = null;
        //    dt.Columns.Add(newColumn3);

        //    System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
        //    newColumn4.DefaultValue = null;
        //    dt.Columns.Add(newColumn4);

        //    System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
        //    newColumn5.DefaultValue = null;
        //    dt.Columns.Add(newColumn5);

        //    //dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
        //    //for (int i = 0; i < dt.Rows.Count; i++)
        //    //{
        //    //    dt.Rows[i]["Id"] = i + 1;
        //    //}
        //    //dt.Columns["Id"].SetOrdinal(0);

        //    return dt;
        //}

        public DataTable MapSubcategoryTOTMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB, string totCategory)
        {
            foreach (var column in dt.Columns.Cast<DataColumn>().ToArray())
            {
                if (dt.AsEnumerable().All(dr => dr.IsNull(column)))
                    dt.Columns.Remove(column);
            }

            DataTable tot_Dt = new DataTable();
            tot_Dt.Columns.Add("ChainName");
            tot_Dt.Columns.Add("GroupName");
            tot_Dt.Columns.Add("Branch");
            tot_Dt.Columns.Add("TOTSubCategory");
            tot_Dt.Columns.Add("OnInvoiceRate");
            tot_Dt.Columns.Add("OffInvoiceMthlyRate");
            tot_Dt.Columns.Add("OffInvoiceQtrlyRate");
            Dictionary<int, string> totSubcategories = new Dictionary<int, string>();

            string[] columnNames = dt.Columns.Cast<DataColumn>()
                                 .Select(x => x.ColumnName)
                                 .ToArray();
            for (var c = 3; c < columnNames.Count(); c++)
            {
                totSubcategories.Add(c, columnNames[c].ToString());
            }

            for (var r = 0; r < dt.Rows.Count; r++)
            {
                var branches = dt.Rows[r][2].ToString();
                var arr_branch = branches.Split(',');
                foreach (var br in arr_branch)
                {
                    foreach (KeyValuePair<int, string> kvp in totSubcategories)
                    {
                        if (dt.Rows[r][0].ToString() == "")
                        { 
                            continue;
                        }
                        var tableRow = tot_Dt.NewRow();
                        tableRow["ChainName"] = dt.Rows[r][0].ToString();
                        tableRow["GroupName"] = dt.Rows[r][1].ToString();
                        tableRow["Branch"] = br;

                        tableRow["TOTSubCategory"] = kvp.Value;
                        //tableRow["OnInvoiceRate"] = (String.IsNullOrEmpty(dt.Rows[r][kvp.Key].ToString())) ? (decimal)0.00 : (Convert.ToDecimal(dt.Rows[r][kvp.Key].ToString().Substring(0, dt.Rows[r][kvp.Key].ToString().LastIndexOf("%")))/100);
                        if (totCategory == "on")
                        {
                            tableRow["OnInvoiceRate"] = (String.IsNullOrEmpty(dt.Rows[r][kvp.Key].ToString())) ? (decimal)0.00 : (Convert.ToDecimal(dt.Rows[r][kvp.Key].ToString()));
                            tableRow["OffInvoiceMthlyRate"] = 0.00;
                            tableRow["OffInvoiceQtrlyRate"] = 0.00;
                        }
                        else if (totCategory == "off")
                        {
                            tableRow["OnInvoiceRate"] = 0.00;
                            tableRow["OffInvoiceMthlyRate"] = (String.IsNullOrEmpty(dt.Rows[r][kvp.Key].ToString())) ? (decimal)0.00 : (Convert.ToDecimal(dt.Rows[r][kvp.Key].ToString()));
                            tableRow["OffInvoiceQtrlyRate"] = 0.00;
                        }
                        else if (totCategory == "quarterly")
                        {
                            tableRow["OnInvoiceRate"] = 0.00;
                            tableRow["OffInvoiceMthlyRate"] = 0.00;
                            tableRow["OffInvoiceQtrlyRate"] = (String.IsNullOrEmpty(dt.Rows[r][kvp.Key].ToString())) ? (decimal)0.00 : (Convert.ToDecimal(dt.Rows[r][kvp.Key].ToString()));
                        }


                        tot_Dt.Rows.Add(tableRow);
                    }
                }

            }
            return tot_Dt;
        }

        public DataTable MapSkuMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        {
            for (var j = 0; j < columnsInExcel.Count(); j++)
            {
                dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
            }

            return dt;
        }


        //public DataTable MapClusterRSCodeMapping(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        //{
        //    for (var j = 0; j < columnsInExcel.Count(); j++)
        //    {
        //        dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
        //    }

        //    System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
        //    newColumn1.DefaultValue = DateTime.Now;
        //    dt.Columns.Add(newColumn1);

        //    System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
        //    newColumn2.DefaultValue = "admin";
        //    dt.Columns.Add(newColumn2);

        //    System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
        //    newColumn3.DefaultValue = null;
        //    dt.Columns.Add(newColumn3);

        //    System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
        //    newColumn4.DefaultValue = null;
        //    dt.Columns.Add(newColumn4);

        //    System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
        //    newColumn5.DefaultValue = "I";
        //    dt.Columns.Add(newColumn5);

        //    dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
        //    for (int i = 0; i < dt.Rows.Count; i++)
        //    {
        //        dt.Rows[i]["Id"] = i + 1;
        //    }
        //    dt.Columns["Id"].SetOrdinal(0);

        //    return dt;
        //}

        //public DataTable MapSalesTaxMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        //{
        //    for (var j = 0; j < columnsInExcel.Count(); j++)
        //    {
        //        dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
        //    }

        //    System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
        //    newColumn1.DefaultValue = DateTime.Now;
        //    dt.Columns.Add(newColumn1);

        //    System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
        //    newColumn2.DefaultValue = "admin";
        //    dt.Columns.Add(newColumn2);

        //    System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
        //    newColumn3.DefaultValue = null;
        //    dt.Columns.Add(newColumn3);

        //    System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
        //    newColumn4.DefaultValue = null;
        //    dt.Columns.Add(newColumn4);

        //    System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
        //    newColumn5.DefaultValue = "I";
        //    dt.Columns.Add(newColumn5);

        //    dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
        //    for (int i = 0; i < dt.Rows.Count; i++)
        //    {
        //        dt.Rows[i]["Id"] = i + 1;
        //    }
        //    dt.Columns["Id"].SetOrdinal(0);

        //    return dt;
        //}

        public DataTable MapMaster(DataTable dt, string[] columnsInExcel, string[] columnsInDB)
        {
            for (var j = 0; j < columnsInExcel.Count(); j++)
            {
                dt.Columns[columnsInExcel[j]].ColumnName = columnsInDB[j];
            }

            //System.Data.DataColumn newColumn1 = new System.Data.DataColumn("CreatedAt", typeof(System.DateTime));
            //newColumn1.DefaultValue = DateTime.Now;
            //dt.Columns.Add(newColumn1);

            //System.Data.DataColumn newColumn2 = new System.Data.DataColumn("CreatedBy", typeof(System.String));
            //newColumn2.DefaultValue = "admin";
            //dt.Columns.Add(newColumn2);

            //System.Data.DataColumn newColumn3 = new System.Data.DataColumn("UpdatedAt", typeof(System.DateTime));
            //newColumn3.DefaultValue = null;
            //dt.Columns.Add(newColumn3);

            //System.Data.DataColumn newColumn4 = new System.Data.DataColumn("UpdatedBy", typeof(System.DateTime));
            //newColumn4.DefaultValue = null;
            //dt.Columns.Add(newColumn4);

            //System.Data.DataColumn newColumn5 = new System.Data.DataColumn("Operation", typeof(System.String));
            //newColumn5.DefaultValue = "I";
            //dt.Columns.Add(newColumn5);

            //dt.Columns.Add(new DataColumn("Id", Type.GetType("System.Int32")));
            //for (int i = 0; i < dt.Rows.Count; i++)
            //{
            //    dt.Rows[i]["Id"] = i + 1;
            //}
            //dt.Columns["Id"].SetOrdinal(0);

            return dt;
        }

    }
}
