using System;
using System.Collections.Specialized;
using System.Data;
using System.Xml;

namespace MiddleWareReports
{
    /// <summary>
    /// Manages the CRUD operations of the FavoriteTemplates table
    /// </summary>
    public class Template
    {
        private DataBase db = new DataBase();

        /// <summary>
        /// Executes and SP depending of the action specified
        /// </summary>
        /// <param name="action">The action to be executed</param>
        /// <param name="parameters">Parameters used in the SP</param>
        private void templateAction(char action, NameValueCollection parameters)
        {
            switch (action)
            {
                case 'I':  //Insert
                    db.executeSP("dbo.SaveUserTemplate", parameters);
                    break;

                case 'U':  //Update
                    db.executeSP("dbo.UpdateUserTemplate", parameters);
                    break;

                case 'D':  //Delete
                    db.executeSP("dbo.DeleteUserTemplate", parameters);
                    break;

                case 'G': //Get
                    break;

                default:
                    throw new Exception("Template operation not supported");
            }
        }

        /// <summary>
        /// Executes an favoriteTemplates SP and then returns the user favorite templates as a XML document
        /// </summary>
        /// <param name="action">Action to be executed</param>
        /// <param name="parameters">Parameters used in the SP</param>
        /// <param name="userId">User who originates the petition</param>
        /// <returns>A XML document containing the user´s favorite templates</returns>
        public XmlDocument Action(char action, NameValueCollection parameters, int userId)
        {
            if (parameters["userId"] == null || parameters["userId"].Length == 0)
            {
                parameters.Add("userId", userId.ToString());
            }

            templateAction(action, parameters);
            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            XmlElement top = xml.CreateElement("", "ReportsTemplates", "");
            top.AppendChild(Get(xml, userId));
            xml.AppendChild(top);
            return xml;
        }

        /// <summary>
        /// Get the user´s favorite templates as a XML
        /// </summary>
        /// <param name="xml">XML to which the element is going to be appended</param>
        /// <param name="userId">User who originates the petition</param>
        /// <returns>A XML element that contains the favorite templates of the user</returns>
        public XmlElement Get(XmlDocument xml, int userId)
        {
            XmlElement userTemplates = xml.CreateElement("", "UserTemplates", "");
            NameValueCollection parameters = new NameValueCollection();
            parameters.Add("userId", userId.ToString());
            DataTable favoriteTemplates = db.executeSP("dbo.GetUserTemplates", parameters);

            foreach (DataRow row in favoriteTemplates.Rows)
            {
                XmlElement element = xml.CreateElement("UserTemplate");
                foreach (DataColumn col in favoriteTemplates.Columns)
                {
                    element.SetAttribute(col.ColumnName, row[col.ColumnName].ToString());
                }
                userTemplates.AppendChild(element);
            }

            return userTemplates;
        }
    }
}