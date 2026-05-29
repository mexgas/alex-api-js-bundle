using DatabaseUpdateValidator.Nuxiba.Model;

namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public interface ISqlFileExecutor
    {
        bool IsDatabaseConnected(string connectionString);

        void ExecuteScript(string sqlScript, string connectionString, string createDatabase);

        void ExecuteFiles(SortedList<long, string> filePaths, string connectionString, DatabaseDto databaseDto);
    }
}