using MiddleWareReports.db;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Data;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;

namespace MiddleWareReports
{
    public class CRMxView : GenericReport
    {
        private CRMxDatabase crmDb;
        //public static int numColums = 0;
        //public static System.Collections.Hashtable nombColums = new System.Collections.Hashtable();
        public CRMxView()
            : base()
        {
            crmDb = new CRMxDatabase();

        }

        protected override XmlElement getCRMFields(System.Xml.XmlDocument xml, System.Collections.Specialized.NameValueCollection parameters, short process)
        {
            XmlElement mainElement = xml.CreateElement("", "Filters", "");
            NameValueCollection reportParams = new NameValueCollection();

            reportParams.Add("id", process.ToString());

            //DataTable filters = db.executeSP("dbo.GetReportFilters", reportParams);


            string crmTemplateId = parameters["crmtemplateId"];
            parameters.Remove("crmtemplateId");

            XmlElement crmFields = getFiltersByCRMTemplate(xml, crmTemplateId);
            //Obtener  headers

            reportParams.Clear();
            reportParams.Add("action", "5");
            reportParams.Add("crmTemplateId", crmTemplateId);
            DataTable CRMTemplateData = crmDb.executeSP("dbo.GetCRMInfo", reportParams); //Obtener tabSheets relacionadas a un template
            XmlElement columns = xml.CreateElement("", "Fields", "");
            columns.SetAttribute("description", TranslatorHelper.getResource("Fields"));
            columns.SetAttribute("dbColumn", "columns");

            XmlElement dateColumn = xml.CreateElement("", "Field", "");
            XmlElement sourceColumn = xml.CreateElement("", "Field", "");

            dateColumn.SetAttribute("id", "crmx_Date");
            dateColumn.SetAttribute("description", TranslatorHelper.getResource("crmx_Date"));

            sourceColumn.SetAttribute("id", "crmxSource");
            sourceColumn.SetAttribute("description", TranslatorHelper.getResource("crmxSource"));

            columns.AppendChild(dateColumn);
            columns.AppendChild(sourceColumn);

            foreach (DataRow CRMRow in CRMTemplateData.Rows)
            {
                XmlElement column = xml.CreateElement("", "Field", "");
                column.SetAttribute("id", CRMRow["header"].ToString());
                column.SetAttribute("description", CRMRow["header"].ToString());
                columns.AppendChild(column);
                //  CRMxView.numColums++;
                //CRMxView.nombColums.Add(CRMRow["dataColumn"].ToString().Trim(), CRMRow["header"].ToString().Trim());
            }

            if (!(columns.HasChildNodes))
            {
                throw new CRMFieldsNotFoundException("Bazinga!");
            }

            DataTable schemaTable = new DataTable();
            schemaTable = getTableColumns();
            DBSchema.clearDBSchema();
            foreach (DataColumn column in schemaTable.Columns)
            {
                //Column DB Type for schema
                DBSchema.setDataType(column.ColumnName, TypeInspector.ConvertToDbType(column.DataType));
            }
            //string templateId = parameters["TemplateId"];
            //parameters.Remove("TemplateId");
            getCRMTemplates(xml, mainElement, process);
            if (columns.HasChildNodes)
                crmFields.AppendChild(columns);
            if (crmFields.HasChildNodes)
                mainElement.AppendChild(crmFields);

            return mainElement;
        }

        private void getCRMTemplates(XmlDocument xml, XmlElement mainElement, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());


            DataTable filters = db.executeSP("dbo.GetReportFilters", reportParams);

            XmlElement element = xml.CreateElement("DummyElement");

            foreach (DataRow filterRow in filters.Rows)
            {
                string xmlParentName = filterRow["xmlParentNode"].ToString();
                string xmlChildName = filterRow["xmlChildNode"].ToString();

                element = xml.CreateElement("", xmlParentName, "");
                element.SetAttribute("description", xmlParentName);
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
            }
            if (element != null && element.HasChildNodes)
                mainElement.AppendChild(element);
            

        }


