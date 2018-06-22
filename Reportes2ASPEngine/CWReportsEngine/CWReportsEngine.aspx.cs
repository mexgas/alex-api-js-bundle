using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Web;
using System.Configuration;
using System.Data.SqlClient;
using System.Threading;
using System.Globalization;
using System.Text;
using System.Xml;
using System.IO;
using MiddleWareReports;

public partial class CWReportsEngine : System.Web.UI.Page
{
    private string code;
    private string type;
    private string errorNumber;
    private string errorMessage;
    private string errorType;
    private string lang;
    private string format;
    private string chart;
    private string favTemplates;
    private string filters;
    private string addFilters;
    private string menus;
    private string templates;
    private string savetemplate;
    private string defaultchart;
    private string totals;
    private string title;
    private string process;
    private string details;
    private string filtersSummaryData;
    private string crmTemplateId;
    private string templateId;
    private string chartFields;


    protected void Page_Load(object sender, EventArgs e)
    {
        short process;

        if (Request["process"] == null)
        {
            process = 0;
        }
        else
        {
            short.TryParse(Request["process"], out process);
        }

        #region CacheControl
        Response.Expires = 0;
        Response.ExpiresAbsolute = DateTime.Now.AddDays(-1);
        Response.AddHeader("pragma", "no-cache");
        Response.AddHeader("cache-control", "private");
        Response.CacheControl = "no-cache";
        #endregion

        UseSession(process);
    }

