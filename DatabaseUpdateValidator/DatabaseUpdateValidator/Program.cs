using DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Constants;
using DatabaseUpdateValidator.Nuxiba.StartUp.BusinessService.Impl;
using NLog;

namespace Main
{
    internal class Program
    {
        // Crear una instancia del logger
        private static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        private static void Main(string[] args)
        {
            // Verificar si se ha pasado un argumento que contenga la ruta
            if (args.Length == 0)
            {
                Logger.Fatal("Please provide a valid path as an argument.");
                throw new Exception("Please provide a valid path as an argument.");
            }

            // Recibir la ruta desde los argumentos de consola
            string path = args[0];

            // Verificar si la ruta proporcionada es válida
            if (!Directory.Exists(path))
            {
                Logger.Fatal($"The provided path '{path}' does not exist.");
                throw new Exception($"The provided path '{path}' does not exist.");
            }

            // Use default values for IP, user, and password if arguments are not provided or are less than 1
            string ip = args.Length > 1 && args[1].Length > 0 ? args[1] : DatabaseUpdateValidatorConstants.SQL_SERVER_SERVER;
            string user = args.Length > 2 && args[2].Length > 0 ? args[2] : DatabaseUpdateValidatorConstants.SQL_SERVER_USER;
            string password = args.Length > 3 && args[3].Length > 0 ? args[3] : DatabaseUpdateValidatorConstants.SQL_SERVER_PASSWORD;

            DatabaseUpdateValidatorConstants.SQL_SERVER_SERVER = ip;
            DatabaseUpdateValidatorConstants.SQL_SERVER_USER = user;
            DatabaseUpdateValidatorConstants.SQL_SERVER_PASSWORD = password;

            Logger.Info($"Server:{ip}, User:{user}, Paswword:{password}");

            var workerServices = new NuxibaWorkerService();
            workerServices.OnStart(path);
        }
    }
}