using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ServicesAlertReport
{
    public class DataReport
    {

        private int _duration;
        private DateTime _dateStart;
        private DateTime _dateEnd;

        public DataReport(DateTime _dateStart, DateTime _dateEnd, int _duration)
        {
            this._dateStart = _dateStart;
            this._dateEnd = _dateEnd;
            this._duration = _duration;
        }


        public override string ToString()
        {
            return string.Format("DateStart {0},DateEnd {1}, duration {2}", _dateStart.ToString("yyyy-MM-dd HH:mm:ss"), _dateEnd.ToString("yyyy-MM-dd HH:mm:ss"), _duration);
        }
    }

    
}
