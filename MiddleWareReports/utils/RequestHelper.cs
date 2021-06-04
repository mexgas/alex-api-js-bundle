using System.Collections.Specialized;
using System.Web;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps into managing some variables of a HttpRequest
    /// </summary>
    public static class RequestHelper
    {
        /// <summary>
        /// Creates a deep copy of the query parameters of a HttpRequest
        /// </summary>
        /// <param name="request">The HttpRequest to be used</param>
        /// <returns>A new NameValueCollection containing the query parameters from the HttpRequest</returns>
        public static NameValueCollection copyRequestQueryParameters(HttpRequest request)
        {
            NameValueCollection newCollection = new NameValueCollection();
            NameValueCollection paramsCollection = request.RequestType == "POST" ? request.Form : request.QueryString;
            if (request != null && paramsCollection != null)
            {
                foreach (string key in paramsCollection)
                {
                    newCollection.Add(key, paramsCollection[key]);
                }
            }
            return newCollection;
        }
    }
}