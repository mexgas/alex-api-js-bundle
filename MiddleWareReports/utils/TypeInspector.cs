using System;
using System.Collections;
using System.Data;
using System.Text.RegularExpressions;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps to infer the type of a passed value as a string
    /// </summary>
    internal static class TypeInspector
    {
        private static Hashtable dbTypeTable;

        /// <summary>
        /// Tries to infer the type of the passed string parameter
        /// </summary>
        /// <param name="value">The string which type wants to be infered</param>
        /// <returns>The infered type of the parameter</returns>
        /// <remarks>Can only infer int, double and string types</remarks>
        public static Type getType(string value)
        {
            Regex doubles = new Regex(@"^[-]*[0-9]+\.[0-9]+$");
            Regex integers = new Regex(@"^[-]*[0-9]+$");
            Type type;

            if (doubles.IsMatch(value))
            {
                type = typeof(double);
            }
            else if (integers.IsMatch(value))
            {
                type = typeof(int);
            }
            else
            {
                type = typeof(string);
            }

            return type;
        }

        /// <summary>
        /// Creates a HashTable that contains SystemTypes and SqlDbType correspondence
        /// </summary>
        /// <param name="t">The SystemType to cast in SqlDbType</param>
        /// <returns>The casted type of SystemType</returns>
        public static SqlDbType ConvertToDbType(Type t)
        {
            if (dbTypeTable == null)
            {
                dbTypeTable = new Hashtable();
                dbTypeTable.Add(typeof(System.Boolean), SqlDbType.Bit);
                dbTypeTable.Add(typeof(System.UInt16), SqlDbType.TinyInt);
                dbTypeTable.Add(typeof(System.Int16), SqlDbType.SmallInt);
                dbTypeTable.Add(typeof(System.Int32), SqlDbType.Int);
                dbTypeTable.Add(typeof(System.Int64), SqlDbType.BigInt);
                dbTypeTable.Add(typeof(System.Double), SqlDbType.Float);
                dbTypeTable.Add(typeof(System.Decimal), SqlDbType.Decimal);
                dbTypeTable.Add(typeof(System.String), SqlDbType.VarChar);
                dbTypeTable.Add(typeof(System.DateTime), SqlDbType.DateTime);
                dbTypeTable.Add(typeof(System.Byte[]), SqlDbType.VarBinary);
                dbTypeTable.Add(typeof(System.Guid), SqlDbType.UniqueIdentifier);
            }
            SqlDbType dbtype;
            try
            {
                dbtype = (SqlDbType)dbTypeTable[t];
            }
            catch
            {
                dbtype = SqlDbType.Variant;
            }
            return dbtype;
        }

        /// <summary>
        /// Remove digits from string
        /// </summary>
        /// <param name="parameter"></param>
        /// <returns>String without digits</returns>
        public static string removeDigits(string value)
        {
            return Regex.Replace(value, @"\d", "");
        }

        /// <summary>
        /// Remove Min or Max from string
        /// </summary>
        /// <param name="parameter"></param>
        /// <returns>String without Min or Max</returns>
        public static string removeMinMax(string value)
        {
            return Regex.Replace(value, @"Min|Max", "");
        }
    }
}