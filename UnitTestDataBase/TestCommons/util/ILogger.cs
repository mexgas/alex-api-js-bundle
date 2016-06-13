using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace TestCommons.util
{
    public interface ILogger
    {
        void log(string info);
        void log(string info, bool isError);
        void log(string formato, Object arg0);
        void log(string formato, Object arg0, bool isError);
    }
}
