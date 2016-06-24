using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;


namespace TestCommons
{
    public class ClientServicesAdmin
    {

        public XmlNode loadFileXLSX(int camId, string filename, byte[] file, WebReference.LoaderConfiguration configuration, out string error)

        {
            error = string.Empty;
            XmlNode node = null;
            try
            {
                WebReference.CenterwareWS soapClient = new WebReference.CenterwareWS();                
                node = soapClient.loadRecords(camId, filename, file, configuration);

            }
            catch (Exception ex)
            {
                error = string.Format("Error: {0}", ex.Message);
            }
            return node;
        }
    }
}
