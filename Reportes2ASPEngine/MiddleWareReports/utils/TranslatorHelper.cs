using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Globalization;
using System.Data;
using System.Collections.Specialized;
using System.Xml;
using System.Resources;
using System.Reflection;
using System.IO;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that searches for an asset and returns its value according to the currently selected culture
    /// </summary>
    public static class TranslatorHelper
    {
        /// <summary>
        /// Resource that wants to be translated
        /// </summary>
        /// <param name="resource">Resource to be translated</param>
        /// <param name="correctUntranslated">If the resource is not translated, it returns the original resource</param>
        /// <returns>The translated string of the resource, otherwise an error message if it was not found</returns>
        /// <example>
        /// getResource("year"); //If current culture is es-MX result is año
        /// getResource("run") ; // If word is not translated result is given like this INVALID_PROPERTY_run
        /// getResource("Dial report"); //Accept words with spaces, result = "Reporte de llamada"
        /// </example>
        public static string getResource(string resource, bool correctUntranslated = false)
        {
            bool isTranslated;
            string translated = getResourceProperty(resource.Replace(" ", ""), out isTranslated);
            if (correctUntranslated && !isTranslated)
            {
                translated = resource;
            }
            return translated;
        }

        /// <summary>
        /// Returns the translated values of a collumn collection, containing only the ones that were translated
        /// and a the original column name as a key
        /// </summary>
        /// <param name="tableColumns">The columns to be translated</param>
        /// <param name="isDetail">valid if the report is to detail</param>
        /// <returns>
        /// A NameValue collection containing the columns that could be translated
        /// and with their original column name as their key
        /// </returns>
        public static NameValueCollection translateColumns(DataColumnCollection tableColumns, short process = 0, bool isDetail = false)
        {
            bool isTranslated;
            NameValueCollection translatedColumns = new NameValueCollection();
            foreach (DataColumn column in tableColumns)
            {
                string property = getResourceProperty(column.ColumnName, out isTranslated, isDetail);
                //Only add columns that can be viewable in the interface 
                if (((!property.Contains("_")) || (isPivotColumn(property) && !property.StartsWith("systemTranslated_"))) && !(process < 10000 && process >= 9000)) //Don't show not translated columns
                {
                    translatedColumns.Add(column.ColumnName, getResourceProperty(column.ColumnName, out isTranslated, isDetail));
                }
                else if (process < 10000 && process >= 9000)
                {
                    if (column.ColumnName == "crmx_Date" || column.ColumnName == "crmxSource" || column.ColumnName.StartsWith("crmx_"))
                    {
                        string column_name = column.ColumnName != "crmx_Date" && column.ColumnName.StartsWith("crmx_") ? column.ColumnName.Replace("crmx_", "") : column.ColumnName;
                        property = getResourceProperty(column_name, out isTranslated, isDetail);
                        if (!property.Contains("_")) //Don't show not translated columns
                            translatedColumns.Add(column.ColumnName, property);
                    }
                    else if (column.ColumnName != "rownum")
                        translatedColumns.Add(column.ColumnName, column.ColumnName);
                }
            }
            return translatedColumns;
        }

        public static NameValueCollection convertColumns(DataColumnCollection tableColumns)
        {
            NameValueCollection convertedColumns = new NameValueCollection();

            foreach (DataColumn column in tableColumns)
            {
                try
                {
                    Type sourceType = typeof(MiddleWareReports.Convertions);
                    var property = sourceType.GetProperty(column.ColumnName);
                    object result = property.GetValue(property, null);
                    if (result is string)
                    {
                        if (result.ToString() == "convertToTime")
                        {
                            convertedColumns.Add(column.ColumnName, result.ToString());
                        }
                    }
                }
                catch (Exception ex)
                {
                    string msg = ex.Message;
                    if (column.ColumnName.Contains("_Time"))
                    {
                        convertedColumns.Add(column.ColumnName, "convertToTime");
                    }
                }
            }

            return convertedColumns;
        }

        /// <summary>
        /// Formats the given date to the current culture format
        /// </summary>
        /// <param name="date">The date to be formated</param>
        /// <returns>The date formated in the current culture format</returns>
        public static string formatDate(DateTime date)
        {
            return string.Format(Thread.CurrentThread.CurrentCulture.DateTimeFormat.FullDateTimePattern, date);
        }

        /// <summary>
        /// Formats the given amount of seconds to the format HH:MM:SS
        /// </summary>
        /// <param name="seconds">The amount of seconds to be formated</param>
        /// <returns>The time formated string</returns>
        public static string formatTime(int seconds)
        {
            return string.Format("{0:00}:{1:00}:{2:00}", Convert.ToInt32(seconds) / 3600, (Convert.ToInt32(seconds) / 60) % 60, Convert.ToInt32(seconds) % 60);
        }
        public static string formatTime(long seconds)
        {
            return string.Format("{0:00}:{1:00}:{2:00}", Convert.ToInt64(seconds) / 3600, (Convert.ToInt64(seconds) / 60) % 60, Convert.ToInt64(seconds) % 60);
        }
        /// <summary>
        /// Parses database values to current culture format if necessary.
        /// </summary>
        /// <param name="dbValue">The value that must be parsed</param>       
        /// <returns>The value of the object in the current culture format</returns>
        public static string parseDbValue(object dbValue)
        {
            string value = "";
            if (dbValue is System.DateTime)
            {
                try
                {
                    DateTime date = (DateTime)dbValue;
                    value = date.ToString(CultureInfo.CurrentCulture);
                }
                catch (Exception ex)
                {
                    string parseDbValue = ex.Message;
                    value = dbValue.ToString();
                }
            }
            else
            {
                value = dbValue.ToString();
            }
            return value;
        }



        /// <summary>
        /// Tries to get the specified property from the current culture resources file
        /// </summary>
        /// <param name="propertyName">The property to search</param>
        /// <param name="isTranslated">Indicates if the property was found into the current culture resources file</param>
        /// <returns>The value of the property or an INVALID_PROPERTY_propertyName message if not found</returns>
        public static string getResourceProperty(string propertyName, out bool isTranslated, bool isDetail = false)
        {
            string original = propertyName;
            propertyName = propertyName.Replace(" ", "");
            string value = "INVALID_PROPERTY_" + propertyName;
            isTranslated = false;
            try
            {
                Type sourceType = typeof(MiddleWareReports.Resources);
                var property = sourceType.GetProperty(propertyName);
                object result = property.GetValue(property, null);
                if (result is string)
                {
                    value = result.ToString();
                    isTranslated = true;
                }
            }
            catch (Exception ex)
            {
                string getResourceProperty = ex.Message;
                if (isPivotColumn(propertyName))
                {
                    value = original;
                }
                else if (isDetail)
                {
                    value = getResourcePropertyDetail(propertyName, isTranslated);
                }
                else if (isNumeric(propertyName))
                {
                    value = propertyName.Trim();
                }
            }
            return value;
        }

        /// <summary>
        /// Tries to get the specified property from the current culture resources file
        /// </summary>
        /// <param name="propertyName">The property to search</param>
        /// <param name="isTranslated">Indicates if the property was found into the current culture resources file</param>
        /// <returns>The value of the property or an INVALID_PROPERTY_propertyName message if not found</returns>
        private static string getResourcePropertyDetail(string propertyName, bool isTranslated)
        {
            //Thread.CurrentThread.CurrentCulture = new CultureInfo("pt-BR");
            //Thread.CurrentThread.CurrentUICulture = new CultureInfo("pt-BR");
            string original = propertyName;
            propertyName = propertyName.Replace(" ", "");
            string value = "INVALID_PROPERTY_" + propertyName;
            isTranslated = false;
            try
            {
                Type sourceType = typeof(MiddleWareReports.ResourcesDetail);
                var property = sourceType.GetProperty(propertyName);
                object result = property.GetValue(property, null);
                if (result is string)
                {
                    value = result.ToString();
                    isTranslated = true;
                }
            }
            catch (Exception) { }
            return value;
        }

        /// <summary>
        /// Removes the untranslated columns of a table
        /// </summary>
        /// <param name="table">The table to be altered</param>
        /// <returns></returns>
        public static void removeUntranslatedTableColumns(DataTable table, short process = 0)
        {
            LinkedList<string> columnsToRemove = new LinkedList<string>();
            foreach (DataColumn column in table.Columns)
            {
                bool isTranslated;
                string property = getResourceProperty(column.ColumnName, out isTranslated);
                //Only add columns that can be viewable in the interface 
                if ((!property.Contains("_")) || isPivotColumn(property))
                {
                    continue;
                }
                else if (process < 10000 && process >= 9000)
                {
                    if (column.ColumnName == "crmx_Date" || column.ColumnName == "crmxSource" || column.ColumnName.StartsWith("crmx_"))
                    {
                        string column_name = column.ColumnName != "crmx_Date" && column.ColumnName.StartsWith("crmx_") ? column.ColumnName.Replace("crmx_", "") : column.ColumnName;
                        property = getResourceProperty(column_name, out isTranslated);
                        if (!property.Contains("_")) //Don't show not translated columns
                            continue;
                    }
                    else if (column.ColumnName != "rownum")
                        continue;
                }
                else
                {
                    columnsToRemove.AddLast(column.ColumnName);
                }
            }

            foreach (string column in columnsToRemove)
            {
                table.Columns.Remove(column);
            }

        }

        /// <summary>
        /// Gets the translation of column in case pivot
        /// </summary>
        /// <param name="column">The column name to evaluate</param>  
        /// <returns>The value translated in case necessary or the original one</returns> 
        public static string getPivotTranslatedColumns(string columnName)
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
                    columnName = partNotToTranslate + partTraslated.Replace('_', ' ');
            }

            return columnName;
        }
        

        /// <summary>
        /// Indicates if the specified column is a pivot column
        /// </summary>
        /// <param name="column">The name of the column to be tested</param>
        /// <returns>The value that indicates if the column is a pivot column</returns>
        private static bool isPivotColumn(string column)
        {
            return (column.EndsWith("_Count") || column.EndsWith("_Time") || column.EndsWith("_Avg") || column.EndsWith("_UnCount"));
        }

        private static bool isNumeric(string number)
        {
            int result;
            return int.TryParse(number, out result);
        }
    }
}
