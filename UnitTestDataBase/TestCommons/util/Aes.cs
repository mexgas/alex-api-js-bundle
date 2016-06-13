using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Security.Cryptography;

namespace TestCommons.util
{
    public static class Aes
    {
        private const int KEY_LEN = 16;
        private const int BLOCK_LEN = 16;

        //Controla la forma en que va pasar los registros tiempo o cantidad
        public static int maxTime = 600; // seg = 10 min cantidad maxima del tiempo en espera
        public static int maxAmount = 200; //cantidad maxima de registros

        //public static string appVersion = "2014.03.01"; //version = AAAA.MM.NumeroDeLiberacionEnElMes

        private static byte getByte(int a, int b)
        {
            if (a >= 48 && a <= 57)
                a = a - 48;
            if (a >= 65 && a <= 70)
                a = a - 55;
            if (a >= 97 && a <= 102)
                a = a - 87;

            if (b >= 48 && b <= 57)
                b = b - 48;
            if (b >= 65 && b <= 70)
                b = b - 55;
            if (b >= 97 && b <= 102)
                b = b - 87;

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

            //pasa llave a arreglo de bytes
            textConverter = new UTF8Encoding();
            bKey = textConverter.GetBytes(llave);
            if (bKey.Length != KEY_LEN)
                Array.Resize(ref bKey, KEY_LEN);

            //pasa datos a arreglo de bytes
            if (bEncripta)
                bInput = textConverter.GetBytes(dato);
            else
            {
                char[] ss;
                ss = dato.ToCharArray();
                bInput = new byte[ss.Length / 2];

                //longitud no valida
                if (bInput.Length % BLOCK_LEN != 0)
                    return "";

                for (int i = 0; i < ss.Length - 1; i = i + 2)
                    bInput[i / 2] = getByte(ss[i], ss[i + 1]);
            }

            //crea los objetos
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
                    b.Append(bOutput[j].ToString("x2"));

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

        public struct Nodes
        {
            public int id;
            public string node;
        }


    }

}
