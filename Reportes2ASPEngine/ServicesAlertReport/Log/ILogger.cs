using System;

namespace ServicesAlertReport.Log
{
    public interface ILogger
    {
         void log(string info);
         void log(string info, bool isError);        
         void log(string formato, Object arg0);
         void log(string formato, Object arg0, bool isError);        
    }
}
