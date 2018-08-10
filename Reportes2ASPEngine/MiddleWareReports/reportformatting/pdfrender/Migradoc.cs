using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using MigraDoc.DocumentObjectModel.Tables;
using MigraDoc.DocumentObjectModel;
using MigraDoc.Rendering;
using PdfSharp;
using System.Collections.Specialized;
using PdfSharp.Drawing;
using PdfSharp.Pdf;
using System.Linq;

namespace MiddleWareReports
{
    public class Migradoc
    {
        const int COLSPERPAGE = 8;
        const int ROWSPERPAGE = 40;

        const double PAGE_LEFT_MARGIN = 1.0;
        const double PAGE_TOP_MARGIN = 1.5;
        const double PAGE_BOTTOM_MARGIN = 0.7;
        const double HEADER_LEFT_MARGIN = 8.5;
        const double HEADER_MAX_WIDTH = 10.5;
        const double FOOTER_LEFT_MARGIN = 10.0;
        const double TABLE_TOP_MARGIN = 6.0;
        const double TABLE_MAX_WIDTH = 26.0;

        const string HEADER_STYLE = "headerStyle";
        const string FOOTER_STYLE = "footerStyle";
        const string TABLE_STYLE = "tableStyle";

        const string headerArgbColor = "0xFF4E4E4E";
        const string totalsArgbColor = "0xFF808080";

        Color headerColor;
        Color totalsColor;


        private int nTables = 0;
        private int start = 0;
        public Migradoc()
        {
            headerColor = Color.Parse(headerArgbColor);
            totalsColor = Color.Parse(totalsArgbColor);
        }

        public byte[] getPdfRenderBytes(DataTable table, string reportName, string logoFilePath = "", int nRows = 0, short process = 0)
        {
            Dictionary<int, LinkedList<Table>> tables = tablesToPdfTables(table, nRows, process);
            PdfDocument pdfDocument = new PdfDocument();
            XImage xImage = XImage.FromFile(logoFilePath);

            byte[] docBytes = null;

            int totalPages = 0;
            foreach (LinkedList<Table> tableList in tables.Values)
            {
                totalPages += tableList.Count;
            }
            int pageNumber = 0;
            foreach (LinkedList<Table> tableList in tables.Values)
            {
                foreach (Table newTable in tableList)
                {
                    PdfPage pdfPage = pdfDocument.AddPage();
                    pdfPage.Orientation = PageOrientation.Landscape;
                    renderPdfPage(pdfPage, xImage, newTable, reportName, pageNumber++, totalPages);
                }
            }

            using (System.IO.MemoryStream stream = new System.IO.MemoryStream())
            {
                pdfDocument.Save(stream, false);
                docBytes = stream.ToArray();
                stream.Flush();
                stream.Close();
            }

            return docBytes;
        }

        private void renderPdfPage(PdfPage pdfPage, XImage xImage, Table table, string reportName, int pageNumber, int totalPages)
        {
            XGraphics xGraphics = XGraphics.FromPdfPage(pdfPage);
            xGraphics.MUH = PdfFontEncoding.Unicode;
            xGraphics.MFEH = PdfFontEmbedding.Default;
            xGraphics.DrawImage(xImage, 0, 0, pdfPage.Width, pdfPage.Height);

            Document document = getDocument();
            Section section = document.AddSection();
            section.PageSetup.TopMargin = getUnit(2.5);
            section.PageSetup.BottomMargin = getUnit(2.5);

            Paragraph headerParagraph = new Paragraph();
            headerParagraph.Style = HEADER_STYLE;
            headerParagraph.Format.Alignment = ParagraphAlignment.Left;
            headerParagraph.Format.Font.Size = "12";
            headerParagraph.AddSpace(10);
            headerParagraph.AddText(reportName);

            Paragraph footerParagraph = new Paragraph();
            footerParagraph.Style = FOOTER_STYLE;
            footerParagraph.AddText(String.Format("{0} / {1}", pageNumber + 1, totalPages));

            section.Add(headerParagraph);
            section.Add(footerParagraph);
            section.Add(table);

            DocumentRenderer documentRenderer = new DocumentRenderer(document);
            documentRenderer.PrepareDocument();
            documentRenderer.RenderObject(xGraphics, getXUnit(HEADER_LEFT_MARGIN), getXUnit(PAGE_TOP_MARGIN), getXUnit(HEADER_MAX_WIDTH), headerParagraph);
            documentRenderer.RenderObject(xGraphics, getXUnit(FOOTER_LEFT_MARGIN), getXUnit(pdfPage.Height.Centimeter - PAGE_BOTTOM_MARGIN), getXUnit(pdfPage.Width.Centimeter), footerParagraph);
            documentRenderer.RenderObject(xGraphics, getXUnit(PAGE_LEFT_MARGIN), getXUnit(TABLE_TOP_MARGIN), getXUnit(TABLE_MAX_WIDTH), table);
        }

