using Nuxiba.NuxibaAppBase.Base.Exceptions;

namespace DatabaseUpdateValidator.Nuxiba.Base.Exceptions
{
    [Serializable]
    public class DatabaseUpdateValidatorException : NuxibaAppBaseException
    {
        public DatabaseUpdateValidatorException(string message) : base(message)
        {
        }

        public DatabaseUpdateValidatorException(string message, Exception innerException)
                : base(message, innerException) { }
    }
}