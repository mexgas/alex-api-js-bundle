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
        public void ExecuteFiles(SortedList<double, string> filePaths, string connectionString, DatabaseDto databaseDto)
        {
            int currentVersion = (int)_sqlExecutor.ExecuteScalar(connectionString, databaseDto.VersionQuery);
            int versionFix = 0;
            if (!string.IsNullOrEmpty(databaseDto.VersionQueryFix))
            {
                versionFix = (int)_sqlExecutor.ExecuteScalar(connectionString, databaseDto.VersionQueryFix);
            }

            int currentVersioFinal = (currentVersion * 1000) + versionFix;
            var sortFile = filePaths.Where(f => f.Key >= currentVersioFinal).OrderBy(o => o.Key).ToList();

            foreach (var filePath in sortFile)
            {
                if (File.Exists(filePath.Value))
                {
                    try
                    {
                        // Read the content of the SQL file
                        string sqlScript = File.ReadAllText(filePath.Value);

                        ValidateDuplicateObjectsDirect(sqlScript);

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
                                Nombre: createMatch.Groups[2].Value           // [dbo].[GetReportMenus]
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
    }
}