    #region Usar Sesion
    public void UseSession(short process)
    {
        int sourceUserId = 0;
        int activeChat = 0;
        int activeAVRS = 0;
        int activeCRM = 0;
        int activeEmail = 0;
        int activeTwitter = 0;
        StringBuilder html = new StringBuilder();
        bool hadException = false;
        string strCulture = "";

        //Build HashTable for Parameters Reader
        ParametersReader.setParameters(RequestHelper.copyRequestQueryParameters(Page.Request));
        #region ReadParametrs
        //Set user id session
        if (ParametersReader.getParameters("sourceUserId", false) != "")
        {
            int.TryParse(ParametersReader.getParameters("sourceUserId", true), out sourceUserId);
            if (Session["sourceUserId"] == null)
            {
                Session["sourceUserId"] = sourceUserId;
            }
            else
            {
                int currentId = -1;
                int.TryParse(Session["sourceUserId"].ToString(), out currentId);
                if (currentId != sourceUserId)
                {
                    Session.Clear();
                    Session["sourceUserId"] = sourceUserId;
                }
            }
        }
        else
        {
            if (Session["sourceUserId"] != null)
            {
                int.TryParse(Session["sourceUserId"].ToString(), out sourceUserId);
            }
        }

        //Set app culture session
        if (ParametersReader.getParameters("lang", false) != "")
        {
            lang = ParametersReader.getParameters("lang", true);
            if (Session["lang"] == null)
            {
                Session["lang"] = lang;
            }
            else
            {
                if (lang != null && !lang.Equals(Session["lang"].ToString()))
                {
                    Session["lang"] = lang;
                }
            }
        }
        else
        {
            if (Session["lang"] != null)
            {
                lang = Session["lang"].ToString();
            }
        }

        //Set active chat session
        if (ParametersReader.getParameters("activeChat", false) != "")
        {
            int.TryParse(ParametersReader.getParameters("activeChat", true), out activeChat);
            if (Session["activeChat"] == null)
            {
                Session["activeChat"] = activeChat;
            }
            else
            {
                if (!activeChat.Equals(Session["activeChat"].ToString()))
                {
                    Session["activeChat"] = activeChat;
                }
            }
        }
        else
        {
            if (Session["activeChat"] != null)
            {
                int.TryParse(Session["activeChat"].ToString(), out activeChat);
            }
        }



        //Set active crm session
        if (ParametersReader.getParameters("activeCRM", false) != "")
        {
            int.TryParse(ParametersReader.getParameters("activeCRM", true), out activeCRM);
            if (Session["activeCRM"] == null)
            {
                Session["activeCRM"] = activeCRM;
            }
            else
            {
                if (!activeCRM.Equals(Session["activeCRM"].ToString()))
                {
                    Session["activeCRM"] = activeCRM;
                }
            }
        }
        else
        {
            if (Session["activeCRM"] != null)
            {
                int.TryParse(ParametersReader.getParameters("activeCRM", true), out activeCRM);
            }
        }


        //Set active AVRS session
        if (ParametersReader.getParameters("activeAVRS", false) != "")
        {
            int.TryParse(ParametersReader.getParameters("activeAVRS", true), out activeAVRS);
            if (Session["activeAVRS"] == null)
            {
                Session["activeAVRS"] = activeAVRS;
            }
            else
            {
                if (!activeChat.Equals(Session["activeAVRS"].ToString()))
                {
                    Session["activeAVRS"] = activeAVRS;
                }
            }
        }
        else
        {
            if (Session["activeAVRS"] != null)
            {
                int.TryParse(Session["activeAVRS"].ToString(), out activeAVRS);
            }
        }


        //Set active crm session
        if (ParametersReader.getParameters("activeEmail", false) != "")
        {
            int.TryParse(ParametersReader.getParameters("activeEmail", true), out activeEmail);
            if (Session["activeEmail"] == null)
            {
                Session["activeEmail"] = activeEmail;
            }
            else
            {
                if (!activeCRM.Equals(Session["activeEmail"].ToString()))
                {
                    Session["activeEmail"] = activeEmail;
                }
            }
        }
        else
        {
            if (Session["activeEmail"] != null)
            {
                int.TryParse(ParametersReader.getParameters("activeEmail", true), out activeEmail);
            }
        }

        //Set active twitter session
        if (ParametersReader.getParameters("activeTwitter", false) != "")
        {
            int.TryParse(ParametersReader.getParameters("activeTwitter", true), out activeTwitter);
            if (Session["activeTwitter"] == null)
            {
                Session["activeTwitter"] = activeTwitter;
            }
            else
            {
                if (!activeCRM.Equals(Session["activeTwitter"].ToString()))
                {
                    Session["activeTwitter"] = activeTwitter;
                }
            }
        }
        else
        {
            if (Session["activeTwitter"] != null)
            {
                int.TryParse(ParametersReader.getParameters("activeTwitter", true), out activeTwitter);
            }
        }
        #endregion

        try
        {
            //Validate user id
            if (sourceUserId <= 0)
            {
                throw new SecurityException("Invalid Session");
            }

            //Get parameters to be cleaned
            NameValueCollection parameters = ParametersReader.getAllParameters();
            foreach (string key in parameters.Keys)
            {
                MiddleWareReports.BadParameterException.correctNameFormation(key);
            }

            //Get URL parameters through HashTable
            getParameters();

            //Get collection of parameters after being processed
            parameters.Clear();
            parameters = ParametersReader.getAllParameters();

            string reportName;

            //Get report name
            int processNew = process;
            if (process == 9010
                && (crmTemplateId != "" || templateId != "")
                )
            {
                processNew++;
            }

            reportName = MiddleWareReports.ReportFactory.getReportName(processNew).GetType().ToString();            


            //Create generic report   
            MiddleWareReports.GenericReport report;
            report = MiddleWareReports.GenericReport.createReport(reportName);
            report.ReportName += processNew != process ? crmTemplateId + templateId : "";


            //Set app culture
            if (lang == "es")
            {
                strCulture = lang + "-MX";
            }
            else if (lang == "en")
            {
                strCulture = lang + "-US";
            }
            else
            {
                strCulture = "es-MX";
            }

            CultureInfo culture = new CultureInfo(strCulture);
            report.CurrentCulture = culture;

            if (defaultchart.Length > 0) //Get default chart by report
            {
                Response.Write(report.getDefaultChart(process).OuterXml);
            }
            else if (favTemplates.Length > 0) //Favorite templates of the user
            {
                Response.Write(new MiddleWareReports.Template().Action(favTemplates[0], parameters, sourceUserId).InnerXml);
            }
            else if (templates.Length > 0) //Recent generated reports of the user
            {
                Response.Write(report.getTemplates(sourceUserId).OuterXml);
            }
            else if (menus.Length > 0) //Get menus of the app
            {
                Response.Write(report.getMenu(sourceUserId, activeChat, activeAVRS, activeCRM, activeEmail, activeTwitter).OuterXml);
            }
            else if (chart.Length > 0) //Get chart by report
            {
                Response.Write(report.getChart(parameters, process).OuterXml);
            }
            else if (filters.Length > 0)//Get filters by report
            {
                if (!(report is RepCRMXTemplates))
                {
                    Response.Write(report.getReportFilters(parameters, process).OuterXml);
                }
                else //Get filters from CRM
                {
                    Response.Write(report.getCRMReportFilters(parameters, process, true).OuterXml);
                }

            }
            else if (crmTemplateId.Length > 0)
            {
                parameters["crmTemplateId"] = crmTemplateId;
                Response.Write(report.getCRMReportFilters(parameters, process, false).OuterXml);
            }
            else if (details.Length > 0)//Get filters by report
            {
                Response.Write(report.getXmlDetailReport(parameters, process).OuterXml);
            }
            else if (format.Equals(""))//Get xmlReport
            {
                if (addFilters.Length > 0)
                    parameters["crmtemplateId"] = templateId;
                if (!string.IsNullOrEmpty(templateId))
                    parameters["templateId"] = templateId;
                Response.Write(report.getXmlReport(parameters, process, addFilters, sourceUserId, savetemplate, totals).OuterXml);
            }
            else //Get report in format X 
            {
                string logoFileName = "";

                //To avoid error messages when exporting
                Response.ClearContent();
                Response.ClearHeaders();

                if (format.Equals("csv"))
                {
                    Response.ContentType = "text/csv";
                }
                else if (format.Equals("pdf"))
                {
                    Response.ContentType = "application/pdf";
                    logoFileName = Server.MapPath("assets/template.pdf");
                }
                else if (format.Equals("xls"))
                {
                    Response.ContentType = "application/ms-excel";
                }
                else
                {
                    Response.ContentType = "text/plain";
                }
                MiddleWareReports.ReportFormat exportFormat = MiddleWareReports.ExportReportFactory.GenerateReport(format);
                byte[] output;
                if (process >= 9000 && process < 10000)
                {
                    output = exportFormat.getOutPut(report.getDataReport(parameters, process), title, logoFileName, filtersSummaryData, true, process);
                }
                else
                    output = exportFormat.getOutPut(report.getDataReport(parameters, process), title, logoFileName, filtersSummaryData, true, 0);

                Response.Clear();
                Response.Charset = "UTF-8";
                Response.Buffer = true;
                Response.BufferOutput = true;
                Response.AppendHeader("Content-Disposition", "attachment;filename=" + report.ReportName + "_" + DateTime.Now.ToString("yyyyMMddhhmm") + "." + format);
                Response.ContentEncoding = System.Text.Encoding.UTF8;
                Response.BinaryWrite(output);
            }
        }
        catch (MiddleWareReports.EmptyResultException empEx)
        {
            hadException = true;
            code = "1";
            type = "0";
            errorNumber = ((int)empEx.GetType().GetProperty("HResult", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic).GetValue(empEx, null)).ToString();
            errorMessage = empEx.Message;
            errorType = "EmptyResultException";
        }
        catch (MiddleWareReports.BadParameterException bpEx)
        {
            hadException = true;
            code = "2";
            type = "1";
            errorNumber = ((int)bpEx.GetType().GetProperty("HResult", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic).GetValue(bpEx, null)).ToString();
            errorMessage = bpEx.Message;
            errorType = "BadParameterException";
        }
        catch (MiddleWareReports.ReportNotFoundException tEx)
        {
            hadException = true;
            code = "3";
            type = "1";
            errorNumber = ((int)tEx.GetType().GetProperty("HResult", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic).GetValue(tEx, null)).ToString();
            errorMessage = tEx.Message;
            errorType = "ReportNotFoundException";
        }
        catch (SqlException sqlEx)
        {
            hadException = true;
            code = "4";
            type = "1";
            errorNumber = sqlEx.ErrorCode.ToString();
            errorMessage = sqlEx.StackTrace;
            errorType = "SqlException";
        }
        catch (SecurityException secEx)
        {
            hadException = true;
            code = "7";
            type = "1";
            errorNumber = "-1";
            errorMessage = secEx.Message;
            errorType = "SecurityException";
        }

        catch (CRMFieldsNotFoundException crmEx)
        {
            hadException = true;
            code = "6";
            type = "0";
            errorNumber = "-1";
            errorMessage = crmEx.Message;
            errorType = "CRMFieldsNotFoundException";
        }


        catch (Exception e)
        {
            hadException = true;
            code = "5";
            type = "1";
            errorNumber = ((int)e.GetType().GetProperty("HResult", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic).GetValue(e, null)).ToString();
            errorMessage = e.StackTrace;
            errorType = "GeneralException";
        }
        finally
        {
            if (hadException)
            {
                if (type == "1")
                {
                    //Genera Log de Error
                    string logFolder = "C:\\logReports";
                    string logPath = logFolder + "\\logReports" + DateTime.Now.ToString("dd") + DateTime.Now.ToString("MM") + DateTime.Now.ToString("yyyy") + ".txt";
                    StreamWriter log;
                    string strLogText = "..::Error " + DateTime.Now.ToString() + "::.. Code:" + code + ", Type:" + errorType + ", Message:" + errorMessage + ", Number:" + errorNumber;

                    if (!(Directory.Exists(logFolder)))
                    {
                        Directory.CreateDirectory(logFolder);
                    }

                    if (!File.Exists(logPath))
                    {
                        log = new StreamWriter(logPath);
                    }
                    else
                    {
                        log = File.AppendText(logPath);
                    }

                    log.WriteLine(strLogText);
                    log.Close();
                }

                //Genera XML de Error o Alerta
                XmlDocument xml = new XmlDocument();
                xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
                XmlElement errors = xml.CreateElement("", "ReportsErrors", "");
                xml.AppendChild(errors);

                XmlElement errorsRoot = xml.CreateElement("", "Errors", "");
                XmlElement error = xml.CreateElement("", "Error", "");

                error.SetAttribute("errorCode", code);
                error.SetAttribute("typeCode", type);
                error.SetAttribute("errorType", errorType);
                error.SetAttribute("errorMessage", errorMessage);
                error.SetAttribute("errorNumber", errorNumber);

                errorsRoot.AppendChild(error);

                xml.ChildNodes.Item(1).AppendChild(errorsRoot);

                Response.Write(xml.OuterXml);
            }
        }
    }

    private void getParameters()
    {
        //Get Parameters and remove after use
        format = ParametersReader.getParameters("format", true);
        details = ParametersReader.getParameters("details", true);
        chart = ParametersReader.getParameters("chart", true);
        favTemplates = ParametersReader.getParameters("favTemplates", true);
        filters = ParametersReader.getParameters("filters", true);
        addFilters = ParametersReader.getParameters("addFilters", true);
        menus = ParametersReader.getParameters("menus", true);
        templates = ParametersReader.getParameters("templates", true);
        savetemplate = ParametersReader.getParameters("savetemplate", true);
        defaultchart = ParametersReader.getParameters("defaultChart", true);
        totals = ParametersReader.getParameters("totals", true);
        title = ParametersReader.getParameters("title", true);
        process = ParametersReader.getParameters("process", true);
        filtersSummaryData = ParametersReader.getParameters("filtersSummaryData", true);
        templateId = ParametersReader.getParameters("templateId", true);
        chartFields = ParametersReader.getParameters("chartFields", true);
        crmTemplateId = ParametersReader.getParameters("crmTemplateId", true);
    }

    #endregion
}
