using System;

namespace MiddleWareReports
{
    /// <summary>
    /// Helper class that indicates that the specified report is not supported in the current version.
    /// </summary>
    public class ReportNotFoundException : Exception
    {
        public ReportNotFoundException(string message)
            : base(message)
        {
        }
    }
}