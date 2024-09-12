using DatabaseUpdateValidator.Nuxiba.StartUp.BusinessService.Impl;

namespace Main
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            // Verificar si se ha pasado un argumento que contenga la ruta
            if (args.Length == 0)
            {
                Console.WriteLine("Por favor, proporciona una ruta válida como argumento.");
                return;
            }

            // Recibir la ruta desde los argumentos de consola
            string path = args[0];

            // Verificar si la ruta proporcionada es válida
            if (!Directory.Exists(path))
            {
                Console.WriteLine($"La ruta proporcionada '{path}' no existe.");
                return;
            }

            // Crear una instancia de NuxibaWorkerService y llamar al método OnStart con la ruta proporcionada
            var workerServices = new NuxibaWorkerService();
            workerServices.OnStart(path);
        }
    }
}