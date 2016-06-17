using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Xml;

namespace TestCommons.Tests
{
    [TestClass()]
    public class ValidateResponseASPXTests
    {
        private ValidateResponseASPX aspxAgent;


        [TestInitialize]
        public void TestInitialize()
        {
            aspxAgent = new ValidateResponseASPX("http://192.168.1.250/AgentRIA/AgentEngine.aspx");
        }

        [TestMethod()]
        public void getResponseXMLSetting()
        {
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            try
            {
                parameters.Add("CWACode", "0");
                parameters.Add("KRIA", "87E1FECF07C5238B69935E815172A659");
                XmlDocument doc = aspxAgent.getResponse(parameters);
                bool resultado = doc != null;
                Assert.IsTrue(resultado);
            }
            catch (Exception ex)
            {
                Assert.Fail("Error " + ex.Message);
            }
        }

        [TestMethod()]
        public void getResponseDtmfOptionsMakeCall()
        {
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            try
            {
                parameters.Add("type", "1%2C2%2C3");
                parameters.Add("CWAcode", "9");
                parameters.Add("CamEspId", "1");
                parameters.Add("CallOutId", "5676");
                parameters.Add("nRequest", "142");
                parameters.Add("TypeInOut", "2");
                parameters.Add("Telephone", "2023");
                parameters.Add("cks", "303");

                XmlDocument doc = aspxAgent.getResponse(parameters);
                bool resultado = doc != null;
                Assert.IsTrue(resultado);

                XmlNode node = doc.SelectSingleNode("/Graphics/DTMFOptions");
                if (node == null)
                    Assert.Fail("Not Exists Node /Graphics/DTMFOptions");

                string available = node.Attributes["available"].Value;
                if (string.IsNullOrEmpty(available))
                {
                    Assert.Fail("Attribute available is null or empty");
                }
                
            }
            catch (Exception ex)
            {
                Assert.Fail("Error " + ex.Message);
            }
        }
    }
}