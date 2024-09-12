using DatabaseUpdateValidator.Nuxiba.Base.Exceptions;
using Nuxiba.NuxibaAppBase.Base.Repository;

namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public class SqlFileExecutor : BaseRepository, ISqlFileExecutor
    {
        private readonly ISqlExecutor _sqlExecutor;

        // Constructor inyecta las dependencias
        public SqlFileExecutor(ISqlExecutor sqlExecutor)
        {
            _sqlExecutor = sqlExecutor;
        }

        public void ExecuteScript(string sqlScript, string connectionString, string createDatabase)
        {
            _sqlExecutor.ExecuteSqlScript(connectionString, sqlScript, createDatabase);
        }

        // Método para leer y ejecutar los archivos SQL
        public void ExecuteFiles(SortedList<double, string> filePaths, string connectionString)
        {
            foreach (var filePath in filePaths)
            {
                if (File.Exists(filePath.Value))
                {
                    try
                    {
                        // Leer el contenido del archivo SQL
                        string sqlScript = File.ReadAllText(filePath.Value);

                        // Ejecutar el script en la base de datos
                        _sqlExecutor.ExecuteSqlScript(connectionString, sqlScript, filePath.Value);

                        // Loggear éxito
                        Logger.Info($"Archivo ejecutado correctamente: {filePath.Value} version:{filePath.Key}");
                    }
                    catch (Exception ex)
                    {
                        // Loggear errores
                        Logger.Warn($"Error al ejecutar el archivo: {filePath}, Error: {ex.Message}");
                        throw;
                    }
                }
                else
                {
                    throw new DatabaseUpdateValidatorException($"El archivo no existe: {filePath}");
                }
            }
        }
    }
}