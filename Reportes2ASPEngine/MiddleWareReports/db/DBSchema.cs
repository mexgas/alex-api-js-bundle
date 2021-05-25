using System.Collections;
using System.Data;

namespace MiddleWareReports
{
    internal static class DBSchema
    {
        private static Hashtable dataType = new Hashtable();

        /// <summary>
        /// Clear Hashtable that contains DBSchema by report
        /// </summary>
        public static void clearDBSchema()
        {
            dataType.Clear();
        }

        /// <summary>
        /// //Add Hashtable that contains DBSchema by report
        /// </summary>
        /// <param name="columnName">Description of the DB column</param>
        /// <param name="type">SqlDbType of the DB column</param>
        public static void setDataType(string columnName, SqlDbType type)
        {
            dataType.Add(columnName, type);
        }

        /// <summary>
        /// Get Hashtable that contains DBSchema by report
        /// </summary>
        /// <param name="columnName">Description of the DB column</param>
        /// <returns>SqlDbType for DB column</returns>
        public static SqlDbType getDataType(string columnName)
        {
            if (columnName == "dateStart" || columnName == "dateEnd")
            {
                columnName = "date";
                return SqlDbType.DateTime;
            }
            return (SqlDbType)dataType[columnName];
        }
    }
}