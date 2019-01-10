using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Net.Security;
using System.Timers;
using Ionic.Zip;
using Limilabs.Client;
using Limilabs.Client.SMTP;
using Limilabs.Mail;
using Limilabs.Mail.Headers;
using MiddleWareReports;
using ServicesAlertReport.DB;
using ServicesAlertReport.Log;

namespace ServicesAlertReport
{
    class Core
    {

        private Logger mylog;
        private DataBaseServices db;
        private Timer mainTimerAlert;
        private Timer mainTimerStatistics;
        private int eachTimeAlert = 1;
        private int eachTimeStatistics = 1;
        private ServicesAlertReport services;
        private MiddleWareReports.GenericReport report;

        /// <summary>
        /// Properties SMTP Credetential
        /// </summary>
        private SMTPData smtpData;
        /// <summary>
        /// Object send Mail
        /// </summary>
        private Smtp smtp;

        public Core(ServicesAlertReport services, Logger myLog2, DataBaseServices db)
        {
            this.services = services;
            this.mylog = myLog2;
            this.db = db;
            string lang = "es";
            string strCulture;
            mainTimerAlert = new System.Timers.Timer();
            mainTimerStatistics = new System.Timers.Timer();
            CultureInfo culture = new CultureInfo("es-MX");
            string reportName = MiddleWareReports.ReportFactory.getReportName(2010).GetType().ToString();
            report = MiddleWareReports.GenericReport.createReport(reportName);
            try
            {
                eachTimeAlert = Convert.ToInt32(db.getValueSetting(37));
                eachTimeStatistics = Convert.ToInt32(db.getValueSetting(38));
                if (eachTimeAlert < 9) eachTimeAlert = 9;
                if (eachTimeStatistics < 21) eachTimeAlert = 21;

                lang = db.getValueSetting(23);
                switch (lang)
                {
                    case "en":
                        strCulture = lang + "-US";
                        break;
                    case "pt":
                        strCulture = lang + "-BR";
                        break;
                    case "es":
                    default:
                        strCulture = "es-MX";
                        break;
                }
                culture = new CultureInfo(strCulture);
            }
            catch (Exception e)
            {
                eachTimeAlert = 30;
                eachTimeStatistics = 60;
                mylog.log("Error parser eachTime default 60, error: " + e.Message, true);

            }
            report.CurrentCulture = culture;
            mylog.log(string.Format("eachTimeAlert: {0}, eachTimeStatistics:{1}, culture:{2}", eachTimeAlert, eachTimeStatistics, culture));

        }

        public void startCore()
        {
            mainTimerAlert.Elapsed += new ElapsedEventHandler(onElapsedTimeAlertReport);
            mainTimerAlert.Interval = 1000 * 60 * eachTimeAlert;
            mainTimerAlert.Enabled = true;


            mainTimerStatistics.Elapsed += new ElapsedEventHandler(onElapsedTimeSendReport);
            mainTimerStatistics.Interval = 1000 * 60 * eachTimeStatistics;
            mainTimerStatistics.Enabled = true;
        }

        public void stopCore()
        {
            mainTimerAlert.Stop();
            mainTimerAlert.Enabled = false;
            mainTimerAlert.Elapsed -= new ElapsedEventHandler(onElapsedTimeAlertReport);

            mainTimerStatistics.Stop();
            mainTimerStatistics.Enabled = false;
            mainTimerStatistics.Elapsed -= new ElapsedEventHandler(onElapsedTimeSendReport);
        }
        /// <summary>
        /// Incia el timer
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="eArgs"></param>
        private void onElapsedTimeAlertReport(object sender, ElapsedEventArgs eArgs)
        {
            mainTimerAlert.Stop();
            mainTimerAlert.Enabled = false;
            try
            {
                DataReport dataReport = db.getDataLastRunJob();
                mylog.log(dataReport.ToString());
                DataTable detailTable = db.getValidateReportAgentGI(dataReport.DATE_START, dataReport.DATE_END);
                string title = "ValidateReportAgentGI";
                XlsReport report = new XlsReport();
                byte[] dataReport2 = report.getOutPut(detailTable, title, "", "", true, 2010);
                string fileName = title + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
                fileName = Path.Combine(Path.GetTempPath(), fileName);
                File.WriteAllBytes(fileName, dataReport2);

                connect(fileName);
                File.Delete(fileName);

            }
            catch (EmptyResultException)
            {
                mylog.log("Not exist error report AgentGI");
            }
            catch (Exception e)
            {
                mylog.log(string.Format("Error {0}", e.Message), true); ;
            }

            mainTimerAlert.Start();
            mainTimerAlert.Enabled = true;
        }


