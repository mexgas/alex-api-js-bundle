using System;
using System.Collections.Specialized;

namespace MiddleWareReports
{
    public static class QueryHelper
    {
        public static NameValueCollection copyQueryParameters(NameValueCollection originalCollection)
        {
            NameValueCollection newCollection = new NameValueCollection();
            foreach (string key in originalCollection.Keys) 
            {
                newCollection.Add(key, originalCollection[key]);
            }
            return newCollection;
        }
    }
}
