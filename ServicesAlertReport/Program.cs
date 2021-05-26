using System;
using System.Collections.Generic;
using System.Text;
using ServicesAlertReport.Log;
using System.ServiceProcess;

namespace ServicesAlertReport
{
    class Program
    {
        static void Main(string[] args)
        {
            System.AppDomain.CurrentDomain.UnhandledException += (CurrentDomain_UnhandledException);
            #region debug/install/uninstall/
            if (args.Length == 1)
            {
                if (args[0] == "c" || args[0] == "console")
                {
                    ServicesAlertReport service = new ServicesAlertReport();
                    service.debugStart();

                    readDebugCommand(service);

                    service.debugStop();
                    return;
                }

                if (args[0] == "i" || args[0] == "install")
                {
                    Install(true);
                    return;
                }

                if (args[0] == "u" || args[0] == "uninstall")
                {
                    Install(false);
                    return;
                }
            }
            #endregion

            Environment.CurrentDirectory = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            ServiceBase[] ServicesToRun;
            ServicesToRun = new ServiceBase[] 
			{ 
				new ServicesAlertReport() 
			};
            ServiceBase.Run(ServicesToRun);
        }
        #region Static Install, ReadDebug
        static void Install(bool install)
        {
            System.Configuration.Install.TransactedInstaller ti = new System.Configuration.Install.TransactedInstaller();
            ProjectInstaller mi = new ProjectInstaller();
            ti.Installers.Add(mi);

            String path = String.Format("/assemblypath={0}", System.Reflection.Assembly.GetExecutingAssembly().Location);
            String[] cmdline = { path };

            System.Configuration.Install.InstallContext ctx = new System.Configuration.Install.InstallContext("", cmdline);
            ti.Context = ctx;

            if (install)
                ti.Install(new System.Collections.Hashtable());
            else
                ti.Uninstall(null);
        }

        static void readDebugCommand(ServicesAlertReport service)
        {
            string input;
            bool cont = true;

            while (cont)
            {
                input = Console.ReadLine();
                if (input.Length > 0)
                    switch (input[0])
                    {
                        case 'q':
                            cont = false;
                            break;
                        case 'r':
                            service.debugTest("restart");
                            break;
                    }
            }

        }

        static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            string x;
            Logger l;
            try
            {
                Exception ex = (Exception)e.ExceptionObject;
                x = "Error " + ex.Message + " / " + ex.StackTrace;

                l = new Logger("Exception");
                l.open();
                l.log(x);
                l.close(false);
            }
            finally
            {
            }
        }
        #endregion
    }
}
