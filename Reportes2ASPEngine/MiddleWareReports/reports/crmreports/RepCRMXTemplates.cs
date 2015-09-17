using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Data;
using System.Linq;
using System.Text;
using System.Xml;
using MiddleWareReports.db;
using System.Xml.Linq;


namespace MiddleWareReports
{
    public class RepCRMXTemplates : GenericReport
    {
        private CRMxDatabase crmDb;
        public RepCRMXTemplates() : base()
        {
            crmDb = new CRMxDatabase();

        }

        protected override XmlElement getCRMFields(XmlDocument xml, NameValueCollection parameters, short process)
        {
            XmlElement mainElement = xml.CreateElement("", "Filters", "");
            NameValueCollection reportParams = new NameValueCollection();
           
                reportParams.Add("id", process.ToString());

                DataTable filters = db.executeSP("dbo.GetReportFilters", reportParams);



                foreach (DataRow filterRow in filters.Rows)
                {
                    string xmlParentName = filterRow["xmlParentNode"].ToString();
                    string xmlChildName = filterRow["xmlChildNode"].ToString();
                    XmlElement element = xml.CreateElement("", xmlParentName, "");
                    element.SetAttribute("description",xmlParentName);

                    reportParams.Clear();
                    reportParams.Add("action", "0");
                    DataTable catalog = crmDb.executeSP("dbo.getCRMInfo", reportParams);
                    foreach (DataRow filterDataRow in catalog.Rows)
                    {
                        XmlElement childElement = xml.CreateElement("", xmlChildName, "");
                        
                        childElement.SetAttribute("description", filterDataRow["description"].ToString());
                        childElement.SetAttribute("id", filterDataRow["id"].ToString());
                        dbColumn = filterDataRow["dbColumn"].ToString();
                        element.AppendChild(childElement);
                    }
                    element.SetAttribute("dbColumn", dbColumn);
                    if (catalog.Rows.Count > 0)
                       mainElement.AppendChild(element);
                }


            return mainElement;
        }


        


        ///// <summary>
        ///// Obtains the report´s filter menus used to display the search options of the report
        ///// </summary>
        ///// <param name="xml">Xml to which the node will be appended</param>
        ///// <param name="parameters">Parameters used in the SP</param>
        ///// <param name="process">Report id</param>
        ///// <returns>A xml list of the filter menus that the report can use</returns>
        //protected override XmlElement getFiltersMenus(XmlDocument xml, NameValueCollection parameters, short process)
        //{
        //    NameValueCollection reportParams = new NameValueCollection();
        //    reportParams.Add("id", process.ToString());

        //    DataTable filtersMenusT = reportDb.executeSP("dbo.GetReportFiltersMenus", reportParams);
        //    XmlElement filtersMenus = xml.CreateElement("", "FiltersMenus", "");

        //    foreach (DataRow filterRow in filtersMenusT.Rows)
        //    {
        //        string name = filterRow["name"].ToString();
        //        string id = filterRow["id"].ToString();
        //        XmlElement element = xml.CreateElement("", "FilterMenu", "");
        //        element.SetAttribute("description", name);
        //        element.SetAttribute("id", id);
        //        filtersMenus.AppendChild(element);
        //    }
        //    return filtersMenus;
        //}


        ///// <summary>
        ///// Obtains report´s filters used for search queries
        ///// </summary>
        ///// <param name="parameters">Parameters used in the query</param>
        ///// <param name="process">Id of the report to be searched</param>
        ///// <returns>A xml list containing the filters and the values that can be used in the report´s search queries</returns>
        //public override XmlDocument getReportFilters(NameValueCollection parameters, short process)
        //{

        //    string complementColumns = "";
        //    changeCulture();

        //    XmlDocument xml = new XmlDocument();
        //    xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
        //    XmlElement catalogs = xml.CreateElement("", "Catalogs", "");
        //    xml.AppendChild(catalogs);


        //    XmlElement filters = getFilters(xml, parameters, process, complementColumns);
        //    XmlElement menus = getFiltersMenus(xml, parameters, process);

        //    //XmlElement CRMTemplates = getCRMFields(xml, parameters, process);
        //    //DetailReports

        //    xml.ChildNodes.Item(1).AppendChild(filters);
        //    xml.ChildNodes.Item(1).AppendChild(menus);
        //    // xml.ChildNodes.Item(1).AppendChild(CRMTemplates);


        //    return xml;

        //}


    }
}
