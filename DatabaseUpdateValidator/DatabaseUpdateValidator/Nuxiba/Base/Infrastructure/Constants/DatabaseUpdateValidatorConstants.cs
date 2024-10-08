using System.Diagnostics.CodeAnalysis;

namespace DatabaseUpdateValidator.Nuxiba.Base.Infrastructure.Constants
{
    [ExcludeFromCodeCoverage]
    public static class DatabaseUpdateValidatorConstants
    {
        public static readonly string APPLICATION_ASSEMBLY_NAME = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name ?? "";
        public static readonly string APPLICATION_NAME = "DatabaseUpdateValidator.Service";
        public static string SQL_SERVER_SERVER { get; set; } = "127.0.0.1,1436";
        public static string SQL_SERVER_USER { get; set; } = "sa";
        public static string SQL_SERVER_PASSWORD { get; set; } = "Nuxiba2024_";
        public static string SQL_SERVER_SUBFIX { get; set; } = "";
        public static bool IS_DETACH { get; set; } = true;
    }
}