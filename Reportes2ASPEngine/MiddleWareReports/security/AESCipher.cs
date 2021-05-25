using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace MiddleWareReports
{
    public static class AesCipher
    {
        private const int KEY_LEN = 16;
        private const int BLOCK_LEN = 16;

        private static byte getByte(int a, int b)
        {
            if (a >= 48 && a <= 57)
            {
                a = a - 48;
            }

            if (a >= 65 && a <= 70)
            {
                a = a - 55;
            }

            if (a >= 97 && a <= 102)
            {
                a = a - 87;
            }

            if (b >= 48 && b <= 57)
            {
                b = b - 48;
            }

            if (b >= 65 && b <= 70)
            {
                b = b - 55;
            }

            if (b >= 97 && b <= 102)
            {
                b = b - 87;
            }

            return (byte)((a << 4) + b);
        }

        public static string transform(string dato, string llave, bool bEncripta)
        {
            String resultado;
            UTF8Encoding textConverter;

            RijndaelManaged myRijndaelManaged;
            ICryptoTransform myICryptoTransform;
            MemoryStream myMemoryStream;
            CryptoStream myCryptoStream;

            byte[] bKey;
            byte[] bInput;
            byte[] bOutput;

            //Transform array keys in bytes
            textConverter = new UTF8Encoding();
            bKey = textConverter.GetBytes(llave);
            if (bKey.Length != KEY_LEN)
            {
                Array.Resize(ref bKey, KEY_LEN);
            }

            //Convert data in array of bytes
            if (bEncripta)
            {
                bInput = textConverter.GetBytes(dato);
            }
            else
            {
                char[] ss;
                ss = dato.ToCharArray();
                bInput = new byte[ss.Length / 2];

                //Invalid length
                if (bInput.Length % BLOCK_LEN != 0)
                {
                    return "";
                }

                for (int i = 0; i < ss.Length - 1; i = i + 2)
                {
                    bInput[i / 2] = getByte(ss[i], ss[i + 1]);
                }
            }

            //Objects created
            myRijndaelManaged = new RijndaelManaged();
            myRijndaelManaged.BlockSize = BLOCK_LEN * 8;
            myRijndaelManaged.KeySize = KEY_LEN * 8;
            myRijndaelManaged.Padding = PaddingMode.Zeros;

            if (bEncripta)
            {
                myICryptoTransform = myRijndaelManaged.CreateEncryptor(bKey, new byte[BLOCK_LEN]);
                myMemoryStream = new MemoryStream();
                myCryptoStream = new CryptoStream(myMemoryStream, myICryptoTransform, CryptoStreamMode.Write);

                //Write all data to the crypto stream and flush it.
                myCryptoStream.Write(bInput, 0, bInput.Length);
                myCryptoStream.FlushFinalBlock();

                bOutput = myMemoryStream.ToArray();
                StringBuilder b = new StringBuilder((int)myMemoryStream.Length);
                for (int j = 0; j < bOutput.Length; j++)
                {
                    b.Append(bOutput[j].ToString("x2"));
                }

                resultado = b.ToString();
            }
            else
            {
                myICryptoTransform = myRijndaelManaged.CreateDecryptor(bKey, new byte[BLOCK_LEN]);
                myMemoryStream = new MemoryStream(bInput);
                myCryptoStream = new CryptoStream(myMemoryStream, myICryptoTransform, CryptoStreamMode.Read);

                //Read the data out of the crypto stream.
                bOutput = new byte[bInput.Length];
                myCryptoStream.Read(bOutput, 0, bOutput.Length);

                resultado = textConverter.GetString(bOutput).TrimEnd(new char[] { (char)0 });
            }

            //clear
            myCryptoStream.Close();
            myMemoryStream.Close();
            myRijndaelManaged.Clear();

            return resultado;
        }
    }
}