        /// <summary>
        /// Incia el timer
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="eArgs"></param>
        private void onElapsedTimeSendReport(object sender, ElapsedEventArgs eArgs)
        {
            mainTimerStatistics.Stop();
            mainTimerStatistics.Enabled = false;

            try
            {
                string zipFileName = "ReportMail" + DateTime.Now.ToString("yyyyMMdd") + ".zip";
                List<int> listActions = db.getListAction();
                List<string> listFileName = new List<string>();
                XlsReport report = new XlsReport();
                foreach (int act in listActions)
                {
                    string title = "ReportMail" + act;
                    try
                    {
                        DataTable detailTable = db.getReportGeneric(act);

                        byte[] dataReport2 = report.getOutPut(detailTable, title, "", "", false, 2010);
                        string fileName = title + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
                        fileName = Path.Combine(Path.GetTempPath(), fileName);
                        File.WriteAllBytes(fileName, dataReport2);
                        listFileName.Add(fileName);


                    }
                    catch (EmptyResultException)
                    {

                    }
                    catch (Exception e)
                    {
                        mylog.log(string.Format("Error {0}, title: {1}", e.Message, title), true);
                    }
                }
                if (listFileName.Count > 0)
                {
                    zipFiles(listFileName, zipFileName);
                    zipFileName = Path.Combine(Path.GetTempPath(), zipFileName);
                    connect(zipFileName);
                    foreach (string f in listFileName) File.Delete(f);
                    File.Delete(zipFileName);
                }


            }

            catch (Exception e)
            {
                mylog.log(string.Format("Error {0}", e.Message), true);
            }

            mainTimerStatistics.Start();
            mainTimerStatistics.Enabled = true;
        }



        /// <summary>
        /// Realiza la conexion u revisa que se modifica
        /// </summary>
        /// <returns></returns>
        private bool connect(string fileName)
        {
            using (smtp = new Smtp())
            {
                try
                {
                    smtpData = db.getSmtpProperties();
                    if (smtpData.useSSL)
                    {
                        smtp.ServerCertificateValidate += new ServerCertificateValidateEventHandler(validateCertificateSSL);
                    }

                    smtp.Connect(smtpData.server, smtpData.port, smtpData.useSSL);
                    smtp.UseBestLogin(smtpData.user, smtpData.pwd);
                    if (smtp.SupportedExtensions().Contains(SmtpExtension.StartTLS) && smtpData.useTLS)
                    {
                        smtp.StartTLS();
                    }

                    ArrayList destMailboxes = db.getListMail(0);
                    if (destMailboxes.Count <= 0)
                    {
                        mylog.log("List Mail Empty");
                        return false;
                    }
                    report.changeCulture();
                    bool isTransaleted = false;
                    string message = TranslatorHelper.getResourceProperty("messageBodyMailAlert", out isTransaleted);
                    if (!isTransaleted)
                    {
                        message = "Mensaje de alerta reporte";
                    }
                    return smtpSendFile(fileName, destMailboxes, message);
                }
                catch (Exception ex)
                {
                    mylog.log("Error Connect SMTP " + ex.Message, true);
                    return false;
                }
            }
        }

        private bool smtpSendFile(string filename, ArrayList destination, string mailMessage)
        {
            try
            {
                bool isTransaleted = false;
                string subject = TranslatorHelper.getResourceProperty("messageSubjectMailAlert", out isTransaleted);
                if (!isTransaleted)
                {
                    subject = "Mensaje de alerta reporte";
                }

                MailBuilder builder = new MailBuilder();
                builder.From.Add(new MailBox(smtpData.user));

                builder.Subject = subject;
                builder.Text = mailMessage;

                foreach (object var in destination)
                {
                    mylog.log("Adding email: " + var.ToString());
                    builder.To.Add(new MailBox(var.ToString()));
                }
                mylog.log("Message created");


                builder.AddAttachment(filename);
                mylog.log("Attachment created: " + filename);


                IMail email = builder.Create();
                ISendMessageResult result = smtp.SendMessage(email);
                if (result.Status == SendMessageStatus.Success)
                {
                    mylog.log("Send Message Success " + filename);
                }


                return true;
            }
            catch (Exception ex)
            {
                mylog.log("Message not created " + ex.Message, true);
                return false;
            }
        }


        /// <summary>
        /// Envia certificados de autentificacion cuando es necesario
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void validateCertificateSSL(object sender, ServerCertificateValidateEventArgs e)
        {
            const SslPolicyErrors ignoredErrors =
                SslPolicyErrors.RemoteCertificateChainErrors |  // self-signed
                SslPolicyErrors.RemoteCertificateNameMismatch;  // name mismatch

            string nameOnCertificate = e.Certificate.Subject;

            if ((e.SslPolicyErrors & ~ignoredErrors) == SslPolicyErrors.None)
            {
                e.IsValid = true;
                return;
            }
            e.IsValid = false;
        }

        private void zipFiles(List<string> listFileName, string zipToCreate)
        {
            DirectoryInfo di = new DirectoryInfo(Path.GetTempPath());
            foreach (string fileName in listFileName)
            {
                using (ZipFile zip = new ZipFile())
                {
                    zip.AddFile(fileName, "/");
                    zip.Save(Path.Combine(Path.GetTempPath(), zipToCreate));
                }
            }
        }


    }
}
