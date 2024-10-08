using Nuxiba.NuxibaAppBase.Base.Infrastructure.Components;
using System.Diagnostics.CodeAnalysis;
using System.Resources;

namespace DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Resource
{
    [ExcludeFromCodeCoverage]
    public class DatabaseUpdateValidatorResources : IResources
    {
        public static ResourceManager Resource
        {
            get { return Properties.Resources.ResourceManager; }
        }

        public ResourceManager ResourceFiles
        { get { return Resource; } }
    }
}