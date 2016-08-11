using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using System.Collections.Specialized;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that transforms the information of a DataTable into a html with a xls extension and returns its output as bytes
    /// </summary>
    public class XlsReport : ReportFormat
    {
        private string reportName;
        private NameValueCollection translatedColumns;
        private NameValueCollection convertedColumns;

        /// <summary>
        /// Transforms a datable into a html file with a xls extension and returns its bytes in an array
        /// </summary>
        /// <param name="data">The DataTable to be transformed</param>
        /// <param name="reportName">The name of the report</param>
        /// <returns>A byte array of the resulting file</returns>
        /// <exception>Throws an EmptyResultException if the DataTable is empty</exception>
        public byte[] getOutPut(DataTable data, string reportName, string logoFileName = "", string filterSummaryData = "", bool translate = true)
        {
            EmptyResultException.dataTableIsEmpty(data);

            if (translate)
            {
                translatedColumns = TranslatorHelper.translateColumns(data.Columns);
                convertedColumns = TranslatorHelper.convertColumns(data.Columns);
            }
            else
            {
                translatedColumns = TranslatorHelper.translateColumns(data.Columns);
            }

            this.reportName = reportName;
            StringBuilder output = new StringBuilder();
            try
            {
                LinkedList<string> columnsNames = new LinkedList<string>();

                //Retrieve column schema into a DataTable.                
                foreach (DataColumn column in data.Columns)
                {
                    //Save column name if its viewable

                    if (!translate)
                    {
                        columnsNames.AddLast(column.ColumnName);
                    }
                    else if (!string.IsNullOrEmpty(translatedColumns[column.ColumnName]))
                    {
                        columnsNames.AddLast(column.ColumnName);
                    }
                }

                //Generate html table
                output = generateHtml(columnsNames, data, filterSummaryData, translate);
            }
            catch (Exception e)
            {
                String temp = e.Message;
            }

            //Add BOM byte to display correctly foreign characters in UTF-8 
            //Source: https://en.wikipedia.org/wiki/Byte_order_mark 
            byte[] bBOM = new byte[] { 0xEF, 0xBB, 0xBF };
            byte[] bContent = System.Text.Encoding.UTF8.GetBytes(output.ToString());
            byte[] bToWrite = new byte[bBOM.Length + bContent.Length];
            bBOM.CopyTo(bToWrite, 0);
            bContent.CopyTo(bToWrite, bBOM.Length);

            return bToWrite;
        }

        /// <summary>
        /// Generates a html table that can be openend in excel
        /// </summary>
        /// <param name="headers">The name of the columns</param>
        /// <param name="data">The DataTable to be transformed</param>
        /// <returns>The html file text in a StringBuilder</returns>
        private StringBuilder generateHtml(LinkedList<string> headers, DataTable data, string filterSummaryData, bool translate)
        {
            StringBuilder html = new StringBuilder();
            html.AppendLine("<html><head><style>.b{border: 1px solid black; mso-number-format:\\@; }.a{background:#FF0000;color:#FFFFFF;border: 1px solid black ;}</style></head><body>");
            html.AppendLine("<table style=\"border: 1px solid black ; text-align:center; font-family:sans-serif;\">");
            //Place report name
            html.AppendLine("<tr>");
            html.AppendLine(string.Format("<td colspan=\"{1}\" style=\"background:#000000;color:#FFFFFF;border: 1px solid black ; text-align:center; \" >{0}</td>", reportName, headers.Count));
            html.AppendLine("</tr>");

            if (filterSummaryData != "")
            {
                string[] filters = filterSummaryData.Split('|');
                foreach (string filter in filters)
                {
                    if (filter != "")
                    {
                        string header = filter.Split('>')[0];
                        html.AppendLine("<tr>");
                        html.AppendLine(string.Format("<td style=\"background:#FF0000;color:#FFFFFF;border: 1px solid black ; \" >{0}</td>", header));
                        html.AppendLine("</tr>");

                        foreach (string elem in filter.Split('>')[1].Split(','))
                        {
                            html.AppendLine("<tr>");
                            html.AppendLine(string.Format("<td style=\"border: 1px solid black ;\"></td>"));
                            html.AppendLine(string.Format("<td style=\"border: 1px solid black ;\">{0}</td>", elem));
                            html.AppendLine("</tr>");
                        }
                    }
                }

            }

            html.AppendLine("<tr>");
            html.AppendLine("</tr>");
            //Place report columns
            html.AppendLine("<tr>");
            //Place headers
            foreach (string header in headers)
            {
                if (translate)
                    html.AppendLine(string.Format("<td class=\"a\">{0}</td>", translatedColumns[header]));
                else
                    html.AppendLine(string.Format("<td class=\"a\">{0}</td>", header));

            }
            html.AppendLine("</tr>");
            //Place Rows
            string value = "";
            foreach (DataRow row in data.Rows)
            {
                html.AppendLine("<tr>");
                foreach (string col in headers)
                {
                    value = row[col].ToString();
                    value = TranslatorHelper.parseDbValue(value);
                    if (translate && convertedColumns[col] != null && value != "")
                    {
                        value = TranslatorHelper.formatTime(Convert.ToInt32(value));
                    }

                    html.AppendLine(string.Format("<td class=\"b\">{0}</td>", value));
                }
                html.AppendLine("</tr>");
            }



            html.AppendLine("</table></body></html>");
            return html;
        }
    }
}
