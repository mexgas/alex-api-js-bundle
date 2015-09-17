using System;
using System.Collections.Generic;
using System.Text;

namespace MiddleWareReports
{
    /// <summary>
    /// Fabricates the different type of report format classes supported by the application
    /// </summary>
    public static class ExportReportFactory
    {
        /// <summary>
        /// Returns an instance of a report type class
        /// </summary>
        /// <param name="reportType">Report file extension</param>
        /// <returns>An instance of the report</returns>
        public static ReportFormat GenerateReport(string reportType)
        {
            if (reportType.Equals("csv"))
            {
                return new CsvReport();
            }
            else if (reportType.Equals("pdf"))
            {
                return new PdfReport();
            }
            else if (reportType.Equals("xls"))
            {
                return new XlsReport();
            }
            else
            {
                throw new Exception(string.Format("Format type {0} is not supported for exportation", reportType));
            }
        }
    }
}
