using Microsoft.Data.SqlClient;
using Nuxiba.NuxibaAppBase.Base.Repository;

namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public class SqlExecutor : BaseRepository, ISqlExecutor
    {
        private const int CommandTimeoutSeconds = 120 * 60;
        private const int MaxExecutionAttempts = 2;
        private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(5);

        public void ExecuteSqlScript(string connectionString, string script, string fileName)
        {
            ExecuteWithRetry(fileName, () =>
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    using (SqlCommand command = new SqlCommand(script, connection))
                    {
                        command.CommandTimeout = CommandTimeoutSeconds;
                        connection.Open();
                        command.ExecuteNonQuery();
                    }
                }
            });
        }

        public object ExecuteScalar(string connectionString, string script)
        {
            return ExecuteWithRetry("scalar query", () =>
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    using (SqlCommand command = new SqlCommand(script, connection))
                    {
                        command.CommandTimeout = CommandTimeoutSeconds;
                        connection.Open();
                        return command.ExecuteScalar();
                    }
                }
            });
        }

        private void ExecuteWithRetry(string operationName, Action execute)
        {
            ExecuteWithRetry(operationName, () =>
            {
                execute();
                return true;
            });
        }

        private T ExecuteWithRetry<T>(string operationName, Func<T> execute)
        {
            for (int attempt = 1; attempt <= MaxExecutionAttempts; attempt++)
            {
                try
                {
                    return execute();
                }
                catch (Exception ex) when (attempt < MaxExecutionAttempts)
                {
                    Logger.Warn($"Execution failed for {operationName}. Attempt {attempt} of {MaxExecutionAttempts}. Retrying in {RetryDelay.TotalSeconds} seconds. Error: {ex.Message}");
                    Thread.Sleep(RetryDelay);
                }
            }

            throw new InvalidOperationException("SQL execution retry flow ended unexpectedly.");
        }
    }
}
