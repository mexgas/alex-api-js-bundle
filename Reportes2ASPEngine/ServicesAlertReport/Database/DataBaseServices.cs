using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using Microsoft.Win32;
using ServicesAlertReport.Log;
using ServicesAlertReport.Security;
using System.Collections;

namespace ServicesAlertReport.DB
{
    public class DataBaseServices
    {
        /**************************************
         * 1) Si se van a hacer updates sin esperar resultado, usar la funcion executeQueryAsync, solamente hay que poner los parametros en el SqlCommand
         * 2) Si se espera algun resultado, usar el using para no dejar las conexiones abiertas
         * */

        public static int minRequieredVersion = 119;
        protected static SqlConnectionStringBuilder csb;
        protected SqlConnection asynConnection;
        public Logger logger;
        private Random randy;
        protected string ApplicationName;

        public DataBaseServices(Logger logger, string applicationName = "ServicesAlertReport")
        {
            this.logger = logger;
            try
            {
                randy = new Random();
                this.ApplicationName = applicationName;
                buildCnString();
                asynConnection = new SqlConnection(csb.ToString());
                asynConnection.Open();
            }
            catch (Exception e)
            {
                log(e.Message, true);
            }
        }

        /// <summary>
        /// Conexion a las diferentes base de datos CW y AVRS
        /// </summary>
        /// <param name="db">Si es igual a AVRS busca el registro pertinente</param>
        public void buildCnString()
        {
            try
            {

                String database = "3b8d335069a8c5a373419a8c1c6bd0aa";
                String password = "370909b16ba952906b09a369fd49a8fd";
                String server = "f517a65163f31b824b09ce768a859e02"; //127.0.0.1                
                String user = "183f5bf17c2d2409157ead96ecfc25a7";
                RegistryKey rKey;
                rKey = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Nuxiba\ReportsRia\", RegistryKeyPermissionCheck.ReadSubTree);

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

                SqlConnectionStringBuilder csbTemp = new SqlConnectionStringBuilder();
                csbTemp.DataSource = AesCipher.transform(server, "nuxibaenckey0706", false);
                csbTemp.InitialCatalog = AesCipher.transform(database, "nuxibaenckey0706", false);
                csbTemp.UserID = AesCipher.transform(user, "nuxibaenckey0706", false);
                csbTemp.Password = AesCipher.transform(password, "nuxibaenckey0706", false);
                csbTemp.AsynchronousProcessing = true;
                csbTemp.MultipleActiveResultSets = true;
                csbTemp.MinPoolSize = 0;
                csbTemp.MaxPoolSize = 5;
                csbTemp.ApplicationName = ApplicationName;

                csb = csbTemp;

                log("Connection string built to server: " + csbTemp.DataSource);
            }
            catch (Exception e)
            {
                log(e.Message);
            }
        }


