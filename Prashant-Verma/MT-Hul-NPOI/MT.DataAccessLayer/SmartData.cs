using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MT.CacheEngine;
using System.Xml;
using System.Data.OleDb;
using System.Diagnostics;
using System.IO;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using NPOI.HSSF.UserModel;

namespace MT.DataAccessLayer
{
    public class SmartData
    {
        string ConnectionString = ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString;
        DatabaseType dbtype = (DatabaseType)Enum.Parse(typeof(DatabaseType), ConfigurationSettings.AppSettings["DatabaseType"]);
        private static int bulkCopyTimeout = 2000;
        private static int bulkBatchSize = 10000;
        private static int commandTimeout = 120000;

        public void InsertDataUsingDataTable(List<IRow> rows, string[] columnsInExcel, string[] columnsInDB, string tableName)
        {
            const int batchSize = 10000; // Batch size for bulk copy
            DataTable dataTable = new DataTable(); // Create a DataTable to hold the data

            try
            {
                // Add columns to DataTable based on columns in DB
                foreach (var column in columnsInDB)
                {
                    dataTable.Columns.Add(column);
                }

                // Process each row and add it to the DataTable
                foreach (var row in rows)
                {
                    DataRow dataRow = dataTable.NewRow();

                    for (int i = 0; i < columnsInDB.Length; i++)
                    {
                        // Ensure the row has enough cells to match the columns
                        if (i < row.LastCellNum)
                        {
                            var cell = row.GetCell(i);
                            if (cell != null)
                            {
                                dataRow[i] = cell.ToString(); // Assuming string data; adjust as needed for types
                            }
                        }
                    }

                    dataTable.Rows.Add(dataRow);
                }

                Console.WriteLine("Opening SQL connection...");
                Debug.WriteLine("Opening SQL connection...");

                // Perform bulk insert
                using (SqlConnection sqlcon = new SqlConnection(ConnectionString))
                {
                    sqlcon.Open();
                    Debug.WriteLine("SQL connection opened successfully.");

                    using (SqlBulkCopy bulkCopy = new SqlBulkCopy(sqlcon))
                    {
                        bulkCopy.BulkCopyTimeout = bulkCopyTimeout;
                        bulkCopy.BatchSize = batchSize;
                        bulkCopy.DestinationTableName = tableName;

                        // Map DataTable columns to database columns
                        for (int i = 0; i < columnsInDB.Length; i++)
                        {
                            bulkCopy.ColumnMappings.Add(columnsInDB[i], columnsInDB[i]);
                        }

                        Debug.WriteLine("Starting bulk copy...");
                        bulkCopy.WriteToServer(dataTable);  // Directly write the DataTable to the server
                        Debug.WriteLine("Bulk copy completed successfully.");
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"An error occurred: {ex.Message}");
                throw;
            }
        }

        //Function to Insert Records  
        public void InsertCSVRecords(DataTable csvdt, string[] columnsInExcel, string[] columnsInDB, string tableName)
        {

            using (SqlConnection sqlcon = new SqlConnection(ConnectionString))
            {
                
                using (SqlBulkCopy bulkCopy = new SqlBulkCopy(sqlcon))
                {
                    bulkCopy.BulkCopyTimeout = bulkCopyTimeout;
                    bulkCopy.BatchSize = bulkBatchSize;
                    //MasterConstants.UploadSecondarySales_DB_Column
                    //Mapping Table column    
                    for (global::System.Int32 i = 0; i < columnsInDB.Length; i++)
                    {
                        bulkCopy.ColumnMappings.Add(columnsInDB[i], columnsInDB[i]);
                    }
                    bulkCopy.DestinationTableName = tableName;// "mtSecSalesReport1";
                    sqlcon.Open();
                    bulkCopy.WriteToServer(csvdt);
                    sqlcon.Close();
                }
            }
        }
        public DataTable GetData(DbRequest request)
        {
            DataSet ds = new DataSet();
            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                IDbCommand cmd = DataFactory.CreateCommand(request.SqlQuery, dbtype, cnn);

                DataFactory.SetDbParameter(request, cmd, dbtype);

                IDbDataAdapter da = DataFactory.CreateAdapter(cmd, dbtype);
                //new SqlParameter

                da.Fill(ds);
            }

            return ds.Tables[0];
        }

