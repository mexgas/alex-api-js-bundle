using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ServicesAlertReport
{
    public class SMTPData
    {
        public string server;
        public string user = "";
        public string pwd;
        public int port;
        public bool useSSL;
        public bool useTLS;

        public SMTPData()
        {
            this.server = "smtp.gmail.com";
            user = "nuxiba.prueba@gmail.com";
            pwd = "Nuxiba2010";
            port = 465;
            useSSL = true;
            useTLS = false;
        }
    }
}
