using Microsoft.VisualStudio.TestTools.UnitTesting;
using MiddleWareReports;
using System.Collections.Specialized;
using System.Xml;

namespace TestReport
{
    /// <summary>
    ///Se trata de una clase de prueba para GenericReportTest y se pretende que
    ///contenga todas las pruebas unitarias GenericReportTest.
    ///</summary>
    [TestClass()]
    public class GenericReportTest
    {
        private TestContext testContextInstance;

        /// <summary>
        ///Obtiene o establece el contexto de la prueba que proporciona
        ///la información y funcionalidad para la ejecución de pruebas actual.
        ///</summary>
        public TestContext TestContext
        {
            get
            {
                return testContextInstance;
            }
            set
            {
                testContextInstance = value;
            }
        }

        #region Atributos de prueba adicionales

        //
        //Puede utilizar los siguientes atributos adicionales mientras escribe sus pruebas:
        //
        //Use ClassInitialize para ejecutar código antes de ejecutar la primera prueba en la clase
        //[ClassInitialize()]
        //public static void MyClassInitialize(TestContext testContext)
        //{
        //}
        //
        //Use ClassCleanup para ejecutar código después de haber ejecutado todas las pruebas en una clase
        //[ClassCleanup()]
        //public static void MyClassCleanup()
        //{
        //}
        //
        //Use TestInitialize para ejecutar código antes de ejecutar cada prueba
        //[TestInitialize()]
        //public void MyTestInitialize()
        //{
        //}
        //
        //Use TestCleanup para ejecutar código después de que se hayan ejecutado todas las pruebas
        //[TestCleanup()]
        //public void MyTestCleanup()
        //{
        //}
        //

        #endregion Atributos de prueba adicionales

        /// <summary>
        ///Test method getXmlReport
        /////Report IVR-Encuesta
        ///</summary>
        [TestMethod()]
        public void getXmlReportLoadData()
        {
            GenericReport target = new RepIVRSurveys();
            NameValueCollection parameters = new NameValueCollection();
            try
            {
                parameters.Add("dateStart", "2016-06-01 00:00");
                parameters.Add("pivotColumns", "question_Count");
                parameters.Add("page", "1");
                parameters.Add("isGroupPivot", "False");
                parameters.Add("translatedSpecialColumns", "");
                parameters.Add("complementGroupBy", "");
                parameters.Add("pivotFunction", "max");
                parameters.Add("complementColumns", "date|userId|login|scriptId|surveyId|survey|calId|calKey|campaignId|inboundId|campACDDescription");
                parameters.Add("dateEnd", "2016-06-24 23:59");
                parameters.Add("groupByColumns", "");

                short process = 6050;
                string addFilters = string.Empty;
                int sourceUserId = 1;
                string savetemplate = "save";
                string totals = "1";
                XmlDocument actual;
                actual = target.getXmlReport(parameters, process, addFilters, sourceUserId, savetemplate, totals);
                Assert.IsNotNull(actual);
                if (actual == null)
                {
                    Assert.Fail("Not Exists parameters");
                }

                XmlDocument doc = target.getXmlReport(parameters, process, addFilters, sourceUserId, savetemplate, totals);
                XmlNodeList node = doc.SelectNodes("/Report/Rows/Row/Cell");

                if (node == null)
                {
                    Assert.Fail("Not Exists Node /Report/Rows/Row/Cell");
                }

                //search the word "Monto" or "amount"
                foreach (XmlNode i in node)
                {
                    if (i.Attributes["name"].Value.Contains("amount") || i.Attributes["name"].Value.Contains("Monto"))
                    {
                        Assert.Fail("the attribute Monto or amount exists");
                    }
                    if (string.IsNullOrEmpty("name"))
                    {
                        Assert.Fail("Attribute name is null or empty");
                    }
                }
            }
            catch (System.Exception ex)
            {
                Assert.Fail("Error " + ex.Message);
            }
        }
    }
}