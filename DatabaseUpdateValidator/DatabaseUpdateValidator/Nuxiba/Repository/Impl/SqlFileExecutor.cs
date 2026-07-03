using DatabaseUpdateValidator.Nuxiba.Base.Exceptions;
using Nuxiba.NuxibaAppBase.Base.Repository;
using DatabaseUpdateValidator.Nuxiba.Model;
using Microsoft.Data.SqlClient;
using System.Text;
using System.Text.RegularExpressions;

namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public class SqlFileExecutor : BaseRepository, ISqlFileExecutor
    {
        private const string SqlIdentifierPattern = "(?:\\[(?:[^\\]]|\\]\\])+\\]|\"(?:[^\"]|\"\")+\"|[A-Za-z_#@][A-Za-z0-9_@$#]*)";

        private static readonly string SqlObjectNamePattern = $"{SqlIdentifierPattern}(?:\\s*\\.\\s*{SqlIdentifierPattern}){{0,2}}";

        private static readonly Regex ObjectDeclarationRegex = new(
            $"\\b(?:(?:CREATE\\s+OR\\s+ALTER)|CREATE|ALTER)\\s+(?<type>PROC(?:EDURE)?|FUNCTION|VIEW|TRIGGER)\\s+(?<name>{SqlObjectNamePattern})(?=\\s|\\(|;|$)",
            RegexOptions.IgnoreCase | RegexOptions.Singleline | RegexOptions.CultureInvariant);

        private static readonly Regex JobDeclarationRegex = new(
            @"\bsp_(?:add|update)_job\b(?<arguments>.*?)(?=\bsp_(?:add|update)_job\b|\bGO\b|$)",
            RegexOptions.IgnoreCase | RegexOptions.Singleline | RegexOptions.CultureInvariant);

        private static readonly Regex JobNameArgumentRegex = new(
            @"@job_name\s*=\s*N?'(?<name>(?:''|[^'])*)'",
            RegexOptions.IgnoreCase | RegexOptions.Singleline | RegexOptions.CultureInvariant);

        private static readonly Regex DynamicSqlLiteralPrefixRegex = new(
            @"(?:^|\s)(?:SET|SELECT)\s+@\w*sql\w*\s*(?:=|\+=)\s*(?:N)?\s*$|(?:^|\s)DECLARE\s+@\w*sql\w*\b[^;]*=\s*(?:N)?\s*$|(?:^|\s)EXEC(?:UTE)?\s*(?:\(\s*)?(?:N)?\s*$|(?:^|\s)sp_executesql\s+(?:N)?\s*$",
            RegexOptions.IgnoreCase | RegexOptions.Singleline | RegexOptions.CultureInvariant);

        private static readonly Regex DynamicSqlKeywordRegex = new(
            @"\b(CREATE|ALTER|DROP|SELECT|INSERT|UPDATE|DELETE|MERGE|EXEC(?:UTE)?|TRUNCATE)\b",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

        private static readonly Dictionary<Regex, string> Sql2016IncompatibilityPatterns = new()
        {
            { new Regex(@"\bCONCAT_WS\s*\(", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant), "CONCAT_WS (added in SQL Server 2017)" },
            { new Regex(@"\bSTRING_AGG\s*\(", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant), "STRING_AGG (added in SQL Server 2017)" },
            { new Regex(@"\bTRIM\s*\(", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant), "TRIM (added in SQL Server 2017)" },
            { new Regex(@"\bTRANSLATE\s*\(", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant), "TRANSLATE (added in SQL Server 2017)" }
        };

        private readonly ISqlExecutor _sqlExecutor;

        public SqlFileExecutor(ISqlExecutor sqlExecutor)
        {
            _sqlExecutor = sqlExecutor;
        }

        public bool IsDatabaseConnected(string connectionString)
        {
            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    connection.Open(); // Intentar abrir la conexión
                    if (connection.State == System.Data.ConnectionState.Open)
                    {
                        Logger.Debug("Conexión a la base de datos establecida correctamente.");
                        return true;
                    }
                }
            }
            catch (SqlException ex)
            {
                Logger.Debug($"Error al conectar a la base de datos: {ex.Message}");
            }

            return false;
        }

        public void ExecuteScript(string sqlScript, string connectionString, string createDatabase)
        {
            _sqlExecutor.ExecuteSqlScript(connectionString, sqlScript, createDatabase);
        }

        // Method to read and execute the SQL files
        public void ExecuteFiles(SortedList<long, string> filePaths, string connectionString, DatabaseDto databaseDto)
        {
            int currentVersion = (int)_sqlExecutor.ExecuteScalar(connectionString, databaseDto.VersionQuery);
            int versionFix = 0;
            if (!string.IsNullOrEmpty(databaseDto.VersionQueryFix))
            {
                versionFix = (int)_sqlExecutor.ExecuteScalar(connectionString, databaseDto.VersionQueryFix);
            }

            // Cálculo: (version * 1000000) + (versionFix * 1000) + patch
            // Ej: v1.1 = (1 * 1000000) + (1 * 1000) + 0 = 1001000
            long currentVersioFinal = ((long)currentVersion * 1000000) + ((long)versionFix * 1000);
            var sortFile = filePaths.Where(f => f.Key >= currentVersioFinal).OrderBy(o => o.Key).ToList();

            var fileNameFinal = sortFile.Last();

            foreach (var filePath in sortFile)
            {
                if (File.Exists(filePath.Value))
                {
                    try
                    {
                        // Read the content of the SQL file
                        string sqlScript = File.ReadAllText(filePath.Value);

                        if (fileNameFinal.Value == filePath.Value)
                        {
                            ValidateDuplicateObjectsDirect(sqlScript);
                            ValidateDuplicateDynamicSql(sqlScript);
                            ValidateSql2016Compatibility(sqlScript);
                        }

                        // Execute the script in the database
                        _sqlExecutor.ExecuteSqlScript(connectionString, sqlScript, filePath.Value);

                        // Log success
                        Logger.Info($"File executed successfully: {filePath.Value} version: {filePath.Key}");
                    }
                    catch (Exception ex)
                    {
                        string msg = $"while executing the file: {filePath.Value} ex:{ex.Message}";
                        Logger.Error(msg);
                        throw new Exception(msg, ex);
                    }
                }
                else
                {
                    throw new DatabaseUpdateValidatorException($"File does not exist: {filePath.Value}");
                }
            }
        }

        private void ValidateDuplicateObjectsDirect(string contenidoSql)
        {
            var duplicated = FindDuplicateObjects(ExtractDeployableObjectDeclarations(contenidoSql, "direct SQL", 1));

            if (duplicated.Any())
            {
                var duplicateList = string.Join(Environment.NewLine + "- ", duplicated);
                throw new Exception($"Duplicate objects found:{Environment.NewLine}- {duplicateList}");
            }
        }

        private void ValidateDuplicateDynamicSql(string contenidoSql)
        {
            var directObjects = ExtractDeployableObjectDeclarations(contenidoSql, "direct SQL", 1);
            var dynamicObjects = ExtractDynamicSqlBlocks(contenidoSql)
                .SelectMany(block => ExtractDeployableObjectDeclarations(block.Value, "dynamic SQL", block.StartLine))
                .ToList();

            var duplicatedObjects = FindDuplicateObjects(directObjects.Concat(dynamicObjects))
                .Where(item => item.Contains("dynamic SQL", StringComparison.OrdinalIgnoreCase))
                .ToList();

            if (duplicatedObjects.Any())
            {
                var duplicateList = string.Join(Environment.NewLine + "- ", duplicatedObjects);
                throw new Exception($"Duplicate objects found in dynamic SQL:{Environment.NewLine}- {duplicateList}");
            }
        }

        private void ValidateSql2016Compatibility(string contenidoSql)
        {
            var incompatibleFeatures = new List<string>();
            var directSql = MaskSqlCommentsAndStrings(contenidoSql);

            AddSql2016CompatibilityIssues(directSql, 1, "direct SQL", incompatibleFeatures);

            foreach (var block in ExtractDynamicSqlBlocks(contenidoSql))
            {
                if (LooksLikeSql(block.Value))
                {
                    AddSql2016CompatibilityIssues(block.Value, block.StartLine, "dynamic SQL", incompatibleFeatures);
                }
            }

            if (incompatibleFeatures.Any())
            {
                var featureList = string.Join(Environment.NewLine + "- ", incompatibleFeatures);
                Logger.Warn($"SQL Server 2016 compatibility issues found:{Environment.NewLine}- {featureList}");
                throw new Exception($"SQL Server 2016 incompatible features detected:{Environment.NewLine}- {featureList}");
            }
        }

        private static List<string> FindDuplicateObjects(IEnumerable<SqlObjectDeclaration> declarations)
        {
            return declarations
                .GroupBy(item => $"{item.Type}|{item.NormalizedName}", StringComparer.OrdinalIgnoreCase)
                .Where(group => group.Count() > 1)
                .Select(group =>
                {
                    var first = group.First();
                    var locations = string.Join(", ", group.Select(item => $"{item.Source} line {item.LineNumber}"));
                    return $"{first.Type} {first.DisplayName} at {locations}";
                })
                .ToList();
        }

        private static List<SqlObjectDeclaration> ExtractObjectDeclarations(string sql, string source, int baseLineNumber)
        {
            var objects = new List<SqlObjectDeclaration>();

            foreach (Match match in ObjectDeclarationRegex.Matches(sql))
            {
                var type = NormalizeObjectType(match.Groups["type"].Value);
                var displayName = NormalizeWhitespace(match.Groups["name"].Value);
                var normalizedName = NormalizeSqlObjectName(displayName);
                var lineNumber = GetLineNumber(sql, match.Index, baseLineNumber);

                objects.Add(new SqlObjectDeclaration(type, displayName, normalizedName, lineNumber, source));
            }

            return objects;
        }

        private static List<SqlObjectDeclaration> ExtractDeployableObjectDeclarations(string sql, string source, int baseLineNumber)
        {
            var sqlWithoutComments = MaskSqlComments(sql);
            var sqlWithoutCommentsAndStrings = MaskSqlCommentsAndStrings(sql);
            var objects = ExtractObjectDeclarations(sqlWithoutCommentsAndStrings, source, baseLineNumber);

            objects.AddRange(ExtractJobDeclarations(sqlWithoutComments, source, baseLineNumber));

            return objects;
        }

        private static List<SqlObjectDeclaration> ExtractJobDeclarations(string sql, string source, int baseLineNumber)
        {
            var jobs = new List<SqlObjectDeclaration>();

            foreach (Match jobMatch in JobDeclarationRegex.Matches(sql))
            {
                var nameMatch = JobNameArgumentRegex.Match(jobMatch.Groups["arguments"].Value);
                if (!nameMatch.Success)
                {
                    continue;
                }

                var displayName = nameMatch.Groups["name"].Value.Replace("''", "'");
                var normalizedName = NormalizeWhitespace(displayName).ToLowerInvariant();
                var lineNumber = GetLineNumber(sql, jobMatch.Groups["arguments"].Index + nameMatch.Index, baseLineNumber);

                jobs.Add(new SqlObjectDeclaration("JOB", displayName, normalizedName, lineNumber, source));
            }

            return jobs;
        }

        private static List<SqlStringLiteral> ExtractDynamicSqlBlocks(string sql)
        {
            return ExtractSqlStringLiterals(sql)
                .Where(literal => IsDynamicSqlLiteral(sql, literal.StartIndex))
                .ToList();
        }

        private static bool IsDynamicSqlLiteral(string sql, int literalStartIndex)
        {
            var contextStart = Math.Max(0, literalStartIndex - 400);
            var context = sql.Substring(contextStart, literalStartIndex - contextStart);
            var statementStart = Math.Max(Math.Max(context.LastIndexOf(';'), context.LastIndexOf('\n')), context.LastIndexOf('\r'));

            if (statementStart >= 0)
            {
                context = context.Substring(statementStart + 1);
            }

            return DynamicSqlLiteralPrefixRegex.IsMatch(context);
        }

        private static List<SqlStringLiteral> ExtractSqlStringLiterals(string sql)
        {
            var literals = new List<SqlStringLiteral>();
            var lineNumber = 1;
            var inLineComment = false;
            var inBlockComment = false;

            for (var i = 0; i < sql.Length;)
            {
                var current = sql[i];
                var next = i + 1 < sql.Length ? sql[i + 1] : '\0';

                if (inLineComment)
                {
                    if (current == '\r' || current == '\n')
                    {
                        inLineComment = false;
                    }

                    if (current == '\n')
                    {
                        lineNumber++;
                    }

                    i++;
                    continue;
                }

                if (inBlockComment)
                {
                    if (current == '*' && next == '/')
                    {
                        inBlockComment = false;
                        i += 2;
                        continue;
                    }

                    if (current == '\n')
                    {
                        lineNumber++;
                    }

                    i++;
                    continue;
                }

                if (current == '-' && next == '-')
                {
                    inLineComment = true;
                    i += 2;
                    continue;
                }

                if (current == '/' && next == '*')
                {
                    inBlockComment = true;
                    i += 2;
                    continue;
                }

                if (current == '\'')
                {
                    var literal = ReadSqlStringLiteral(sql, i, lineNumber);
                    literals.Add(literal);
                    lineNumber += CountLineBreaks(literal.RawText);
                    i = literal.EndIndex + 1;
                    continue;
                }

                if (current == '\n')
                {
                    lineNumber++;
                }

                i++;
            }

            return literals;
        }

        private static SqlStringLiteral ReadSqlStringLiteral(string sql, int startIndex, int startLine)
        {
            var value = new StringBuilder();
            var rawText = new StringBuilder();
            var i = startIndex + 1;

            rawText.Append(sql[startIndex]);

            while (i < sql.Length)
            {
                var current = sql[i];
                rawText.Append(current);

                if (current == '\'')
                {
                    var next = i + 1 < sql.Length ? sql[i + 1] : '\0';

                    if (next == '\'')
                    {
                        value.Append('\'');
                        rawText.Append(next);
                        i += 2;
                        continue;
                    }

                    return new SqlStringLiteral(value.ToString(), rawText.ToString(), startLine, startIndex, i);
                }

                value.Append(current);
                i++;
            }

            return new SqlStringLiteral(value.ToString(), rawText.ToString(), startLine, startIndex, sql.Length - 1);
        }

        private static void AddSql2016CompatibilityIssues(string sql, int baseLineNumber, string source, ICollection<string> incompatibleFeatures)
        {
            foreach (var pattern in Sql2016IncompatibilityPatterns)
            {
                foreach (Match match in pattern.Key.Matches(sql))
                {
                    var lineNumber = GetLineNumber(sql, match.Index, baseLineNumber);
                    var lineText = GetLineText(sql, match.Index);
                    incompatibleFeatures.Add($"{source} line {lineNumber}: {pattern.Value}. SQL: {lineText}");
                }
            }
        }

        private static string MaskSqlCommentsAndStrings(string sql)
        {
            var result = new StringBuilder(sql.Length);
            var inLineComment = false;
            var inBlockComment = false;
            var inString = false;

            for (var i = 0; i < sql.Length;)
            {
                var current = sql[i];
                var next = i + 1 < sql.Length ? sql[i + 1] : '\0';

                if (inLineComment)
                {
                    if (current == '\r' || current == '\n')
                    {
                        inLineComment = false;
                        result.Append(current);
                    }
                    else
                    {
                        result.Append(' ');
                    }

                    i++;
                    continue;
                }

                if (inBlockComment)
                {
                    if (current == '*' && next == '/')
                    {
                        result.Append("  ");
                        inBlockComment = false;
                        i += 2;
                        continue;
                    }

                    result.Append(IsLineBreak(current) ? current : ' ');
                    i++;
                    continue;
                }

                if (inString)
                {
                    if (current == '\'')
                    {
                        result.Append(' ');

                        if (next == '\'')
                        {
                            result.Append(' ');
                            i += 2;
                            continue;
                        }

                        inString = false;
                        i++;
                        continue;
                    }

                    result.Append(IsLineBreak(current) ? current : ' ');
                    i++;
                    continue;
                }

                if (current == '-' && next == '-')
                {
                    result.Append("  ");
                    inLineComment = true;
                    i += 2;
                    continue;
                }

                if (current == '/' && next == '*')
                {
                    result.Append("  ");
                    inBlockComment = true;
                    i += 2;
                    continue;
                }

                if (current == '\'')
                {
                    result.Append(' ');
                    inString = true;
                    i++;
                    continue;
                }

                result.Append(current);
                i++;
            }

            return result.ToString();
        }

        private static string MaskSqlComments(string sql)
        {
            var result = new StringBuilder(sql.Length);
            var inLineComment = false;
            var inBlockComment = false;
            var inString = false;

            for (var i = 0; i < sql.Length;)
            {
                var current = sql[i];
                var next = i + 1 < sql.Length ? sql[i + 1] : '\0';

                if (inLineComment)
                {
                    if (current == '\r' || current == '\n')
                    {
                        inLineComment = false;
                        result.Append(current);
                    }
                    else
                    {
                        result.Append(' ');
                    }

                    i++;
                    continue;
                }

                if (inBlockComment)
                {
                    if (current == '*' && next == '/')
                    {
                        result.Append("  ");
                        inBlockComment = false;
                        i += 2;
                        continue;
                    }

                    result.Append(IsLineBreak(current) ? current : ' ');
                    i++;
                    continue;
                }

                if (inString)
                {
                    result.Append(current);

                    if (current == '\'')
                    {
                        if (next == '\'')
                        {
                            result.Append(next);
                            i += 2;
                            continue;
                        }

                        inString = false;
                    }

                    i++;
                    continue;
                }

                if (current == '-' && next == '-')
                {
                    result.Append("  ");
                    inLineComment = true;
                    i += 2;
                    continue;
                }

                if (current == '/' && next == '*')
                {
                    result.Append("  ");
                    inBlockComment = true;
                    i += 2;
                    continue;
                }

                if (current == '\'')
                {
                    inString = true;
                }

                result.Append(current);
                i++;
            }

            return result.ToString();
        }

        private static bool LooksLikeSql(string value)
        {
            return DynamicSqlKeywordRegex.IsMatch(value);
        }

        private static string NormalizeObjectType(string type)
        {
            return type.Equals("PROC", StringComparison.OrdinalIgnoreCase) ? "PROCEDURE" : type.ToUpperInvariant();
        }

        private static string NormalizeSqlObjectName(string name)
        {
            var normalizedParts = name
                .Split('.')
                .Select(part => UnquoteSqlIdentifier(part.Trim()).ToLowerInvariant())
                .Where(part => !string.IsNullOrWhiteSpace(part))
                .ToList();

            if (normalizedParts.Count == 1)
            {
                normalizedParts.Insert(0, "dbo");
            }

            return string.Join(".", normalizedParts);
        }

        private static string UnquoteSqlIdentifier(string identifier)
        {
            if (identifier.Length >= 2 && identifier[0] == '[' && identifier[^1] == ']')
            {
                return identifier.Substring(1, identifier.Length - 2).Replace("]]", "]");
            }

            if (identifier.Length >= 2 && identifier[0] == '"' && identifier[^1] == '"')
            {
                return identifier.Substring(1, identifier.Length - 2).Replace("\"\"", "\"");
            }

            return identifier;
        }

        private static string NormalizeWhitespace(string value)
        {
            return Regex.Replace(value, @"\s+", " ").Trim();
        }

        private static int CountLineBreaks(string value)
        {
            var count = 0;

            foreach (var current in value)
            {
                if (current == '\n')
                {
                    count++;
                }
            }

            return count;
        }

        private static int GetLineNumber(string value, int index, int baseLineNumber)
        {
            var lineNumber = baseLineNumber;
            var length = Math.Min(index, value.Length);

            for (var i = 0; i < length; i++)
            {
                if (value[i] == '\n')
                {
                    lineNumber++;
                }
            }

            return lineNumber;
        }

        private static string GetLineText(string value, int index)
        {
            if (string.IsNullOrEmpty(value))
            {
                return string.Empty;
            }

            var safeIndex = Math.Min(Math.Max(index, 0), value.Length - 1);
            var lineStart = value.LastIndexOf('\n', safeIndex);
            var lineEnd = value.IndexOf('\n', safeIndex);

            lineStart = lineStart < 0 ? 0 : lineStart + 1;
            lineEnd = lineEnd < 0 ? value.Length : lineEnd;

            var line = value.Substring(lineStart, lineEnd - lineStart).Trim();
            return line.Length <= 300 ? line : $"{line.Substring(0, 297)}...";
        }

        private static bool IsLineBreak(char value)
        {
            return value == '\r' || value == '\n';
        }

        private sealed class SqlObjectDeclaration
        {
            public SqlObjectDeclaration(string type, string displayName, string normalizedName, int lineNumber, string source)
            {
                Type = type;
                DisplayName = displayName;
                NormalizedName = normalizedName;
                LineNumber = lineNumber;
                Source = source;
            }

            public string Type { get; }

            public string DisplayName { get; }

            public string NormalizedName { get; }

            public int LineNumber { get; }

            public string Source { get; }
        }

        private sealed class SqlStringLiteral
        {
            public SqlStringLiteral(string value, string rawText, int startLine, int startIndex, int endIndex)
            {
                Value = value;
                RawText = rawText;
                StartLine = startLine;
                StartIndex = startIndex;
                EndIndex = endIndex;
            }

            public string Value { get; }

            public string RawText { get; }

            public int StartLine { get; }

            public int StartIndex { get; }

            public int EndIndex { get; }
        }
    }
}