        private Document getDocument()
        {
            Style tableStyle = new Style(TABLE_STYLE, "Normal");
            tableStyle.Font.Color = Colors.Black;
            tableStyle.Font.Size = "8.5";
            tableStyle.Font.Name = "Arial";

            Style headerStyle = new Style(HEADER_STYLE, "Normal");
            headerStyle.Font.Color = headerColor;
            headerStyle.Font.Size = "10";

            Style footerStyle = new Style(FOOTER_STYLE, "Normal");
            headerStyle.Font.Bold = true;
            footerStyle.Font.Size = "8";

            Document document = new Document();
            document.Styles.Add(tableStyle);
            document.Styles.Add(headerStyle);
            document.Styles.Add(footerStyle);
            return document;
        }

        private XUnit getXUnit(double cm)
        {
            return XUnit.FromCentimeter(cm);
        }

        private Unit getUnit(double value)
        {
            return Unit.FromCentimeter(value);
        }

        private string getTranslation(string data, short process)
        {
            if (process < 10000 && process >= 9000)
            {
                if (data == "crmx_Date" || data == "crmxSource" || data.StartsWith("crmx_"))
                {
                    string column_name = data != "crmx_Date" && data.StartsWith("crmx_") ? data.Replace("crmx_", "") : data;
                    return TranslatorHelper.getResource(column_name, true);
                }
                else
                    return data;
            }
            else
                return TranslatorHelper.getResource(data, true);
        }

        public Dictionary<int, LinkedList<Table>> tablesToPdfTables(DataTable data, int nRows, short process = 0)
        {
            NameValueCollection convertedColumns = TranslatorHelper.convertColumns(data.Columns);

            List<int> maximunLengthForColumns = Enumerable.Range(0, data.Columns.Count)
                                                .Select(col => data.AsEnumerable()
                                                .Select(row => row[col]).OfType<string>()
                                                .Max(val => val.Length)).ToList(); // Determina el texto mas largo por columnas

            for (int i = 0; i < maximunLengthForColumns.Count; i++) // compara el texto mas largo contra los headers de la tabla
            {
                string str = getTranslation(data.Columns[i].ColumnName, process);

                if (str.Length > maximunLengthForColumns[i])
                {
                    maximunLengthForColumns[i] = str.Length;
                }

                if (convertedColumns[data.Columns[i].ColumnName] != null && str.Length < 10)
                {
                    maximunLengthForColumns[i] = 10;
                }

            }

            Dictionary<int, LinkedList<Table>> tables = new Dictionary<int, LinkedList<Table>>();

            double tempWidth = 0;
            double tempWidth2 = 0;
            start = 0;
            nTables = 0;
            for (int i = 0; i < maximunLengthForColumns.Count; i++)
            {
                tempWidth2 = maximunLengthForColumns[i] * 0.1666;

                if ((tempWidth2 > TABLE_MAX_WIDTH || tempWidth + tempWidth2 > TABLE_MAX_WIDTH) && tempWidth > 0) // determina la cantidad de columnas por hoja
                {
                    generaPagesPDF(data, tables, convertedColumns, maximunLengthForColumns, nRows, i - 1, process);
                    tempWidth = 0;
                }

                if (tempWidth2 > TABLE_MAX_WIDTH || i == maximunLengthForColumns.Count - 1)
                {
                    generaPagesPDF(data, tables, convertedColumns, maximunLengthForColumns, nRows, i, process);
                    tempWidth = 0;
                    tempWidth2 = 0;
                }

                tempWidth += tempWidth2;

            }
            generaPagesPDF(data, tables, convertedColumns, maximunLengthForColumns, nRows, maximunLengthForColumns.Count, process);
            return tables;
        }

