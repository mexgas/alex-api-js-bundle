using DatabaseUpdateValidator.Nuxiba.Model;

namespace DatabaseUpdateValidator.Nuxiba.StartUp.BusinessService
{
    public interface IStartUpService
    {
        void Start(List<DatabaseDto> databaseDtos);

        void Stop();
    }
}