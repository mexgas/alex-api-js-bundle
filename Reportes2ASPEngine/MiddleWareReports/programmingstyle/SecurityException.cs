using System;

namespace MiddleWareReports
{
    /// <summary>
    /// Helper class that indicates that the session is invalid.
    /// </summary>
    public class SecurityException : Exception
    {
        public SecurityException(string message)
            : base(message)
        {
        }
    }
}