using Nuxiba.NuxibaAppBase.Base.Model;

namespace DatabaseUpdateValidator.Nuxiba.Model
{
    public class DatabaseDto : BaseModel
    {
        public string DatabaseName { get; set; }
        public string Server { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
        public double VersionDb { get; set; }
        public string DirectoryPath { get; set; }
        public string Pattern { get; set; }
        public string QueryAttaach { get; set; }
        public string DetachDB { get; set; }
    }
}