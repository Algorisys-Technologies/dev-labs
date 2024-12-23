using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.OleDb;
using System.Data.OracleClient;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.DataAccessLayer
{
    public class DataFactory
    {
        private DataFactory() { }

        public static IDbConnection CreateConnection
           (string ConnectionString,
           DatabaseType dbtype)
        {
            IDbConnection cnn;

            switch (dbtype)
            {
                case DatabaseType.Access:
                    cnn = new OleDbConnection
                       (ConnectionString);
                    break;
                case DatabaseType.SQLServer:
                    cnn = new SqlConnection
                       (ConnectionString);
                    break;
                case DatabaseType.Oracle:
                    cnn = new OracleConnection
                       (ConnectionString);
                    break;
                default:
                    cnn = new SqlConnection
                       (ConnectionString);
                    break;
            }

            return cnn;
        }


        public static IDbCommand CreateCommand
           (string CommandText, DatabaseType dbtype,
           IDbConnection cnn)
        {
            IDbCommand cmd;
            switch (dbtype)
            {
                case DatabaseType.Access:
                    cmd = new OleDbCommand
                       (CommandText,
                       (OleDbConnection)cnn);
                    break;

                case DatabaseType.SQLServer:
                    cmd = new SqlCommand
                       (CommandText,
                       (SqlConnection)cnn);
                    break;

                case DatabaseType.Oracle:
                    cmd = new OracleCommand
                       (CommandText,
                       (OracleConnection)cnn);
                    break;
                default:
                    cmd = new SqlCommand
                       (CommandText,
                       (SqlConnection)cnn);
                    break;
            }

            return cmd;
        }


        public static IDbDataAdapter CreateAdapter
           (IDbCommand cmd, DatabaseType dbtype)
        {
            DbDataAdapter da;
            switch (dbtype)
            {
                case DatabaseType.Access:
                    da = new OleDbDataAdapter((OleDbCommand)cmd);
                    break;

                case DatabaseType.SQLServer:
                    da = new SqlDataAdapter((SqlCommand)cmd);
                    break;

                case DatabaseType.Oracle:
                    da = new OracleDataAdapter((OracleCommand)cmd);
                    break;

                default:
                    da = new SqlDataAdapter((SqlCommand)cmd);
                    break;
            }

            return da;
        }


        public static void SetDbParameter(DbRequest request, IDbCommand command, DatabaseType dbtype)
        {
            if (null != request.Parameters && request.Parameters.Count > 0)
            {
                foreach (Parameter para in request.Parameters)
                {
                    DbParameter p1;
                    switch (dbtype)
                    {
                        case DatabaseType.Access:
                            p1 = new System.Data.OleDb.OleDbParameter(para.ParameterName, para.ParameterValue);
                            command.Parameters.Add(p1);
                            break;
                        case DatabaseType.SQLServer:
                            p1 = new System.Data.SqlClient.SqlParameter(para.ParameterName, para.ParameterValue);
                            command.Parameters.Add(p1);
                            break;
                        default:
                            command.Parameters.Add(para);
                            break;
                    }
                }
            }
        }

    }
}

