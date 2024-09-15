using Nuxiba.NuxibaAppBase.Base.Infrastructure.Containers.Scanners;
using Nuxiba.NuxibaAppBase.Base.Repository;
using Nuxiba.NuxibaAppBase.Common.Wrapper.Impl;
using Nuxiba.NuxibaAppBase.Common.Wrapper;
using DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Containers.Scanners;
using DatabaseUpdateValidator.Nuxiba.Model;

namespace DatabaseUpdateValidator.Nuxiba.StartUp.BusinessService.Impl
{
    public class NuxibaWorkerService : BaseRepository
    {
        private readonly IStartUpService startUpService;
        private readonly INuxibaContext context;

        public NuxibaWorkerService()
        {
            Logger.Info("**************************** CREATE APPLICATION NuxibaOutboundWhatsAppWorkerService *****************************************");
            NuxibaContext.SetIContainerScanner(new DatabaseUpdateValidatorScanner());
            MappingScanner.RegisterMapper(NuxibaContext.WindsorContainer);

            context = new NuxibaContext();

            startUpService = context.Resolve<IStartUpService>();
        }

        public void OnStart(string path)
        {
            Logger.Info("**************************** START APPLICATION *****************************************");

            DatabaseDto databaseDto = new DatabaseDto();
            string username = "sa";
            string password = "nuxiba";
            string server = "127.0.0.1";

            DatabaseDto CCenterRIA = new DatabaseDto
            {
                DatabaseName = "CCenterRIA",
                UserName = username,
                Password = password,
                Server = server,
                DirectoryPath = Path.Combine(path, "./CCenterRIA/UpdateDB/"),
                Pattern = @".+_v(?<version>\d+)(\.(?<versionFix>\d+))?_.+\.sql",
                QueryAttaach = @"CREATE DATABASE CCenterRIA
ON (FILENAME = '/var/opt/mssql/data/CCenterRIA.mdf'),
(FILENAME = '/var/opt/mssql/data/CCenterRIA_log.ldf')
FOR ATTACH;"
,
                DetachDB = @"ALTER DATABASE CCenterRIA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
EXEC sp_detach_db 'CCenterRIA';"
            };
            DatabaseDto CCRecorderRIA = new DatabaseDto
            {
                DatabaseName = "CCRecorderRIA",
                UserName = username,
                Password = password,
                Server = server,
                DirectoryPath = Path.Combine(path, "./RecorderRIA/UpdateDB/"),
                Pattern = @"^.+_v(?<version>\d+)_.+\.sql",
                QueryAttaach = @"CREATE DATABASE CCRecorderRIA
ON (FILENAME = '/var/opt/mssql/data/CCRecorderRIA.mdf'),
(FILENAME = '/var/opt/mssql/data/CCRecorderRIA_log.ldf')
FOR ATTACH;",
                DetachDB = @"ALTER DATABASE CCRecorderRIA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
EXEC sp_detach_db 'CCRecorderRIA';"
            };
            DatabaseDto CCReportsRIA = new DatabaseDto
            {
                DatabaseName = "CCReportsRIA",
                UserName = username,
                Password = password,
                Server = server,
                DirectoryPath = Path.Combine(path, "./ccReportsRia/UpdateDB/"),
                Pattern = @"^.+_nr(?<version>\d+)_.+\.sql",
                QueryAttaach = @"CREATE DATABASE CCReportsRIA
ON (FILENAME = '/var/opt/mssql/data/ccReportsRia.mdf'),
(FILENAME = '/var/opt/mssql/data/ccReportsRia_1.ldf')
FOR ATTACH;"
,
                DetachDB = @"ALTER DATABASE CCReportsRIA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
EXEC sp_detach_db 'CCReportsRIA';"
            };

            var list = new List<DatabaseDto>
            {
                CCenterRIA, CCRecorderRIA, CCReportsRIA
            };

            startUpService.Start(list);
        }

        public void OnStop()
        {
            Logger.Info("**************************** BEGIN STOP APPLICATION *****************************************");
            try
            {
                startUpService.Stop();
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }
            Logger.Info("**************************** END STOP APPLICATION *****************************************");
        }
    }
}