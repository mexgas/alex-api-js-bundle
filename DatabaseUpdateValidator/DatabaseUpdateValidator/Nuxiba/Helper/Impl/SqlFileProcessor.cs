using Nuxiba.NuxibaAppBase.Base.Repository;
using System.Text.RegularExpressions;

namespace DatabaseUpdateValidator.Nuxiba.Helper.Impl
{
    public class SqlFileProcessor : BaseRepository, ISqlFileProcessor
    {
        public List<string> GetOrderedSqlFiles(string directoryPath, string pattern)
        {
            Regex regex = new Regex(pattern);
            var sqlFiles = Directory.GetFiles(directoryPath, "*.sql")
                .Select(file => new
                {
                    FileName = file,
                    Match = regex.Match(Path.GetFileName(file))
                })
                .Where(file => file.Match.Success)
                .Select(file => new
                {
                    FileName = file.FileName,
                    Version = file.Match.Groups[1].Value
                })
                .OrderBy(file => file.Version)
                .Select(file => file.FileName)
                .ToList();

            return sqlFiles;
        }

        public SortedList<double, string> MapVersionFile(List<string> sqlFiles, string pattern, double currentVersion)
        {
            SortedList<double, string> fileList = new SortedList<double, string>();
            Regex regex = new Regex(pattern);
            foreach (var sqlFile in sqlFiles)
            {
                Match match = regex.Match(sqlFile);
                int versionFile = Convert.ToInt32(match.Groups["version"].Value);
                int versionFileFix = 0;
                if (match.Groups["versionFix"].Length > 0)
                {
                    versionFileFix = Convert.ToInt32(match.Groups["versionFix"].Value);
                }

                int versionFinal = (versionFile * 1000) + versionFileFix;

                if (versionFinal >= currentVersion)
                {
                    fileList.Add(versionFinal, sqlFile);
                }
            }
            return fileList;
        }
    }
}