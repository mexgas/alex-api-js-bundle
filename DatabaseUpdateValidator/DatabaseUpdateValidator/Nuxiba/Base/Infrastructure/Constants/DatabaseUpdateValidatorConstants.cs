using System.Diagnostics.CodeAnalysis;

namespace DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Constants
{
    [ExcludeFromCodeCoverage]
    public static class DatabaseUpdateValidatorConstants
    {
        public static readonly string APPLICATION_ASSEMBLY_NAME = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name ?? "";
        public static readonly string APPLICATION_NAME = "DatabaseUpdateValidator.Service";
    }
}