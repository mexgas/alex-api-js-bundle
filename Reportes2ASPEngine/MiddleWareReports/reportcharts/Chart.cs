using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Collections.Specialized;
using System.Data;
using System.Xml;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps to transform a DataTable into XMLs 
    /// that can be consumed to create charts.
    /// </summary>
    public static class Chart 
    {

        const string YEAR = "year";
        const string MONTH = "month";
        const string DAY = "day";
        const string HOUR = "hour";
        const string MINUTES = "minutes";
        const string GROUPBYYEAR = "year";
        const string GROUPBYMONTH = "year,month";
        const string GROUPBYDAY = "year,month,day";
        const string GROUPBYHOUR = "year,month,day,hour";
        const string GROUPBYMINUTES = "year,month,day,hour,minutes";
    
        /// <summary>
        /// Transforms a DataTable into a chartXml that has multiple series. The first column is considered 
        /// the x-axis while the last column is intended to be the y-axis value of the inner columns that act as a group.
        /// </summary>
        /// <param name="tableData">The DataTable to be transformed into a chart xml with multiple series.</param>
        /// <returns>A chart xml that specifies a x-axis and also various series with different y values.</returns>
        public static XmlDocument transformToMultipleSeriesXml(DataTable tableData)
        {
            LinkedList<string> columns = new LinkedList<string>();
            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            XmlElement chart = xml.CreateElement("", "Chart", "");
            chart.SetAttribute("type", "2");
            xml.AppendChild(chart);

            //Translate columns, only translated columns will appear in the collection
            NameValueCollection translatedColumns = TranslatorHelper.translateColumns(tableData.Columns);
                        
            //Get the columns names of the table
            foreach (DataColumn col in tableData.Columns)
            {
                columns.AddLast(col.ColumnName);              
            }
            
            if (columns.Count > 0)
            {
                string xAxis = columns.First.Value; //First column is the first part of the x-axis
                string countColumn = columns.Last.Value;
                string lastXValue = "" ; //Value used to determine if we had moved further into the x-axis
                LinkedList<string> groupByDates = checkIfDateGroupBy(columns); //Determines if the table is ordered on a certain date group
                string xAxisGroupByValue = transformToGroupByColumn(xAxis, groupByDates); // x-axis value 
                XmlElement xfieldXml = null;

                StringBuilder yFieldBuilder = new StringBuilder();
                foreach(string col in columns)
                {
                    if (!col.Equals(xAxis) && !col.Equals(countColumn) && !groupByDates.Contains(col)
                            && translatedColumns[col] != null && translatedColumns[col].Length > 0)
                    {                       
                        //Serie label
                        if (yFieldBuilder.Length == 0)
                        {
                            yFieldBuilder.Append(translatedColumns[col]);
                        }
                        else
                        {
                            yFieldBuilder.Append("-" + translatedColumns[col]);
                        }
                    }                 
                }

                //Create Series
                List<ChartItem> sortedSeries = new List<ChartItem>();
                LinkedList<string> series = new LinkedList<string>();
                XmlElement seriesNode = xml.CreateElement("", "Series", "");

                //Create xAxis node
                XmlElement axisNode = xml.CreateElement("", "Axis", "");
                axisNode.SetAttribute("xname", xAxisGroupByValue);
                axisNode.SetAttribute("yname", yFieldBuilder.ToString());

                foreach (DataRow row in tableData.Rows)
                {
                   
                    StringBuilder yValueBuilder = new StringBuilder();
                    int countSum = -1;

                    foreach (string col in columns)
                    {

                        string tempColumn = valueOfGroupByColumn(xAxis,groupByDates,row);

                        //We have move into the x-axis to another point
                        if (col.Equals(xAxis)  && !lastXValue.Equals(tempColumn))
                        {
                            lastXValue = "";
                        }

                        //Save last xml node and create a new one using the new x-axis value
                        if (lastXValue.Length == 0)
                        {
                            if (xfieldXml != null)
                            {
                                axisNode.AppendChild(xfieldXml);                         
                            }

                            //New XmlNode with current x-axis value
                            xfieldXml = xml.CreateElement("", "Xfield", "");                         
                            xfieldXml.SetAttribute("xvalue", tempColumn);
                            lastXValue = tempColumn;
                        }

                        //If current row´s column is not part of the x-axis add it series value
                        if (!col.Equals(xAxis) && !col.Equals(countColumn) && !groupByDates.Contains(col) 
                            && translatedColumns[col] != null && translatedColumns[col].Length > 0)
                        {
                            if (xfieldXml != null)
                            {                                                            
                                //Serie value
                                if (yValueBuilder.Length == 0)
                                {
                                    yValueBuilder.Append(row[col].ToString());
                                }
                                else
                                {
                                    yValueBuilder.Append("-" + row[col].ToString());
                                }

                                //y-axis value of serie
                                int i = 0;
                                if (countSum < 0 && int.TryParse(row[countColumn].ToString(), out i))
                                {
                                    countSum = i;
                                }

                            }
                        }
                    }

                    String translated = TranslatorHelper.getResource(yValueBuilder.ToString(), true);
                    ChartItem chartItem = new ChartItem(translated, yValueBuilder.ToString());
                    if (!sortedSeries.Contains(chartItem))
                    {
                        sortedSeries.Add(chartItem);
                    }

                    //Create serie node
                    XmlElement yField2 = xml.CreateElement("", "Yfield", "");
                    yField2.SetAttribute("yvalue", chartItem.yValue);                    
                    if (countSum == -1) // Column was not found into translated columns
                    {
                        countSum = 0;
                    }
                    yField2.SetAttribute("ycount", countSum.ToString());

                    //Reset serie values to be used in the next row
                    xfieldXml.AppendChild(yField2);                  
                    yValueBuilder = new StringBuilder();
                    countSum = -1;
                }

                sortedSeries.Sort();
                foreach (ChartItem chartItem in sortedSeries)
                {
                    XmlElement serie = xml.CreateElement("", "Serie", "");
                    serie.SetAttribute("value", chartItem.yValue);
                    seriesNode.AppendChild(serie);
                }

                if (xfieldXml != null)
                {                    
                    axisNode.AppendChild(xfieldXml);                    
                }

                if(axisNode != null)
                {
                    xml.ChildNodes.Item(1).AppendChild(axisNode);
                }

                if (seriesNode != null)
                {
                    xml.ChildNodes.Item(1).AppendChild(seriesNode);
                }
                
            }
            return xml;
        }

        /// <summary>
        /// Transforms a DataTable into a xmlChart with only one serie. The first and subsequent columns are considered
        /// the x-axis while the last column is considered to be its value in the y-axis.
        /// </summary>
        /// <remarks>
        /// The following columns: year,month,day,hour and minutes are grouped automatically and considered as 
        /// only one single column.
        /// </remarks>
        /// <param name="tableData">The DataTable to be transformed into a chart xml with only one serie</param>
        /// <returns>A xml that contains only one serie</returns>
        public static XmlDocument transformToOneSerieXml(DataTable tableData)
        {
            LinkedList<string> columns = new LinkedList<string>();
            XmlDocument xml = new XmlDocument();
            xml.AppendChild(xml.CreateNode(XmlNodeType.XmlDeclaration, "", ""));
            XmlElement chart = xml.CreateElement("", "Chart", "");
            chart.SetAttribute("type", "1");
            xml.AppendChild(chart);

            //Translate columns, only translated columns will appear in the collection
            NameValueCollection translatedColumns = TranslatorHelper.translateColumns(tableData.Columns);

            //Get the columns of the table
            foreach (DataColumn col in tableData.Columns)
            {
                columns.AddLast(col.ColumnName);
            }
                                               
            if (columns.Count > 0)
            {
                StringBuilder xLabel = new StringBuilder();

                //All the columns except the last one are combined into the x-axis
                foreach (string col in columns)
                {
                    if (translatedColumns[col] != null && translatedColumns[col].Length > 0)
                    {
                        xLabel.Append(string.Format("{0}-", translatedColumns[col]));
                    }
                }

                if (xLabel.Length > 0)
                {
                    xLabel.Remove(xLabel.Length - 1, 1);
                }

                //Node that represents the x-axis
                XmlElement axisNode = xml.CreateElement("", "Axis", "");
                axisNode.SetAttribute("xname", xLabel.ToString());
                
                string countColumn = columns.Last.Value;
               
                List<ChartItem> sortedSeries = new List<ChartItem>();

                foreach (DataRow row in tableData.Rows)
                {
                   
                    StringBuilder xValue = new StringBuilder();

                    //All the columns except the last one are combined into the x-axis
                    foreach (string col in columns)
                    {
                        if (translatedColumns[col] != null && translatedColumns[col].Length > 0)
                        {                        
                            xValue.Append(string.Format("{0}-", row[col]));
                        }
                    }

                    if (xValue.Length > 0)
                    {
                        xValue.Remove(xValue.Length - 1, 1);
                    }

                    //Node that represents a point in the x axis

                    ChartItem chartItem = new ChartItem(xValue.ToString(), row[countColumn].ToString(), xValue.ToString());
                    sortedSeries.Add(chartItem);
                }

                sortedSeries.Sort();
                foreach (ChartItem chartItem in sortedSeries)
                {
                    XmlElement xfieldXml = xml.CreateElement("", "Xfield", "");
                    xfieldXml.SetAttribute("xvalue", chartItem.xValue);
                    xfieldXml.SetAttribute("yvalue", chartItem.yValue);
                    axisNode.AppendChild(xfieldXml);
                }

                if (axisNode != null)
                {
                    xml.ChildNodes.Item(1).AppendChild(axisNode);
                }
            }
            return xml;
        }

        /// <summary>
        /// Transforms a column, along with the date columns into a single valued column
        /// </summary>
        /// <remarks>
        /// If the xAxis column is part of the date columns, it is only considered once in the final value
        /// </remarks>
        /// <param name="xAxis">Column considered the x-axis</param>
        /// <param name="dateColumns">Group of columns forming a date</param>        
        /// <returns>The value of appending all the columns with a '-'</returns>
        private static string transformToGroupByColumn(string xAxis,LinkedList<string> dateColumns)
        {
            string result = TranslatorHelper.getResource(xAxis) ;
            bool ignoreXaxis = false;

            if (dateColumns.Contains(xAxis))
            {
                result = "";
                ignoreXaxis = true;
            }
            foreach (string col in dateColumns)
            {
                if (ignoreXaxis)
                {
                    result += TranslatorHelper.getResource(col);
                    ignoreXaxis = false;
                }
                else
                {
                    result += "-" + TranslatorHelper.getResource(col);
                }
            }
            return result;
        }

        /// <summary>
        /// Method that gets the value of the group by clause as if there was a column named after it. 
        /// If a time period column is part of the xAxis, its value is only place once.
        /// </summary>
        /// <param name="xAxis">Value of the xAxis</param>
        /// <param name="dateColumns">A group time period ex: {Month,day,hour,minutes}</param>
        /// <param name="row">Row from wich the value will be retrieved</param>
        /// <returns>The appended values of the columns in the group by clause for the current row</returns>
        private static string valueOfGroupByColumn(string xAxis, LinkedList<string> dateColumns,DataRow row)
        {
            string result = "";
            bool ignoreXaxis = false;

            if (dateColumns.Contains(xAxis))
            {
                result = "";
                ignoreXaxis = true;
            }
            else
            {
                result += row[xAxis];
            }

            foreach (string col in dateColumns)
            {
                if (ignoreXaxis)
                {                   
                    result += row[col].ToString();
                    ignoreXaxis = false;
                }
                else
                {
                    result += "-" + row[col].ToString();
                }
            }

            return result;           
        }

        /// <summary>
        /// Method that checks if a table contains some key columns that define a time group as specified in the 
        /// reports database schema.
        /// </summary>
        /// <remarks>
        /// Searches for the following columns : year,month,day,hour and minutes
        /// </remarks>
        /// <param name="columns">The collection of columns that will be checked</param>
        /// <returns>A collection of the time measures that where found in the initial column list</returns>
        private static LinkedList<string> checkIfDateGroupBy(LinkedList<string> columns)        
        {
            LinkedList<string> result = new LinkedList<string>();            
            string[] dateGroups = { YEAR, MONTH, DAY, HOUR, MINUTES };
            foreach (string group in dateGroups)
            {
                if(columns.Contains(group))
                {
                   result.AddLast(group);
                }
            }

            return result;
        }
    }
}
