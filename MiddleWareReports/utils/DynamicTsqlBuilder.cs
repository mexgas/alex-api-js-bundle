using NLog;
using System;
using System.Collections.Generic;
using System.Text;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps in building T-sql queries
    /// </summary>
    public static class DynamicTsqlBuilder
    {
        private static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        #region SQL Clauses

        private const string AND = "AND";
        private const string OR = "OR";
        private const string BETWEEN = "BETWEEN";
        private const string GROUPBY = "GROUP BY";
        private const string ORDERBY = "ORDER BY";
        private const string ASCENDING = "ASC";
        private const string DESCENDING = "DESC";
        private const string ROWNUM = "rownum";


        #endregion SQL Clauses

        #region SQL Clauses Methods

        /// <summary>
        /// Creates a SELECT statement
        /// </summary>
        /// <param name="parameters">The columns to be selected</param>
        /// <param name="tableName">The name of the table to be queried</param>
        /// <param name="addRowNum">Indicates if row numbers must be added for paging</param>
        /// <param name="addCountColumn">Indicates if a count column must be added for charts</param>
        /// <param name="dynamicQuery">The created dynamic query to be used</param>
        /// <returns></returns>
        public static StringBuilder selectFromStatement(LinkedList<string> parameters, string tableName, bool addRowNum, bool addCountColumn, string countColumn, string pivotColumns, string complementColumns, string where, string pivotFunction, bool isTimePeriod, string groupByColumns, DynamicQuery dynamicQuery, string dateColumnName, bool isGroupPivot)
        {
            if (pivotColumns != "" && complementColumns != "" && !addCountColumn)
            {
                string[] pivotColumnsArray = pivotColumns.Split('|');
                string[] complementColumnsArray = GetFilterColumnsPivot(parameters, complementColumns.Split('|'));

                return GetPivotColumns(pivotColumnsArray, tableName, complementColumnsArray, addRowNum, where, pivotFunction, isTimePeriod, parameters, groupByColumns, dynamicQuery, isGroupPivot);
            }
            else
            {
                return SelectReportFromStatement(parameters, tableName, addRowNum, addCountColumn, countColumn, isTimePeriod, dynamicQuery, dateColumnName);
            }
        }

        /// <summary>
        /// Starts the where statement with a clause that verifies that a date is between two dates
        /// </summary>
        /// <param name="dateStart">Records must be greater or equal to this date</param>
        /// <param name="dateEnd">Records must be lesser or equal to this date</param>
        /// <returns>A where statement that searches for rows between a start date and an end date</returns>
        /// <remarks>Example: WHERE date >= @dateStart AND date &gt; @dateEnd </remarks>
        public static StringBuilder WhereDateStatement(DateTime dateStart, DateTime dateEnd)
        {
            StringBuilder statement = new StringBuilder();
            statement.AppendLine(string.Format("\t WHERE {0} >= '{1}' AND {0} <= '{2}'  ", "date", dateStart.ToString("yyyy-MM-dd HH:mm:ss"), dateEnd.ToString("yyyy-MM-dd HH:mm:ss")));
            return statement;
        }

        /// <summary>
        /// Takes a query and wraps it in another query that only takes the rows with a rownumber value corresponding to the passed page number.
        /// First row = (pageNumber * pageSize)  | Last row =( (pageNumber + 1) * pageSize)
        /// </summary>
        /// <param name="queryWithRowNum">A query that contains a rownum column</param>
        /// <param name="pageSize">Number of results per page</param>
        /// <param name="pageNumber">Page number</param>
        /// <param name="dynamicQuery">The created dynamic query to be used</param>
        /// <returns>A query that only selects the rows contained into the given page</returns>
        public static StringBuilder AddPaging(StringBuilder queryWithRowNum, string reportName, int pageSize, int pageNumber, bool isPivot, bool isTimePeriod, DynamicQuery dynamicQuery)
        {
            if (pageNumber > 0)
            {
                pageNumber--;
            }

            StringBuilder statement = new StringBuilder();
            if (isPivot)
            {
                statement.Append(string.Format(" {0}) AS A_GROUP", queryWithRowNum));
            }
            else if (isTimePeriod && !dynamicQuery.IsTotals)
            {
                statement.Append(string.Format(" {0}) AS B_GROUP", queryWithRowNum));
            }
            else
            {
                string columns = "*";
                if (dynamicQuery.IsTotals)
                {
                    columns = dynamicQuery.TotalColumns;
                }
                statement.AppendLine(string.Format(" SELECT {0} FROM ({1} {2}) AS C_GROUP", columns, queryWithRowNum, Environment.NewLine));
            }

            if (dynamicQuery.SqlPaginate.Length == 0 && !dynamicQuery.IsTotals)
            {
                dynamicQuery.SqlPaginate = statement.ToString().Trim();
            }

            string pageInfo = string.Format("\r\n WHERE {0} > {1} AND {0} <= {2} ", ROWNUM, pageSize * pageNumber, pageSize * (pageNumber + 1));

            if (!dynamicQuery.IsTotals)
            {
                statement.Append(pageInfo);
            }

            if (isPivot)
            {
                statement.Append("''");
            }
            return statement;
        }

        /// <summary>
        /// Prepends a statement with an AND and encloses it in parentheses
        /// </summary>
        /// <param name="statement">The statement to be enclosed and prepended with an AND</param>
        /// <returns>The statement between parentheses and prepended by an AND</returns>
        public static StringBuilder AndConjunction(StringBuilder statement)
        {
            return ConjunctionStatement(AND, statement);
        }

        /// <summary>
        /// Prepends a statement with an OR and encloses it in parentheses
        /// </summary>
        /// <param name="statement">The statement to be enclosed and prepended with an OR</param>
        /// <returns>The statement between parentheses and prepended by an OR</returns>
        public static StringBuilder OrConjunction(StringBuilder statement)
        {
            return ConjunctionStatement(OR, statement);
        }

        /// <summary>
        /// Given a collection of values, separated by | , creates various equality statements concatenated
        /// by AND statements.
        /// </summary>
        /// <param name="parameter">The parameter to be used in the equality statement</param>
        /// <param name="value">A serie of values separated by | that will be used to create equality statements</param>
        /// <returns>
        /// A serie of equality statements equal to the number of elements in the value that compare to the
        /// specified parameter and concatenated with AND operators
        /// </returns>
        /// <example><code>andStatement("name","john|ana|ron"); // name = 'john' AND name = 'ana' AND name = 'ron'</code></example>
        /// <seealso cref="DynamicTsqlBuilder.BooleanStatement"/>
        public static StringBuilder AndStatement(string parameter, string value)
        {
            return BooleanStatement(AND, parameter, value);
        }

        /// <summary>
        /// Given a collection of values, separated by | , creates various equality statements concatenated
        /// by AND statements.
        /// </summary>
        /// <param name="parameter">The parameter to be used in the equality statement</param>
        /// <param name="value">A serie of values separated by | that will be used to create equality statements</param>
        /// <returns>
        /// A serie of equality statements equal to the number of elements in the value that compare to the
        /// specified parameter and concatenated with AND operators
        /// </returns>
        /// <example><code>andStatement("name","john|ana|ron"); // name = 'john' AND name = 'ana' AND name = 'ron'</code></example>
        /// <seealso cref="DynamicTsqlBuilder.BooleanStatement"/>
        public static StringBuilder AndStatement(string parameter, string value, string op)
        {
            StringBuilder stament = new StringBuilder();
            stament.Append(string.Format("{0} {1} {2}", parameter, TranslateOperator(op), value));

            return ConjunctionStatement(AND, stament);
        }

        /// <summary>
        /// Given a collection of values, separated by | , creates various equality statements concatenated
        /// by OR statements.
        /// </summary>
        /// <param name="parameter">The parameter to be used in the equality statement</param>
        /// <param name="value">A serie of values separated by | that will be used to create equality statements</param>
        /// <returns>
        /// A serie of equality statements equal to the number of elements in the value that compare to the
        /// specified parameter and concatenated with OR operators
        /// </returns>
        /// /// <example><code>orStatement("name","john|ana|ron"); // name = 'john' OR name = 'ana' OR name = 'ron'</code></example>
        ///  <seealso cref="DynamicTsqlBuilder.BooleanStatement"/>
        public static StringBuilder OrStatement(string parameter, string value)
        {
            return BooleanStatement(OR, parameter, value);
        }

        /// <summary>
        /// Create operator between with parameter min and max
        /// </summary>
        /// <param name="parameter">The parameter to be used in the equality statement</param>
        /// <returns>
        /// Statement the operator BETWEEN parameter
        /// </returns>
        public static StringBuilder BetweenStatement(string parameter)
        {
            return new StringBuilder().Append(string.Format(" {0} {1} {3} {2} {4} ", parameter, BETWEEN, AND, "@" + parameter + "Min", "@" + parameter + "Max"));
        }

        /// <summary>
        /// Creates a GROUP BY statement with the given columns
        /// </summary>
        /// <param name="columns">The columns that conform the GROUP BY statement</param>
        /// <returns>A GROUP BY statement using the columns passed in the parameter</returns>
        public static StringBuilder GroupByStatement(LinkedList<string> columns)
        {
            return AggregateByStatement(GROUPBY, columns);
        }

        /// <summary>
        /// Creates an ORDER BY statement with the given columns in ascending order
        /// </summary>
        /// <param name="columns">The columns that conform the ORDER BY statement</param>
        /// <returns>An ORDER BY statement using the columns passed in the parameter in ascending order</returns>
        public static StringBuilder OrderByAscStatement(LinkedList<string> columns)
        {
            return OrderByStatementPrivate(columns, ASCENDING);
        }

        /// <summary>
        /// Creates an ORDER BY statement with the given columns in descending order
        /// </summary>
        /// <param name="columns">The columns that conform the ORDER BY statement</param>
        /// <returns>An ORDER BY statement using the columns passed in the parameter in descending order</returns>
        public static StringBuilder OrderByDescStatement(LinkedList<string> columns)
        {
            return OrderByStatementPrivate(columns, DESCENDING);
        }

        /// <summary>
        /// Creates an ORDER BY statement with the given columns with no specific order
        /// </summary>
        /// <param name="columns">The columns that conform the ORDER BY statement</param>
        /// <returns>An ORDER BY statement using the columns passed in the parameter with no specific order</returns>
        public static StringBuilder OrderByStatement(LinkedList<string> columns)
        {
            return OrderByStatementPrivate(columns);
        }

        /// <summary>
        /// Makes a count query to the table specified
        /// </summary>
        /// <param name="dynamicQuery">The created dynamic query to be used in the count query</param>
        /// <returns>The text to make a count query to the specified table</returns>
        public static StringBuilder Paginate(DynamicQuery dynamicQuery)
        {
            return new StringBuilder(string.Format(" SELECT count(*) FROM {0}", dynamicQuery.SqlPaginate));
        }

        /// <summary>
        /// Selects one row from a table to get its colummns
        /// </summary>
        /// <param name="tableName">The table to be used in the query</param>
        /// <returns>The text to select 1 row from the specified table</returns>
        public static StringBuilder GetTableColumns(string tableName)
        {
            return new StringBuilder(string.Format("SELECT TOP 1 * FROM [dbo].[{0}] ", tableName));
        }

        /// <summary>
        /// Gets the columns to be used for the totals query
        /// </summary>
        /// <param name="process">Id of the report to be searched</param>
        /// <returns>The text indicating the columns to be used for the totals query</returns>
        public static StringBuilder GetTotalColumns(short process)
        {
            return new StringBuilder(string.Format("SELECT TotalColumns FROM ReportsTotals WHERE Id={0}", process));
        }

        /// <summary>
        /// Creates a HAVING  statement with the given operator and value
        /// </summary>
        /// <param name="havingOp">Operator to be used in the statement</param>
        /// <param name="havingVal">Value to be compared with the COUNT(*)</param>
        /// <remarks>
        /// Accepted operators: e = '=' , ne = '&lt;&gt;' l = '&lt;' , g = '&gt;' , le = '&lt;=' , ge= '&gt;='
        /// </remarks>
        ///<example><code></code> having("ge", 5) ; // HAVING COUNT(*) >= 5  </example>
        /// <returns>A HAVING  statement with  the passed operator and value</returns>
        public static StringBuilder Having(string havingOp, int havingVal)
        {
            StringBuilder statement = new StringBuilder();
            string validOperator = "";
            validOperator = TranslateOperator(havingOp);

            if (validOperator.Length > 0)
            {
                statement.Append(string.Format(" HAVING count(*) {0} {1} ", validOperator, havingVal));
            }

            return statement;
        }

        #endregion SQL Clauses Methods

        #region Private Methods

        /// <summary>
        /// Helps creating an ORDER BY statement
        /// </summary>
        /// <param name="columns">Columns used in the order by</param>
        /// <param name="orderType">ASC | DESC | Nothing</param>
        /// <returns>An ORDER BY statement using the columns passed and the ordering type specified</returns>
        private static StringBuilder OrderByStatementPrivate(LinkedList<string> columns, string orderType = "")
        {
            return AggregateByStatement(ORDERBY, columns).Append(string.Format(" {0} ", orderType));
        }

        /// <summary>
        /// Helps making a conjunction given a statement and a conjunction operator
        /// </summary>
        /// <param name="conjunction">AND | OR</param>
        /// <param name="statement">The statement to be appended</param>
        /// <returns>A conjunction of the statement and the passed operator</returns>
        private static StringBuilder ConjunctionStatement(string conjunction, StringBuilder statement)
        {
            return new StringBuilder().AppendLine(string.Format(" {0} ({1})", conjunction, statement));
        }

        /// <summary>
        /// Creates a selec statement for the given columns, table and adding special columns if necessary
        /// </summary>
        /// <param name="columns">Table´s columns to be used in the query</param>
        /// <param name="tableName">Table to be used in the select statement</param>
        /// <param name="addRowNum">Indicates if rownum column must be added</param>
        /// <param name="addCountColumn">Indicates if a count(*) column must be added</param>
        /// <param name="dynamicQuery">The created dynamic query to be used</param>
        /// <returns>The SELECT FROM part of a sql statement</returns>
        private static StringBuilder SelectReportFromStatement(LinkedList<string> columns, string tableName, bool addRowNum, bool addCountColumn, string countColumn, bool isTimePeriod, DynamicQuery dynamicQuery, string dateColumnName)
        {
            StringBuilder statement = new StringBuilder();
            string rowNumExpression = "";

            if (addCountColumn)
            {

                countColumn = !string.IsNullOrEmpty(countColumn) ? string.Format(", {0} as totalCount ", countColumn)
                : ", count(*) as  totalCount ";
            }

            if (addRowNum)
            {
                rowNumExpression = string.Format(" ROW_NUMBER() OVER(ORDER BY {0}) AS {1} ,", dateColumnName, ROWNUM);
            }

            StringBuilder columnsTemp = new StringBuilder();
            statement.Append(" SELECT ");

            foreach (string column in columns)
            {
                columnsTemp.Append(string.Format(" {0} ,", column));
            }

            if (columnsTemp.Length > 0) //Only select the specified columns in the parameter
            {
                columnsTemp.Remove(columnsTemp.Length - 1, 1);
                if (isTimePeriod && !dynamicQuery.IsTotals)
                {
                    string mainColumns = "*";
                    if (dynamicQuery.IsTotals)
                    {
                        mainColumns = dynamicQuery.TotalColumns;
                    }

                    statement.Append(String.Format("{0} FROM (", mainColumns));
                    statement.Append(" SELECT " + rowNumExpression + " * FROM ( ");
                    statement.Append(" SELECT ").Append(columnsTemp.ToString());
                }
                else
                {
                    statement.Append(rowNumExpression + columnsTemp.ToString() + countColumn);
                }
            }
            else // Select all columns
            {
                statement.Append(rowNumExpression + " * ");
            }

            statement.Append(string.Format(" FROM {0} WITH(NOLOCK) ", tableName));

            return statement;
        }

        /// <summary>
        /// Creates a selec statement for the given columns
        /// </summary>
        /// <param name="parameters">Table´s columns to be used in the query</param>
        /// <param name="complementColumns">Table to be used in the select statement</param>
        /// <returns>Array columns selected</returns>
        private static string[] GetFilterColumnsPivot(LinkedList<string> parameters, string[] complementColumns)
        {
            if (parameters.Count == 0)
            {
                return complementColumns;
            }

            LinkedList<string> columns = new LinkedList<string>();
            string[] arrayColumns;
            foreach (string column in complementColumns)
            {
                if (parameters.Contains("[" + column + "]") || column == "date")
                {
                    columns.AddLast(column);
                }
            }
            arrayColumns = new string[columns.Count];
            columns.CopyTo(arrayColumns, 0);
            return arrayColumns;
        }

        private static StringBuilder GetPivotColumns(string[] pivotColumns, string reportName, string[] complementColumns, bool addRowNum, string where, string pivotFunction, bool isTimePeriod, LinkedList<string> parameters, string groupByColumns, DynamicQuery dynamicQuery, bool isGroupPivot)
        {
            StringBuilder pivot = new StringBuilder();
            string tempC = "";
            string tempP = "";
            string tempT = "";
            string rowNumExpression = "";
            string pivotFunctionTotal = "";
            string columnstoGroup = "";

            if (pivotFunction != "")
            {
                pivot.AppendLine(" declare @out nvarchar(max) exec sp_executesql N'");

                if (addRowNum)
                {
                    string orderBy = complementColumns[0];
                    for (int i = 0; i < complementColumns.Length; i++)
                    {
                        if (complementColumns[i] != "date")
                        {
                            continue;
                        }

                        orderBy = complementColumns[i];
                        break;
                    }
                    rowNumExpression = string.Format(" ROW_NUMBER() OVER(ORDER BY {0}) AS {1} ,", "[" + orderBy + "]", ROWNUM);
                }

                foreach (string pivotColumn in pivotColumns)
                {
                    pivot.AppendLine(string.Format(" declare @pivot1_{0} nvarchar(max)", pivotColumn));
                    pivot.AppendLine(string.Format(" declare @pivot2_{0} nvarchar(max)", pivotColumn));
                    if (dynamicQuery.IsTotals)
                    {
                        pivot.AppendLine(string.Format(" declare @pivot3_{0} nvarchar(max)", pivotColumn));
                    }
                    pivot.Append(string.Format(" select @pivot1_{0} = coalesce(@pivot1_{0} + '','','''') + QuoteName({0})", pivotColumn));
                    pivot.Append(string.Format(" from (\r\nselect distinct {0} from {1} {3} \t{2} ) T1_{0} {3}", pivotColumn, reportName, where, Environment.NewLine));
                    if (dynamicQuery.IsTotals || isGroupPivot)
                    {
                        pivot.AppendLine(string.Format(" select @pivot2_{0} = coalesce(@pivot2_{0} + '','', '''') + ''isnull({1}('' + QuoteName({0}) + ''),0) AS'' + QuoteName({0})", pivotColumn, pivotFunction));
                    }
                    else
                    {
                        pivot.AppendLine(string.Format(" select @pivot2_{0} = coalesce(@pivot2_{0} + '','', '''') + ''isnull('' + QuoteName({0}) + '',0) AS'' + QuoteName({0})", pivotColumn));
                    }

                    pivot.AppendLine(string.Format(" from (select distinct {0} from {1} {3}\t {2} ) T2_{0} {3}", pivotColumn, reportName, where, Environment.NewLine));
                    if (dynamicQuery.IsTotals)
                    {
                        if (isGroupPivot)
                        {
                            pivotFunctionTotal = (pivotColumn.EndsWith("_Avg") ? "avg" : "sum");
                        }
                        else
                        {
                            pivotFunctionTotal = "max";
                        }

                        if (isGroupPivot)
                        {
                            pivot.AppendLine(string.Format(" select @pivot3_{0} = coalesce(@pivot3_{0} + '','', '''') + ''isnull({1}('' + QuoteName({0}) + ''),0) AS'' + QuoteName({0})", pivotColumn, pivotFunctionTotal));
                        }
                        else
                        {
                            pivot.AppendLine(string.Format(" select @pivot3_{0} = coalesce(@pivot3_{0} + '','', '''') + '' {1}('''''''') AS'' + QuoteName({0})", pivotColumn, pivotFunctionTotal));
                        }

                        pivot.Append(string.Format(" from (select distinct {0} from {1} {3} \t{2} ) T3_{0} {3}", pivotColumn, reportName, where, Environment.NewLine));
                    }
                }
                pivot.AppendLine(" declare @query nvarchar(max)");

                foreach (string complementColumn in complementColumns)
                {
                    tempC += string.Format(" [{0}],", complementColumn);
                }

                foreach (string pivotV in pivotColumns)
                {
                    tempP += string.Format(" '' + @pivot2_{0} + '',", pivotV);
                    tempT += string.Format(" '' + @pivot3_{0} + '',", pivotV);
                }

                tempP = tempP.Substring(0, tempP.Length - 1);
                tempT = tempT.Substring(0, tempT.Length - 1);

                string mainColumns = "*";
                if (dynamicQuery.IsTotals)
                {
                    mainColumns = tempT;
                    if (dynamicQuery.TotalColumns.Length > 0)
                    {
                        mainColumns += "," + dynamicQuery.TotalColumns;
                    }
                }

                pivot.Append(string.Format(" set @query = '' SELECT {0} FROM (SELECT {1} * FROM (", mainColumns, rowNumExpression));
                pivot.Append(" select ");

                pivot.Append(tempC + tempP);

                pivot.Append(string.Format(" from (select "));

                tempP = "";
                foreach (string pivotColumn in pivotColumns)
                {
                    tempP += string.Format("[{0}], [{1}],", pivotColumn, pivotColumn.Split('_')[1]);
                }
                tempP = tempP.Substring(0, tempP.Length - 1);

                if (isTimePeriod && !dynamicQuery.IsTotals)
                {
                    foreach (string column in parameters)
                    {
                        columnstoGroup += column + ",";
                    }
                    columnstoGroup = columnstoGroup.Substring(0, columnstoGroup.Length - 1);
                    pivot.Append(string.Format(" {0} from {1} {2} {4} \t{3} {4} \t) AS D_GROUP", columnstoGroup, reportName, where, groupByColumns, Environment.NewLine));
                }
                else
                {
                    pivot.Append(string.Format(" {0} from {1} {3} \t {2} {3} \t) AS E_GROUP", tempC + tempP, reportName, where, Environment.NewLine));
                }

                foreach (string pivotColumn in pivotColumns)
                {
                    pivot.AppendLine(string.Format(" pivot ({0}({1}) for {2} in ('' + @pivot1_{2} + '')) as PV_{2}", pivotFunction, pivotColumn.Split('_')[1], pivotColumn));
                }

                tempC = tempC.Substring(0, tempC.Length - 1);
                if (dynamicQuery.IsTotals || isGroupPivot)
                {
                    pivot.Append(string.Format(" group by {0} {1}) AS F_GROUP ", tempC, Environment.NewLine));
                }
                else
                {
                    pivot.AppendLine(" ) AS F_GROUP ");
                }

                if (!dynamicQuery.IsTotals)
                {
                    if (isTimePeriod)
                    {
                        columnstoGroup = columnstoGroup.Replace(@"'' + ''", "");
                        dynamicQuery.SqlPaginate = String.Format("select {0} from {1} WITH(NOLOCK) {2} {3}", columnstoGroup, reportName, where, groupByColumns);
                    }
                    else
                    {
                        dynamicQuery.SqlPaginate = String.Format("select {0} from {1} WITH(NOLOCK) {2} group by {0}", tempC, reportName, where);
                    }
                    dynamicQuery.SqlPaginate = String.Format("select * from ({0}) AS G_GROUP", dynamicQuery.SqlPaginate);
                }
            }
            else
            {
                pivot.AppendLine(" declare @out nvarchar(max) exec N'");
            }
            return pivot;
        }

        /// <summary>
        /// Helps into making BY statements
        /// </summary>
        /// <param name="aggregateClause">GROUP BY | ORDER BY</param>
        /// <param name="columns">columns to be used in the statement</param>
        /// <returns>A BY query using the specified operator and columns</returns>
        private static StringBuilder AggregateByStatement(string aggregateClause, LinkedList<string> columns)
        {
            StringBuilder statement = new StringBuilder();
            statement.Append(" " + aggregateClause + " ");
            StringBuilder columnsStatement = new StringBuilder();

            foreach (string column in columns)
            {
                columnsStatement.Append(string.Format(" {0},", "[" + column + "]"));
            }

            if (columnsStatement.Length > 0)
            {
                columnsStatement.Remove(columnsStatement.Length - 1, 1);
            }

            statement.Append(columnsStatement.ToString() + " ");

            return statement;
        }

        /// <summary>
        /// Given a collection of values, separated by | , creates various equality statements concatenated
        /// by the conjunction type value.
        /// </summary>
        /// <param name="conjunctionType">The operator to be used in the conjunctions</param>
        /// <param name="parameter">The parameter to be used in the equality statement</param>
        /// <param name="value">A serie of values separated by | that will be used to create equality statements</param>
        /// <returns>
        /// A serie of equality statements equal to the number of elements in the value that compare to the
        /// specified parameter and concatenated with the conjunction type operators
        /// </returns>
        private static StringBuilder BooleanStatement(string conjunctionType, string parameter, string value)
        {
            StringBuilder statement = new StringBuilder();
            int i = 1;

            if (!string.IsNullOrEmpty(parameter) && !string.IsNullOrEmpty(value))
            {
                value = value.Replace('|', ',');
                string[] elements = value.Split(',');

                if (conjunctionType.Equals(OR))
                {
                    Logger.Trace("Change OR for in {0}:{1}", parameter, value);
                    statement.AppendFormat(" {0} in( ", parameter);

                    for (i = 1; i <= elements.Length; i++)
                    {
                        statement.AppendFormat("@{0}{1},", parameter, i);
                    }

                    statement.Length--;
                    statement.Append(")");

                }
                else
                {
                    statement.AppendFormat(" {0} @{1}1 = {2} ", "", parameter, parameter);
                    for (i = 2; i < elements.Length; i++)
                    {
                        statement.AppendFormat(" {0} {1}} = @{1}{2} ", conjunctionType, parameter, i);
                    }
                }
            }
            Logger.Trace(statement);
            return statement;
        }

        /// <summary>
        /// Transforms some letters to  SQL inequality operators
        /// </summary>
        /// <param name="op">The inequality operator to be transformed</param>
        /// <returns>An SQL inequality operator</returns>
        private static string TranslateOperator(string op)
        {
            op = op.ToLower();

            if (op.Equals("l"))
            {
                return "<";
            }
            else if (op.Equals("g"))
            {
                return ">";
            }
            else if (op.Equals("le"))
            {
                return "<=";
            }
            else if (op.Equals("ge"))
            {
                return ">=";
            }
            else if (op.Equals("e"))
            {
                return "==";
            }
            else if (op.Equals("ne"))
            {
                return "<>";
            }
            else
            {
                return "";
            }
        }

        #endregion Private Methods
    }
}