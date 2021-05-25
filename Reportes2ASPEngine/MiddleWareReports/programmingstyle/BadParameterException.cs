using System;
using System.Text.RegularExpressions;

namespace MiddleWareReports
{
    /// <summary>
    /// Helper class that checks if value contains only letters
    /// in order to comply with the database schema of the reports.
    /// </summary>
    public class BadParameterException : Exception
    {
        public BadParameterException(string message)
            : base(message)
        {
        }

        /// <summary>
        /// Check if a string only contains letters
        /// </summary>
        /// <param name="parameter">Value to be checked</param>
        /// <returns>true if passed value only contains letters, throws BadParameterException otherwise.</returns>
        public static bool correctNameFormation(string parameter)
        {
            //Regex that only matches strings that only contain letters
            Regex onlyLetters = new Regex("^[a-zA-Z]+$");

            if (onlyLetters.IsMatch(parameter))
            {
                return true;
            }
            else
            {
                throw new BadParameterException("Parameter " + parameter + " contains non letters characters");
            }
        }
    }
}