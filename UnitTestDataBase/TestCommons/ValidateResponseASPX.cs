using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Xml.Linq;
using System.Xml;
namespace TestCommons
{
    public class ValidateResponseASPX
    {
        private string url;
        private string error;
        public ValidateResponseASPX(string url)
        {
            this.url = url;
            error = string.Empty;
        }



        public XmlDocument getResponse(Dictionary<string, string> parameters)
        {
            StringBuilder builder = new StringBuilder();
            Stream stream = null;
            XmlDocument doc = new XmlDocument();
            foreach (KeyValuePair<string, string> kvp in parameters) builder.Append(kvp.Key + "=" + kvp.Value + "&");


            HttpWebRequest request = (HttpWebRequest)HttpWebRequest.Create(string.Format("{0}?{1}", url, builder));
            request.AllowAutoRedirect = false; // find out if this site is up and don't follow a redirector            
            try
            {
                HttpWebRequest webrequest = (HttpWebRequest)HttpWebRequest.Create(url);
                webrequest.Timeout = 5000; //Timeout 5 seg.

                HttpWebResponse response = (HttpWebResponse)request.GetResponse();
                if (response.StatusCode == HttpStatusCode.OK)
                {
                    stream = response.GetResponseStream();
                    string str = System.Text.Encoding.Default.GetString(ReadFully(stream));
                    doc.LoadXml(str);
                    stream.Close();
                }

            }
            catch (Exception ex)
            {
                error = ex.Message;
            }
            finally
            {
                if (stream != null)
                {
                    stream.Close();
                }
            }

            return doc;

        }

        public string LAST_ERROR { get { return error; } }

        private byte[] ReadFully(Stream input)
        {
            byte[] buffer = new byte[16 * 1024];
            using (MemoryStream ms = new MemoryStream())
            {
                int read;
                while ((read = input.Read(buffer, 0, buffer.Length)) > 0)
                {
                    ms.Write(buffer, 0, read);
                }
                return ms.ToArray();
            }
        }

    }
}
