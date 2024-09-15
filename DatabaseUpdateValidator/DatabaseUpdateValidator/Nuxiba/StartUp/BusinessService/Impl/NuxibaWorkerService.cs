using Nuxiba.NuxibaAppBase.Base.Infrastructure.Containers.Scanners;
using Nuxiba.NuxibaAppBase.Base.Repository;
using Nuxiba.NuxibaAppBase.Common.Wrapper.Impl;
using Nuxiba.NuxibaAppBase.Common.Wrapper;
using DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Containers.Scanners;
using DatabaseUpdateValidator.Nuxiba.Model;
using DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Constants;

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
            string username = DatabaseUpdateValidatorConstants.SQL_SERVER_USER;
            string password = DatabaseUpdateValidatorConstants.SQL_SERVER_PASSWORD;
            string server = DatabaseUpdateValidatorConstants.SQL_SERVER_SERVER;

            DatabaseDto CCenterRIA = new DatabaseDto
            {
                DatabaseName = "CCenterRIA",
                UserName = username,
                Password = password,
                Server = server,
                DirectoryPath = Path.Combine(path, "./CCenterRIA/UpdateDB/"),
                Pattern = @".+_v(?<version>\d+)(\.(?<versionFix>\d+))?_.+\.sql",
                VersionQuery = @"ccsp_getVersion 'BD'",
                VersionQueryFix = @"declare @version varchar(max);
                    select @version =valor from ccsettings where setting_id=77;
                    select cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@version,'.') where id=4;",
                QueryAttaach = @"
if not exists(select * from sys.databases where name='CCenterRIA') begin
    CREATE DATABASE CCenterRIA
    ON (FILENAME = '/var/opt/mssql/data/CCenterRIA.mdf'),
    (FILENAME = '/var/opt/mssql/data/CCenterRIA_log.ldf')
    FOR ATTACH;
end"
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
                VersionQuery = "select cast(substring(valor, 1, charindex('.', valor)-1) as int) from ccSettings where setting_id = 24",
                QueryAttaach = @"
if not exists(select * from sys.databases where name='CCRecorderRIA') begin
    CREATE DATABASE CCRecorderRIA
    ON (FILENAME = '/var/opt/mssql/data/CCRecorderRIA.mdf'),
    (FILENAME = '/var/opt/mssql/data/CCRecorderRIA_log.ldf')
    FOR ATTACH;
end",
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
                VersionQuery = "select cast(par_valor as int) from trec_parametros where par_id = 30",
                QueryAttaach = @"
if not exists(select * from sys.databases where name='CCReportsRIA') begin
    CREATE DATABASE CCReportsRIA
    ON (FILENAME = '/var/opt/mssql/data/ccReportsRia.mdf'),
    (FILENAME = '/var/opt/mssql/data/ccReportsRia_1.ldf')
    FOR ATTACH;
end"
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