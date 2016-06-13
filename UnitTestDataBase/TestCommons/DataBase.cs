using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using TestCommons.util;

namespace TestCommons
{
    public class DataBase
    {
        private static volatile DataBase instance;
        private static object syncRoot = new Object();
        private static SqlConnectionStringBuilder csb;
        private SqlConnection asynConnection;
        private Random randy;
        private Logger logger;

        /// <summary>
        /// Crea una conexion a CCenterRIA y CCRecorderRIA
        /// </summary>
        private DataBase(Logger logger)
        {
            try
            {
                this.logger = logger;
                randy = new Random();
                buildCnString();
                asynConnection = new SqlConnection(csb.ToString());
                asynConnection.Open();
            }
            catch (Exception ex)
            {
                log("Constructor " + ex.Message, true);

            }
        }

        /// <summary>
        /// Crea una instancia de Base Datos para cualquier lugar de la aplicacion
        /// </summary>
        /// <returns></returns>
        public static DataBase getInstance(Logger log)
        {
            if (instance == null)
            {
                lock (syncRoot)
                {
                    if (instance == null)
                    {
                        instance = new DataBase(log);
                    }
                }
            }
            return instance;
        }

        /// <summary>
        /// Cadena de conexion para CCenterRIA y CCRecorderRIA con ApplicationName = "NuxibaBaseXMngr";
        /// </summary>
        /// <param name="db">si se marca opcion AVRS pide los registros de CCRecorder</param>
        private void buildCnString()
        {
            String database = "3b8d335069a8c5a373419a8c1c6bd0aa";
            String password = "370909b16ba952906b09a369fd49a8fd";
            String server = "494493634969ee62a57ae1decabd7c25"; //127.0.0.1                
            String user = "183f5bf17c2d2409157ead96ecfc25a7";
            RegistryKey rKey;

            rKey = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Nuxiba\Centerware_V\", RegistryKeyPermissionCheck.ReadSubTree);
            object key = null;

            if (rKey != null)
            {

                key = rKey.GetValue("DataBase");
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
            SqlConnectionStringBuilder temp;
            temp = new SqlConnectionStringBuilder();
            temp.DataSource = Aes.transform(server, "nuxibaenckey0706", false);
            temp.InitialCatalog = Aes.transform(database, "nuxibaenckey0706", false);
            temp.UserID = Aes.transform(user, "nuxibaenckey0706", false);
            temp.Password = Aes.transform(password, "nuxibaenckey0706", false);
            temp.AsynchronousProcessing = true;
            temp.MultipleActiveResultSets = true;
            temp.MinPoolSize = 0;
            temp.MaxPoolSize = 5;
            temp.ApplicationName = "NuxibaTestDB";

            csb = temp;

        }

        /// <summary>
        /// Obtine la ubicacion donde esta el log
        /// </summary>
        public Logger Log { set { logger = value; } }

        /// <summary>
        /// Realiza una cadena conexion a CCenterRIA para probar la conexion
        /// </summary>
        /// <returns></returns>
        public bool testConnexion()
        {
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = "select valor from ccsettings where setting_id = 77";
                    cmd.CommandType = CommandType.Text;
                    string temp = cmd.ExecuteScalar().ToString();
                }
                catch (Exception ex)
                {
                    log(getQuery(cmd) + " " + ex.Message, true);
                    return false;
                }
                finally
                {
                    laConnection.Close();
                }
            }
            return true;
        }

        /// <summary>
        /// Ejecuta una consulta a la base datos retorna un solo valor
        /// </summary>
        /// <param name="query"></param>
        /// <returns></returns>
        public object executeScalar(string query)
        {
            object res = null;
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = query;
                    cmd.CommandType = CommandType.Text;
                    res = cmd.ExecuteScalar();
                }
                catch (Exception ex)
                {
                    log(getQuery(cmd) + " " + ex.Message, true);

                }
                finally
                {
                    laConnection.Close();
                }
            }
            return res;
        }
        /// <summary>
        /// Ejecuta una consulta que no rergesa valores de forma sincrona
        /// </summary>
        /// <param name="query"></param>
        /// <returns></returns>
        public bool executeNonQuery(string query, out string error)
        {
            error = string.Empty;
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = query;
                    cmd.CommandType = CommandType.Text;
                    cmd.ExecuteNonQuery();
                    return true;
                }
                catch (Exception ex)
                {
                    error = ex.Message;
                    log(getQuery(cmd) + " " + ex.Message, true);
                    return false;
                }
                finally
                {
                    laConnection.Close();
                }
            }
        }


        #region Async
        private void insertNameBX(string name, int serviceId)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = "ccsp_BaseXmngr";
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@action", 4);
            cmd.Parameters.AddWithValue("@name", name);
            cmd.Parameters.AddWithValue("@option", serviceId);
            executeQueryAsync(cmd);
        }



        public void executeQueryAsync(SqlCommand cmd, int id = 0)
        {
            try
            {
                DbAsyncObject asyncObj = new DbAsyncObject();
                asyncObj.cmd = cmd;
                asyncObj.process = randy.Next(1, 10000);

                log("Starting DB Process: DB" + asyncObj.process + " - " + getQuery(asyncObj.cmd));

                if (asynConnection.State == ConnectionState.Closed)
                    asynConnection.Open();

                asyncObj.cmd.Connection = asynConnection;
                asyncObj.cmd.BeginExecuteNonQuery(onExecuteQuery, asyncObj);
            }
            catch (Exception e)
            {
                log(e.StackTrace + " " + e.Message, true);
                throw new IOException(e.Message);

            }
        }

        public void onExecuteQuery(IAsyncResult ar)
        {
            try
            {
                DbAsyncObject asyncObj = (DbAsyncObject)ar.AsyncState;
                asyncObj.cmd.EndExecuteNonQuery(ar);
                //cmd.Connection.Close();  <--No cerrar, si se hace otra peticion asincrona se rompe
                log("Process Finished : DB" + asyncObj.process);
            }
            catch (Exception e)
            {
                throw new IOException(e.Message);

            }
        }

        #endregion

        private void log(String message, Boolean isError = false)
        {
            if (isError)
            {
                message = "DBERROR " + message;
                logger.log(message);
            }
            else
                logger.log("DB " + message);
        }

        private static String getQuery(SqlCommand cmd)
        {
            String query = cmd.CommandText;
            SqlParameter p;

            for (int i = 0; i < cmd.Parameters.Count; i++)
            {
                p = cmd.Parameters[i];
                if (i == 0)
                    query += " " + p.ParameterName;
                else
                    query += ", " + p.ParameterName;

                query += "='" + p.Value.ToString() + "'";
            }

            return query;
        }
    }

    public struct DbAsyncObject
    {
        public SqlCommand cmd;
        public int process;
    }
}
