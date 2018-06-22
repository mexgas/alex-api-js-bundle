using System;
using System.Text;
using System.Text.RegularExpressions;
using System.Reflection;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Globalization;

namespace MiddleWareReports
{
    /// <summary>
    /// Class used to manage the group times that can be handled by the application
    /// </summary>
    public static class TimePeriodGroup
    {

        /// <summary>
        /// Test if the column is part of the TimePeriod Enum
        /// </summary>
        /// <param name="col">Column name to be tested</param>
        /// <returns>True if the column is contained in the TimePeriod Enum, otherwise false</returns>
        public static bool isTimePeriod(string col)
        {
            col = col.ToLowerInvariant();
            foreach (TimePeriod t in Enum.GetValues(typeof(TimePeriod)))
            {
                if (col.Equals(GetStringValue(t)))
                {
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// Expands a TimePeriod column into its select statement
        /// </summary>
        /// <param name="col">Column to be expanded</param>
        /// <returns>The expanded query to get the specified column</returns>
        public static string expandTimePeriodSelect(string col)
        {
            col = col.ToLowerInvariant();
            foreach (TimePeriod t in Enum.GetValues(typeof(TimePeriod)))
            {
                if (col.Equals(GetStringValue(t)))
                {
                    TimePeriodSelectValue tpsv = (TimePeriodSelectValue)Enum.Parse(typeof(TimePeriodSelectValue), GetStringValue(t), true);
                    return GetStringValue(tpsv) + " as [" + GetStringValue(t) + "]";
                }
            }
            return col;
        }

        public static string insertDateColumn(TimePeriod t, bool isPivotReport, NameValueCollection values, CultureInfo currentCulture)
        {
            TimePeriodDateValue timeDate = (TimePeriodDateValue)Enum.Parse(typeof(TimePeriodDateValue), GetStringValue(t), true);
            if (t <= TimePeriod.H)
            {
                if (isPivotReport)
                    return " convert(smalldatetime,convert(varchar(14),min([date]),121) + '' + ''cast(" + GetStringValue(timeDate).Replace("'", "") + " as varchar)'' + '') as [date]";

                return " convert(smalldatetime,convert(varchar(14),min([date]),121) + " + GetStringValue(timeDate) + ") as [date]";
            }

            if (t == TimePeriod.D)
                return GetStringValue(timeDate) + " as [date]";
            if (t == TimePeriod.PE)
            {
                string dateStart = DateTime.Parse(values["@dateStart"]).ToString(currentCulture);
                string dateEnd = DateTime.Parse(values["@dateEnd"]).ToString(currentCulture);
                return String.Format("'{0} - {1}' as [date]", dateStart, dateEnd);
            }
            if (t == TimePeriod.M)
                return GetStringValue(timeDate) + " as [date]";
            return "min(date) as [date]";

        }

        /// <summary>
        /// Given a column list, inserts the necessary time columns to fit the GROUP BY operation
        /// </summary>
        /// <param name="columns">The original columns used in the query</param>
        /// <param name="timePeriod">The time period grouping to be used</param>
        /// <returns>The original columns plus the necessary time columns appended at the start of the list</returns>
        public static LinkedList<string> insertTimePeriodColumns(LinkedList<string> columns, string timePeriod)
        {
            timePeriod = timePeriod.ToLowerInvariant();
            TimePeriod t = (TimePeriod)Enum.Parse(typeof(TimePeriod), timePeriod, true);

            string[] cols;

            if (t <= TimePeriod.HH)
            {
                cols = new string[] { "minutes", "hour", "day", "month", "year" };
            }
            else if (t == TimePeriod.H)
            {
                cols = new string[] { "hour", "day", "month", "year" };
            }
            else if (t == TimePeriod.D)
            {
                cols = new string[] { "day", "month", "year" };
            }
            else if (t == TimePeriod.M)
            {
                cols = new string[] { "month", "year" };
            }
            else if (t >= TimePeriod.SE)
            {
                cols = new string[] { "month", "year" };
            }
            else //TimePeriod.Y
            {
                cols = new string[] { "year" };
            }

            foreach (string tp in cols)
            {
                if (columns.Contains(tp))
                {
                    columns.Remove(tp);
                }

                columns.AddFirst(tp);
            }

            return columns;
        }

        /// <summary>
        /// Given a group by the necessary time columns to fit the GROUP BY operation
        /// </summary>
        /// <param name="timePeriod">The time period grouping to be used</param>
        /// <param name="groupByColumns">group by columns filter</param>
        /// <returns>Construction of the group by the columns needed</returns>
        public static string insertGroupByColumns(string timePeriod, string groupByColumns)
        {
            timePeriod = timePeriod.ToLowerInvariant();
            TimePeriod t = (TimePeriod)Enum.Parse(typeof(TimePeriod), timePeriod, true);
            if (t == TimePeriod.PE)
            {
                return String.Format("GROUP BY {0}", groupByColumns);
            }
            string groupby = "GROUP BY [year], [month], [day]";
            if (t == TimePeriod.HH || t == TimePeriod.QH)
            {
                TimePeriodSelectValue timePeriodSelect = (TimePeriodSelectValue)Enum.Parse(typeof(TimePeriodSelectValue), GetStringValue(t), true);
                groupby += ", [hour], " + GetStringValue(timePeriodSelect);
            }
            else if (t == TimePeriod.M) {
                groupby += ",CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + '-01', 121)";
            }
            else if (t == TimePeriod.H) groupby += ", [hour]";

            groupby += ", " + groupByColumns;

            return groupby;
        }


        public static LinkedList<string> columnsTimePeriod(LinkedList<string> columns, string originalTimePeriodCol, string complementGroupBy, bool isPivotReport, NameValueCollection values, CultureInfo currentCulture)
        {
            Dictionary<string, string> dictionaryComplementGroupBy = new Dictionary<string, string>();
            LinkedList<string> columnsAux = new LinkedList<string>();
            TimePeriod t = (TimePeriod)Enum.Parse(typeof(TimePeriod), originalTimePeriodCol, true);
            string dateColumn = TimePeriodGroup.insertDateColumn(t, isPivotReport, values, currentCulture);
            string[] colsTimePeriod = complementGroupBy.Split('|');
            string[] aux;
            string key;
            string value;
            LinkedList<string> columnsTimePeriod = new LinkedList<string>();
            foreach (string col in colsTimePeriod)
            {
                if (col.Contains(":"))
                {
                    aux = col.Split(':');
                    if (columns.Count > 0 && aux.Length == 3 && aux[2] == "pivotGroup")
                    {
                        columns.AddLast("[" + aux[1] + "]");
                    }
                    value = Regex.Replace(aux[0], @"_([^(count|avg|time)]|[\d|TIMEGROUP|\s]+)", ",$1") + " AS [" + aux[1] + "]";
                    key = "[" + aux[1] + "]";
                }
                else
                {
                    value = key = "[" + col + "]";
                }
                dictionaryComplementGroupBy.Add(key, value);
            }
            if (t != TimePeriod.PE)
            {
                dictionaryComplementGroupBy.Add("[year]", "[year]");
                dictionaryComplementGroupBy.Add("[month]", "[month]");
                dictionaryComplementGroupBy.Add("[day]", "[day]");
                if (t == TimePeriod.D)
                {
                    dictionaryComplementGroupBy.Add("[hour]", "0 AS [hour]");
                    dictionaryComplementGroupBy.Add("[minutes]", "0 AS [minutes]");
                }
                else if (t == TimePeriod.H)
                {
                    dictionaryComplementGroupBy.Add("[hour]", "min([hour]) AS [hour]");
                    dictionaryComplementGroupBy.Add("[minutes]", "0 AS [minutes]");
                }
                else // if (t == TimePeriod.HH || t == TimePeriod.QH)
                {
                    dictionaryComplementGroupBy.Add("[hour]", "min([hour]) AS [hour]");
                    dictionaryComplementGroupBy.Add("[minutes]", "min([minutes]) AS [minutes]");
                }
            }

            columnsAux.AddLast(dateColumn);
            bool isFilterColumn = columns.Count > 0 ? true : false;
            foreach (var pair in dictionaryComplementGroupBy)
            {
                if (isFilterColumn)
                {
                    if (columns.Contains(pair.Key) || columns.Contains("_"))
                        columnsAux.AddLast(pair.Value);
                }
                else
                {
                    columnsAux.AddLast(pair.Value);
                }
            }
            return columnsAux;
        }


        /// <summary>
        /// Searches the languages resources for the translation of the time period keyword
        /// </summary>
        /// <param name="col">Time period to be translated</param>
        /// <returns>The translation of the time period column</returns>
        public static string translateTimePeriodKeyWord(string col)
        {
            col = col.ToLowerInvariant();
            foreach (TimePeriod t in Enum.GetValues(typeof(TimePeriod)))
            {
                if (col.Equals(GetStringValue(t)))
                {
                    return TranslatorHelper.getResource(GetStringValue(t));
                }
            }
            return col;
        }

        /// <summary>
        /// Will get the string value for a given enums value, this will
        /// only work if you assign the StringValue attribute to
        /// the items in your enum.
        /// </summary>
        /// <param name="value">Enum from which the string attribute is going to be obtained</param>
        /// <returns>The enum´s value of the StringAttribute</returns>
        public static string GetStringValue(Enum value)
        {
            // Get the type
            Type type = value.GetType();

            // Get fieldinfo for this type
            FieldInfo fieldInfo = type.GetField(value.ToString());

            // Get the stringvalue attributes
            StringValueAttribute[] attribs = fieldInfo.GetCustomAttributes(
                typeof(StringValueAttribute), false) as StringValueAttribute[];

            // Return the first if there was a match.
            return attribs.Length > 0 ? attribs[0].StringValue : null;
        }
    }

    /// <summary>
    /// Time periods used for grouping in the application
    /// </summary>
    public enum TimePeriod
    {
        [StringValue("qh")]
        QH = 1,  //Quarter hour
        [StringValue("hh")]
        HH = 2,   //Half hour  
        [StringValue("h")]
        H = 3,   //Hour
        [StringValue("d")]
        D = 4,   //Day
        [StringValue("m")]
        M = 5,   //Month 
        [StringValue("y")]
        Y = 6,   //Year
        [StringValue("tr")]
        TR = 7,   //Trimester
        [StringValue("se")]
        SE = 8,   //Semester   
        [StringValue("pe")]
        PE = 9   //Period
    }

    /// <summary>
    /// Time period equivalences in T-SQL, assuming the Table follows the specified columns convention
    /// </summary>
    public enum TimePeriodSelectValue
    {
        [StringValue("(CASE WHEN minutes < 15 THEN 1 WHEN minutes <30 THEN 2 WHEN minutes <45 THEN 3 ELSE 4 END)")]
        QH,
        [StringValue("(CASE WHEN minutes < 30 THEN 1 ELSE 2 END)")]
        HH,
        [StringValue("hour")]
        H,
        [StringValue("day")]
        D,
        [StringValue("month")]
        M,
        [StringValue("year")]
        Y,
        [StringValue("(CASE WHEN month <= 3 THEN 1 WHEN month <=6 THEN 2 WHEN month <= 9 THEN 3 ELSE 4 END)")]
        TR
    }



    public enum TimePeriodDateValue
    {
        [StringValue("(CASE WHEN min(minutes) < 15 THEN '00' WHEN min(minutes) < 30 THEN '15' WHEN min(minutes) < 45 THEN '30' ELSE '45' END)")]
        QH,
        [StringValue("(CASE WHEN min(minutes) < 30 THEN '00' ELSE '30' END)")]
        HH,
        [StringValue("'00'")]
        H,
        [StringValue("convert(datetime,convert(varchar(11),min(date)))")]
        D,
        [StringValue("")]
        PE,
        [StringValue("CONVERT(smalldatetime, CONVERT(varchar(7), [date], 121) + '-01', 121)")]
        M
    }
}
