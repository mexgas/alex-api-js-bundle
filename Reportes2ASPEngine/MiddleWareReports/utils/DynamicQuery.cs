using System;
using System.Collections.Specialized;
using System.Text;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps in DynamicQuery construction
    /// </summary>
    public class DynamicQuery
    {
        short process;
        bool isTotals;
        StringBuilder stmt;
        StringBuilder parameters;
        NameValueCollection values;
        string sqlPaginate = "";
        bool isPivotReport;
        string totalColumns;

        public short Process
        {
            get { return process; }
            set { process = value; }
        }

        public bool IsTotals
        {
            get { return isTotals; }
        }

        public string TotalColumns
        {
            get { return totalColumns; }
            set {
                totalColumns = value;
                isTotals = true;
            }
        }

        public StringBuilder Stmt
        {
            get { return stmt; }
            set { stmt = value; }
        }

        public StringBuilder Parameters
        {
            get { return parameters; }
            set { parameters = value; }
        }

        public NameValueCollection Values
        {
            get { return values; }
            set { values = value; }
        }

        public string SqlPaginate
        {
            get { return sqlPaginate; }
            set { sqlPaginate = value; }
        }

        public bool IsPivotReport
        {
            get { return isPivotReport; }
            set { isPivotReport = value; }
        }

        public DynamicQuery(short process)
        {
            this.process = process;
        }

    }
}
