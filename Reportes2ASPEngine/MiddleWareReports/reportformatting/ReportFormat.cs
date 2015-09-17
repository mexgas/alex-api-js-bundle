using System;
using System.Data;

namespace MiddleWareReports
{
    /// <summary>
    /// Interface that represents certain format report and allows to get its representation as an array of bytes
    /// </summary>
    public interface ReportFormat
    {
        /// <summary>
        /// Gets the representation of the report as an array of bytes
        /// </summary>
        /// <param name="data">The data to be transformed</param>
        /// <param name="reportName">The name of the report</param>
        /// <returns>The report in a certain format as an array of bytes</returns>
        byte[] getOutPut(DataTable data, string reportName, string logoFileName = "", string filterSummaryData = "",bool translate = true) ;
    }

}
