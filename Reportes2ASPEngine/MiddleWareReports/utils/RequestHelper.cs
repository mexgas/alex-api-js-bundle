using System;
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
            if (request != null && request.QueryString != null)
            {                
                foreach (string key in request.QueryString)
                {
                    newCollection.Add(key, request.QueryString[key]);
                }              
            }
            return newCollection;
          
        }
    }
}
