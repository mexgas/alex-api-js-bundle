using System;
using System.Collections.Specialized;
using System.Text;
using System.Xml;
using System.Data;

namespace MiddleWareReports
{
    /// <summary>
    /// Interface that gives the basic contract for a report that wants to be represented into the application
    /// </summary>
    public interface NuxibaReport
    {
        XmlDocument getXmlReport(NameValueCollection parameters, short process, string addFilters, int sourceUserId, string savetemplate, string totals);
        DataTable getDataReport(NameValueCollection parameters, short process);
        string ReportName { get; }
    }
}
