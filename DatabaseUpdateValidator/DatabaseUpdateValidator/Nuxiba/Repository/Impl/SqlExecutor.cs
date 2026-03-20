using Microsoft.Data.SqlClient;
using Nuxiba.NuxibaAppBase.Base.Repository;

namespace DatabaseUpdateValidator.Nuxiba.Repository.Impl
{
    public class SqlExecutor : BaseRepository, ISqlExecutor
    {
        public void ExecuteSqlScript(string connectionString, string script, string fileName)
        {
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                using (SqlCommand command = new SqlCommand(script, connection))
                {
                    // increase command timeout to 60 minutes for heavy queries
                    command.CommandTimeout = 60 * 60; // seconds
                    connection.Open();
                    command.ExecuteNonQuery();
                }
            }
        }

        public object ExecuteScalar(string connectionString, string script)
        {
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                using (SqlCommand command = new SqlCommand(script, connection))
                {
                    // increase command timeout to 60 minutes for heavy queries
                    command.CommandTimeout = 60 * 60; // seconds
                    connection.Open();
                    return command.ExecuteScalar();
                }
            }
        }
    }
}