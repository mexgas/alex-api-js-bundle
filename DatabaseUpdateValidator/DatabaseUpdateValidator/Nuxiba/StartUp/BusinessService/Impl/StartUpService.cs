using DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Constants;
using DatabaseUpdateValidator.Nuxiba.Helper;
using DatabaseUpdateValidator.Nuxiba.Model;
using DatabaseUpdateValidator.Nuxiba.Repository;
using DatabaseUpdateValidator.Nuxiba.Repository.Impl;
using Microsoft.Data.SqlClient;
using Nuxiba.NuxibaAppBase.Base.BusinessService;
using Nuxiba.NuxibaAppBase.Base.Infrastructure.Components;

namespace DatabaseUpdateValidator.Nuxiba.StartUp.BusinessService.Impl
{
    public class StartUpService : BaseBusinessService, IStartUpService
    {
        private ISqlFileProcessor sqlFileProcessor;
        private ISqlFileExecutor sqlFileExecutor;

        public StartUpService(IBaseMessageResource messageResource
            , ISqlFileProcessor sqlFileProcessor
            , ISqlFileExecutor sqlFileExecutor
                              ) : base(messageResource)
        {
            this.sqlFileProcessor = sqlFileProcessor;
            this.sqlFileExecutor = sqlFileExecutor;
        }

        public void Start(List<DatabaseDto> databaseDtos)
        {
            Logger.Info("*********************** Start *********************************************************************************");
            foreach (DatabaseDto databaseDto in databaseDtos)
            {
                var listFile = sqlFileProcessor.GetOrderedSqlFiles(databaseDto.DirectoryPath, databaseDto.Pattern);
                var sort = sqlFileProcessor.MapVersionFile(listFile, databaseDto.Pattern, databaseDto.VersionDb);
                SqlConnectionStringBuilder sqlConnectionStringBuilder = new SqlConnectionStringBuilder();
                sqlConnectionStringBuilder.ApplicationName = DatabaseUpdateValidatorConstants.APPLICATION_NAME;
                sqlConnectionStringBuilder.DataSource = databaseDto.Server;
                sqlConnectionStringBuilder.InitialCatalog = databaseDto.DatabaseName;
                sqlConnectionStringBuilder.UserID = databaseDto.UserName;
                sqlConnectionStringBuilder.Password = databaseDto.Password;
                sqlConnectionStringBuilder.Encrypt = false;

                sqlFileExecutor.ExecuteFiles(sort, sqlConnectionStringBuilder.ToString());
            }
        }

        public void Stop()
        {
            try
            {
                Logger.Debug("Stack");

                Logger.Info("***************************************** Stop End *********************************************************************");
            }
            catch (Exception ex)
            {
                Logger.Error(ex);
            }
        }
    }
}