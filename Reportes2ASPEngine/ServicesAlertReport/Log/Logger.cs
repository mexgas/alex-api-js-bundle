using System;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Threading;
using System.IO.Compression;
using Ionic.Zip;
using System.Text;

namespace ServicesAlertReport.Log
{
    public class Logger : ILogger
    {
        //propiedades
        object syncRoot;
        FileStream theFileStream = null;
        StreamWriter theStreamWriter = null;
        String path = "";

        string theFilename = "";
        Timer theResetTimer;

        const long MAXFILESIZE = 30000000;
        long iBytesEscritos;
        bool sysLog;

        //metodos 
        public Logger(string fileName)
        {
            syncRoot = new object();
            theFilename = fileName;
            theResetTimer = new Timer(onTimer);
            path = PathLogs.LOG_PATH;
        }
        public Logger(string fileName, string path)
        {
            syncRoot = new object();
            theFilename = fileName;
            theResetTimer = new Timer(onTimer);
            this.path = path;
        }
        public void open()
        {
            open(true);
        }

        public void open(Boolean sysLog)
        {
            DateTime now;
            TimeSpan ts;
            this.sysLog = sysLog;
            try
            {
                //checa directorio
                if (!Directory.Exists(path))
                    Directory.CreateDirectory(path);

                //calcula
                now = DateTime.Now;

                //abre archvio
                String completeName = "";

                if (sysLog)
                    completeName = System.IO.Path.Combine(path, buildFileName());
                else
                    completeName = System.IO.Path.Combine(path, theFilename + ".log");

                theFileStream = new FileStream(completeName, FileMode.Append, FileAccess.Write, FileShare.ReadWrite);
                theStreamWriter = new StreamWriter(theFileStream);

                logStack();

                //calcula timer, para cambio de nombre archivo
                ts = now.TimeOfDay;
                ts = new TimeSpan(24, 0, 10).Subtract(ts);
                theResetTimer.Change(ts, new TimeSpan(-1));

                log("Timer expires in {0} hours", ts.TotalHours);
            }
            catch (Exception e)
            {
                log("Open: " + e.Message, true);
            }
        }
        public void close(bool killTimer)
        {
            logStack();

            if (killTimer)
                theResetTimer.Dispose();

            try
            {
                if (theStreamWriter != null)
                    theStreamWriter.Close();
                if (theFileStream != null)
                    theFileStream.Close();
            }
            catch (Exception)
            {
            }
        }

        public void log(string info)
        {
            log(info, false);
        }
        public virtual void log(string info, bool isError)
        {
            if (sysLog)
            {
                iBytesEscritos += Encoding.UTF8.GetByteCount(info);
                if (iBytesEscritos > MAXFILESIZE)
                {
                    try
                    {
                        writeToConsole(writeLog("Changing file name", false));
                        lock (syncRoot)
                        {
                            if (theStreamWriter != null)
                                theStreamWriter.Close();
                            if (theFileStream != null)
                                theFileStream.Close();
                            open();
                        }
                    }
                    catch (Exception a)
                    {
                        writeToConsole(writeLog("Error on Logger timer: " + a.Message, false));
                    }
                }
            }

            writeToConsole(writeLog(info, isError));
        }
        public void log(string formato, Object arg0)
        {
            log(String.Format(formato, arg0), false);
        }
        public void log(string formato, Object arg0, bool isError)
        {
            log(String.Format(formato, arg0), isError);
        }
        public void logStack()
        {
            String elMetodo;
            MethodBase mb;
            int pos;

            //obtiene stack
            mb = new StackTrace(1, true).GetFrame(0).GetMethod();
            elMetodo = mb.DeclaringType.ToString();

            //limpia, deja el nombre de la clase
            pos = elMetodo.LastIndexOf('.');
            if (pos > -1)
                elMetodo = elMetodo.Substring(pos + 1);

            log(elMetodo.ToString() + "->" + mb.Name, false);
        }

        protected string writeLog(string info, bool isError)
        {
            String fullLine = "";
            lock (syncRoot)
            {
                //Formatear linea
                fullLine = logLineFormat(info);// String.Format("{2,-4}{0,-13:HH:mm:ss.fff}{1}", DateTime.Now, info, Thread.CurrentThread.GetHashCode());
                try
                {
                    theStreamWriter.WriteLine(fullLine);
                    theStreamWriter.Flush();
                }
                catch (Exception e)
                {
                    fullLine = e.Message;
                }
            }
            return fullLine;
        }

        protected void writeToConsole(string info)
        {
            Console.WriteLine(info);
        }

        protected String logLineFormat(string info)
        {
            return String.Format("{2,-4}{0,-13:HH:mm:ss.fff}{1}", DateTime.Now, info, Thread.CurrentThread.GetHashCode());
        }

        //eventos
        private void onTimer(Object state)
        {
            try
            {
                log("Changing file name");
                lock (syncRoot)
                {
                    close(false);
                    open();
                }
                zipStart();
            }
            catch (Exception a)
            {
                log("Error on Logger timer: " + a.Message);
            }
        }
        //Obtiene el nombre del archivo con prefijo letra a-z
        private string buildFileName()
        {
            char maxCharacter = 'a';
            string searchFiles = theFilename + DateTime.Now.ToString("yyyyMMdd") + "_*.log";
            string completeName;
            iBytesEscritos = 0;
            int ultimoFile = 0;
            long tamFile = 0;
            DirectoryInfo di = new DirectoryInfo(path);
            FileInfo[] files = di.GetFiles(searchFiles, SearchOption.TopDirectoryOnly);
            //97 --> 'a'
            if (files.Length > 0)
            {
                ultimoFile = files.Length - 1;
                tamFile = files[ultimoFile].Length;
                maxCharacter = Convert.ToChar(97 + ultimoFile);
            }

            if (tamFile > (MAXFILESIZE - 3000000))
                maxCharacter = Convert.ToChar(((int)maxCharacter) + 1);
            else
                iBytesEscritos = tamFile;
            if (maxCharacter == Convert.ToChar(123)) //'z' + 1 
            {
                iBytesEscritos = 0;
                maxCharacter = 'z';
            }
            completeName = string.Format("{0}{1}_{2}.log", theFilename, DateTime.Now.ToString("yyyyMMdd"), maxCharacter);
            return completeName;
        }
        //crea zip para la compresion de archivos
        private void zipFilesAsync()
        {
            DateTime ayer = DateTime.Now.AddDays(-1);
            string searchFiles = theFilename + ayer.ToString("yyyyMMdd") + "_*.log";
            string zipToCreate = theFilename + ayer.ToString("yyyyMMdd") + ".zip";
            DirectoryInfo di = new DirectoryInfo(path);
            FileInfo[] files = di.GetFiles(searchFiles, SearchOption.TopDirectoryOnly);
            if (files.Length > 0)
            {
                using (ZipFile zip = new ZipFile())
                {
                    foreach (FileInfo fi in files)
                    {
                        zip.AddFile(fi.FullName, "/");
                    }
                    zip.Save(path + @"\" + zipToCreate);
                }
                foreach (FileInfo fi in files)
                {
                    if (fi != null)
                    {
                        fi.Delete();
                    }
                }

            }
        }

        private void zipStart()
        {
            Thread thread = new Thread(new ThreadStart(zipFilesAsync));
            thread.Start();
        }
    }
}