        public DataSet GetDataSet(DbRequest request)
        {
            DataSet ds = new DataSet();
            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                IDbCommand cmd = DataFactory.CreateCommand(request.SqlQuery, dbtype, cnn);

                DataFactory.SetDbParameter(request, cmd, dbtype);

                IDbDataAdapter da = DataFactory.CreateAdapter(cmd, dbtype);
                //new SqlParameter

                da.Fill(ds);
            }

            return ds;
        }



        public int ExecuteQuery(DbRequest request)
        {
            int noOfRowsAffected = 0;
            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                cnn.Open();
                IDbCommand cmd = DataFactory.CreateCommand(request.SqlQuery, dbtype, cnn);
                DataFactory.SetDbParameter(request, cmd, dbtype);

                noOfRowsAffected = cmd.ExecuteNonQuery();

            }
            return noOfRowsAffected;

        }
        public void ExecuteNonQuery(DbRequest request)
        {

            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                cnn.Open();
                IDbCommand cmd = DataFactory.CreateCommand(request.SqlQuery, dbtype, cnn);
                DataFactory.SetDbParameter(request, cmd, dbtype);
                cmd.ExecuteNonQuery();

            }


        }
        public string ExecuteScalarGetString(DbRequest request)
        {
            string result = "null";
            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                cnn.Open();
                IDbCommand cmd = DataFactory.CreateCommand(request.SqlQuery, dbtype, cnn);
                DataFactory.SetDbParameter(request, cmd, dbtype);
                var data = cmd.ExecuteScalar();
                if (data != null)
                {
                    result = data.ToString();
                }
            }

            return result;

        }
        public XmlDocument ExtractXMLDoc(DbRequest request)
        {
            XmlReader reader;

            XmlDocument xmlDoc;


            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                cnn.Open();
                IDbCommand cmd = DataFactory.CreateCommand(request.SqlQuery, dbtype, cnn);
                DataFactory.SetDbParameter(request, cmd, dbtype);
                reader = ((SqlCommand)cmd).ExecuteXmlReader();

            }
            xmlDoc = new XmlDocument();



            while (reader.Read())
            {

                xmlDoc.Load(reader);

            }

            return xmlDoc;

        }

        public int ExecuteStoredProcedure(DbRequest request)
        {
            int noOfRowsAffected = 0;
            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                cnn.Open();
                IDbCommand cmd = DataFactory.CreateCommand(request.StoredProcedureName, dbtype, cnn);
                cmd.CommandType = CommandType.StoredProcedure;
                DataFactory.SetDbParameter(request, cmd, dbtype);
                cmd.CommandTimeout = commandTimeout;
                noOfRowsAffected = cmd.ExecuteNonQuery();
            }
            return noOfRowsAffected;

        }

        public DataTable GetdataExecuteStoredProcedure(DbRequest request)
        {
            DataSet ds = new DataSet();
            using (IDbConnection cnn = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                IDbCommand cmd = DataFactory.CreateCommand(request.StoredProcedureName, dbtype, cnn);
                cmd.CommandType = CommandType.StoredProcedure;

                DataFactory.SetDbParameter(request, cmd, dbtype);

                IDbDataAdapter da = DataFactory.CreateAdapter(cmd, dbtype);
                //new SqlParameter

                da.Fill(ds);
            }

            return ds.Tables[0];

        }
        public void BulkInsert(DataTable sourceTable)
        {
            //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --start
            string correctColumnsOrder = GetColumns(sourceTable);
            using (IDbConnection connection = DataFactory.CreateConnection(ConnectionString, dbtype))
            {
                connection.Open();
                if (!IsTableStructureValid(sourceTable.TableName, correctColumnsOrder, connection))
                {
                    // throw exception if table structure is invalid
                    string msg = "The column order for " + sourceTable.TableName + " is not correct.  Please verify." + Environment.NewLine;
                    msg += "The correct order is [" + correctColumnsOrder + "]";

                    connection.Dispose();
                    // throw new TableStructureException(msg);
                    throw new Exception(msg);
                }


                //using (SqlConnection cnn = new SqlConnection(ConnectionString))
                //{
                using (SqlBulkCopy bulkCopy = new SqlBulkCopy((SqlConnection)connection, SqlBulkCopyOptions.Default, null))
                {
                    bulkCopy.DestinationTableName = sourceTable.TableName;
                    bulkCopy.BulkCopyTimeout = bulkCopyTimeout;
                    bulkCopy.BatchSize = bulkBatchSize;
                    try
                    {
                        // Write from the source to the destination.
                        bulkCopy.WriteToServer(sourceTable);
                    }
                    catch (Exception ex)
                    {
                        // LOG the exceptions here.
                        throw;
                    }
                }
            }
            //  }

        }

        //public void Insert(DataTable sourceTable, SqlConnection connection, SqlTransaction tx)
        //{

        //        // Create the SqlBulkCopy object. 
        //        // Note that the column positions in the source DataTable 
        //        // match the column positions in the destination table so 
        //        // there is no need to map columns. 

        //        //new SqlBulkCopy(connection, SqlBulkCopyOptions.TableLock, null);   // Check this for more performance, but will lock the table.

        //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --start
        //string correctColumnsOrder = GetColumns(sourceTable);
        //if (!IsTableStructureValid(sourceTable.TableName, correctColumnsOrder, connection, tx))
        //{
        //    // throw exception if table structure is invalid
        //    string msg = "The column order for " + sourceTable.TableName + " is not correct.  Please verify." + Environment.NewLine;
        //    msg += "The correct order is [" + correctColumnsOrder + "]";

        //    ////connection.Dispose();
        //    // throw new TableStructureException(msg);
        //    throw new Exception(msg);
        //}
        //        //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --end
        //        //changed by UP - default
        //        using (SqlBulkCopy bulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, tx))
        //        {
        //            bulkCopy.DestinationTableName = sourceTable.TableName;
        //            bulkCopy.BulkCopyTimeout = bulkCopyTimeout;
        //            bulkCopy.BatchSize = bulkBatchSize;
        //            try
        //            {
        //                // Write from the source to the destination.
        //                bulkCopy.WriteToServer(sourceTable);
        //            }
        //            catch (Exception ex)
        //            {
        //                // LOG the exceptions here.
        //                throw;
        //            }
        //        }           
        //}

        public void BulkUpdate(DataTable sourceTable, string spName)
        {
            // First insert in the staging table, then bulk update
            using (SqlConnection connection = new SqlConnection(ConnectionString))
            {
                connection.Open();

                // Create the SqlBulkCopy object. 
                // Note that the column positions in the source DataTable 
                // match the column positions in the destination table so 
                // there is no need to map columns. 

                //new SqlBulkCopy(connection, SqlBulkCopyOptions.TableLock, null);   // Check this for more performance, but will lock the table.

                //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --start
                string correctColumnsOrder = GetColumns(sourceTable);
                if (!IsTableStructureValid(sourceTable.TableName, correctColumnsOrder, connection))
                {
                    // throw exception if table structure is invalid
                    string msg = "The column order for " + sourceTable.TableName + " is not correct.  Please verify." + Environment.NewLine;
                    msg += "The correct order is [" + correctColumnsOrder + "]";

                    connection.Dispose();
                    //throw new TableStructureException(msg);
                    throw new Exception(msg);
                }
                //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --end

                string tempTableName = "#" + sourceTable.TableName;
                SqlCommand command1 = new SqlCommand("SET ROWCOUNT 1; SELECT * INTO " + tempTableName + " FROM " + sourceTable.TableName + " WHERE 1=0; SET ROWCOUNT 0;", connection);
                command1.CommandType = CommandType.Text;
                command1.ExecuteNonQuery();

                //changed by UP - default
                using (SqlBulkCopy bulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, null))
                {
                    //bulkCopy.DestinationTableName = "_" + sourceTable.TableName;
                    bulkCopy.DestinationTableName = tempTableName;
                    bulkCopy.BulkCopyTimeout = bulkCopyTimeout;
                    bulkCopy.BatchSize = bulkBatchSize;

                    try
                    {
                        // Write from the source to the destination.
                        bulkCopy.WriteToServer(sourceTable);
                    }
                    catch (Exception ex)
                    {
                        // LOG the exceptions here.
                        throw;
                    }
                }


                string commandText = spName; // "uspSecSalesCalculations";

                SqlCommand command = new SqlCommand(commandText, connection);
                command.CommandType = CommandType.StoredProcedure;
                command.Connection = connection;
                command.CommandTimeout = commandTimeout;
                command.ExecuteNonQuery();
            }
        }

        //public void Update(DataTable sourceTable, string spName, SqlConnection connection, SqlTransaction tx)
        //{
        //    // First insert in the staging table, then bulk update

        //    // Create the SqlBulkCopy object. 
        //    // Note that the column positions in the source DataTable 
        //    // match the column positions in the destination table so 
        //    // there is no need to map columns. 

        //    //new SqlBulkCopy(connection, SqlBulkCopyOptions.TableLock, null);   // Check this for more performance, but will lock the table.

        //    //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --start
        //    string correctColumnsOrder = GetColumns(sourceTable);
        //    if (!IsTableStructureValid(sourceTable.TableName, correctColumnsOrder, connection, tx))
        //    {
        //        // throw exception if table structure is invalid
        //        string msg = "The column order for " + sourceTable.TableName + " is not correct.  Please verify." + Environment.NewLine;
        //        msg += "The correct order is [" + correctColumnsOrder + "]";

        //        connection.Dispose();
        //        //throw new TableStructureException(msg);
        //        throw new Exception(msg);
        //    }
        //    //[CR128]: Validations added for Bulk insert to check the sequence of table columns.  --end

        //    string tempTableName = "#" + sourceTable.TableName;
        //    SqlCommand command1 = new SqlCommand("SET ROWCOUNT 1; SELECT * INTO " + tempTableName + " FROM " + sourceTable.TableName + " WHERE 1=0; SET ROWCOUNT 0;", connection);
        //    command1.CommandType = CommandType.Text;
        //    command1.Transaction = tx;
        //    command1.ExecuteNonQuery();

        //    //changed by UP - default
        //    using (SqlBulkCopy bulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, tx))
        //    {
        //        //bulkCopy.DestinationTableName = "_" + sourceTable.TableName;
        //        bulkCopy.DestinationTableName = tempTableName;
        //        bulkCopy.BulkCopyTimeout = bulkCopyTimeout;
        //        bulkCopy.BatchSize = bulkBatchSize;

        //        try
        //        {
        //            // Write from the source to the destination.
        //            bulkCopy.WriteToServer(sourceTable);
        //        }
        //        catch (Exception ex)
        //        {
        //            // LOG the exceptions here.
        //            throw;
        //        }
        //    }

        //    DataRow queryRow = dsSQL.Tables["Query"].Select("Id = '" + spName + "'")[0];

        //    string commandText = queryRow["CommandText"].ToString();
        //    string commandType = queryRow["CommandType"].ToString();

        //    SqlCommand command = new SqlCommand(commandText, connection);
        //    command.CommandType = (CommandType)Enum.Parse(typeof(CommandType), commandType);
        //    command.Connection = connection;
        //    command.Transaction = tx;
        //    command.CommandTimeout = commandTimeout;
        //    command.ExecuteNonQuery();

        //}


        private string GetColumns(DataTable table)
        {
            string columns = "";
            foreach (DataColumn col in table.Columns)
            {
                columns += col.ColumnName.ToLower() + ",";
            }
            columns = columns.Substring(0, columns.Length - 1);

            return columns;
        }

        private bool IsTableStructureValid(string tableName, string columns, IDbConnection connection)
        {
            bool result = true;

            //changed by UP - Caching
            var tableColumns = CacheManager<object>.Cache.Get(tableName + "-Columns");
            if (null == tableColumns || tableColumns.ToString().Length == 0)
            {
                //select STUFF(COLUMN_NAME, 1, 1, '') AS COLUMN_NAME from sys.tables t CROSS APPLY  (SELECT ',' + name AS [text()] FROM sys.columns c WHERE c.object_id = t.object_id FOR XML PATH('') ) o (COLUMN_NAME) where name='ebgltransaction'
                string query = "select STUFF(COLUMN_NAME, 1, 1, '') AS COLUMN_NAME from sys.tables t CROSS APPLY  (SELECT ',' + name AS [text()] FROM sys.columns c WHERE c.object_id = t.object_id FOR XML PATH('') ) o (COLUMN_NAME)";
                query += "where name='" + tableName + "'";

                IDbCommand cmd = DataFactory.CreateCommand(query, dbtype, connection);

                //SqlCommand command1 = new SqlCommand(query, connection);
                //command1.CommandType = CommandType.Text;
                //var tableColumns = command1.ExecuteScalar();
                tableColumns = cmd.ExecuteScalar();
                CacheManager<object>.Cache.Add(tableName + "-Columns", tableColumns);
            }
            if (!columns.ToLower().Equals(tableColumns.ToString().ToLower()))
            {
                result = false;
            }
            return result;
        }

        private bool IsTableStructureValid(string tableName, string columns, IDbConnection connection, SqlTransaction tx)
        {
            bool result = true;

            //changed by UP - Caching
            var tableColumns = CacheManager<object>.Cache.Get(tableName + "-Columns");
            if (null == tableColumns || tableColumns.ToString().Length == 0)
            {
                //select STUFF(COLUMN_NAME, 1, 1, '') AS COLUMN_NAME from sys.tables t CROSS APPLY  (SELECT ',' + name AS [text()] FROM sys.columns c WHERE c.object_id = t.object_id FOR XML PATH('') ) o (COLUMN_NAME) where name='ebgltransaction'
                string query = "select STUFF(COLUMN_NAME, 1, 1, '') AS COLUMN_NAME from sys.tables t CROSS APPLY  (SELECT ',' + name AS [text()] FROM sys.columns c WHERE c.object_id = t.object_id FOR XML PATH('') ) o (COLUMN_NAME)";
                query += "where name='" + tableName + "'";
                IDbCommand cmd = DataFactory.CreateCommand(query, dbtype, connection);

                //SqlCommand command1 = new SqlCommand(query, connection);
                //command1.CommandType = CommandType.Text;
                //var tableColumns = command1.ExecuteScalar();
                tableColumns = cmd.ExecuteScalar();
                CacheManager<object>.Cache.Add(tableName + "-Columns", tableColumns);
            }
            if (!columns.ToLower().Equals(tableColumns.ToString().ToLower()))
            {
                result = false;
            }
            return result;
        }


        public void Bulk_Update(DataTable sourceTable, string spName, string paramName)
        {
            DataTable dt = new DataTable();
            dt = sourceTable;

            string constr = ConnectionString;
            using (SqlConnection con = new SqlConnection(constr))
            {
                using (SqlCommand cmd = new SqlCommand(spName))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Connection = con;
                    cmd.Parameters.AddWithValue(paramName, dt);
                    con.Open();
                    cmd.ExecuteNonQuery();
                    con.Close();
                }
            }
        }

    }
}
