using Nuxiba.NuxibaAppBase.Base.Repository;
using System.Text.RegularExpressions;

namespace DatabaseUpdateValidator.Nuxiba.Helper.Impl
{
    public class SqlFileProcessor : BaseRepository, ISqlFileProcessor
    {
        public List<string> GetOrderedSqlFiles(string directoryPath, string pattern)
        {
            Regex regex = new Regex(pattern, RegexOptions.IgnoreCase);
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
                    Version = GetVersionKey(file.Match)
                })
                .OrderBy(file => file.Version)
                .ThenBy(file => file.FileName)
                .Select(file => file.FileName)
                .ToList();

            return sqlFiles;
        }

        public SortedList<long, string> MapVersionFile(List<string> sqlFiles, string pattern, long currentVersion)
        {
            SortedList<long, string> fileList = new SortedList<long, string>();
            Regex regex = new Regex(pattern, RegexOptions.IgnoreCase);
            foreach (var sqlFile in sqlFiles)
            {
                Match match = regex.Match(Path.GetFileName(sqlFile));
                long versionFinal = GetVersionKey(match);

                if (versionFinal >= currentVersion)
                {
                    fileList.Add(versionFinal, sqlFile);
                }
            }
            return fileList;
        }

        private static long GetVersionKey(Match match)
        {
            int versionFile = GetIntGroupValue(match, "version");
            int versionFileFix = GetIntGroupValue(match, "versionFix");
            int patchVersion = GetIntGroupValue(match, "patch");

            return ((long)versionFile * 1000000) + ((long)versionFileFix * 1000) + patchVersion;
        }

        private static int GetIntGroupValue(Match match, string groupName)
        {
            Group group = match.Groups[groupName];
            return group.Success ? Convert.ToInt32(group.Value) : 0;
        }
    }
}
