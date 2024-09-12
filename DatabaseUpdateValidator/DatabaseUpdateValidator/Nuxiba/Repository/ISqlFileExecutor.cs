namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public interface ISqlFileExecutor
    {
        void ExecuteFiles(SortedList<double, string> filePaths, string connectionString);
    }
}