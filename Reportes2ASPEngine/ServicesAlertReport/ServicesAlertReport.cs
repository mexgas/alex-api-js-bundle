using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.ServiceProcess;
using System.Text;
using ServicesAlertReport.Log;
using ServicesAlertReport.DB;
using System.Reflection;
using System.Timers;

namespace ServicesAlertReport
{
    partial class ServicesAlertReport : ServiceBase
    {
        private static Logger mylog;
        private DataBase db;
        private System.Timers.Timer mainTimer;

        public ServicesAlertReport()
        {
            InitializeComponent();

            mylog = new Logger("ServicesAlertReport");
            mylog.open();
            db = new DataBase(mylog);
            Version vDownloadManager = Assembly.GetEntryAssembly().GetName().Version;
            mylog.log("SERVICE INFO: DownloadManager Version: " + vDownloadManager.ToString());


            mainTimer = new System.Timers.Timer();
            mainTimer.Elapsed += new ElapsedEventHandler(onElapsedTime);
            mainTimer.Interval = 1000 * 60;
            mainTimer.Enabled = false;
        }

        #region Methods Start Stop debug

        protected override void OnStart(string[] args)
        {
            lock (this)
            {              
                init();
            }
        }

        protected override void OnStop()
        {
            lock (this)
            {
                stop();
            }
        }

        public void debugStart()
        {
            OnStart(null);
        }
        public void debugStop()
        {
            OnStop();
        }
        public void debugRestart()
        {
            debugStop();
            debugStart();
        }
        public void debugTest(string x)
        {
            if (x == "restart")
            {
                debugRestart();
            }
        }

        #endregion


        /// <summary>
        /// Incia el timer
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="eArgs"></param>
        private void onElapsedTime(object sender, ElapsedEventArgs eArgs)
        {
            startCore();
        }


        /// <summary>
        /// Evento para iniciar los archivos configuracion  y la conexion con Activity Server
        /// </summary>
        private void startCore()
        {
            mainTimer.Stop();            

        }
        /// <summary>
        /// Detiene timmer para que no reinicie el servicio
        /// </summary>
        private void stopCore()
        {
            mainTimer.Stop();
        }

        /// <summary>
        /// Inicia el timer para la conexion
        /// </summary>
        private void init()
        {
            mainTimer.Start();
            log("SERVICE: DownloadManager Service Started");

        }
        /// <summary>
        /// Detiene el socket y timmer para detener el servicio
        /// </summary>
        private void stop()
        {         
            stopCore();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            log("SERVICE: DownloadManager Service is stopped");
        }

        /// <summary>
        /// Imprime informacion en el archivo y lo imprime en pantalla
        /// </summary>
        /// <param name="message"></param>
        /// <param name="isError"></param>
        private static void log(String message, bool isError = false)
        {
            mylog.log(message, isError);
        }

    }
}
