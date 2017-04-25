using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Xml;

namespace TestCommons.Tests
{
    [TestClass()]
    class CW_296Test
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
        public void getResponse2961()
        {
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            try
            {
                parameters.Add("Action", "10");
                parameters.Add("Process", "18");
                parameters.Add("SourceUserID", "3");
                parameters.Add("canReprogram", "1");
                parameters.Add("description", "asdf");
                parameters.Add("endConversation", "0");
                parameters.Add("random", "0.8813604721799493");
                parameters.Add("sort", "0");
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

        [TestMethod()]
        public void getResponse2962()
        {
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            try
            {
                parameters.Add("Action", "8");
                parameters.Add("Process", "18");
                parameters.Add("SourceUserID", "3");
                parameters.Add("Insertqualif_Id", "5");
                parameters.Add("Type" ,   "0");
                parameters.Add("Type2" ,  "1");
                parameters.Add("random", "0.8813604721799493");
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

        [TestMethod()]
        public void getResponse2963()
        {
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            try
            {
                parameters.Add("Action", "17");
                parameters.Add("Process", "18");
                parameters.Add("CamEspID","1");
                parameters.Add("CamEspOption","0");
                parameters.Add("MirrorCampId","1");
                parameters.Add("SourceUserID","3");
                parameters.Add("random", "0.8813604721799493");
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

        [TestMethod()]
        public void getResponse2964()
        {
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            try
            {
                parameters.Add("Action", "17");
                parameters.Add("Process", "18");
                parameters.Add("CamEspID", "1");
                parameters.Add("CamEspOption", "0");
                parameters.Add("MirrorCampId", "0");
                parameters.Add("SourceUserID", "3");
                parameters.Add("random", "0.8813604721799493");
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
