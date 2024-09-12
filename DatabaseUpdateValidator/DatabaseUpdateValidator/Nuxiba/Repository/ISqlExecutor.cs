namespace DatabaseUpdateValidator.Nuxiba.Repository
{
    public interface ISqlExecutor
    {
        void ExecuteSqlScript(string connectionString, string script, string fileName);
    }
}