using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace MiddleWareReports
{
    class XionDecrypter
    {
        String ENCKEY = "nuxibaenckey0706";
        String XionReleaseENCKEY = "586cadacd7754df9cc2ddf0a4fbbddb7d7ae9fae95893644a10897a854ffc7a1";

        public String DesencriptaKey()
        {
            string XionENCKEYDecripted;
            XionENCKEYDecripted = AesCipher.transform(XionReleaseENCKEY, ENCKEY, false);
            return XionENCKEYDecripted;
        }

        public String DesencriptaMenu(String key, String value)
        {
            String MenuDecripted;
            MenuDecripted = AesCipher.transform(value, key, false);
            return MenuDecripted;
        }
    }
}
