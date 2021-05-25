using System.Collections;
using System.Collections.Specialized;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps in reading URL parameters
    /// </summary>
    public static class ParametersReader
    {
        private static Hashtable paramReader = new Hashtable();

        /// <summary>
        /// Adds parameters to a Hashtable
        /// <param name="parameters">Specifies parameters from URL</param>
        /// </summary>
        public static void setParameters(NameValueCollection parameters)
        {
            paramReader.Clear();
            foreach (string param in parameters)
            {
                paramReader.Add(param, parameters[param]);
            }
        }

        /// <summary>
        /// Gets parameters from the Hashtable
        /// <param name="parameters">Specifies parameters from URL</param>
        /// <param name="remove">Specifies if parameters has to be removed from Hashtable</param>
        /// <returns>URL parameter just in case it exits otherwise return empty param</returns>
        /// </summary>
        public static string getParameters(string parameter, bool remove)
        {
            string param = "";
            if (paramReader.ContainsKey(parameter))
            {
                param = (string)paramReader[parameter];
                if (remove)
                {
                    paramReader.Remove(parameter);
                }
            }
            return param;
        }

        /// <summary>
        /// Gets all parameters from the Hashtable
        /// <returns>All URL parameters in the Hashtable</returns>
        /// </summary>
        public static NameValueCollection getAllParameters()
        {
            NameValueCollection allParams = new NameValueCollection();
            foreach (DictionaryEntry param in paramReader)
            {
                allParams.Add(param.Key.ToString(), param.Value.ToString());
            }
            return allParams;
        }
    }
}