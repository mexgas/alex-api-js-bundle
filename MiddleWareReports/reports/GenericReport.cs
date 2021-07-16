using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Data;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that implements the basic methods from the NuxibaReport interface
    /// and that serves as base for the reports contained in the appliaction.
    /// </summary>
    public class GenericReport : NuxibaReport
    {
        protected string reportName;
        protected NameValueCollection translatedColumns;
        private readonly Dictionary<string, string> translatedSpecialColumns = new Dictionary<string, string>();
        protected NameValueCollection convertedColumns;
        private CultureInfo currentCulture;
        protected const int PAGE_SIZE = 50;
        protected int currentPageNumber = 1;
        protected StringBuilder lastParameters = new StringBuilder();
        protected NameValueCollection lastValues = new NameValueCollection();
        protected string dbColumn = "";
        protected DataBase db;

        /// <summary>
        /// Current culture for the report
        /// </summary>
        public CultureInfo CurrentCulture
        {
            set { currentCulture = value; }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public GenericReport()
        {
            this.reportName = this.GetType().Name;
            this.translatedColumns = new NameValueCollection();
            this.convertedColumns = new NameValueCollection();
            this.db = new DataBase();
        }

        /// <summary>
        /// Name of the report
        /// </summary>
        public string ReportName
        {
            get { return reportName; }
            set { reportName = value; }
        }

        /// <summary>
        /// Changes the current culture of the report
        /// </summary>
        public void ChangeCulture()
        {
            if (currentCulture != null)
            {
                Thread.CurrentThread.CurrentCulture = currentCulture;
                Thread.CurrentThread.CurrentUICulture = currentCulture;
            }
            else
            {
                Thread.CurrentThread.CurrentCulture = new CultureInfo("es-MX");
                Thread.CurrentThread.CurrentUICulture = new CultureInfo("es-MX");
            }
        }

        protected virtual DataTable GetDefaultFilters(int type, DataTable catalog)
        {
            return catalog;
        }

        /// <summary>
        /// Gets the report data as a XML document
        /// </summary>
        /// <param name="parameters">Parameters used in the query as a match criteria for the report</param>
        /// <param name="process">Id of the report</param>
        /// <remarks>Parameter names must be named excatly after the columns in the table</remarks>
        /// <returns>The data of the report as a XML</returns>
        public virtual XmlDocument GetXmlReport(NameValueCollection parameters, short process, string addFilters, int sourceUserId, string savetemplate, string totals)
        {
            ChangeCulture();

            DateTime dateEndParam = DateTime.Now;
            DateTime dateNow = DateTime.Now;
            if (parameters["dateEnd"] != null && parameters["dateEnd"].Length > 0)
            {
                dateEndParam = DateTime.Parse(parameters["dateEnd"].ToString(), CultureInfo.CurrentCulture);
            }

            string isDay = "0";
            if (dateEndParam.Year == dateNow.Year && dateEndParam.Month == dateNow.Month && dateEndParam.Day == dateNow.Day)
            {
                isDay = "1";
            }

            NameValueCollection parametersToSave = new NameValueCollection(parameters);
            NameValueCollection parametersTotals = new NameValueCollection(parameters);
            NameValueCollection parametersAddFilter = new NameValueCollection();
            XmlDocument xmlAddFilters = new XmlDocument();
            bool calculateTotals = true;

            //Add Filrters used by report selected (Note: Fill DBSchema)
            if (addFilters.Length > 0)
            {
                //Create XML including filters used by report
                xmlAddFilters = getReportFilters(parametersAddFilter, process);
            }

            //Get report data (details and totals) via a DB query
            DynamicQuery dynamicQuery = new DynamicQuery(process);
            DataTable detailTable = executeReader(parameters, true, false, dynamicQuery, process);
            DataTable totalsTable = null;

            if (calculateTotals)
            {
                bool isTimePeriod = false;
                TimePeriod t = TimePeriod.H;
                switch (process)
                {
                    case 7150:
                        parametersTotals["timePeriod"] = "M";
                        break;

                    case 7130:
                        parametersTotals["timePeriod"] = "D";
                        break;

                    default:
                        break;
                }
                if (parametersTotals["timePeriod"] != null && parametersTotals["timePeriod"].Length > 0)
                {
                    isTimePeriod = TimePeriodGroup.isTimePeriod(parametersTotals["timePeriod"]);
                    if (isTimePeriod)
                    {
                        string timePeriod = parametersTotals["timePeriod"];
                        t = (TimePeriod)Enum.Parse(typeof(TimePeriod), timePeriod, true);
                    }
                }
                dynamicQuery.TotalColumns = GetTotalColumns(dynamicQuery, detailTable, isTimePeriod, t, parametersTotals);
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
            name.SetAttribute("isDay", isDay);
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

                foreach (XmlNode node in xmlAddFilters.DocumentElement.ChildNodes)
                {
                    XmlNode imported = xmlReport.ImportNode(node, true);
                    catalogs.AppendChild(imported);
                }

                report.AppendChild(catalogs);
            }

            //Save recent report in DB after xmlReport build
            if (savetemplate.Length > 0)
            {
                saveTemplate(sourceUserId, process, parametersToSave, savetemplate);
            }

            return xmlReport;
        }

        /// <summary>
        /// Gets the report data as a XML document
        /// </summary>
        /// <param name="parameters">Parameters used in the query as a match criteria for the report</param>
        /// <param name="process">Id of the report</param>
        /// <remarks>Parameter names must be named excatly after the columns in the table</remarks>
        /// <returns>The data of the report as a XML</returns>
        public XmlDocument getXmlDetailReport(NameValueCollection parameters, short process)
        {
            ChangeCulture();

            //Get report data (details and totals) via a DB query
            DynamicQuery dynamicQuery = new DynamicQuery(process);
            DataTable detailTable = executeReader(parameters, false, true, dynamicQuery, process);

            //Generate XML
            XmlDocument xmlReport = new XmlDocument();
            xmlReport.AppendChild(xmlReport.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            EmptyResultException.dataTableIsEmpty(detailTable);
            translatedColumns = TranslatorHelper.translateColumns(detailTable.Columns, process, true);
            convertedColumns = TranslatorHelper.convertColumns(detailTable.Columns);
            XmlElement report = xmlReport.CreateElement("", "Report", "");
            xmlReport.AppendChild(report);
            XmlElement name = xmlReport.CreateElement("", "ReportName", "");
            name.SetAttribute("name", this.reportName);
            name.SetAttribute("isDay", "0");
            name.InnerText = this.reportName;
            report.AppendChild(name);
            report.AppendChild(getXmlRows(xmlReport, detailTable, "Rows"));

            return xmlReport;
        }

        /// <summary>
        /// Gets the results of executing a query with the given parameters in the report´s db table
        /// </summary>
        /// <param name="parameters">Parameters used for the query</param>
        /// <param name="process">Id of the report to be searched</param>
        /// <remarks>Parameter names must be named excatly after the columns in the table</remarks>
        /// <returns>A DataTable with the data satisfying the query parameters</returns>
        public virtual DataTable getDataReport(NameValueCollection parameters, short process)
        {
            ChangeCulture();
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
            dynamicQuery.TotalColumns = GetTotalColumns(dynamicQuery, detailTable, isTimePeriod, t, parametersTotals);
            DataTable totalsTable = executeReader(parametersTotals, false, false, dynamicQuery, process);
            totalsTable = getGrandTotalTable(detailTable, totalsTable);

            DataTable detailTableConvert = GetConvertColumnTime(detailTable);
            DataTable totalsTableConvert = GetConvertColumnTime(totalsTable);

            DataTable union = new DataTable();
            DataColumn[] newcolumns = new DataColumn[detailTableConvert.Columns.Count];

            for (int i = 0; i < totalsTableConvert.Columns.Count; i++)
            {
                newcolumns[i] = new DataColumn(
                totalsTableConvert.Columns[i].ColumnName, totalsTableConvert.Columns[i].DataType);
            }

            union.Columns.AddRange(newcolumns);
            union.BeginLoadData();

            //Object to translate system columns
            object[] systemTranslatedColumns = new object[detailTableConvert.Columns.Count];

            foreach (DataRow row in detailTableConvert.Rows)
            {
                for (int i = 0; i < detailTableConvert.Columns.Count; i++)
                {
                    systemTranslatedColumns[i] = getSystemTranslatedColumns(detailTable.Columns[i].ColumnName.ToString(), row[i].ToString());
                }
                union.LoadDataRow(systemTranslatedColumns, true);
            }

            systemTranslatedColumns = null;

            foreach (DataRow row in totalsTableConvert.Rows)
            {
                union.LoadDataRow(row.ItemArray, true);
            }

            union.EndLoadData();
            return union;
        }

        private DataTable GetConvertColumnTime(DataTable detailTable)
        {
            DataTable detailTableConvert = detailTable.Clone();
            convertedColumns = TranslatorHelper.convertColumns(detailTable.Columns);

            foreach (DataColumn column in detailTableConvert.Columns)
            {
                if (convertedColumns[column.ColumnName] != null || column.ColumnName.EndsWith("_Time")) //Only return translated columns
                {
                    detailTableConvert.Columns[column.ColumnName].DataType = typeof(string);
                }
            }
            foreach (DataRow dataRow in detailTable.Rows) //Add rows to the XML
            {
                DataRow dataRowNew = detailTableConvert.NewRow();
                foreach (DataColumn column in detailTable.Columns)
                {
                    if (convertedColumns[column.ColumnName] != null || column.ColumnName.EndsWith("_Time")) //Only return translated columns
                    {
                        string value = TranslatorHelper.parseDbValue(dataRow[column.ColumnName]);
                        if (
                            (convertedColumns[column.ColumnName] != null || column.ColumnName.EndsWith("_Time"))
                            && value != "")
                        {
                            if (dataRow[column.ColumnName] is DateTime)
                            {
                                value = TranslatorHelper.formatTime((DateTime)dataRow[column.ColumnName]);
                            }
                            else
                            {
                                value = TranslatorHelper.formatTime(Convert.ToInt64(value));
                            }
                        }

                        dataRowNew[column.ColumnName] = value;
                    }
                    else
                    {
                        dataRowNew[column.ColumnName] = dataRow[column.ColumnName];
                    }
                }
                detailTableConvert.Rows.Add(dataRowNew);
            }
            return detailTableConvert;
        }

        /// <summary>
        /// Obtains report´s filters used for search queries
        /// </summary>
        /// <param name="parameters">Parameters used in the query</param>
        /// <param name="process">Id of the report to be searched</param>
        /// <returns>A xml list containing the filters and the values that can be used in the report´s search queries</returns>
        public XmlDocument getReportFilters(NameValueCollection parameters, short process)
        {
            string complementColumns = "";
            ChangeCulture();

            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            XmlElement catalogs = xml.CreateElement("", "Catalogs", "");
            xml.AppendChild(catalogs);

            XmlElement pivots = getPivotColumns(xml, parameters, process, out complementColumns);
            XmlElement filters = getFilters(xml, parameters, process, complementColumns);
            XmlElement menus = getFiltersMenus(xml, parameters, process);
            XmlElement ranges = getRanges(xml, parameters, process);
            XmlElement texts = getTexts(xml, parameters, process);
            XmlElement groupby = getGroupByColumns(xml, parameters, process);
            XmlElement detailReports = getDetailReports(xml, process);
            XmlElement translates = getTranslatedColumns(xml, process);

            xml.ChildNodes.Item(1).AppendChild(detailReports);
            xml.ChildNodes.Item(1).AppendChild(filters);
            xml.ChildNodes.Item(1).AppendChild(menus);
            xml.ChildNodes.Item(1).AppendChild(ranges);
            xml.ChildNodes.Item(1).AppendChild(texts);
            xml.ChildNodes.Item(1).AppendChild(pivots);
            xml.ChildNodes.Item(1).AppendChild(groupby);
            xml.ChildNodes.Item(1).AppendChild(translates);

            return xml;
        }

        /// <summary>
        /// Obtains report´s filters used for search queries
        /// </summary>
        /// <param name="parameters">Parameters used in the query</param>
        /// <param name="process">Id of the report to be searched</param>
        /// <returns>A xml list containing the filters and the values that can be used in the report´s search queries</returns>

        public XmlDocument getCRMReportFilters(NameValueCollection parameters, short process, bool getMenus)
        {
            ChangeCulture();

            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            XmlElement catalogs = xml.CreateElement("", "Catalogs", "");
            xml.AppendChild(catalogs);

            XmlElement filters = getCRMFields(xml, parameters, process);
            xml.ChildNodes.Item(1).AppendChild(filters);

            if (getMenus)
            {
                XmlElement menus = getFiltersMenus(xml, parameters, process);
                xml.ChildNodes.Item(1).AppendChild(menus);
            }
            else
            {
                XmlElement filtersMenus = xml.CreateElement("", "FiltersMenus", "");
                XmlElement element = xml.CreateElement("", "FilterMenu", "");
                element.SetAttribute("description", "crmfilters");
                element.SetAttribute("id", "8");
                filtersMenus.AppendChild(element);
                xml.ChildNodes.Item(1).AppendChild(filtersMenus);
            }
            return xml;
        }

        /// <summary>
        /// Obtains fields reportables by the crm template
        /// </summary>
        /// <param name="parameters">Parameters used in the query</param>
        /// <returns>A xml list containing the fields that can be used in the crm´s search queries</returns>
        public XmlDocument getCRMFields(NameValueCollection parameters, short process)
        {
            ChangeCulture();

            XmlDocument xml = new XmlDocument();

            XmlElement CRMTemplates = getCRMFields(xml, parameters, process);

            DataTable schemaTable = new DataTable();
            schemaTable = getTableColumns();
            DBSchema.clearDBSchema();
            foreach (DataColumn column in schemaTable.Columns)
            {
                //Column DB Type for schema
                DBSchema.setDataType(column.ColumnName, TypeInspector.ConvertToDbType(column.DataType));
            }
            if (CRMTemplates.HasChildNodes)
            {
                xml.AppendChild(CRMTemplates);
            }

            return xml;
        }

        /// <summary>
        /// Gets the rows
        /// </summary>
        /// <param name="xmlReport">The XML document</param>
        /// <param name="table">Table containing rows</param>
        /// <param name="nodeName">Then name of the XML node</param>
        /// <returns>The data rows of the report as a XML element</returns>
        protected virtual XmlElement getXmlRows(XmlDocument xmlReport, DataTable table, string nodeName)
        {
            XmlElement rows = xmlReport.CreateElement("", nodeName, "");

            foreach (DataRow dataRow in table.Rows) //Add rows to the XML
            {
                XmlElement row = xmlReport.CreateElement("", "Row", "");
                foreach (DataColumn column in table.Columns)
                {
                    if (translatedColumns[column.ColumnName] != null) //Only return translated columns
                    {
                        string value = TranslatorHelper.parseDbValue(dataRow[column.ColumnName]);
                        if (convertedColumns[column.ColumnName] != null && value != "")
                        {
                            if (dataRow[column.ColumnName] is DateTime)
                            {
                                value = TranslatorHelper.formatTime((DateTime)dataRow[column.ColumnName]);
                            }
                            else
                            {
                                value = TranslatorHelper.formatTime(Convert.ToInt64(value));
                            }
                        }
                        XmlElement el = xmlReport.CreateElement("", "Cell", "");

                        el.SetAttribute("value", getSystemTranslatedColumns(column.ColumnName, value));
                        el.SetAttribute("name", getPivotTranslatedColumns(translatedColumns[column.ColumnName]));

                        row.AppendChild(el);

                        value = translatedColumns[column.ColumnName];
                    }
                }
                rows.AppendChild(row);
            }

            return rows;
        }

        /// <summary>
        /// Gets the translation of value in case necessary
        /// </summary>
        /// <param name="column">The column to evaluate</param>
        /// <param name="value">The value to translate</param>
        /// <returns>The value translated in case necessary or the original one</returns>
        protected string getSystemTranslatedColumns(string column, string value)
        {
            bool isTranslated;
            string valueTranslated;
            ///SOlo cuando se utiliza pivote no agrupado esta solo para la opcion Count homologar nuevo _SubFijo
            if (translatedSpecialColumns.ContainsKey(column) || column.EndsWith("_Count") || column.EndsWith("_UnCount"))
            {
                if (value.Contains("systemTranslated_"))
                {
                    valueTranslated = TranslatorHelper.getResourceProperty(value, out isTranslated, false);
                    if (isTranslated)
                    {
                        value = valueTranslated;
                    }
                }
            }

            return value;
        }

        /// <summary>
        /// Gets the translation of column in case pivot
        /// </summary>
        /// <param name="column">The column name to evaluate</param>
        /// <returns>The value translated in case necessary or the original one</returns>
        protected string getPivotTranslatedColumns(string columnName)
        {
            bool isTranslated;
            string partNotToTranslate;
            string partToTranslate;
            string partTraslated;

            if (columnName.EndsWith("_Count") || columnName.EndsWith("_Time") || columnName.EndsWith("_Avg") || columnName.EndsWith("_UnCount"))
            {
                partNotToTranslate = columnName.Substring(0, columnName.LastIndexOf("_"));
                partToTranslate = columnName.Substring(columnName.LastIndexOf("_"));

                partTraslated = TranslatorHelper.getResourceProperty(partToTranslate, out isTranslated, false);
                if (isTranslated)
                {
                    columnName = partNotToTranslate + partTraslated.Replace('_', ' ');
                }
            }

            return columnName;
        }

        /// <summary>
        /// Gets the list columns for detail reports when clicking on the selected column
        /// </summary>
        /// <param name="xml">The XML document</param>
        /// <param name="process">Return num process de reports</param>
        /// <returns>The data rows of the detail report as a XML element</returns>
        protected XmlElement getXmlDetailReports(XmlDocument xml, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            reportParams.Add("action", "0");
            DataTable columnsDetail = db.executeSP("dbo.ccspGetDetailReports", reportParams);
            XmlElement detailReportsXml = xml.CreateElement("", "DetailReports", "");
            String reportName = MiddleWareReports.ReportFactory.getReportName(process).reportName;
            string[] columns;
            foreach (DataRow detailRow in columnsDetail.Rows)
            {
                string column = detailRow["columns"].ToString();
                string pivotColumns = detailRow["pivotColumns"].ToString();
                if (!string.IsNullOrEmpty(column))
                {
                    columns = column.Split('|');
                    foreach (string col in columns)
                    {
                        XmlElement element = xml.CreateElement("", "DetailReport", "");
                        element.SetAttribute("id", col);
                        element.SetAttribute("name", TranslatorHelper.getResource(col, true));
                        detailReportsXml.AppendChild(element);
                    }
                }

                if (!string.IsNullOrEmpty(pivotColumns))
                {
                    columns = pivotColumns.Split('|');
                    foreach (string col in columns)
                    {
                        string[] colId = col.Split(':');
                        StringBuilder query = new StringBuilder();
                        query.Append("select distinct(" + colId[0] + ") as [colPivot], " + colId[1] + " as [id] from " + reportName);
                        DataTable columnsPivot = db.executeDynamicQuery(query);
                        foreach (DataRow details in columnsPivot.Rows)
                        {
                            XmlElement element = xml.CreateElement("", "DetailReport", "");
                            element.SetAttribute("id", colId[1] + "|" + details["id"].ToString());
                            element.SetAttribute("name", getPivotTranslatedColumns(TranslatorHelper.getResource(details["colPivot"].ToString(), true)));
                            detailReportsXml.AppendChild(element);
                        }
                    }
                }
            }
            return detailReportsXml;
        }

        /// <summary>
        /// Gets the list columns to create the filter to detail report
        /// </summary>
        /// <param name="xml">The XML document</param>
        /// <param name="process">Return num process de reports</param>
        /// <returns>The data rows of the detail report as a XML element</returns>
        private XmlElement getDetailReports(XmlDocument xml, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            reportParams.Add("action", "1");
            DataTable columnsDetail = db.executeSP("dbo.ccspGetDetailReports", reportParams);
            XmlElement detailReportsXml = xml.CreateElement("", "DetailReports", "");
            foreach (DataRow detailRow in columnsDetail.Rows)
            {
                string dbColumnFilter = detailRow["dbColumnFilter"].ToString();
                string showColumnsDetail = detailRow["showColumnsDetail"].ToString();
                if (!string.IsNullOrEmpty(dbColumnFilter) && !string.IsNullOrEmpty(showColumnsDetail))
                {
                    XmlElement element = xml.CreateElement("", "DetailReport", "");
                    element.SetAttribute("dbColumn", dbColumnFilter);
                    element.SetAttribute("showColumnsDetail", showColumnsDetail);
                    detailReportsXml.AppendChild(element);
                }
            }
            return detailReportsXml;
        }

        /// <summary>
        /// Gets the columns list to be filled and translated
        /// </summary>
        /// <param name="xml">The XML document</param>
        /// <param name="process">The report number</param>
        /// <returns>The data rows of the columns to be filled and translated as a XML element</returns>
        private XmlElement getTranslatedColumns(XmlDocument xml, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            DataTable columnsTranslate = db.executeSP("dbo.ccspGetTranslatedReports", reportParams);
            XmlElement translatedReportsXml = xml.CreateElement("", "TranslatedSpecialColumns", "");
            foreach (DataRow translatedRow in columnsTranslate.Rows)
            {
                string columnsTranslated = translatedRow["columns"].ToString();
                if (!string.IsNullOrEmpty(columnsTranslated))
                {
                    XmlElement element = xml.CreateElement("", "TranslatedSpecialColumn", "");
                    element.SetAttribute("specialColumns", columnsTranslated);
                    translatedReportsXml.AppendChild(element);
                }
            }
            return translatedReportsXml;
        }

        /// <summary>
        /// Obtains the report´s pivot columns in case they exit
        /// </summary>
        /// <param name="xml"></param>
        /// <param name="parameters"></param>
        /// <param name="process"></param>
        /// <returns></returns>
        private XmlElement getGroupByColumns(XmlDocument xml, NameValueCollection parameters, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            DataTable pivotColumnsT = db.executeSP("dbo.ccspGetGroupByColumns", reportParams);
            XmlElement groupByColumnsXml = xml.CreateElement("", "GroupByColumns", "");

            foreach (DataRow pivotRow in pivotColumnsT.Rows)
            {
                string columns = pivotRow["columns"].ToString();
                string groupByColumns = pivotRow["groupByColumns"].ToString();
                XmlElement element = xml.CreateElement("", "GroupByColumn", "");
                element.SetAttribute("columns", columns);
                element.SetAttribute("groupByColumns", groupByColumns);
                groupByColumnsXml.AppendChild(element);
            }

            return groupByColumnsXml;
        }

        /// <summary>
        /// Obtains the report´s pivot columns in case they exit
        /// </summary>
        /// <param name="xml"></param>
        /// <param name="parameters"></param>
        /// <param name="process"></param>
        /// <returns></returns>
        private XmlElement getPivotColumns(XmlDocument xml, NameValueCollection parameters, short process, out string complementColumns)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            DataTable pivotColumnsT = db.executeSP("dbo.GetPivotColumns", reportParams);
            XmlElement pivotColumns = xml.CreateElement("", "PivotColumns", "");
            complementColumns = "";
            foreach (DataRow pivotRow in pivotColumnsT.Rows)
            {
                string columns = pivotRow["columns"].ToString();
                complementColumns = pivotRow["complementColumns"].ToString();
                string pivotFunction = pivotRow["pivotFunction"].ToString();
                string isGroupPivot = pivotRow["isGroupPivot"].ToString();
                XmlElement element = xml.CreateElement("", "PivotColumn", "");
                element.SetAttribute("columns", columns);
                element.SetAttribute("complementColumns", complementColumns);
                element.SetAttribute("pivotFunction", pivotFunction);
                element.SetAttribute("isGroupPivot", isGroupPivot);
                pivotColumns.AppendChild(element);
            }
            complementColumns = complementColumns.Trim();
            return pivotColumns;
        }

        /// <summary>
        /// Obtains the report´s filter menus used to display the search options of the report
        /// </summary>
        /// <param name="xml">Xml to which the node will be appended</param>
        /// <param name="parameters">Parameters used in the SP</param>
        /// <param name="process">Report id</param>
        /// <returns>A xml list of the filter menus that the report can use</returns>
        protected virtual XmlElement getFiltersMenus(XmlDocument xml, NameValueCollection parameters, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            DataTable filtersMenusT = db.executeSP("dbo.GetReportFiltersMenus", reportParams);
            XmlElement filtersMenus = xml.CreateElement("", "FiltersMenus", "");

            foreach (DataRow filterRow in filtersMenusT.Rows)
            {
                string name = filterRow["name"].ToString();
                string id = filterRow["id"].ToString();
                string showFilter = filterRow["showFilter"].ToString();
                string defaultValue = filterRow["defaultValue"].ToString();
                XmlElement element = xml.CreateElement("", "FilterMenu", "");
                element.SetAttribute("description", name);
                element.SetAttribute("id", id);
                element.SetAttribute("showFilter", showFilter);
                element.SetAttribute("defaultValue", defaultValue);
                filtersMenus.AppendChild(element);
            }

            return filtersMenus;
        }

        /// <summary>
        /// Obtains the report´s CRM Templates menus used to display the search options of the report
        /// </summary>
        /// <param name="xml">Xml to which the node will be appended</param>
        /// <param name="parameters">Parameters used in the SP</param>
        /// <param name="process">Report id</param>
        /// <returns>A xml list of the CRM Templates that the report can use</returns>
        protected virtual XmlElement getCRMFields(XmlDocument xml, NameValueCollection parameters, short process)
        {
            throw new NotImplementedException();
            //Look up for the RepCRMXTemplates class
        }

        protected virtual XmlElement getFiltersByCRMTemplate(XmlDocument xml, string templateId)
        {
            throw new NotImplementedException();
            //Look up for the RepCRMxTemplates class
        }

        /// <summary>
        /// Gets the filters of the reports
        /// </summary>
        /// <param name="parameters">Parameters used in the query</param>
        /// <returns>A xml containing the filters applyable to the report</returns>
        private XmlElement getFilters(XmlDocument xml, NameValueCollection parameters, short process, string complementColumns)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            DataTable filters = db.executeSP("dbo.GetReportFilters", reportParams);

            if (parameters["type"] == null)
            {
                parameters.Add("type", "");
            }
            if (parameters["action"] == null)
            {
                parameters.Add("action", "");
            }
            parameters["action"] = "0";
            XmlElement filtersRoot = xml.CreateElement("", "Filters", "");
            foreach (DataRow filterRow in filters.Rows)
            {
                parameters["type"] = filterRow["type"].ToString();
                string xmlParentName = filterRow["xmlParentNode"].ToString();
                string xmlChildName = filterRow["xmlChildNode"].ToString();
                XmlElement element = xml.CreateElement("", xmlParentName, "");
                element.SetAttribute("description", TranslatorHelper.getResource(xmlParentName));
                DataTable catalog = db.executeSP("dbo.ccspRepCatalogos", parameters);
                catalog = GetDefaultFilters(int.Parse(filterRow["type"].ToString()), catalog);
                foreach (DataRow filterDataRow in catalog.Rows)
                {
                    XmlElement childElement = xml.CreateElement("", xmlChildName, "");
                    string descriptionFilter = filterDataRow["description"].ToString();
                    if (descriptionFilter.StartsWith("systemTranslated_"))
                    {
                        descriptionFilter = TranslatorHelper.getResource(descriptionFilter);
                    }
                    childElement.SetAttribute("description", descriptionFilter);
                    childElement.SetAttribute("id", filterDataRow["id"].ToString());
                    dbColumn = filterDataRow["dbColumn"].ToString();
                    element.AppendChild(childElement);
                }
                element.SetAttribute("dbColumn", dbColumn);
                if (catalog.Rows.Count > 0)
                {
                    filtersRoot.AppendChild(element);
                }
            }

            //Add table columns
            XmlElement columns = getColumns(xml, complementColumns);
            if (!(columns.IsEmpty))
            {
                filtersRoot.AppendChild(columns);
            }
            return filtersRoot;
        }

        /// <summary>
        /// Gets the filters text of the reports
        /// </summary>
        /// <param name="parameters">Parameters used in the query</param>
        /// <returns>A xml containing the filters applyable to the report</returns>
        private XmlElement getTexts(XmlDocument xml, NameValueCollection parameters, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            reportParams.Add("action ", "2");
            DataTable filters = db.executeSP("dbo.GetReportFilters", reportParams);

            XmlElement TextsRoot = xml.CreateElement("", "Texts", "");
            foreach (DataRow filterRow in filters.Rows)
            {
                string description;
                description = TranslatorHelper.getResource(filterRow["dbColumn"].ToString(), true);
                XmlElement element = xml.CreateElement("", "Text", "");
                element.SetAttribute("dbColumn", filterRow["dbColumn"].ToString());
                element.SetAttribute("restrictExp", filterRow["restrictExp"].ToString());
                element.SetAttribute("description", description);
                TextsRoot.AppendChild(element);
            }
            return TextsRoot;
        }

        /// <summary>
        /// Gets the filters range of the reports
        /// </summary>
        /// <param name="parameters">Parameters used in the query</param>
        /// <returns>A xml containing the filters applyable to the report</returns>
        private XmlElement getRanges(XmlDocument xml, NameValueCollection parameters, short process)
        {
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            reportParams.Add("action ", "1");
            DataTable filters = db.executeSP("dbo.GetReportFilters", reportParams);

            if (parameters["type"] == null)
            {
                parameters.Add("type", "");
            }
            if (parameters["action"] == null)
            {
                parameters.Add("action", "");
            }
            parameters["action"] = "1";
            XmlElement RangesRoot = xml.CreateElement("", "Ranges", "");
            foreach (DataRow filterRow in filters.Rows)
            {
                parameters["type"] = filterRow["type"].ToString();
                DataTable catalog = db.executeSP("dbo.ccspRepCatalogos", parameters);
                string description;
                foreach (DataRow filterDataRow in catalog.Rows)
                {
                    description = TranslatorHelper.getResource(filterDataRow["dbColumn"].ToString(), true);
                    XmlElement element = xml.CreateElement("", "Range", "");
                    element.SetAttribute("min", filterDataRow["min"].ToString());
                    element.SetAttribute("max", filterDataRow["max"].ToString());
                    element.SetAttribute("dbColumn", filterDataRow["dbColumn"].ToString());
                    element.SetAttribute("description", description);
                    RangesRoot.AppendChild(element);
                }
            }
            return RangesRoot;
        }

        /// <summary>
        /// Creates a new instance of the class
        /// </summary>
        /// <param name="reportName">Name of the report to be used</param>
        /// <returns>A new instance of the class</returns>
        public static GenericReport createReport(string reportName)
        {
            return (MiddleWareReports.GenericReport)Activator.CreateInstance(null, reportName, new object[] { }).Unwrap();
        }

        /// <summary>
        /// Gets a Xml chart from the report
        /// </summary>
        /// <param name="paramValueList">Parameters used in the query</param>
        /// <param name="process">Id of the report</param>
        /// <returns>A chart Xml from the report</returns>
        public XmlDocument getChart(NameValueCollection paramValueList, short process)
        {
            ChangeCulture();

            if (paramValueList["columns"] != null && paramValueList["columns"].Length > 0)
            {
                int columnCount = 0;
                string paramColumns = paramValueList["columns"].ToString();
                int charType = Int32.Parse(paramColumns.Substring(0, paramColumns.IndexOf('|')));
                paramColumns = paramColumns.Substring(paramColumns.IndexOf('|') + 1);
                paramValueList["columns"] = paramColumns;
                string[] cols = paramColumns.Split('|');
                columnCount = cols.Length;

                string havingOp = "";
                int havingVal = -1;

                //string timePeriodVal = "";
                //Group by time period
                if (paramValueList["timePeriod"] != null && paramValueList["timePeriod"].Length > 0)
                {
                    //    timePeriodVal = paramValueList["timePeriod"];
                    paramValueList.Remove("timePeriod");
                }

                if (paramValueList["havingOp"] != null && paramValueList["havingOp"].Length > 0)
                {
                    havingOp = paramValueList["havingOp"];
                    paramValueList.Remove("havingOp");
                }

                if (paramValueList["havingVal"] != null && paramValueList["havingVal"].Length > 0)
                {
                    int.TryParse(paramValueList["havingVal"], out havingVal);
                    paramValueList.Remove("havingVal");
                }

                StringBuilder havingStatement = new StringBuilder();
                if (havingOp.Length > 0 && havingVal >= 0)
                {
                    havingStatement = DynamicTsqlBuilder.Having(havingOp, havingVal);
                }

                if (columnCount <= 0)
                {
                    throw new Exception("Missing group by statement = Not enough columns were given to make a chart, give at least 1");
                }

                string xAxis = cols[0];

                LinkedList<string> columns = new LinkedList<string>();
                foreach (string c in cols)
                {
                    columns.AddLast(c);
                }

                DynamicQuery dynamicQuery = new DynamicQuery(process);

                statementBuilder(paramValueList, false, false, true, false, dynamicQuery, process, "date");

                StringBuilder query = dynamicQuery.Stmt;

                query.Append((DynamicTsqlBuilder.GroupByStatement(columns)));
                query.Append(havingStatement);
                query.Append(DynamicTsqlBuilder.OrderByDescStatement(columns));

                switch (process)
                {
                    case 8061:
                        if (query.ToString().Contains("[avgDisposition]"))
                        {
                            query.Remove(0, query.Length);
                            query.Append("SELECT * FROM ( SELECT * FROM (  SELECT  [agentName], AVG([avgDisposition]) as avgDisposition,  AVG(Dispositions) as totalCount FROM RepAVRSAgent WITH(NOLOCK)  WHERE date >= @dateStart AND date < @dateEnd  AND ( avgDisposition BETWEEN @avgDispositionMin AND @avgDispositionMax  )  GROUP BY [agentName] ) AS H_GROUP ) AS B_GROUP ");
                        }
                        break;

                    case 8062:
                        if (query.ToString().Contains("[avgDisposition]"))
                        {
                            query.Remove(0, query.Length);
                            query.Append("SELECT * FROM ( SELECT * FROM (  SELECT  [Supervisor], AVG([avgDisposition]) as avgDisposition,  AVG(Dispositions) as totalCount FROM RepAVRSSupervisor WITH(NOLOCK)  WHERE date >= @dateStart AND date < @dateEnd  AND ( avgDisposition BETWEEN @avgDispositionMin AND @avgDispositionMax  )  GROUP BY [Supervisor] ) AS H_GROUP ) AS B_GROUP ");
                        }
                        break;

                    case 8063:
                        if (query.ToString().Contains("[avgDisposition]"))
                        {
                            query.Remove(0, query.Length);
                            query.Append("SELECT * FROM ( SELECT * FROM (  SELECT  [Section], AVG([avgDisposition]) as avgDisposition,  AVG(Dispositions) as totalCount FROM RepAVRSSection WITH(NOLOCK)  WHERE date >= @dateStart AND date < @dateEnd  AND ( avgDisposition BETWEEN @avgDispositionMin AND @avgDispositionMax  )  GROUP BY [Section] ) AS H_GROUP ) AS B_GROUP");
                        }
                        break;

                    case 8064:
                        if (query.ToString().Contains("[avgDisposition]"))
                        {
                            query.Remove(0, query.Length);
                            query.Append("SELECT * FROM ( SELECT * FROM (  SELECT  [question], AVG([avgDisposition]) as avgDisposition,  AVG(Dispositions) as totalCount FROM RepAVRSQuestion WITH(NOLOCK)  WHERE date >= @dateStart AND date < @dateEnd  AND ( avgDisposition BETWEEN @avgDispositionMin AND @avgDispositionMax  )  GROUP BY [question] ) AS H_GROUP ) AS B_GROUP");
                        }
                        break;

                    case 8081:
                        if (query.ToString().Contains("[avgDisposition]"))
                        {
                            query.Remove(0, query.Length);
                            query.Append("SELECT * FROM ( SELECT * FROM (  SELECT  [agentName], AVG([avgDisposition]) as avgDisposition,  AVG(Dispositions) as totalCount FROM RepAVRSAgent WITH(NOLOCK)  WHERE date >= @dateStart AND date < @dateEnd  AND ( avgDisposition BETWEEN @avgDispositionMin AND @avgDispositionMax  )  GROUP BY [agentName] ) AS H_GROUP ) AS B_GROUP ");
                        }
                        break;

                    case 8082:
                        if (query.ToString().Contains("[avgDisposition]"))
                        {
                            query.Remove(0, query.Length);
                            query.Append("SELECT * FROM ( SELECT * FROM (  SELECT  [question], AVG([avgDisposition]) as avgDisposition,  AVG(Dispositions) as totalCount FROM RepAVRSQuestion WITH(NOLOCK)  WHERE date >= @dateStart AND date < @dateEnd  AND ( avgDisposition BETWEEN @avgDispositionMin AND @avgDispositionMax  )  GROUP BY [question] ) AS H_GROUP ) AS B_GROUP");
                        }
                        break;
                }

                //Execute dynamic query
                DataTable table = db.executeDynamicQuery(query, dynamicQuery.Parameters, dynamicQuery.Values);
                //Check that table is not empty
                EmptyResultException.dataTableIsEmpty(table);

                if (charType == 1 && columnCount == 1)
                {
                    return Chart.transformToOneSerieXml(table);
                }
                else
                {
                    return Chart.transformToMultipleSeriesXml(table, charType);
                }
            }
            else
            {
                throw new Exception("Missing group by statement = Not enough columns were given to make a chart, give at least 1");
            }
        }

        /// <summary>
        /// Returns the columns of the table as a XmlElement that can be appended to a XmlDocument
        /// </summary>
        /// <param name="xml">The XmlDocument from which the XmlElement will be created</param>
        /// <returns>A XmlElement containing the columns of the report´s table</returns>
        protected XmlElement getColumns(XmlDocument xml, string complementColumns)
        {
            bool isPivot = complementColumns != "";
            List<string> listColums = new List<string>(complementColumns.Split('|'));
            DataTable schemaTable = new DataTable();
            NameValueCollection parameters = new NameValueCollection();
            schemaTable = getTableColumns();
            XmlElement columns = xml.CreateElement("", "Fields", "");
            columns.SetAttribute("description", TranslatorHelper.getResource("Fields"));
            columns.SetAttribute("dbColumn", "columns");

            DBSchema.clearDBSchema();
            foreach (DataColumn column in schemaTable.Columns)
            {
                //Column DB Type for schema
                DBSchema.setDataType(column.ColumnName, TypeInspector.ConvertToDbType(column.DataType));

                if (isPivot && !listColums.Contains(column.ColumnName))
                {
                    continue;
                }

                XmlElement element = xml.CreateElement("", "Field", "");
                element.SetAttribute("id", column.ColumnName);
                string description = TranslatorHelper.getResource(column.ColumnName);
                element.SetAttribute("description", description);
                if (!description.Contains("_")) //Filter fields not viewable by the user
                {
                    columns.AppendChild(element);
                }
            }
            return columns;
        }

        /// <summary>
        /// Executes a statement that returns a set of rows
        /// </summary>
        /// <param name="parameters">Parameters to construct the query</param>
        /// <param name="addPaging">Indicates if only a range of rows must be returned</param>
        /// <param name="dynamicQuery">The created dynamic query to be used</param>
        /// <returns>A DataTable containing the rows fitting the criteria of the constructed query</returns>
        /// <remarks>Parameters must be named after the columns of the report table</remarks>
        protected virtual DataTable executeReader(NameValueCollection parameters, bool addPaging, bool isDetail, DynamicQuery dynamicQuery, short process)
        {
            if (dynamicQuery.IsTotals && dynamicQuery.TotalColumns.Length == 0 && !dynamicQuery.IsPivotReport)
            {
                return null;
            }

            statementBuilder(parameters, true, addPaging, false, isDetail, dynamicQuery, process, "date");
            return db.executeDynamicQuery(dynamicQuery.Stmt, dynamicQuery.Parameters, dynamicQuery.Values);
        }

        /// <summary>
        /// Creates the query to get the columns of the table
        /// </summary>
        /// <returns>A DataTable with zero or one rows and with all columns selected</returns>
        protected virtual DataTable getTableColumns()
        {
            StringBuilder query = new StringBuilder();
            query.Append(DynamicTsqlBuilder.GetTableColumns(reportName));
            return db.executeDynamicQuery(query);
        }

        /// <summary>
        /// Gets the columns to be used for the totals query
        /// </summary>
        /// <param name="dynamicQuery">The created dynamic query to be used</param>
        /// <param name="detailTable">The table containing the columns with the detailed information of the report</param>
        /// <returns>A text indicating the columns to be used for the totals query</returns>
        protected string GetTotalColumns(DynamicQuery dynamicQuery, DataTable detailTable, bool isTimePeriod, TimePeriod t, NameValueCollection parametersTotals)
        {
            StringBuilder query = new StringBuilder();
            query.Append(DynamicTsqlBuilder.GetTotalColumns(dynamicQuery.Process));
            DataTable table = db.executeDynamicQuery(query);
            string totalColumns = table.Rows.Count == 0 ? string.Empty : table.Rows[0][0].ToString().Trim();

            if (totalColumns.Length == 0)
            {
                return totalColumns;
            }

            if (totalColumns.Contains("_TIMEGROUP"))
            {
                if (t == TimePeriod.PE)
                {
                    DateTime dateStart = DateTime.Parse(parametersTotals["dateStart"].ToString());
                    DateTime dateEnd = DateTime.Parse(parametersTotals["dateEnd"].ToString());
                    totalColumns = totalColumns.Replace("_TIMEGROUP", "," + dateEnd.Subtract(dateStart).TotalSeconds.ToString());
                }
                else if (t == TimePeriod.D)
                {
                    totalColumns = totalColumns.Replace("_TIMEGROUP", ",86400");
                }
                else if (t == TimePeriod.H)
                {
                    totalColumns = totalColumns.Replace("_TIMEGROUP", ",3600");
                }
                else if (t == TimePeriod.HH)
                {
                    totalColumns = totalColumns.Replace("_TIMEGROUP", ",1800");
                }
                else
                {
                    totalColumns = totalColumns.Replace("_TIMEGROUP", ",900");
                }
            }

            string[] pairs = totalColumns.Split('|');
            totalColumns = "";
            foreach (string pair in pairs)
            {
                string[] columnPair = pair.Split(':');
                string function = columnPair[0];
                string column = columnPair[1];
                if (!detailTable.Columns.Contains(column))
                {
                    continue;
                }

                column = String.Format("[{0}]", column);
                if (columnPair.Length == 3)
                {
                    function = Regex.Replace(columnPair[2], @"_([^(count|avg|time)]|[\d|TIMEGROUP|\s]+)", ",$1");
                    totalColumns += String.Format("({0}) as {1},", function, column);
                }
                else
                {
                    if (function.Equals("sum"))
                    {
                        totalColumns += String.Format("isnull({0}(cast({1} as bigint)),0) as {1},", function, column);
                    }
                    else
                    {
                        totalColumns += String.Format("isnull({0}({1}),0) as {1},", function, column);
                    }
                }
            }
            table = new DataTable();
            if (totalColumns.Length > 0)
            {
                totalColumns = totalColumns.Remove(totalColumns.Length - 1, 1);
            }
            return totalColumns;
        }

        /// <summary>
        /// Used for creating the WHERE statement, and adding columns for paging or counting
        /// </summary>
        /// <param name="paramValueList">Parameters to be used in the WHERE statement</param>
        /// <param name="addRowNumber">Indicates if a row number column must be added</param>
        /// <param name="addPaging">Indicates if the resulting query is going to be paginated</param>
        /// <param name="addCountColumn">Indicates if a count column must be added</param>
        /// <param name="dynamicQuery">The created dynamic query to be used</param>
        /// <returns></returns>
        protected void statementBuilder(NameValueCollection paramValueList, bool addRowNumber, bool addPaging, bool addCountColumn, bool isDetail, DynamicQuery dynamicQuery, short process, string dateColumnName)
        {
            StringBuilder tsql = new StringBuilder();
            StringBuilder whereStatement = new StringBuilder();
            StringBuilder parameters = new StringBuilder();
            NameValueCollection values = new NameValueCollection();
            TimePeriod t = TimePeriod.H;
            DateTime dateStart, dateEnd = DateTime.Now;
            //Add time period column
            string originalTimePeriodCol = "";
            bool isTimePeriod = false;
            int timeMinutes;
            switch (process)
            {
                case 7150:
                    paramValueList["timePeriod"] = "M";
                    break;

                case 7130:
                    paramValueList["timePeriod"] = "D";
                    break;

                default:
                    break;
            }
            if (paramValueList["timePeriod"] != null && paramValueList["timePeriod"].Length > 0)
            {
                isTimePeriod = TimePeriodGroup.isTimePeriod(paramValueList["timePeriod"]);
                if (isTimePeriod)
                {
                    originalTimePeriodCol = paramValueList["timePeriod"];
                }
            }
            paramValueList.Remove("timePeriod");

            if (paramValueList["dateEnd"] != null && paramValueList["dateEnd"].Length > 0)
            {
                String dateEndString = paramValueList["dateEnd"].ToString();
                dateEnd = DateTime.Parse(dateEndString, CultureInfo.CurrentCulture);

                if (isTimePeriod)
                {
                    t = (TimePeriod)Enum.Parse(typeof(TimePeriod), originalTimePeriodCol, true);
                }

                timeMinutes = dateEnd.Minute;

                dateEnd = new DateTime(dateEnd.Year, dateEnd.Month, dateEnd.Day, dateEnd.Hour, 0, 0);
                switch (t)
                {
                    case TimePeriod.H:
                    case TimePeriod.D:
                    case TimePeriod.PE:
                        if (timeMinutes >= 1)
                        {
                            timeMinutes = 59;
                        }
                        else
                        {
                            timeMinutes = 0;
                        }

                        dateEnd = dateEnd.AddMinutes(timeMinutes);
                        break;

                    case TimePeriod.HH:
                        if (timeMinutes > 30)
                        {
                            timeMinutes = 59;
                        }
                        else if (timeMinutes >= 1)
                        {
                            timeMinutes = 29;
                        }
                        else
                        {
                            timeMinutes = 0;
                        }

                        dateEnd = dateEnd.AddMinutes(timeMinutes);
                        break;

                    case TimePeriod.QH:
                        if (timeMinutes > 45)
                        {
                            timeMinutes = 59;
                        }
                        else if (timeMinutes > 30)
                        {
                            timeMinutes = 44;
                        }
                        else if (timeMinutes > 15)
                        {
                            timeMinutes = 29;
                        }
                        else if (timeMinutes >= 1)
                        {
                            timeMinutes = 14;
                        }
                        else
                        {
                            timeMinutes = 0;
                        }

                        dateEnd = dateEnd.AddMinutes(timeMinutes);
                        break;
                }
            }

            if (paramValueList["dateStart"] != null && paramValueList["dateStart"].Length > 0
                && paramValueList["dateEnd"] != null && paramValueList["dateEnd"].Length > 0)
            {
                whereStatement.AppendLine(string.Format("\t WHERE {0} >= {1} AND {0} < {2}  ", dateColumnName, "@dateStart", "@dateEnd"));

                parameters.Append(string.Format("@dateStart " + DBSchema.getDataType("dateStart").ToString()));
                values.Add("@dateStart", paramValueList["dateStart"].ToString());

                if (!isTimePeriod)
                {
                    dateEnd = DateTime.Parse(paramValueList["dateEnd"].ToString(), CultureInfo.CurrentCulture);
                }
                parameters.Append(string.Format(", @dateEnd " + DBSchema.getDataType("dateEnd").ToString()));

                values.Add("@dateEnd", dateEnd.ToString("yyy-MM-dd HH:mm:ss"));
            }
            paramValueList.Remove("dateStart");
            paramValueList.Remove("dateEnd");

            //Add paging
            int page = 1;
            if (addPaging && paramValueList["page"] != null && paramValueList["page"].Length > 0)
            {
                int.TryParse(paramValueList["page"], out page);
                currentPageNumber = page;
            }
            paramValueList.Remove("page");

            LinkedList<string> columns = new LinkedList<string>();

            //Read columns
            if (paramValueList["columns"] != null && paramValueList["columns"].Length > 0 && !dynamicQuery.IsTotals)
            {
                string[] cols = paramValueList["columns"].Split('|');
                foreach (string col in cols)
                {
                    columns.AddLast("[" + col + "]");
                }
            }

            paramValueList.Remove("columns");

            //Read countColumn
            string countColumn = "";
            if (paramValueList["countColumn"] != null && paramValueList["countColumn"].Length > 0)
            {
                countColumn = paramValueList["countColumn"];
            }
            paramValueList.Remove("countColumn");

            //Read pivotColumns
            string pivotColumns = "";
            if (paramValueList["pivotColumns"] != null && paramValueList["pivotColumns"].Length > 0)
            {
                pivotColumns = paramValueList["pivotColumns"];
            }
            paramValueList.Remove("pivotColumns");

            //Read complementColumns
            string complementColumns = "";
            if (paramValueList["complementColumns"] != null && paramValueList["complementColumns"].Length > 0)
            {
                complementColumns = paramValueList["complementColumns"];
            }
            paramValueList.Remove("complementColumns");

            //Read pivotFunction
            string pivotFunction = "";
            if (paramValueList["pivotFunction"] != null && paramValueList["pivotFunction"].Length > 0)
            {
                pivotFunction = paramValueList["pivotFunction"];
            }
            paramValueList.Remove("pivotFunction");

            //Read isGroupPivot
            bool isGroupPivot = true;
            if (paramValueList["isGroupPivot"] != null && paramValueList["isGroupPivot"].Length > 0)
            {
                isGroupPivot = Convert.ToBoolean(paramValueList["isGroupPivot"]);
            }
            paramValueList.Remove("isGroupPivot");

            bool isPivotReport = (pivotColumns != "" && complementColumns != "" && pivotFunction != "");

            string groupByColumns = "";
            if (paramValueList["groupByColumns"] != null && paramValueList["groupByColumns"].Length > 0)
            {
                if (isTimePeriod)
                {
                    groupByColumns = "[" + paramValueList["groupByColumns"].Replace("|", "],[") + "]";
                    groupByColumns = TimePeriodGroup.insertGroupByColumns(originalTimePeriodCol, groupByColumns);
                }
            }
            paramValueList.Remove("groupByColumns");

            //Read translatedColumns
            translatedSpecialColumns.Clear();
            if (paramValueList["translatedSpecialColumns"] != null && paramValueList["translatedSpecialColumns"].Length > 0)
            {
                string[] specialColumns = paramValueList["translatedSpecialColumns"].Split('|');
                foreach (string specialColumnToAdd in specialColumns)
                {
                    translatedSpecialColumns.Add(specialColumnToAdd, specialColumnToAdd);
                }
            }
            paramValueList.Remove("translatedSpecialColumns");

            string complementGroupBy = "";
            if (paramValueList["complementGroupBy"] != null && paramValueList["complementGroupBy"].Length > 0)
            {
                if (isTimePeriod)
                {
                    complementGroupBy = paramValueList["complementGroupBy"];
                }
            }
            paramValueList.Remove("complementGroupBy");

            isTimePeriod = (originalTimePeriodCol != "" && groupByColumns != "" && complementGroupBy != "");

            if (isTimePeriod && !dynamicQuery.IsTotals)
            {
                if (complementGroupBy.Contains("_TIMEGROUP"))
                {
                    t = (TimePeriod)Enum.Parse(typeof(TimePeriod), originalTimePeriodCol, true);
                    if (t == TimePeriod.PE)
                    {
                        dateStart = DateTime.Parse(values["@dateStart"].ToString());
                        dateEnd = DateTime.Parse(values["@dateEnd"].ToString());
                        complementGroupBy = complementGroupBy.Replace("_TIMEGROUP", "," + dateEnd.Subtract(dateStart).TotalSeconds.ToString());
                    }
                    else if (t == TimePeriod.D)
                    {
                        complementGroupBy = complementGroupBy.Replace("_TIMEGROUP", ",86400");
                    }
                    else if (t == TimePeriod.H)
                    {
                        complementGroupBy = complementGroupBy.Replace("_TIMEGROUP", ",3600");
                    }
                    else if (t == TimePeriod.HH)
                    {
                        complementGroupBy = complementGroupBy.Replace("_TIMEGROUP", ",1800");
                    }
                    else
                    {
                        complementGroupBy = complementGroupBy.Replace("_TIMEGROUP", ",900");
                    }
                }
                columns = TimePeriodGroup.columnsTimePeriod(columns, originalTimePeriodCol, complementGroupBy, isPivotReport, values, currentCulture);
            }

            if (paramValueList["range"] != null && paramValueList["range"].Length > 0)
            {
                string[] ranges = paramValueList["range"].Split('|');
                foreach (string r in ranges)
                {
                    string[] aux = r.Split(':');
                    whereStatement.Append(DynamicTsqlBuilder.AndConjunction(DynamicTsqlBuilder.BetweenStatement(aux[0])));

                    parameters.Append(string.Format(", @" + aux[0] + "Min" + " " + DBSchema.getDataType(aux[0]).ToString()));
                    values.Add("@" + aux[0] + "Min", aux[1]);

                    parameters.Append(string.Format(", @" + aux[0] + "Max" + " " + DBSchema.getDataType(aux[0]).ToString()));
                    values.Add("@" + aux[0] + "Max", aux[2]);
                }
            }
            paramValueList.Remove("range");

            if (isDetail)
            {
                string timePeriodDetail;
                if (paramValueList["groupBy"] != null && paramValueList["groupBy"].Length > 0)
                {
                    timePeriodDetail = paramValueList["groupBy"];
                }
                else
                {
                    timePeriodDetail = "H";
                }

                paramValueList.Remove("groupBy");

                t = (TimePeriod)Enum.Parse(typeof(TimePeriod), timePeriodDetail, true);
                switch (t)
                {
                    case TimePeriod.D:
                        timeMinutes = 1440;
                        break;

                    case TimePeriod.H:
                        timeMinutes = 60;
                        break;

                    case TimePeriod.HH:
                        timeMinutes = 30;
                        break;

                    default:
                        timeMinutes = 15;
                        break;
                }

                if (paramValueList["date"] != null && paramValueList["date"].Length > 0)
                {
                    String dateDetail = paramValueList["date"].ToString();
                    if (t == TimePeriod.PE)
                    {
                        string[] dateDetailPE = dateDetail.Split('-');
                        dateStart = DateTime.Parse(dateDetailPE[0].Trim(), CultureInfo.CurrentCulture);
                        dateEnd = DateTime.Parse(dateDetailPE[1].Trim(), CultureInfo.CurrentCulture);
                    }
                    else
                    {
                        dateStart = DateTime.Parse(dateDetail, CultureInfo.CurrentCulture);
                        dateEnd = dateStart.AddMinutes(timeMinutes);
                    }

                    whereStatement.AppendLine(string.Format("\t WHERE {0} >= {1} AND {0} < {2}  ", "date", "@dateStart", "@dateEnd"));

                    parameters.Append(string.Format("@dateStart " + DBSchema.getDataType("dateStart").ToString()));
                    values.Add("@dateStart", dateStart.ToString("yyyy-MM-dd HH:mm"));

                    parameters.Append(string.Format(", @dateEnd " + DBSchema.getDataType("dateEnd").ToString()));
                    values.Add("@dateEnd", dateEnd.ToString("yyyy-MM-dd HH:mm"));
                }
                paramValueList.Remove("date");

                if (paramValueList["columnId"] != null && paramValueList["columnId"].Length > 0
                    && paramValueList["id"] != null && paramValueList["id"].Length > 0)
                {
                    string[] columnId = paramValueList["columnId"].ToString().Split('|');
                    string[] id = paramValueList["id"].ToString().Split('|');
                    int columnLength = columnId.Length;

                    for (int i = 0; i < columnLength; i++)
                    {
                        whereStatement.Append(DynamicTsqlBuilder.AndConjunction(DynamicTsqlBuilder.OrStatement(columnId[i], id[i])));

                        parameters.Append(string.Format(", @" + columnId[i] + "1 " + DBSchema.getDataType(columnId[i]).ToString()));
                        values.Add("@" + columnId[i] + "1", id[i]);
                    }
                }
                paramValueList.Remove("columnId");
                paramValueList.Remove("id");

                string columnDetail = "";
                string columnData = paramValueList["column"];
                if (!string.IsNullOrEmpty(columnData))
                {
                    columnDetail = columnData;
                    if (columnDetail.Contains("|"))
                    {
                        string[] colPivot = columnDetail.Split('|');
                        whereStatement.Append(DynamicTsqlBuilder.AndConjunction(DynamicTsqlBuilder.OrStatement(colPivot[0], colPivot[1])));

                        parameters.Append(string.Format(", @" + colPivot[0] + "1 " + DBSchema.getDataType(colPivot[0]).ToString()));
                        values.Add("@" + colPivot[0] + "1", colPivot[1]);
                    }
                    else
                    {
                        whereStatement.Append(DynamicTsqlBuilder.AndStatement(columnDetail, "0", "ge"));

                        parameters.Append(string.Format(", @" + columnDetail + "1 " + DBSchema.getDataType(columnDetail).ToString()));
                        values.Add("@" + columnDetail + "1", "0");
                    }
                }
                paramValueList.Remove("column");
            }

            NameValueCollection valuesPivot = new NameValueCollection();
            StringBuilder parametersPivot = new StringBuilder();
            foreach (string parameter in paramValueList)
            {
                string value = "";

                int i = 1;
                if (paramValueList[parameter].ToString() != "")
                {

                    whereStatement.Append(DynamicTsqlBuilder.AndConjunction(DynamicTsqlBuilder.OrStatement(parameter, paramValueList[parameter])));

                    value = paramValueList[parameter].Replace('|', ',');

                    string[] elements = value.Split(',');
                    foreach (string element in elements)
                    {
                        parameters.Append(string.Format(", @" + parameter + i.ToString() + " " + DBSchema.getDataType(parameter).ToString()));
                        values.Add("@" + parameter + i.ToString(), element);
                        i++;
                    }
                }
            }
            dateColumnName = "[" + dateColumnName + "]";

            tsql.Append(DynamicTsqlBuilder.selectFromStatement(columns, reportName, addRowNumber, addCountColumn, countColumn, pivotColumns, complementColumns, whereStatement.ToString(), pivotFunction, isTimePeriod, groupByColumns, dynamicQuery, dateColumnName, isGroupPivot));

            if (!(isPivotReport && !addCountColumn))
            {
                tsql.Append(whereStatement);
            }

            if (isTimePeriod && !isPivotReport && !dynamicQuery.IsTotals)
            {
                tsql.Append(groupByColumns);
                tsql.Append(" ) AS H_GROUP ");
            }

            if (addPaging || dynamicQuery.IsTotals)
            {
                tsql = DynamicTsqlBuilder.AddPaging(tsql, this.reportName, PAGE_SIZE, page, (isPivotReport && !addCountColumn), isTimePeriod, dynamicQuery);
            }
            else if (isPivotReport)
            {
                tsql.Append(" ) AS I_GROUP ''");
            }
            else if (isTimePeriod && !dynamicQuery.IsTotals)
            {
                tsql.Append(" ) AS J_GROUP ");
            }

            lastParameters = parameters;
            lastValues = values;

            if (isPivotReport && !addCountColumn)
            {
                tsql.Append(" select @out = @query");
                tsql.Append(" ', N'@out varchar(max) output");
                string paramsType = "";
                string paramsValue = "";
                if (parameters != null && values != null)
                {
                    foreach (string parameter in values.Keys)
                    {
                        SqlDbType type = DBSchema.getDataType(TypeInspector.removeDigits(parameter.Replace("@", "")));
                        paramsType += parameter + " " + type.ToString() + ",";

                        switch (type)
                        {
                            case SqlDbType.Int:
                                paramsValue += parameter + "=" + values[parameter] + ",";
                                break;

                            case SqlDbType.DateTime:
                                var dateTime = DateTime.Parse(values[parameter]);
                                var hour = dateTime.TimeOfDay.ToString();
                                var date = values[parameter].ToString().Split(' ')[0];
                                paramsValue += parameter + "='" + date + " " + hour + "',";
                                break;

                            default:
                                paramsValue += parameter + "='" + values[parameter] + "',";
                                break;
                        }
                    }
                    paramsType = paramsType.Substring(0, paramsType.Length - 1);
                    paramsValue = paramsValue.Substring(0, paramsValue.Length - 1);
                }
                tsql.Append(string.Format(", {0}', @out output, {1} ", paramsType, paramsValue));
                tsql.AppendLine(string.Format(" exec sp_executesql @stmt = @out,{0} @params=N'{1}',{2}", Environment.NewLine, paramsType, paramsValue));
            }

            dynamicQuery.Stmt = tsql;
            dynamicQuery.Parameters = parameters.Replace(SqlDbType.VarChar.ToString(), SqlDbType.VarChar.ToString() + "(max)");
            dynamicQuery.Values = values;
            dynamicQuery.IsPivotReport = (isPivotReport && !addCountColumn);

            if (!addPaging && dynamicQuery.SqlPaginate == "" && !dynamicQuery.IsTotals)
            {
                dynamicQuery.SqlPaginate = dynamicQuery.Stmt.ToString().Trim();
            }
            if (!dynamicQuery.IsTotals)
            {
                dynamicQuery.SqlPaginate = String.Format("({0}) AS K_GROUP", dynamicQuery.SqlPaginate);
            }
        }

        /// <summary>
        /// Returns a paging XmlElement indicating how many pages exist for the table, with the current PAGE_SIZE
        /// using the last where statement that was formed
        /// </summary>
        /// <param name="xml">The xml from which the element is created</param>
        /// <param name="dynamicQuery">The created dynamic query</param>
        /// <returns>An XmlElement containing paging information about the resulting table</returns>
        protected virtual XmlElement innerPaginate(XmlDocument xml, DynamicQuery dynamicQuery)
        {
            StringBuilder query = DynamicTsqlBuilder.Paginate(dynamicQuery);
            DataTable table = db.executeDynamicQuery(query, lastParameters, lastValues);
            int totalPages = 1;
            int totalRows = 0;

            foreach (DataRow row in table.Rows)
            {
                foreach (DataColumn column in table.Columns)
                {
                    if (PAGE_SIZE > 0)
                    {
                        if (int.TryParse(row[column].ToString(), out totalRows))
                        {
                            if (PAGE_SIZE <= totalRows && totalRows > 0)
                            {
                                double temp = totalRows / (double)PAGE_SIZE;
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
            data.SetAttribute("totalrows", totalRows.ToString());

            return data;
        }

        /// <summary>
        /// Obtains the menus for the application
        /// </summary>
        /// <param name="sourceUserId">The admin id used to get the menus that can be seen by the user</param>
        /// <param name="activeChat">Indicates if the chat reports are visible</param>
        /// <param name="activeAVRS">Indicates if the AVRS reports are visible</param>
        /// <param name="activeCRM">Indicates if the CRM reports are visible</param>
        /// <param name="activeEmail">Indicates if the EMAIL reports are visible</param>
        /// <returns>A xml containing the menus that the user can access</returns>
        public XmlDocument getMenu(int sourceUserId, int activeChat, int activeAVRS, int activeCRM, int activeEmail, int activeTwitter)
        {
            ChangeCulture();
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("userId", sourceUserId.ToString());
            reportParams.Add("activeChat", activeChat.ToString());
            reportParams.Add("activeAVRS", activeAVRS.ToString());
            reportParams.Add("activeCRM", activeCRM.ToString());
            reportParams.Add("activeEmail", activeEmail.ToString());
            reportParams.Add("activeTwitter", activeTwitter.ToString());
            DataTable menus = db.executeSP("dbo.GetReportMenus", reportParams);

            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));

            XmlElement catalogs = xml.CreateElement("", "ReportsMenus", "");
            xml.AppendChild(catalogs);

            XmlElement element = null;
            XmlElement element2 = null;
            int xmlMenuId = 0;
            int xmlMenuId2 = 0;

            //------------------desencriptamos la llave
            String LicenseXionDecrip;
            XionDecrypter Decrypter = new XionDecrypter();
            String MenuDecripter;

            LicenseXionDecrip = Decrypter.DesencriptaKey();
            //-----------------------------------

            XmlElement menusRoot = xml.CreateElement("", "Menus", "");
            foreach (DataRow menuRow in menus.Rows)
            {
                string xmlMenuNivel = menuRow["Nivel"].ToString().Trim();
                string xmlMenuDescription = menuRow["menu_descrip"].ToString().Trim();
                xmlMenuDescription = TranslatorHelper.getResource(xmlMenuDescription);
                string xmlMenuFiltersType = menuRow["filtersType"].ToString().Trim();
                string xmlMenuProcess = menuRow["menu_id"].ToString().Trim();
                string menuEncripted = menuRow["release"].ToString().Trim();
                MenuDecripter = Decrypter.DesencriptaMenu(LicenseXionDecrip, menuEncripted);

                xmlMenuId2 = int.Parse(menuRow["menu_id"].ToString().Trim());

                if (xmlMenuNivel == "A")
                {
                    if ((xmlMenuId != xmlMenuId2) && xmlMenuId != 0)
                    {
                        if (element2 != null)
                        {
                            element.AppendChild(element2);
                            element2 = null;
                        }
                        menusRoot.AppendChild(element);
                        element = null;
                    }

                    if (element == null)
                    {
                        element = xml.CreateElement("", "MenuType", "");
                    }

                    element.SetAttribute("label", xmlMenuDescription);
                    element.SetAttribute("element", MenuDecripter);

                    xmlMenuId = xmlMenuId2;
                }
                else if (xmlMenuNivel == "B")
                {
                    if (element2 != null)
                    {
                        element.AppendChild(element2);
                    }

                    element2 = xml.CreateElement("", "MenuItem", "");
                    element2.SetAttribute("label", xmlMenuDescription);
                    element2.SetAttribute("filtersType", xmlMenuFiltersType);
                    element2.SetAttribute("process", xmlMenuProcess);
                    element2.SetAttribute("element", MenuDecripter);
                }
                else if (xmlMenuNivel == "C")
                {
                    XmlElement element3 = xml.CreateElement("", "MenuSubItem", "");
                    element3.SetAttribute("label", xmlMenuDescription);
                    element3.SetAttribute("filtersType", xmlMenuFiltersType);
                    element3.SetAttribute("process", xmlMenuProcess);
                    element3.SetAttribute("element", MenuDecripter);
                    element2.AppendChild(element3);
                }
            }
            if (element2 != null && element != null)
            {
                element.AppendChild(element2);
            }

            if (element != null)
            {
                menusRoot.AppendChild(element);
            }

            xml.ChildNodes.Item(1).AppendChild(menusRoot);

            return xml;
        }

        /// <summary>
        /// Obtains the templates for the application
        /// </summary>
        /// <param name="sourceUserId">The admin id used to get the templates that can be seen by the user</param>
        /// <returns>A xml containing the templates that the user can access</returns>
        public XmlDocument getTemplates(int sourceUserId)
        {
            ChangeCulture();
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("userId", sourceUserId.ToString());
            DataTable menus = db.executeSP("dbo.GetReportTemplates", reportParams);

            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));

            XmlElement catalogs = xml.CreateElement("", "ReportsTemplates", "");
            xml.AppendChild(catalogs);

            XmlElement menusRoot = xml.CreateElement("", "Templates", "");
            foreach (DataRow menuRow in menus.Rows)
            {
                string xmlId = menuRow["id"].ToString().Trim();
                string xmlParameters = menuRow["parameters"].ToString().Trim();
                string xmlReportName = menuRow["reportName"].ToString().Trim();
                xmlReportName = TranslatorHelper.getResource(xmlReportName);
                string xmlDate = menuRow["date"].ToString().Trim();

                XmlElement element = xml.CreateElement("Template");
                element.SetAttribute("id", xmlId);
                element.SetAttribute("parameters", xmlParameters);
                element.SetAttribute("reportName", xmlReportName);
                element.SetAttribute("date", xmlDate);

                menusRoot.AppendChild(element);
            }

            xml.ChildNodes.Item(1).AppendChild(menusRoot);

            //User favorite templates
            xml.ChildNodes.Item(1).AppendChild(new Template().Get(xml, sourceUserId));

            return xml;
        }

        /// <summary>
        /// Obtains the default charts for the application
        /// </summary>
        /// <param name="sourceUserId">The admin id used to get the default charts that can be seen by the user</param>
        /// <returns>A xml containing the default charts that the user can access</returns>
        public XmlDocument getDefaultChart(short process)
        {
            ChangeCulture();
            NameValueCollection reportParams = new NameValueCollection();
            reportParams.Add("id", process.ToString());
            DataTable menus = db.executeSP("dbo.GetDefaultChart", reportParams);

            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));

            XmlElement catalogs = xml.CreateElement("", "ReportsDefaultCharts", "");
            xml.AppendChild(catalogs);

            XmlElement menusRoot = xml.CreateElement("", "Charts", "");
            foreach (DataRow menuRow in menus.Rows)
            {
                string xmlReportName = menuRow["reportName"].ToString().Trim();
                xmlReportName = TranslatorHelper.getResource(xmlReportName);
                string xmlChartType = menuRow["chartType"].ToString().Trim();
                string xmlColumns = menuRow["columns"].ToString().Trim();
                string xmlCountColumn = menuRow["countColumn"].ToString().Trim();
                string xmlChartDescription = menuRow["chartDescription"].ToString().Trim();
                xmlChartDescription = TranslatorHelper.getResource(xmlChartDescription);
                string xmlIsTime = menuRow["isTime"].ToString().Trim();

                XmlElement element = xml.CreateElement("Chart");
                element.SetAttribute("reportName", xmlReportName);
                element.SetAttribute("chartType", xmlChartType);
                element.SetAttribute("columns", xmlColumns);
                element.SetAttribute("countColumn", xmlCountColumn);
                element.SetAttribute("chartDescription", xmlChartDescription);
                element.SetAttribute("isTime", xmlIsTime);
                menusRoot.AppendChild(element);
            }

            xml.ChildNodes.Item(1).AppendChild(menusRoot);

            return xml;
        }

        //TODO: Hacer clase de plantillas temporales
        /// <summary>
        /// Save the templates for the application
        /// </summary>
        /// <param name="sourceUserId">The admin id used to saved templates</param>
        public void saveTemplate(int sourceUserId, short process, NameValueCollection reportParams, string action)
        {
            ChangeCulture();
            NameValueCollection Params = new NameValueCollection();
            Params.Add("userId", sourceUserId.ToString());
            Params.Add("process", process.ToString());
            string sp = "";
            int i = 1;
            StringBuilder parameters = new StringBuilder();
            parameters.Append("process=" + process.ToString() + "&");
            foreach (string Key in reportParams.Keys)
            {
                if (i < reportParams.Count)
                {
                    parameters.Append(Key + "=" + reportParams[Key] + "&");
                    i++;
                }
                else
                {
                    parameters.Append(Key + "=" + reportParams[Key]);
                }
            }

            Params.Add("parameters", parameters.ToString());

            if (action != null && action != "")
            {
                sp = "dbo.SaveReportTemplates";
                DataTable menus = db.executeSP(sp, Params);
            }
        }

        /// <summary>
        /// Gets the grand totals table of the dynamic query
        /// </summary>
        /// <param name="detailTable">The table with the columns to be used to copy the same columns order</param>
        /// <param name="totalsTable">The table with the columns to be compared with the detail table columns</param>
        /// <returns>A DataTable with one total row</returns>
        protected DataTable getGrandTotalTable(DataTable detailTable, DataTable totalsTable)
        {
            DataTable newTable = new DataTable();
            newTable.Rows.Add(newTable.NewRow());
            foreach (DataColumn col in detailTable.Columns)
            {
                DataColumn newCol = new DataColumn(col.ColumnName);
                newTable.Columns.Add(newCol);
                if (totalsTable == null)
                {
                    continue;
                }

                if (totalsTable.Columns.Contains(col.ColumnName))
                {
                    newTable.Rows[0][newCol] = totalsTable.Rows[0][col.ColumnName];
                }
            }
            return newTable;
        }
    }
}