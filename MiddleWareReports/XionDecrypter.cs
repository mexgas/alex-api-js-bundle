using System;

namespace MiddleWareReports
{
    internal class XionDecrypter
    {
        private readonly string ENCKEY = "nuxibaenckey0706";
        private readonly string XionReleaseENCKEY = "586cadacd7754df9cc2ddf0a4fbbddb7d7ae9fae95893644a10897a854ffc7a1";

        public string DesencriptaKey()
        {
            return AesCipher.transform(XionReleaseENCKEY, ENCKEY, false);
        }

        public string DesencriptaMenu(String key, String value)
        {
            return AesCipher.transform(value, key, false);
        }
    }
}