using System;
using System.Data;

namespace MiddleWareReports
{
    #region PdfReport

    /// <summary>
    /// Class that transforms the information of a DataTable into a pdf and returns its output as bytes
    /// </summary>
    public class PdfReport : ReportFormat
    {
        private string reportName;

        /// <summary>
        /// Transforms the data of a DataTable into a pdf that has the passed report name paramater as a header
        /// </summary>
        /// <param name="data">The DataTable with the information</param>
        /// <param name="reportName">The value that will be placed at the header of each page</param>
        /// <returns>An array of bytes of the pdf file generated</returns>
        /// <exception>Throws an EmptyResultException if the DataTable is empty</exception>
        public byte[] getOutPut(DataTable data, String reportName, string logoFileName = "", string filterSummaryData = "", bool translate = true, short process = 0)
        {
            EmptyResultException.dataTableIsEmpty(data);
            int nRows = 0;
            this.reportName = reportName;
            if (translate)
            {
                TranslatorHelper.removeUntranslatedTableColumns(data, process);
            }

            for (int i = 0; i < data.Columns.Count; i++)
            {
                string nameTranslated = TranslatorHelper.getPivotTranslatedColumns(data.Columns[i].ColumnName);

                try
                {
                    data.Columns[i].ColumnName = nameTranslated;
                }
                catch (Exception)
                {
                    data.Columns[i].ColumnName = nameTranslated + i;
                }
            }

            DataTable dataClone = data.Clone();
            for (int i = 0; i < data.Columns.Count; i++)
            {
                dataClone.Columns[i].DataType = System.Type.GetType("System.String");
            }

            if (filterSummaryData != "")
            {
                string[] filters = filterSummaryData.Split('|');
                foreach (string filter in filters)
                {
                    if (filter != "")
                    {
                        nRows++;
                        string header = filter.Split('>')[0];
                        DataRow headerRow = dataClone.NewRow();
                        headerRow[0] = header;
                        dataClone.Rows.Add(headerRow);

                        foreach (string elem in filter.Split('>')[1].Split(','))
                        {
                            DataRow elemRow = dataClone.NewRow();
                            elemRow[1] = elem;
                            dataClone.Rows.Add(elemRow);
                            nRows++;
                        }
                    }
                }
            }

            foreach (DataRow row in data.Rows)
            {
                dataClone.ImportRow(row);
            }
            /**/

            return generatePDF(dataClone, reportName, logoFileName, nRows, process);
        }

        /// <summary>
        /// Creates a PDF file that is first streamed into a buffer and then the contents of this
        /// buffer are retrieved into an array of bytes.
        /// </summary>
        /// <param name="data">The DataTable that provides the information</param>
        /// <param name="reportName">It will be placed on the header of each page</param>
        /// <returns>A byte array containing the bytes of the generated Pdf file</returns>
        private byte[] generatePDF(DataTable data, string reportName, string logoFileName, int nRows, short process = 0)
        {
            Migradoc renderer = new Migradoc();
            return renderer.getPdfRenderBytes(data, reportName, logoFileName, nRows, process);
        }

        #endregion PdfReport
    }
}