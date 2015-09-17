using System;
using System.Text.RegularExpressions;

namespace MiddleWareReports
{
    /// <summary>
    /// Helper class that checks if a CRM Template contains fields that can be reportables
    /// in order to comply with the database schema of the reports.
    /// </summary>
    public class CRMFieldsNotFoundException : Exception
    {
        public CRMFieldsNotFoundException(string message)
            : base(message)
        {
        }

       
    }
}