        protected override XmlElement getFiltersByCRMTemplate(XmlDocument xml, string templateId)
        {

            NameValueCollection reportParams = new NameValueCollection(); // Get Campaign Info
            reportParams.Add("action", "0");
            reportParams.Add("type", "1");
            DataTable temp = db.executeSP("dbo.ccspRepCatalogos", reportParams);
            List<Abs_Element> campaings = new List<Abs_Element>();

            foreach (DataRow row in temp.Rows)
            {
                campaings.Add(new Abs_Element() { id = row["id"].ToString(), name = row["description"].ToString() });
            }


            List<Abs_Element> acds = new List<Abs_Element>(); //Get ACD Info
            reportParams.Clear();
            reportParams.Add("action", "0");
            reportParams.Add("type", "7");
            temp = db.executeSP("dbo.ccspRepCatalogos", reportParams);
            foreach (DataRow row in temp.Rows)
            {
                acds.Add(new Abs_Element() { id = row["id"].ToString(), name = row["description"].ToString() });
            }

            reportParams.Clear();  //Service information
            reportParams.Add("crmTemplateId", templateId);
            reportParams.Add("action", "2");
            DataTable crmInfo = crmDb.executeSP("dbo.GetCRMInfo", reportParams);

            
            XmlElement crmxFilters = xml.CreateElement("", "CRMxFilters", "");
            string dbColumn = "crmxSource";
            XmlElement campaingsRoot = xml.CreateElement("", "Campaigns", "");  //Create a root for campaigns
            campaingsRoot.SetAttribute("description", TranslatorHelper.getResource("Campaigns"));
            campaingsRoot.SetAttribute("dbColumn", dbColumn);

            XmlElement acdsRoot = xml.CreateElement("", "Acds", "");//root for ACD groups
            acdsRoot.SetAttribute("description", TranslatorHelper.getResource("Acds"));
            acdsRoot.SetAttribute("dbColumn", dbColumn);

            Dictionary<String, XmlElement> acdXmls = new Dictionary<string, XmlElement>(); //dictionary to store acd xml element 

            foreach (DataRow serviceRow in crmInfo.Rows)
            {
                string currentValue = serviceRow.ItemArray[0].ToString();
                if (!string.IsNullOrEmpty(currentValue) && currentValue.StartsWith("call:i:"))
                {
                    string id = currentValue.Split(':')[2];
                    string dnis = currentValue.Split(':')[3];
                    IEnumerable<Abs_Element> acdQuery =
                            from acd in acds
                            where acd.id == id
                            select acd;
                    foreach (Abs_Element acdResult in acdQuery)
                    {
                        if (!acdXmls.ContainsKey(acdResult.id))
                        {
                            acdXmls[acdResult.id] = xml.CreateElement("", "Acd", "");
                            acdXmls[acdResult.id].SetAttribute("description", acdResult.name);
                            acdXmls[acdResult.id].SetAttribute("id", acdResult.id);
                            acdsRoot.AppendChild(acdXmls[acdResult.id]);
                        }
                        if (dnis != null)
                        {
                            XmlElement dnisElement = xml.CreateElement("", "Did", "");
                            dnisElement.SetAttribute("id", currentValue);
                            dnisElement.SetAttribute("description", dnis);
                            acdXmls[acdResult.id].AppendChild(dnisElement);
                        }
                    }
                }
                else if (!string.IsNullOrEmpty(currentValue) && currentValue.StartsWith("call:o:"))
                {
                    string id = currentValue.Split(':')[2];


                    IEnumerable<Abs_Element> campaignQuery =
                            from camp in campaings
                            where camp.id == id
                            select camp;
                    foreach (Abs_Element campaignResult in campaignQuery)
                    {
                        XmlElement campTemp = xml.CreateElement("", "Campaing", "");
                        campTemp.SetAttribute("id", currentValue);
                        campTemp.SetAttribute("description", campaignResult.name);
                        campTemp.SetAttribute("checked", "0");
                        campaingsRoot.AppendChild(campTemp);
                    }
                }


            }





            if (acdsRoot.HasChildNodes)
                crmxFilters.AppendChild(acdsRoot);
            if (campaingsRoot.HasChildNodes)
                crmxFilters.AppendChild(campaingsRoot);
            
            return crmxFilters;


        }

        protected override DataTable getTableColumns()
        {
            StringBuilder query = new StringBuilder();
            query.Append(DynamicTsqlBuilder.getTableColumns(reportName));
            return crmDb.executeDynamicQuery(query);
        }

