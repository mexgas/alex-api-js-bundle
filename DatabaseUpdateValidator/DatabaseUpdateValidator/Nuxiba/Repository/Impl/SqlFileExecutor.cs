using DatabaseUpdateValidator.Nuxiba.Base.Exceptions;
using Nuxiba.NuxibaAppBase.Base.Repository;
using DatabaseUpdateValidator.Nuxiba.Model;
using Microsoft.Data.SqlClient;

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
    }
}