using MT.Model;
using OfficeOpenXml.FormulaParsing.Excel.Functions.Information;
using OfficeOpenXml.FormulaParsing.Excel.Functions.RefAndLookup;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using NPOI.HSSF.UserModel;

namespace MT.Utility
{
    public class ReadExcel
    {
        public DataTable ReadExcelFile(string path)
        {
            DataTable dt = new DataTable();
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
            {
                IWorkbook workbook = null;
                if (Path.GetExtension(path).Equals(".xls"))
                {
                    workbook = new HSSFWorkbook(fs);  // For .xls files
                }
                else
                {
                    workbook = new XSSFWorkbook(fs);  // For .xlsx files
                }

                // Get the first sheet
                ISheet sheet = workbook.GetSheetAt(0);

                // Read the header row for column names
                IRow headerRow = sheet.GetRow(0);
                int cellCount = headerRow.LastCellNum;
                for (int i = 0; i < cellCount; i++)
                {
                    dt.Columns.Add(headerRow.GetCell(i).ToString());
                }

                // Read the rest of the rows
                for (int i = 1; i <= sheet.LastRowNum; i++)  // Skipping the header row
                {
                    IRow row = sheet.GetRow(i);
                    DataRow dataRow = dt.NewRow();
                    for (int j = 0; j < cellCount; j++)
                    {
                        dataRow[j] = row.GetCell(j) != null ? row.GetCell(j).ToString() : null;
                    }
                    dt.Rows.Add(dataRow);
                }

                // Filtering columns
                string[] columnsToCheck = { "Customer code", "Region" };
                foreach (var col in dt.Columns.Cast<DataColumn>().ToList())
                {
                    if (!columnsToCheck.Contains(col.ColumnName))
                    {
                        dt.Columns.Remove(col);
                    }
                }
            }
            return dt;
        }


        public bool ValidateExcel(string path)
        {
            bool isValid = true;
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
            {
                IWorkbook workbook = null;
                if (Path.GetExtension(path).Equals(".xls"))
                {
                    workbook = new HSSFWorkbook(fs);  // For .xls files
                }
                else
                {
                    workbook = new XSSFWorkbook(fs);  // For .xlsx files
                }

                // Get the first sheet
                ISheet sheet = workbook.GetSheetAt(0);

                // Read the header row for column names
                IRow headerRow = sheet.GetRow(0);
                int cellCount = headerRow.LastCellNum;

                string[] columnNames = new string[cellCount];
                for (int i = 0; i < cellCount; i++)
                {
                    columnNames[i] = headerRow.GetCell(i).ToString();
                }

                string[] columnsToCheck = { "Customer code", "Region" };
                isValid = !columnsToCheck.Except(columnNames).Any();
            }

            return isValid;
        }



        private BaseResponse ValidateExcel(string path, string[] columnsInExcel)
        {
            BaseResponse response = new BaseResponse();
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
            {
                IWorkbook workbook = null;
                if (Path.GetExtension(path).Equals(".xls"))
                {
                    workbook = new HSSFWorkbook(fs);  // For .xls files
                }
                else
                {
                    workbook = new XSSFWorkbook(fs);  // For .xlsx files
                }

                // Get the first sheet
                ISheet sheet = workbook.GetSheetAt(0);

                // Read the header row for column names
                IRow headerRow = sheet.GetRow(0);
                int cellCount = headerRow.LastCellNum;

                List<string> columnNamesInExcel = new List<string>();
                for (int i = 0; i < cellCount; i++)
                {
                    columnNamesInExcel.Add(headerRow.GetCell(i).ToString().ToLower().Trim());
                }

                foreach (var column in columnsInExcel)
                {
                    if (!columnNamesInExcel.Contains(column.ToLower().Trim()))
                    {
                        response.IsSuccess = false;
                        response.MessageText = "Columns not matching with the Template.<br/> Column Names should be: " + string.Join(",", columnsInExcel);
                        return response;
                    }
                }

                response.IsSuccess = true;
                response.MessageText = "success";
            }

            return response;
        }

        public DataTable GetDataTableFromExcelNPOI(string path, bool hasHeader = true)
        {
            DataTable dt = new DataTable();

            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
            {
                IWorkbook workbook = WorkbookFactory.Create(fs);
                ISheet sheet = workbook.GetSheetAt(0); // Get the first sheet

                IRow headerRow = sheet.GetRow(0);
                int cellCount = headerRow.LastCellNum;

                // Adding columns
                for (int i = 0; i < cellCount; i++)
                {
                    ICell cell = headerRow.GetCell(i);
                    if (hasHeader)
                    {
                        dt.Columns.Add(cell.ToString());
                    }
                    else
                    {
                        dt.Columns.Add($"Column {i + 1}");
                    }
                }

                // Reading data rows
                int rowCount = sheet.LastRowNum;
                for (int i = (hasHeader ? 1 : 0); i <= rowCount; i++)
                {
                    IRow row = sheet.GetRow(i);
                    DataRow dataRow = dt.NewRow();
                    for (int j = 0; j < cellCount; j++)
                    {
                        if (row.GetCell(j) != null)
                        {
                            dataRow[j] = row.GetCell(j).ToString();
                        }
                    }
                    dt.Rows.Add(dataRow);
                }
            }

            return dt;
        }


