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

        public SortedList<long, string> MapVersionFile(List<string> sqlFiles, string pattern, long currentVersion)
        {
            SortedList<long, string> fileList = new SortedList<long, string>();
            Regex regex = new Regex(pattern);
            foreach (var sqlFile in sqlFiles)
            {
                Match match = regex.Match(sqlFile);
                int versionFile = Convert.ToInt32(match.Groups["version"].Value);
                int versionFileFix = 0;
                int patchVersion = 0;

                if (match.Groups["versionFix"].Length > 0)
                {
                    versionFileFix = Convert.ToInt32(match.Groups["versionFix"].Value);
                }

                // Capturar patch opcional (ej: .1, .2 en v1.1.1)
                if (match.Groups["patch"].Length > 0)
                {
                    patchVersion = Convert.ToInt32(match.Groups["patch"].Value);
                }

                // Cálculo: (version * 1000000) + (versionFix * 1000) + patch
                // Ej: v1.1.1 = (1 * 1000000) + (1 * 1000) + 1 = 1001001
                long versionFinal = ((long)versionFile * 1000000) + ((long)versionFileFix * 1000) + patchVersion;

                if (versionFinal >= currentVersion)
                {
                    fileList.Add(versionFinal, sqlFile);
                }
            }
            return fileList;
        }
    }
}