using System;

namespace MiddleWareReports
{
    /// <summary>
    /// Class that helps to sort the chat items
    /// </summary>
    public class ChartItem : IComparable<ChartItem>, IEquatable<ChartItem>
    {
        private String _xValue;
        private String _yValue;
        private String _sortValue;

        /// <summary>
        /// Gets or sets the x-axis value
        /// </summary>
        public String xValue
        {
            get { return _xValue; }
            set { _xValue = value; }
        }

        /// <summary>
        /// Gets or sets the y-axis value
        /// </summary>
        public String yValue
        {
            get { return _yValue; }
            set { _yValue = value; }
        }

        /// <summary>
        /// Gets or sets the value used to sort
        /// </summary>
        public String sortValue
        {
            get { return _sortValue; }
            set { _sortValue = value; }
        }

        /// <summary>
        /// Constructor. Sets the sort by x-axis option
        /// </summary>
        /// <param name="xValue">The x-axis value</param>
        /// <param name="yValue">The y-axis value</param>
        /// <param name="sortValue">The value used to sort</param>
        public ChartItem(String xValue, String yValue, String sortValue)
        {
            this.xValue = xValue;
            this.yValue = yValue;
            this.sortValue = sortValue;
        }

        /// <summary>
        /// Constructor. Sets the sort by y-axis option
        /// </summary>
        /// <param name="yValue">The y-axis value</param>
        /// <param name="sortValue">The value used to sort</param>
        public ChartItem(String yValue, String sortValue)
        {
            this.yValue = yValue;
            this.sortValue = sortValue;
        }

        /// <summary>
        /// Compares two objects to let them be ordered
        /// </summary>
        /// <param name="parameter">The object to be compared</param>
        /// <returns>-1 if the object is smaller, 0 if it is equal, or 1 if it is greater</returns>
        public int CompareTo(ChartItem other)
        {
            if (ReferenceEquals(null, other)) return 1;
            return sortValue.CompareTo(other.sortValue);
        }

        /// <summary>
        /// Compares two objects to let them be ordered
        /// </summary>
        /// <param name="parameter">The object to be compared</param>
        /// <returns>true if it is equal, false if it is different</returns>
        public bool Equals(ChartItem other)
        {
            if (ReferenceEquals(null, other)) return false;
            if (ReferenceEquals(this, other)) return true;
            return sortValue.Equals(other.sortValue);
        }
    }
}