        public MasterResponse ValidateAndReadExcelWithoutHeader(string path, string[] columnsInExcel)
        {
            MasterResponse response = new MasterResponse();
            var dt = GetDataTableFromExcelNPOI(path, false); // Read without header

            List<string> columnNamesFromExcel = dt.Columns.Cast<DataColumn>()
                .Select(c => c.ColumnName.ToLowerInvariant()).ToList();

            // Validate columns
            if (!columnsInExcel.All(column => columnNamesFromExcel.Contains(column.ToLowerInvariant())))
            {
                response.IsSuccess = false;
                response.MessageText = "Columns not matching with the Template. Column Names should be: " + string.Join(",", columnsInExcel);
                return response;
            }

            response.IsSuccess = true;
            response.Data = dt;
            response.MessageText = "success";

            return response;
        }

        public MasterResponse ValidateAndReadExcel(string path, string[] columnsInExcel)
        {
            MasterResponse response = new MasterResponse();
            var dt = GetDataTableFromExcelNPOI(path, true); // Read with header

            List<string> columnNamesFromExcel = dt.Columns.Cast<DataColumn>()
                .Select(c => c.ColumnName.ToLowerInvariant()).ToList();

            // Validate columns
            if (!columnsInExcel.All(column => columnNamesFromExcel.Contains(column.ToLowerInvariant())))
            {
                response.IsSuccess = false;
                response.MessageText = "Columns not matching with the Template. Column Names should be: " + string.Join(",", columnsInExcel);
                return response;
            }

            response.IsSuccess = true;
            response.Data = dt;
            response.MessageText = "success";

            return response;
        }


        public DataTable RemoveDuplicates(DataTable table, List<string> keyColumns)
        {
            var uniqueness = new HashSet<string>();
            StringBuilder sb = new StringBuilder();
            DataRowCollection rows = table.Rows;
            ArrayList duplicateList = new ArrayList();
            int i = rows.Count;
            foreach (DataRow row in table.Rows)
            {
                sb.Length = 0;
                foreach (string colname in keyColumns)
                {
                    sb.Append(row[colname].ToString().Trim());
                    sb.Append("|");
                }

                if (uniqueness.Contains(sb.ToString()))
                {
                    duplicateList.Add(row);
                }
                else
                {
                    uniqueness.Add(sb.ToString());
                }
            }

            foreach (DataRow dRow in duplicateList)
                table.Rows.Remove(dRow);
            return table;
        }

        public DataTable RemoveDuplicateRows(DataTable dTable, string colName)
        {
            Hashtable hTable = new Hashtable();
            ArrayList duplicateList = new ArrayList();
            foreach (DataRow drow in dTable.Rows)
            {
                if (hTable.Contains(drow[colName]))
                    duplicateList.Add(drow);
                else
                    hTable.Add(drow[colName], string.Empty);
            }

            //Removing a list of duplicate items from datatable.
            foreach (DataRow dRow in duplicateList)
                dTable.Rows.Remove(dRow);

            //Datatable which contains unique records will be return as output.
            return dTable;
        }

        public MasterResponse ValidateAndReadSubCategoryTOTExcel(string path, string[] columnsInExcel, string totCategory)
        {
            MasterResponse response = new MasterResponse();
            DataTable dt = new DataTable();

            try
            {
                // Load the Excel file
                using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read))
                {
                    IWorkbook workbook = WorkbookFactory.Create(fs);

                    // Determine the correct sheet name based on `totCategory`
                    string sheetName = string.Empty;
                    if (totCategory == "on")
                    {
                        sheetName = "DIRECT-ECOMM-HAIKO-TOT (On)";
                    }
                    else if (totCategory == "off")
                    {
                        sheetName = "DIRECT-ECOMM-HAIKO-TOT (Off)";
                    }
                    else if (totCategory == "quarterly")
                    {
                        sheetName = "DIRECT-ECOMM-HAIKO-TOT (OffQtr)";
                    }

                    // Find the sheet by name
                    ISheet sheet = workbook.GetSheet(sheetName);

                    if (sheet == null)
                    {
                        response.IsSuccess = false;
                        response.MessageText = $"Sheet '{sheetName}' not found.";
                        return response;
                    }

                    // Read the first row (header) for column validation
                    IRow headerRow = sheet.GetRow(0);
                    List<string> columnNamesInExcel = new List<string>();
                    for (int i = 0; i < headerRow.LastCellNum; i++)
                    {
                        columnNamesInExcel.Add(headerRow.GetCell(i).ToString().ToLower().Trim());
                    }

                    // Validate that all columnsInExcel are present in the Excel file
                    foreach (var column in columnsInExcel)
                    {
                        if (!columnNamesInExcel.Contains(column.ToLower().Trim()))
                        {
                            response.IsSuccess = false;
                            response.MessageText = $"Columns not matching with the Template. Column Names should be: {string.Join(",", columnsInExcel)}";
                            return response;
                        }
                    }

                    // If validation is successful, read the data into the DataTable
                    int cellCount = headerRow.LastCellNum;

                    // Create DataTable columns
                    foreach (var col in columnsInExcel)
                    {
                        dt.Columns.Add(col);
                    }

                    // Read all rows (starting from row 1 for data)
                    for (int rowIdx = 1; rowIdx <= sheet.LastRowNum; rowIdx++)
                    {
                        IRow row = sheet.GetRow(rowIdx);
                        if (row == null) continue;

                        DataRow dataRow = dt.NewRow();
                        for (int colIdx = 0; colIdx < cellCount; colIdx++)
                        {
                            if (row.GetCell(colIdx) != null)
                            {
                                dataRow[colIdx] = row.GetCell(colIdx).ToString();
                            }
                        }
                        dt.Rows.Add(dataRow);
                    }

                    response.IsSuccess = true;
                    response.Data = dt;
                    response.MessageText = "success";
                }
            }
            catch (Exception ex)
            {
                response.IsSuccess = false;
                response.MessageText = $"An error occurred: {ex.Message}";
            }

            return response;
        }

    }

}