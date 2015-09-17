using System;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Text;
using System.Collections.Specialized;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that transforms the information of a DataTable into a csv and returns its output as bytes
    /// </summary>
    public class CsvReport : ReportFormat
    {
        private NameValueCollection translatedColumns;
        private NameValueCollection convertedColumns;

        /// <summary>
        /// Given a datatable and a reportname, it transforms the contents of the DataTable into 
        /// an csv file and gives its output as bytes.
        /// </summary>
        /// <param name="data">The DataTable to be transformed</param>
        /// <param name="reportName">The name of the report</param>
        /// <returns>A byte array of the transformed csv file</returns>
        /// <exception>Throws an EmptyResultException if the DataTable is empty</exception>
        public byte[] getOutPut(DataTable data, string reportName, string logoFileName = "", string filterSummaryData = "", bool translate = true)
        {
            EmptyResultException.dataTableIsEmpty(data);

            StringBuilder output = new StringBuilder();
            if (translate)
            {
                translatedColumns = TranslatorHelper.translateColumns(data.Columns);
                convertedColumns = TranslatorHelper.convertColumns(data.Columns);
            }
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
                    else if (translatedColumns[column.ColumnName] != null)
                    {
                        columnsNames.AddLast(column.ColumnName);
                    }
                }

                //Generate html table
                output = generateCsv(columnsNames, data, filterSummaryData, translate);
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
        /// Helper method that given a list of headers and a DataTable produces the csv text.
        /// </summary>
        /// <param name="headers">Headers of the csv</param>
        /// <param name="data">Datatable containing the table</param>
        /// <returns>The csv text in a StringBuilder</returns>
        private StringBuilder generateCsv(LinkedList<string> headers, DataTable data, string filterSummaryData, bool translate)
        {
            StringBuilder csv = new StringBuilder();
            int i = 0;

            if (filterSummaryData != "")
            {
                string[] filters = filterSummaryData.Split('|');
                foreach (string filter in filters)
                {
                    if (filter != "")
                    {
                        string header = filter.Split('>')[0];
                        csv.AppendLine();
                        csv.Append(string.Format("{0},", header));
                        for (int ii = 2; ii < i; ii++)
                        {
                            csv.Append(",");
                        }
                        foreach (string elem in filter.Split('>')[1].Split(','))
                        {
                            csv.AppendLine();
                            csv.Append(string.Format(",{0},", elem));
                            for (int ii = 3; ii < i; ii++)
                            {
                                csv.Append(",");
                            }
                        }
                    }
                }

            }
            csv.AppendLine();
            csv.AppendLine();
            //Place headers                     
            foreach (string header in headers)
            {
                if (!translate && i == headers.Count - 1)
                    csv.Append(string.Format("{0}", header));
                else if(!translate)
                    csv.Append(string.Format("{0},", header));
                else if (i == headers.Count - 1)
                    csv.Append(string.Format("{0}", translatedColumns[header]));
                else
                    csv.Append(string.Format("{0},", translatedColumns[header]));

                i++;
            }

            //Place Rows
            string value = "";
            foreach (DataRow row in data.Rows)
            {
                csv.AppendLine();
                i = 0;
                foreach (string col in headers)
                {
                    value = row[col].ToString();
                    value = TranslatorHelper.parseDbValue(value);
                    if (translate && convertedColumns[col] != null && value != "")
                    {
                        value = TranslatorHelper.formatTime(Convert.ToInt32(value));
                    }

                    if (i == 0)
                        csv.Append(string.Format("=\"{0}\"",value));
                    else
                        csv.Append(string.Format(",=\"{0}\"", value));

                    i++;
                }
            }

            

            return csv;
        }
    }
}
