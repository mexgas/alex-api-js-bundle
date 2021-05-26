using System;
using System.Data;

namespace MiddleWareReports
{
    /// <summary>
    /// Helper class that checks if a DataTable does not contains any rows
    /// or if it is null.
    /// </summary>
    public class EmptyResultException : Exception
    {
        public EmptyResultException(string message)
            : base(message)
        {
        }

        /// <summary>
        /// Method that verifies if a DataTable is empty.
        /// </summary>
        /// <param name="table">The DataTable to be verified if it is empty. If true it throws a new EmptyResultException exception. </param>
        public static void dataTableIsEmpty(DataTable table)
        {
            if (table == null || table.Columns == null || table.Rows == null || table.Columns.Count <= 0 || table.Rows.Count <= 0)
            {
                throw new EmptyResultException("EMPTY_RESULT");
            }
        }
    }
}