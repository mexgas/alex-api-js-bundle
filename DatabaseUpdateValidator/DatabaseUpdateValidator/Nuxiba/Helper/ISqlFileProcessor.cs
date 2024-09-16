namespace DatabaseUpdateValidator.Nuxiba.Helper
{
    public interface ISqlFileProcessor
    {
        List<string> GetOrderedSqlFiles(string directoryPath, string pattern);

        SortedList<double, string> MapVersionFile(List<string> sqlFiles, string pattern, double currentVersionFinal);
    }
}