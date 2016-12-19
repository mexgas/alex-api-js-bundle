using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using Microsoft.Win32;
using ServicesAlertReport.Log;
using ServicesAlertReport.Security;

namespace ServicesAlertReport.DB
{
    public class DataBase
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

        public DataBase(Logger logger, string applicationName = "ServicesAlertReport")
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
        public void buildCnString(string db = "")
        {
            try
            {

                String database = "3b8d335069a8c5a373419a8c1c6bd0aa";
                String password = "370909b16ba952906b09a369fd49a8fd";
                String server = "f517a65163f31b824b09ce768a859e02"; //127.0.0.1                
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
