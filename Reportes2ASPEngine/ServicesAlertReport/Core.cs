using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ServicesAlertReport.Log;
using ServicesAlertReport.DB;
using System.Timers;
using System.Data;
using MiddleWareReports;
using System.Collections.Specialized;
using System.IO;

namespace ServicesAlertReport
{
    class Core
    {

        private Logger mylog;
        private DataBaseServices db;
        private Timer mainTimer;

        public Core(Logger myLog2, DataBaseServices db)
        {
            this.mylog = myLog2;
            this.db = db;
            mainTimer = new System.Timers.Timer();
        }

        public void startCore()
        {
            mainTimer.Elapsed += new ElapsedEventHandler(onElapsedTime);
            mainTimer.Interval = 1000 * 10;
            mainTimer.Enabled = true;
        }

        public void stopCore()
        {
            mainTimer.Stop();
            mainTimer.Enabled = false;
            mainTimer.Elapsed -= new ElapsedEventHandler(onElapsedTime);
        }
        /// <summary>
        /// Incia el timer
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="eArgs"></param>
        private void onElapsedTime(object sender, ElapsedEventArgs eArgs)
        {
            mainTimer.Stop();
            mainTimer.Enabled = false;
            try
            {
                DataReport dataReport = db.getDataLastRunJob();
                mylog.log(dataReport.ToString());
                DataTable detailTable = db.getValidateReportAgentGI();
                NameValueCollection translatedColumns = TranslatorHelper.translateColumns(detailTable.Columns, 2010);
                string title = "ValidateReportAgentGI";
                XlsReport report = new XlsReport();
                byte[] dataReport2 = report.getOutPut(detailTable, title, "", "", true, 2010);
                string fileName = title + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
                fileName = Path.Combine(Path.GetTempPath(), fileName);
                File.WriteAllBytes(fileName, dataReport2);
                mylog.log(fileName);
            }
            catch (EmptyResultException)
            {
                mylog.log("Not exist error report AgentGI");
            }
            catch (Exception e)
            {
                mylog.log(string.Format("Error {0}", e.Message), true); ;
            }



            mainTimer.Start();
            mainTimer.Enabled = true;
        }





    }
}