        public override XmlDocument getXmlReport(NameValueCollection parameters, short process, string addFilters, int sourceUserId, string savetemplate, string totals)
        {
            changeCulture();
            NameValueCollection parametersToSave = new NameValueCollection(parameters);
            NameValueCollection parametersTotals = new NameValueCollection(parameters);
            NameValueCollection parametersAddFilter = new NameValueCollection();
            XmlDocument xmlAddFilters = new XmlDocument();
            bool calculateTotals = true; // if (totals == "1")            

            
            //Add Filrters used by report selected (Note: Fill DBSchema)
            if (addFilters.Length > 0)
            {
                //Create XML including filters used by report
                switch (process)
                {
                    case 9010:
                        xmlAddFilters = getCRMFields(parameters, process);
                        break;
                    default:
                        xmlAddFilters = getReportFilters(parametersAddFilter, process);
                        break;
                }
                
            }
            if(parameters["TemplateId"] != null)
                parameters.Remove("TemplateId");

            //Get report data (details and totals) via a DB query
            DynamicQuery dynamicQuery = new DynamicQuery(process);
            DataTable detailTable = executeReader(parameters, true, false, dynamicQuery, process);
            DataTable totalsTable = null;

            if (calculateTotals)
            {
                bool isTimePeriod = false;
                TimePeriod t = TimePeriod.H;
                if (parametersTotals["timePeriod"] != null && parametersTotals["timePeriod"].Length > 0)
                {
                    isTimePeriod = TimePeriodGroup.isTimePeriod(parametersTotals["timePeriod"]);
                    if (isTimePeriod)
                    {
                        string timePeriod = parametersTotals["timePeriod"];
                        t = (TimePeriod)Enum.Parse(typeof(TimePeriod), timePeriod, true);
                    }
                }
                dynamicQuery.TotalColumns = getTotalColumns(dynamicQuery, detailTable, isTimePeriod, t, parametersTotals);
                totalsTable = executeReader(parametersTotals, false, false, dynamicQuery, process);
                totalsTable = getGrandTotalTable(detailTable, totalsTable);
            }

            //Generate XML
            XmlDocument xmlReport = new XmlDocument();
            xmlReport.AppendChild(xmlReport.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            EmptyResultException.dataTableIsEmpty(detailTable);
            translatedColumns = TranslatorHelper.translateColumns(detailTable.Columns, process);
            convertedColumns = TranslatorHelper.convertColumns(detailTable.Columns);
            XmlElement report = xmlReport.CreateElement("", "Report", "");
            xmlReport.AppendChild(report);
            XmlElement name = xmlReport.CreateElement("", "ReportName", "");
            name.SetAttribute("name", this.reportName);
            name.InnerText = this.reportName;
            report.AppendChild(name);
            report.AppendChild(getXmlDetailReports(xmlReport, process));

            report.AppendChild(getXmlRows(xmlReport, detailTable, "Rows"));


            if (calculateTotals)
            {
                report.AppendChild(getXmlRows(xmlReport, totalsTable, "TotalsRows"));
            }

            //Get DB table paging
            XmlElement pageNode = innerPaginate(xmlReport, dynamicQuery);
            if (pageNode != null)
            {
                //Add paging node at the end
                report.AppendChild(pageNode);
            }

            //Add xml
            if (addFilters.Length > 0)
            {
                XmlElement catalogs = xmlReport.CreateElement("", "Catalogs", "");
                XmlElement filters = xmlReport.CreateElement("", "Filters", "");

                XmlElement menus = getFiltersMenus(xmlReport, parameters, process);

                switch (process)
                {
                    case 9010:
                        XmlElement element = xmlReport.CreateElement("", "FilterMenu", "");
                        element.SetAttribute("description", "crmfilters");
                        element.SetAttribute("id", "8");
                        menus.AppendChild(element);
                        break;

                }
                if (menus.HasChildNodes)
                    catalogs.AppendChild(menus);


                foreach (XmlNode node in xmlAddFilters.DocumentElement.ChildNodes)
                {
                    XmlNode imported = xmlReport.ImportNode(node, true);
                    filters.AppendChild(imported);
                }
                catalogs.AppendChild(filters);
                report.AppendChild(catalogs);
            }



            //Save recent report in DB after xmlReport build
            if (savetemplate.Length > 0)
            {
                saveTemplate(sourceUserId, process, parametersToSave, savetemplate);
            }

            return xmlReport;

        }


        protected override XmlElement getXmlRows(XmlDocument xmlReport, DataTable table, string nodeName)
        {
            XmlElement rows = xmlReport.CreateElement("", nodeName, "");

            foreach (DataRow dataRow in table.Rows) //Add rows to the XML
            {
                Dictionary<string, string> findDuplicateds = new Dictionary<string, string>();

                Dictionary<string, string> campaigns = getCampaigns();
                Dictionary<string, string> acds = getAcds();
                XmlElement row = xmlReport.CreateElement("", "Row", "");
                foreach (DataColumn column in table.Columns)
                {
                    if (translatedColumns[column.ColumnName] != null) //Only return translated columns
                    {
                        string value = TranslatorHelper.parseDbValue(dataRow[column.ColumnName]);
                        if (convertedColumns[column.ColumnName] != null && value != "")
                        {
                            value = TranslatorHelper.formatTime(Convert.ToInt32(value));
                        }
                        XmlElement el = xmlReport.CreateElement("", "Cell", "");


                        el.SetAttribute("value", getAcdCampaignRelation(value, campaigns, acds));
                        el.SetAttribute("name", getPivotTranslatedColumns(translatedColumns[column.ColumnName]));


                        row.AppendChild(el);

                        value = translatedColumns[column.ColumnName];

                    }
                }
                rows.AppendChild(row);
            }

            return rows;
        }

        private string getAcdCampaignRelation(string value, Dictionary<string, string> campaigns, Dictionary<string, string> acds)
        {
            string[] split = value.Split(':');
            if (value.StartsWith("call:i:"))//Acd
            {
                value = acds[split[2]] + "(" + split[3] + ")";
            }
            else if (value.StartsWith("call:o:"))//Campaign
            {
                value = campaigns[split[2]];
            }
            return value;
        }


        private Dictionary<string, string> getAcds()
        {
            Dictionary<String, string> res = new Dictionary<string, string>();

            NameValueCollection reportParams = new NameValueCollection(); // Get Campaign Info
            reportParams.Add("action", "0");
            reportParams.Add("type", "7");
            DataTable temp = db.executeSP("dbo.ccspRepCatalogos", reportParams);
            List<Abs_Element> campaings = new List<Abs_Element>();

            foreach (DataRow row in temp.Rows)
            {
                res.Add(row["id"].ToString(), row["description"].ToString());
            }
            return res;
        }

        private Dictionary<string, string> getCampaigns()
        {
            Dictionary<String, string> res = new Dictionary<string, string>();
            List<Abs_Element> acds = new List<Abs_Element>(); //Get ACD Info

            NameValueCollection reportParams = new NameValueCollection(); // Get Campaign Info
            reportParams.Add("action", "0");
            reportParams.Add("type", "1");
            DataTable temp = db.executeSP("dbo.ccspRepCatalogos", reportParams);

            foreach (DataRow row in temp.Rows)
            {
                res.Add(row["id"].ToString(), row["description"].ToString());
            }

            return res;
        }


        public override DataTable getDataReport(NameValueCollection parameters, short process)
        {
            changeCulture();

            NameValueCollection parametersTotals = new NameValueCollection(parameters);

            bool isTimePeriod = false;
            TimePeriod t = TimePeriod.H;
            if (parametersTotals["timePeriod"] != null && parametersTotals["timePeriod"].Length > 0)
            {
                isTimePeriod = TimePeriodGroup.isTimePeriod(parametersTotals["timePeriod"]);
                if (isTimePeriod)
                {
                    string timePeriod = parametersTotals["timePeriod"];
                    t = (TimePeriod)Enum.Parse(typeof(TimePeriod), timePeriod, true);
                }
            }

            DynamicQuery dynamicQuery = new DynamicQuery(process);
            DataTable detailTable = executeReader(parameters, false, false, dynamicQuery, process);
            dynamicQuery.TotalColumns = getTotalColumns(dynamicQuery, detailTable, isTimePeriod, t, parametersTotals);
            DataTable totalsTable = executeReader(parametersTotals, false, false, dynamicQuery, process);
            totalsTable = getGrandTotalTable(detailTable, totalsTable);

            DataTable union = new DataTable();
            DataColumn[] newcolumns = new DataColumn[detailTable.Columns.Count];
            Dictionary<string, string> acds = getAcds();
            Dictionary<string, string> campaigns = getCampaigns();

            translatedColumns = TranslatorHelper.translateColumns(detailTable.Columns, process);
            foreach (DataRow row in detailTable.Rows)
            {
                string rowValue = row["crmxSource"].ToString();
                if (!String.IsNullOrEmpty(rowValue) && rowValue.StartsWith("call:i:"))
                {
                    string[] split = rowValue.Split(':');
                    if (acds.ContainsKey(split[2]) && split[3] != null)
                        row["crmxSource"] = acds[split[2]] + "(" + split[3] + ")";
                }
                else if (!String.IsNullOrEmpty(rowValue) && rowValue.StartsWith("call:o:"))
                {
                    string[] split = rowValue.Split(':');
                    if (campaigns.ContainsKey(split[2]))
                        row["crmxSource"] = campaigns[split[2]];
                }

            }

            List<String> repeatedColumns = new List<string>();
            for (int i = 0; i < totalsTable.Columns.Count; i++)
            {
                if (!string.IsNullOrEmpty(totalsTable.Columns[i].ColumnName) && !string.IsNullOrEmpty(translatedColumns[totalsTable.Columns[i].ColumnName]))
                {


                    if (!repeatedColumns.Contains(translatedColumns[totalsTable.Columns[i].ColumnName]))
                    {
                        repeatedColumns.Add(translatedColumns[totalsTable.Columns[i].ColumnName]);
                    }
                    else
                    {
                        translatedColumns[totalsTable.Columns[i].ColumnName] += " ";
                        repeatedColumns.Add(translatedColumns[totalsTable.Columns[i].ColumnName]);
                    }
                    newcolumns[i] = new DataColumn(
                    translatedColumns[totalsTable.Columns[i].ColumnName], totalsTable.Columns[i].DataType);

                }
            }

            union.Columns.AddRange(newcolumns);
            union.BeginLoadData();
            //union.Rows.Add(detailTable.Rows);

            //Object to translate system columns

            object[] systemTranslatedColumns = new object[detailTable.Columns.Count];

            object[] systemColumns = new object[repeatedColumns.Count];
            foreach (DataRow row in detailTable.Rows)
            {

                for (int i = 0; i < detailTable.Columns.Count; i++)
                {
                    if (!string.IsNullOrEmpty(totalsTable.Columns[i].ColumnName))
                    {
                        if (!string.IsNullOrEmpty(translatedColumns[detailTable.Columns[i].ColumnName]))
                        {
                            systemColumns[i] = getSystemTranslatedColumns(translatedColumns[detailTable.Columns[i].ColumnName], row[i].ToString());
                        }
                        else
                        {
                            detailTable.Columns.RemoveAt(i);
                            totalsTable.Columns.RemoveAt(i);
                            i--;
                        }
                    }

                }
                union.LoadDataRow(systemColumns, true);
            }

            foreach (DataRow row in totalsTable.Rows)
            {
                union.LoadDataRow(row.ItemArray, true);
            }
            union.EndLoadData();

            //table.Rows.Add(totalTable.Rows);
            //table.Merge(totalTable);
            return union;
        }

        protected override DataTable executeReader(NameValueCollection parameters, bool addPaging, bool isDetail, DynamicQuery dynamicQuery, short process)
        {
            if (dynamicQuery.IsTotals && dynamicQuery.TotalColumns.Length == 0 && !dynamicQuery.IsPivotReport) return null;
            statementBuilder(parameters, true, addPaging, false, isDetail, dynamicQuery, process, "crmx_Date");
            return crmDb.executeDynamicQuery(dynamicQuery.Stmt, dynamicQuery.Parameters, dynamicQuery.Values);
        }

        protected override System.Xml.XmlElement innerPaginate(System.Xml.XmlDocument xml, MiddleWareReports.DynamicQuery dynamicQuery)
        {
            StringBuilder query = DynamicTsqlBuilder.paginate(dynamicQuery);
            DataTable table = crmDb.executeDynamicQuery(query, lastParameters, lastValues);
            int totalPages = 1;

            foreach (DataRow row in table.Rows)
            {
                foreach (DataColumn column in table.Columns)
                {
                    if (PAGE_SIZE > 0)
                    {
                        if (int.TryParse(row[column].ToString(), out totalPages))
                        {
                            if (PAGE_SIZE <= totalPages && totalPages > 0)
                            {
                                double temp = (double)totalPages / (double)PAGE_SIZE;
                                temp = Math.Ceiling(temp);
                                totalPages = (int)temp;
                            }
                            else
                            {
                                totalPages = 1;
                            }
                        }
                    }
                }
            }

            XmlElement data = xml.CreateElement("", "Page", "");
            data.SetAttribute("pagesize", PAGE_SIZE.ToString());
            data.SetAttribute("currentpage", currentPageNumber.ToString());
            data.SetAttribute("totalpages", totalPages.ToString());

            return data;
        }
    }
}
