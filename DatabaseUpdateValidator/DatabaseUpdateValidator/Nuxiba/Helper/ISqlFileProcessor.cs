namespace DatabaseUpdateValidator.Nuxiba.Helper
{
    public interface ISqlFileProcessor
    {
        List<string> GetOrderedSqlFiles(string directoryPath, string pattern);

        SortedList<long, string> MapVersionFile(List<string> sqlFiles, string pattern, long currentVersionFinal);
    }
}