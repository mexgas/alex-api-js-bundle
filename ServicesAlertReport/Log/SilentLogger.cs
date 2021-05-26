
namespace ServicesAlertReport.Log
{
    public class SilentLogger  : Logger 
    {

        public SilentLogger(string fileName)
            : base(fileName)
        {
        }

        public SilentLogger(string fileName, string path)
            : base(fileName, path)
        {
        }

        public override void log(string info, bool isError)
        {
            base.writeLog(info, isError);
        }
    }
}
