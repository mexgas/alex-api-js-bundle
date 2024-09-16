using Castle.Windsor;
using DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Constants;
using Nuxiba.NuxibaAppBase.Base.Infrastructure.Containers.Scanners;
using Nuxiba.NuxibaAppBase.Base.Infrastructure.Resources;
using System.Diagnostics.CodeAnalysis;

namespace DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Containers.Scanners
{
    [ExcludeFromCodeCoverage]
    public class DatabaseUpdateValidatorScanner : IContainerScanner
    {
        public void Register(IWindsorContainer container)
        {
            RegistryCommonScanner.Register(container, DatabaseUpdateValidatorConstants.APPLICATION_ASSEMBLY_NAME);

            RegistryCommonScanner.Register(container, new NuxibaAppBaseScanner());

            ResourceNuxiba.LoadResourcesManager();
            ResourceNuxiba.LoadAllResourcesAssembly(); //carga todos los archivos de configuraciones y mensajes
        }
    }
}