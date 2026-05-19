using DatabaseUpdateValidator.Nuxiba.Base.Exceptions;
using Nuxiba.NuxibaAppBase.Base.Repository;
using DatabaseUpdateValidator.Nuxiba.Model;
using Microsoft.Data.SqlClient;
using System.Text.RegularExpressions;
using static System.Net.Mime.MediaTypeNames;

namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public class SqlFileExecutor : BaseRepository, ISqlFileExecutor
    {
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
                            ValidateSql2012Compatibility(sqlScript);
                        }

                        // Execute the script in the database
                        _sqlExecutor.ExecuteSqlScript(connectionString, sqlScript, filePath.Value);

                        // Log success
                        Logger.Info($"File executed successfully: {filePath.Value} version: {filePath.Key}");
                    }
                    catch (Exception ex)
                    {
                        string msg = $"while executing the file: {filePath.Value}";
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
            var objetos = new List<(string Tipo, string Nombre)>();

            using (var reader = new System.IO.StringReader(contenidoSql))
            {
                string linea;
                while ((linea = reader.ReadLine()) != null)
                {
                    linea = linea.Trim();

                    // Solo si empieza con CREATE
                    if (linea.StartsWith("CREATE", StringComparison.OrdinalIgnoreCase))
                    {
                        var patronCreate = new Regex(
                            @"^CREATE\s+(?:OR\s+ALTER\s+)?(PROCEDURE|FUNCTION|VIEW|TRIGGER)\s+(\[?\w+\]?\.\[?\w+\]?)",
                            RegexOptions.IgnoreCase
                        );

                        var createMatch = patronCreate.Match(linea);
                        if (createMatch.Success)
                        {
                            objetos.Add((
                                Tipo: createMatch.Groups[1].Value.ToUpper(),  // PROCEDURE, FUNCTION, etc.
                                Nombre: createMatch.Groups[2].Value
                            ));
                        }
                    }
                }
            }

            // ✅ Buscar duplicados
            var duplicated = objetos.GroupBy(x => (x.Tipo, x.Nombre))
                                    .Where(g => g.Count() > 1)
                                    .Select(g => $"{g.Key.Tipo} {g.Key.Nombre}")
                                    .ToList();

            if (duplicated.Any())
            {
                var listaDuplicados = string.Join(Environment.NewLine + "- ", duplicated);
                throw new Exception($"Duplicate objects found: {listaDuplicados}");
            }
        }

        private void ValidateDuplicateDynamicSql(string contenidoSql)
        {
            var dynamicSqlAssignments = new Dictionary<string, int>();
            var lines = contenidoSql.Split(new[] { Environment.NewLine }, StringSplitOptions.None);
            int lineNumber = 0;

            foreach (var linea in lines)
            {
                lineNumber++;
                var trimmedLine = linea.Trim();

                // Buscar asignaciones de SQL dinámico: SET @sql = ...
                if (trimmedLine.StartsWith("SET", StringComparison.OrdinalIgnoreCase) && trimmedLine.Contains("@"))
                {
                    // Extraer el valor después del = 
                    var setPattern = new Regex(
                        @"SET\s+@(\w+)\s*=\s*(.+?)(?:;|$)",
                        RegexOptions.IgnoreCase | RegexOptions.Singleline
                    );

                    var match = setPattern.Match(trimmedLine);
                    if (match.Success)
                    {
                        string variableName = match.Groups[1].Value.ToUpper();
                        string sqlValue = match.Groups[2].Value.Trim();

                        // Normalizar el valor para comparación (eliminar espacios extra)
                        string normalizedValue = Regex.Replace(sqlValue, @"\s+", " ");

                        string key = $"{variableName}={normalizedValue}";

                        if (dynamicSqlAssignments.ContainsKey(key))
                        {
                            Logger.Warn($"Duplicate SET @sql assignment detected at line {lineNumber}: {key}");
                            dynamicSqlAssignments[key]++;
                        }
                        else
                        {
                            dynamicSqlAssignments[key] = 1;
                        }
                    }
                }
            }

            // Verificar si hay duplicados significativos
            var duplicates = dynamicSqlAssignments.Where(x => x.Value > 1).ToList();
            if (duplicates.Any())
            {
                var duplicateList = string.Join(Environment.NewLine + "- ", 
                    duplicates.Select(d => $"Repeated {d.Value} times: {d.Key.Split('=')[0]}"));
                throw new Exception($"Duplicate dynamic SQL assignments found (same SET @sql repeated):{Environment.NewLine}- {duplicateList}");
            }
        }

        private void ValidateSql2012Compatibility(string contenidoSql)
        {
            var incompatibleFeatures = new List<string>();
            var lines = contenidoSql.Split(new[] { Environment.NewLine }, StringSplitOptions.None);
            int lineNumber = 0;

            // Características no compatibles con SQL Server 2012
            var incompatibilityPatterns = new Dictionary<Regex, string>
            {
                { new Regex(@"STRING_SPLIT\s*\(", RegexOptions.IgnoreCase), "STRING_SPLIT (added in SQL Server 2016)" },
                { new Regex(@"DROP\s+TABLE\s+IF\s+EXISTS\s+", RegexOptions.IgnoreCase), "DROP TABLE IF EXISTS (added in SQL Server 2016)" },
                { new Regex(@"DROP\s+VIEW\s+IF\s+EXISTS\s+", RegexOptions.IgnoreCase), "DROP VIEW IF EXISTS (added in SQL Server 2016)" },
                { new Regex(@"DROP\s+PROCEDURE\s+IF\s+EXISTS\s+", RegexOptions.IgnoreCase), "DROP PROCEDURE IF EXISTS (added in SQL Server 2016)" },
                { new Regex(@"DROP\s+FUNCTION\s+IF\s+EXISTS\s+", RegexOptions.IgnoreCase), "DROP FUNCTION IF EXISTS (added in SQL Server 2016)" },
                { new Regex(@"CONCAT_WS\s*\(", RegexOptions.IgnoreCase), "CONCAT_WS (added in SQL Server 2017)" },
                { new Regex(@"JSON_QUERY\s*\(", RegexOptions.IgnoreCase), "JSON_QUERY (added in SQL Server 2016)" },
                { new Regex(@"JSON_VALUE\s*\(", RegexOptions.IgnoreCase), "JSON_VALUE (added in SQL Server 2016)" },
                { new Regex(@"JSON_MODIFY\s*\(", RegexOptions.IgnoreCase), "JSON_MODIFY (added in SQL Server 2016)" },
                { new Regex(@"JSON_EXTRACT\s*\(", RegexOptions.IgnoreCase), "JSON_EXTRACT (added in SQL Server 2017)" },
                { new Regex(@"FORMAT\s*\(", RegexOptions.IgnoreCase), "FORMAT (added in SQL Server 2012 SP1 - may have compatibility issues)" },
                { new Regex(@"TRIM\s*\(", RegexOptions.IgnoreCase), "TRIM (added in SQL Server 2017)" },
                { new Regex(@"TRANSLATE\s*\(", RegexOptions.IgnoreCase), "TRANSLATE (added in SQL Server 2017)" }
            };

            foreach (var linea in lines)
            {
                lineNumber++;
                var trimmedLine = linea.Trim();

                // Skip comments
                if (trimmedLine.StartsWith("--", StringComparison.Ordinal) || trimmedLine.StartsWith("/*", StringComparison.Ordinal))
                {
                    continue;
                }

                foreach (var pattern in incompatibilityPatterns)
                {
                    if (pattern.Key.IsMatch(trimmedLine))
                    {
                        incompatibleFeatures.Add($"Line {lineNumber}: {pattern.Value}");
                    }
                }
            }

            if (incompatibleFeatures.Any())
            {
                var featureList = string.Join(Environment.NewLine + "- ", incompatibleFeatures);
                Logger.Warn($"SQL Server 2012 compatibility issues found:{Environment.NewLine}- {featureList}");
                throw new Exception($"SQL Server 2012 incompatible features detected:{Environment.NewLine}- {featureList}");
            }
        }
    }
}