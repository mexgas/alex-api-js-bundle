using System;
using System.Data.SqlClient;
using System.Collections.Specialized;
using System.Data;
using System.Text;
using Microsoft.Win32;

namespace MiddleWareReports
{
    public class DataBase
    {
        protected string connectionString;
        private static SqlConnectionStringBuilder csb = null;
   
        public DataBase()
        {
                if (csb == null)
                {
                    BuildConnectionString();
                }

                this.connectionString = csb.ConnectionString;

        }

        
        public DataBase(bool test)
        {
            this.connectionString = DbTest();
        }

        /// <summary>
        /// Obtener el valor de un setting
        /// </summary>
        /// <returns></returns>
        public String getSettingValue(int settingId)
        {
            String valor = "";
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = string.Format("Select valor from ccSettings where setting_id = {0}", settingId);
                    valor = cmd.ExecuteScalar().ToString();
                }
                catch (Exception ex)
                {
                    throw ex;
                }
            }
            return valor;
        }

        /// <summary>
        /// Executes the specified stored procedure with the given parameters
        /// </summary>
        /// <param name="storedProcedureName">Name of the stored procedure to be executed</param>
        /// <param name="parameters">The parameters that must be passed to the stored procedure</param>
        /// <remarks>The parameters must be named the same as the ones from the stored procedure</remarks>
        /// <returns>The DataTable that results from executing the stored procedure with the given parameters</returns>
        public DataTable executeSP(string storedProcedureName, NameValueCollection parameters)
        {
            DataTable table = new DataTable();
            try
            {
                SqlCommand command = new SqlCommand();
                command.CommandTimeout = 60;
                command.CommandText = storedProcedureName;
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Clear();

                foreach (string key in parameters.Keys)
                {

                    string value = parameters[key];
                    Type type = TypeInspector.getType(value);

                    Object obj;
                    var method = type.GetMethod("Parse", new Type[] { typeof(string) });
                    if (method == null)
                    {
                        obj = value;
                    }
                    else
                    {
                        obj = method.Invoke(method, new object[] { value });
                    }

                    if (obj is string)
                    {
                        string temp = (string)obj;
                        obj = temp.Replace('|', ',');
                    }

                    command.Parameters.AddWithValue("@" + key, obj);

                }

                SqlConnection connection = null;
                try
                {
                    using (connection = new SqlConnection(connectionString))
                    {
                        using (command)
                        {
                            if (connection.State != ConnectionState.Open)
                            {
                                connection.Open();
                            }
                            command.Connection = connection;
                            table.Load(command.ExecuteReader());
                        }
                    }
                }
                finally
                {
                    if (connection != null)
                    {
                        connection.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return table;
        }


        /// <summary>
        /// Executes the passed query and returns its results as a DataTable
        /// </summary>
        /// <param name="query">The query to be executed</param>
        /// <param name="parameters">The parameters to be passed in sp_executesql</param>
        /// <param name="values">The values used by query</param>
        /// <returns>The DataTable resulting from executing the query with an ExecuteReader method (sp_executesql)</returns>
        public DataTable executeDynamicQuery(StringBuilder query, StringBuilder parameters = null, NameValueCollection values = null)
        {
            DataTable table = new DataTable();
            Type type = typeof(String);
            try
            {
                SqlCommand command = new SqlCommand();
                command.CommandTimeout = 60;
                command.CommandText = "sp_executesql";
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Clear();
                command.Parameters.AddWithValue("@stmt", query.ToString());
                if (parameters != null && values != null)
                {
                    command.Parameters.AddWithValue("@params", parameters.ToString());
                    foreach (string parameter in values.Keys)
                    {
                        SqlParameter param = new SqlParameter();
                        param.ParameterName = parameter;
                        param.Value = values[parameter];
                        param.SqlDbType = DBSchema.getDataType(TypeInspector.removeMinMax(TypeInspector.removeDigits(parameter.Replace("@", ""))));
                        command.Parameters.Add(param);
                    }
                }
                SqlConnection connection = null;
                try
                {
                    using (connection = new SqlConnection(connectionString))
                    {
                        using (command)
                        {
                            if (connection.State != ConnectionState.Open)
                            {
                                connection.Open();
                            }
                            command.Connection = connection;
                            table.Load(command.ExecuteReader());
                        }
                    }
                }
                finally
                {
                    if (connection != null)
                    {
                        connection.Close();
                    }
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }

            return table;
        }


        /// <summary>
        /// Build the connection string to the report DB 
        /// </summary>      
        protected virtual void BuildConnectionString()
        {
            string database = "";
            string password = "";
            string server = "";
            string user = "";

            RegistryKey rKey = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Nuxiba\ReportsRia\", RegistryKeyPermissionCheck.ReadSubTree);

            if (rKey != null)
            {

                object key = rKey.GetValue("DataBase");
                if (key != null)
                    database = key.ToString();

                key = rKey.GetValue("PassWord");
                if (key != null)
                    password = key.ToString();

                key = rKey.GetValue("Server");
                if (key != null)
                    server = key.ToString();

                key = rKey.GetValue("User");
                if (key != null)
                    user = key.ToString();

                rKey.Close();
            }
            else
            {
                throw new Exception("Registry configuration not found");
            }

            csb = new SqlConnectionStringBuilder();
            string cypherKey = "nuxibaenckey0706";
            csb.DataSource = AesCipher.transform(server, cypherKey, false);
            csb.InitialCatalog = AesCipher.transform(database, cypherKey, false);
            csb.UserID = AesCipher.transform(user, cypherKey, false);
            csb.Password = AesCipher.transform(password, cypherKey, false);
            csb.AsynchronousProcessing = true;
            csb.MinPoolSize = 0;
            csb.MaxPoolSize = 10;
            csb.ApplicationName = "NuxibaReportsV2";

        }

        /// Test connection to the database
        /// </summary>
        /// <returns>A connection string with the current connection settings</returns>
        private string DbTest()
        {
            SqlConnectionStringBuilder connString = new SqlConnectionStringBuilder();
            connString.UserID = "ccUser";
            connString.Password = "guess";
            connString.DataSource = "192.168.1.143";
            connString.InitialCatalog = "ccReports";
            return connString.ToString();
        }
    }
}
