using System;
using System.Security.Cryptography;
using System.Text;

namespace ServicesAlertReport.Security
{
    public class Md5
    {
        public static String createHash(String text)
        {
            MD5 hasher = MD5.Create();
            byte[] arrayText = Encoding.UTF8.GetBytes(text);
            byte[] hash = hasher.ComputeHash(arrayText);
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < hash.Length; i++)
            {
                sb.Append(hash[i].ToString("X2"));
            }
            return sb.ToString();
        }

    }
}
