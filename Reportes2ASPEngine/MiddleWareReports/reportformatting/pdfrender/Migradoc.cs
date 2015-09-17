using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
//using System.Data.DataSetExtensions;
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

        const double PAGE_LEFT_MARGIN   = 2.0;
        const double PAGE_TOP_MARGIN    = 1.5;
        const double PAGE_BOTTOM_MARGIN = 0.7;
        const double HEADER_LEFT_MARGIN = 8.5;
        const double HEADER_MAX_WIDTH   = 10.5;
        const double FOOTER_LEFT_MARGIN = 10.0;
        const double TABLE_TOP_MARGIN   = 6.0;
        const double TABLE_MAX_WIDTH    = 27.0;

        const string HEADER_STYLE = "headerStyle";
        const string FOOTER_STYLE = "footerStyle";
        const string TABLE_STYLE  = "tableStyle";

        const string headerArgbColor = "0xFF4E4E4E";
        const string totalsArgbColor = "0xFF808080";

        Color headerColor;
        Color totalsColor;

        public Migradoc()
        {
            headerColor = Color.Parse(headerArgbColor);
            totalsColor = Color.Parse(totalsArgbColor);
        }
      
        public byte[] getPdfRenderBytes(DataTable table, string reportName, string logoFilePath = "", int nRows = 0)
        {
            Dictionary<int, LinkedList<Table>> tables = tablesToPdfTables(table, nRows);
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
                    /*
                    using System.Threading;
                    Thread thread = new Thread(() => renderPdfPage(pdfPage, xImage, newTable, reportName, pageNumber++, totalPages));
                    thread.Start();
                    while (!thread.IsAlive) ;
                    Thread.Sleep(1);
                    thread.Join();
                    */
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
            // footerParagraph.AddPageField();
            // footerParagraph.AddNumPagesField();

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
            // Style breakStyle = new Style("Break", "Normal");
            // breakStyle.ParagraphFormat.PageBreakBefore = true;
            
            Style tableStyle = new Style(TABLE_STYLE, "Normal");
            tableStyle.Font.Color = Colors.Black;
            tableStyle.Font.Size = "8.5";
            tableStyle.Font.Name = "Arial";
            
            Style headerStyle = new Style(HEADER_STYLE, "Normal");
            //headerStyle.ParagraphFormat.Alignment = ParagraphAlignment.Left;
            headerStyle.Font.Color = headerColor;
            headerStyle.Font.Size = "10";
            // headerStyle.Font.Bold = false;

            Style footerStyle = new Style(FOOTER_STYLE, "Normal");
            headerStyle.Font.Bold = true;
            footerStyle.Font.Size = "8";
            // footerStyle.Font.Underline = Underline.Single;
            // footerStyle.ParagraphFormat.Alignment = ParagraphAlignment.Center;
            
            Document document = new Document();
            document.Styles.Add(tableStyle);
            document.Styles.Add(headerStyle);
            document.Styles.Add(footerStyle);
            // document.Styles.Add(breakStyle);
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

        public Dictionary<int, LinkedList<Table>> tablesToPdfTables(DataTable data, int nRows)
        {
            NameValueCollection convertedColumns = TranslatorHelper.convertColumns(data.Columns);

            //TranslatorHelper.removeUntranslatedTableColumns(data);

            List<int> maximunLengthForColumns = Enumerable.Range(0, data.Columns.Count)
                                                .Select(col => data.AsEnumerable()
                                                .Select(row => row[col]).OfType<string>()
                                                .Max(val => val.Length)).ToList(); // Determina el texto mas largo por columnas

            for (int i = 0; i < maximunLengthForColumns.Count; i++) // compara el texto mas largo contra los headers de la tabla
            {
                string str = TranslatorHelper.getResource(data.Columns[i].ColumnName, true);
                
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
            int start = 0;
            int end = 0;
            int nTables = 0;
           
            for (int i = 0; i < maximunLengthForColumns.Count; i++)
            {
                tempWidth += maximunLengthForColumns[i] * 0.1666;
                if (tempWidth > TABLE_MAX_WIDTH || i == maximunLengthForColumns.Count - 1 ) // determina la cantidad de columnas por hoja
                {
                        int currentRow = 0;
                        int fRow = 0; // filas que se ultilizaran para los filtros
                        bool flag = true;
                        end = i - 1;
                        if (i == maximunLengthForColumns.Count - 1) // En caso de ser las ultimas columnas del reporte
                        {
                            end = maximunLengthForColumns.Count - 1;
                            i = maximunLengthForColumns.Count;
                        }
                        //DataRow last = data.Rows[data.Rows.Count - (1 + nRows)];
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
                                    Column col = temp.AddColumn((maximunLengthForColumns[nColumns] * 0.1666).ToString() + "cm");
                                    col.Format.Alignment = ParagraphAlignment.Center;
                                }
                                                                
                                tables.Add(nTables, new LinkedList<Table>());
                                tables[nTables].AddLast(temp);
                                flag = false;
                            }

                            if (fRow == nRows) // coloca encabezados despues de colocar los filtros aplicados
                            {
                                //Colocar encabezados
                                /**/

                                currentRow++;
                                Row row = tables[nTables].Last.Value.AddRow();
                                row.Shading.Color = Colors.Red;
                                row.Format.Font.Color = Colors.White;


                                Cell cell = null;

                                for (int nColumn = 0; nColumn <= end - start; nColumn++)
                                {
                                    cell = row.Cells[nColumn];
                                    cell.AddParagraph(TranslatorHelper.getResource(data.Columns[nColumn + start].ColumnName, true));
                                }
                                /**/
                            
                            }

                            fRow++;

                            if (start == 0 || fRow > nRows) //Controla espacios en blanco de los filtros
                            {
                                //Colocar tuplas
                                /**/
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

                                    if (convertedColumns[data.Columns[nColumn + start].ColumnName] != null && value != "") // si y solo si la columna tiene transformacion de seg a hh:mm:ss
                                    {
                                        value = TranslatorHelper.formatTime(Convert.ToInt32(value));
                                    }

                                    rowx.Cells[nColumn].AddParagraph(value);
                                }
                                /**/
                            }

                            if (currentRow == ROWSPERPAGE) // limite de tuplas por pagina
                            {
                                currentRow = 0;
                                flag = true;
                                fRow = nRows;
                            }
                            
                        }                 

                        start = i;
                        i--;
                        tempWidth = 0;
                    
                }
            }
                //int columnGroups = data.Columns.Count / COLSPERPAGE;
                //int currentRow = ROWSPERPAGE;
                //Dictionary<int, LinkedList<Table>> tables = new Dictionary<int, LinkedList<Table>>();
                //Dictionary<int, LinkedList<string>> colgs = new Dictionary<int, LinkedList<string>>();
                //int currentColGroup = 0;
                //int groupCounter = 0;
                //string value = "";
                //if (data.Columns.Count % COLSPERPAGE != 0)
                //{
                //    columnGroups++;
                //}          
                //for (int i = 0; i < columnGroups; i++)
                //{
                //    tables.Add(i, new LinkedList<Table>());
                //    colgs.Add(i, new LinkedList<string>());
                //}
                //for (int i = 0; i < data.Columns.Count; i++)
                //{
                //    if (groupCounter == COLSPERPAGE)
                //    {
                //        currentColGroup++;
                //        groupCounter = 0;
                //    }
                //    colgs[currentColGroup].AddLast(data.Columns[i].ColumnName);
                //    groupCounter++;
                //}
                //DataRow last = data.Rows[data.Rows.Count - (1 + nRows)];
                //foreach (DataRow raw in data.Rows)
                //{
                //    if (currentRow == ROWSPERPAGE)
                //    {
                //        currentRow = 0;

                //        for (int i = 0; i < tables.Count; i++)
                //        {
                //            Table temp = new Table();
                //            temp.Style = TABLE_STYLE;
                //            // temp.Borders.Visible = true;                      
                //            // temp.Borders.Width = 1.25;
                //            for (int n = 0; n < colgs[i].Count; n++)
                //            {
                //                Column col = temp.AddColumn(getUnit(TABLE_MAX_WIDTH / ((double)colgs[i].Count)));
                //                col.Format.Alignment = ParagraphAlignment.Center;
                //            }

                //            Row rawz = temp.AddRow();
                //            rawz.Shading.Color = Colors.Red;
                //            rawz.Format.Font.Color = Colors.White;                       
                //            Cell cell = null;
                //            int rowNum = 0;
                //            foreach (string column in colgs[i])
                //            {
                //                cell = rawz.Cells[rowNum];
                //                cell.AddParagraph(TranslatorHelper.getResource(column, true));
                //                rowNum++;
                //            }                        
                //            tables[i].AddLast(temp);
                //        }
                //    }

                //    for (int i = 0; i < tables.Count; i++)
                //    {
                //        Row rawz = tables[i].Last.Value.AddRow();
                //        if (raw.Equals(last))
                //        {
                //            rawz.Shading.Color = totalsColor;
                //            rawz.Format.Font.Bold = true;
                //        }
                //        else
                //        {
                //            rawz.Shading.Color = Colors.White;
                //        }
                //        Cell cell = null;
                //        int rowNum = 0;
                //        foreach (string column in colgs[i])
                //        {
                //            cell = rawz.Cells[rowNum];

                //            value = raw[column].ToString();
                //            value = TranslatorHelper.parseDbValue(value);
                //            if (convertedColumns[column] != null && value != "")
                //            {
                //                value = TranslatorHelper.formatTime(Convert.ToInt32(value));
                //            }

                //            cell.AddParagraph(value);
                //            rowNum++;
                //        }                    
                //    }

                //    currentRow++;
                //}

                return tables;
        }
    }
}
