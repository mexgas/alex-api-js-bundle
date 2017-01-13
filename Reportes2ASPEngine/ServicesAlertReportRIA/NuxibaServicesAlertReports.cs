using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using MiddleWareReports.Log;
using MiddleWareReports;
using System.Reflection;
using System.Timers;

namespace ServicesAlertReportRIA
{
    partial class NuxibaServicesAlertReports : ServiceBase
    {
        private static Logger myLog;
        private DataBase db;
        private Timer mainTimer;

        public NuxibaServicesAlertReports()
        {
            InitializeComponent();
            myLog = new Logger("NuxibaServicesAlertReports");
            myLog.open();

            Version vDownloadManager = Assembly.GetEntryAssembly().GetName().Version;
            myLog.log("SERVICE INFO: AlertReports Version: " + vDownloadManager.ToString());

            mainTimer = new Timer();
            mainTimer.Elapsed += new ElapsedEventHandler(onElapsedTime);
            mainTimer.Interval = 5000;
            mainTimer.Enabled = false;
            mainTimer.AutoReset = false;

            GC.KeepAlive(mainTimer);

        }
        #region Methods Start Stop debug

        protected override void OnStart(string[] args)
        {
            lock (this)
            {
                DateTime now = new DateTime();
                TimeSpan ts;
                System.Threading.Timer theResetTimer = new System.Threading.Timer(onTimerDelete);

                init();

                ts = now.TimeOfDay;
                ts = new TimeSpan(24, 0, 0).Subtract(ts);
                theResetTimer.Change(ts, new TimeSpan(-1));

            }
        }

        protected override void OnStop()
        {
            lock (this)
            {
                stop();
            }
        }
        public void debugStop()
        {
            OnStop();
        }
        public void debugStart()
        {
            OnStart(null);
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
        /// Inicia el timer para la conexion
        /// </summary>
        private void init()
        {
            mainTimer.Start();
            log("SERVICE: AlertReports Service Started");

        }
        /// <summary>
        /// Detiene el socket y timmer para detener el servicio
        /// </summary>
        private void stop()
        {
            GC.WaitForPendingFinalizers();
            GC.Collect();
            log("SERVICE: AlertReports Service is stopped");
        }

        /// <summary>
        /// Imprime informacion en el archivo y lo imprime en pantalla
        /// </summary>
        /// <param name="message"></param>
        /// <param name="isError"></param>
        private static void log(String message, bool isError = false)
        {
            myLog.log(message, isError);
        }

    }
}