        /// <summary>
        /// Obtiene los action para ejecutarse de maneara dinamica
        /// </summary>        
        /// <returns></returns>
        public List<int> getListAction()
        {

            List<int> list = new List<int>();
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = "ccspAlertMailReport";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@action", 0);
                    SqlDataReader dr = cmd.ExecuteReader();
                    while (dr.Read())
                    {
                        list.Add(Convert.ToInt32(dr[0]));
                    }
                }
                catch (Exception e)
                {
                    log(getQuery(cmd) + " " + e.Message, true);
                }
                finally
                {
                    laConnection.Close();
                }
                return list;
            }

        }
        /// <summary>
        /// Obtiene la ultima ejecuccion del Job Master Process
        /// </summary>
        /// <returns></returns>
        public DataReport getDataLastRunJob()
        {

            DataReport dataRes = null;
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = "ccspAlertMailReport";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@action", 1);
                    SqlDataReader dr = cmd.ExecuteReader();
                    if (dr.Read())
                    {
                        dataRes = new DataReport(Convert.ToDateTime(dr[0]), Convert.ToDateTime(dr[1]), Convert.ToInt32(dr[2].ToString()));
                    }
                }
                catch (Exception e)
                {
                    log(getQuery(cmd) + " " + e.Message, true);
                }
                finally
                {
                    laConnection.Close();
                }
                return dataRes;
            }

        }

        /// <summary>
        /// Lista Mail by Report 
        /// </summary>
        /// <param name="type">0 Validate Report, 1 Info Report</param>
        /// <returns></returns>
        public ArrayList getListMail(int type = 0)
        {

            ArrayList list = new ArrayList();
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = "ccspAlertMailReport";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@action", 2);
                    SqlDataReader dr = cmd.ExecuteReader();
                    while (dr.Read())
                    {
                        list.Add(dr[0]);
                    }
                }
                catch (Exception e)
                {
                    log(getQuery(cmd) + " " + e.Message, true);
                }
                finally
                {
                    laConnection.Close();
                }
                return list;
            }

        }

        

        /// <summary>
        /// Revisa si el Reporter AgentGI tiene errores
        /// </summary>
        /// <returns></returns>
        public DataTable getValidateReportAgentGI()
        {

            DataTable table = new DataTable();
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = "ccspAlertMailReport";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@action", 3);
                    table.Load(cmd.ExecuteReader());
                }
                catch (Exception e)
                {
                    log(getQuery(cmd) + " " + e.Message, true);
                }
                finally
                {
                    laConnection.Close();
                }
                return table;
            }

        }


        /// <summary>
        /// Revisa si el Reporter AgentGI tiene errores
        /// </summary>
        /// <returns></returns>
        public DataTable getReportGeneric(int action)
        {

            DataTable table = new DataTable();
            using (SqlConnection laConnection = new SqlConnection(csb.ConnectionString))
            {
                SqlCommand cmd = new SqlCommand();
                try
                {
                    laConnection.Open();
                    cmd.Connection = laConnection;
                    cmd.CommandText = "ccspAlertMailReport";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@action", action);
                    table.Load(cmd.ExecuteReader());
                }
                catch (Exception e)
                {
                    log(getQuery(cmd) + " " + e.Message, true);
                }
                finally
                {
                    laConnection.Close();
                }
                return table;
            }

        }

        /// <summary>
        /// Obtener el valor de un setting
        /// </summary>
        /// <returns></returns>
        public String getValueSetting(int settingId)
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
                catch (Exception e)
                {
                    log(getQuery(cmd) + " " + e.Message, true);
                }
            }
            return valor;
        }

        /// <summary>
        /// Obtiene las credenciales del correo
        /// </summary>
        /// <returns></returns>
        public SMTPData getSmtpProperties()
        {
            SMTPData smtpData = new SMTPData();
            string value = getValueSetting(36);

            try
            {
                string[] paramValues = value.Split('|');
                if (paramValues.Length >= 5)
                {
                    smtpData.server = paramValues[0];
                    smtpData.user = paramValues[1];
                    smtpData.pwd = paramValues[2];
                    smtpData.port = Convert.ToInt32(paramValues[3]);
                    smtpData.useSSL = paramValues[4] == "1";
                }
            }
            catch (Exception e)
            {
                log(string.Format("Error Parser Account SMPT {0}, error:{1}", value, e.Message), true);
            }
            return smtpData;
        }

        #region CW



        /// <summary>
        /// Coloca la ubicacion del servicio en el setting designado
        /// </summary>
        /// <param name="ip"></param>
        /// <param name="settingId"></param>
        public void updateLocation(String ip, string settingId)
        {
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = "update ccsettings set valor='" + ip + "' where setting_id = " + settingId;
            executeQueryAsync(cmd);
        }





        #endregion



        #region QueryAsync

        /// <summary>
        /// 
        /// </summary>
        /// <param name="ar"></param>
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
                log(e.StackTrace + " " + e.Message, true);
            }
        }
        /// <summary>
        /// Ejecuta consultas que no regrese respuestas
        /// </summary>
        /// <param name="cmd"></param>
        public void executeQueryAsync(SqlCommand cmd)
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
            }
        }
        #endregion

        #region Method Protected
        protected void log(String message, Boolean isError)
        {
            if (isError)
            {
                message = "DBERROR " + message;
                logger.log(message);
            }
            else
                logger.log("DB " + message);
        }

        protected void log(String message)
        {
            log(message, false);
        }

        protected static String getQuery(SqlCommand cmd)
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

        #endregion
    }

    public struct DbAsyncObject
    {
        public SqlCommand cmd;
        public int process;
    }
}
