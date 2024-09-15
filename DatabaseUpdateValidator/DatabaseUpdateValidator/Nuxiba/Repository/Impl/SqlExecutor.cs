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
                SqlCommand command = new SqlCommand(script, connection);
                connection.Open();
                command.ExecuteNonQuery();
            }
        }

        public object ExecuteScalar(string connectionString, string script)
        {
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                SqlCommand command = new SqlCommand(script, connection);
                connection.Open();
                return command.ExecuteScalar();
            }
        }
    }
}