        private void generaPagesPDF(DataTable data, Dictionary<int, LinkedList<Table>> tables, NameValueCollection convertedColumns,
            List<int> maximunLengthForColumns, int nRows, int numColum, short process)
        {

            int end = 0;

            int currentRow = 0;
            int fRow = 0; // filas que se ultilizaran para los filtros
            bool flag = true;
            end = numColum - 1;
            double widthColumAll = 0;
            DataRow last = data.Rows[data.Rows.Count - 1]; // tupla de los totales
            foreach (DataRow dRow in data.Rows)
            {
                if (currentRow == 0 && flag) //se inicia la tabla con las dimensiones de las columnas, una por pagina
                {
                    nTables++;

                    Table temp = new Table();
                    temp.Style = TABLE_STYLE;

                    for (int nColumns = start; nColumns <= end; nColumns++)
                    {
                        double widthColum = (maximunLengthForColumns[nColumns] * 0.1666);
                        if (widthColum > TABLE_MAX_WIDTH) widthColum = TABLE_MAX_WIDTH;
                        widthColumAll += widthColum;
                        Column col = temp.AddColumn(widthColum.ToString() + "cm");
                        if (widthColum <= TABLE_MAX_WIDTH && widthColumAll < TABLE_MAX_WIDTH)
                            col.Format.Alignment = ParagraphAlignment.Center;
                        else
                        {
                            col.Format.Alignment = ParagraphAlignment.Justify;
                        }
                    }

                    tables.Add(nTables, new LinkedList<Table>());
                    tables[nTables].AddLast(temp);
                    flag = false;
                }

                if (fRow == nRows) // coloca encabezados despues de colocar los filtros aplicados
                {
                    currentRow++;
                    Table t = tables[nTables].Last.Value;
                    Row row = t.AddRow();
                    row.Shading.Color = Colors.Red;
                    row.Format.Font.Color = Colors.White;


                    Cell cell = null;

                    for (int nColumn = 0; nColumn <= end - start; nColumn++)
                    {
                        cell = row.Cells[nColumn];
                        cell.AddParagraph(getTranslation(data.Columns[nColumn + start].ColumnName, process));
                    }

                }

                fRow++;

                if (start == 0 || fRow > nRows) //Controla espacios en blanco de los filtros
                {
                    string value = "";
                    currentRow++;
                    Row rowx = tables[nTables].Last.Value.AddRow();
                    if (dRow.Equals(last)) // marcar tupla si y solo si es el total
                    {
                        rowx.Shading.Color = totalsColor;
                        rowx.Format.Font.Bold = true;
                    }
                    else
                    {
                        rowx.Shading.Color = Colors.White;
                    }


                    for (int nColumn = 0; nColumn <= end - start; nColumn++) // inserta el valor de la fila delimitada por el inicio y el fin de las columnas
                    {

                        value = dRow[nColumn + start].ToString();
                        value = TranslatorHelper.parseDbValue(value);

                        rowx.Cells[nColumn].AddParagraph(value);
                    }
                }

                if (currentRow == ROWSPERPAGE) // limite de tuplas por pagina
                {
                    currentRow = 0;
                    flag = true;
                    fRow = nRows;
                }

            }

            start = numColum;
        }
    }


}
