using Microsoft.Win32;
using System;
using System.Data.SqlClient;

namespace MiddleWareReports.db
{
    public class CRMxDatabase : DataBase
    {
        private static SqlConnectionStringBuilder csb = null;

        public CRMxDatabase()
            : base()
        {
            if (csb == null)
            {
                BuildConnectionString();
            }

            this.connectionString = csb.ConnectionString;
        }

        protected override void BuildConnectionString()
        {
            string database = "";
            string password = "";
            string server = "";
            string user = "";

            RegistryKey rKey = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Nuxiba\ReportsRia\", RegistryKeyPermissionCheck.ReadSubTree);

            if (rKey != null)
            {
                object key = rKey.GetValue("CRMxDataBase");
                if (key != null)
                {
                    database = key.ToString();
                }

                key = rKey.GetValue("CRMxPassWord");
                if (key != null)
                {
                    password = key.ToString();
                }

                key = rKey.GetValue("CRMxServer");
                if (key != null)
                {
                    server = key.ToString();
                }

                key = rKey.GetValue("CRMxUser");
                if (key != null)
                {
                    user = key.ToString();
                }

                rKey.Close();
            }
            else
            {
                throw new Exception("Registry configuration not found");
            }
            csb = new SqlConnectionStringBuilder();
            string cypherKey = "nuxibaenckey0706";
            csb.DataSource = server;
            csb.InitialCatalog = database;
            csb.UserID = AesCipher.transform(user, cypherKey, false);
            csb.Password = AesCipher.transform(password, cypherKey, false);
            csb.AsynchronousProcessing = true;
            csb.MinPoolSize = 0;
            csb.MaxPoolSize = 10;
            csb.ApplicationName = "NuxibaReportsV2";
        }
    }
}