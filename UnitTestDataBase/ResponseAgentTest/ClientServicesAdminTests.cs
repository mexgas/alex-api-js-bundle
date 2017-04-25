using Microsoft.VisualStudio.TestTools.UnitTesting;
using TestCommons;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace TestCommons.Tests
{
    [TestClass()]
    public class ClientServicesAdminTests
    {
        private ClientServicesAdmin client;

        [TestInitialize]
        public void TestInitialize()
        {
            client = new ClientServicesAdmin();
        }

        [TestMethod()]
        public void LoadFileXLSXTest()
        {
            string error;
            XmlNode node = null;
            try
            {
                string fileName = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "../../Resources/InBase.xls");
                byte[] bytes = System.IO.File.ReadAllBytes(fileName);
                WebReference.LoaderConfiguration configuration = new WebReference.LoaderConfiguration();
                configuration.HasHeader = true;
                configuration.TableName = "Hoja1";
                configuration.AllowCellPhones = true;
                configuration.RecordID = "id";
                configuration.Telephones = new string[] { "cal_telefono" };
                node = client.loadFileXLSX(1, "InBase.xls", bytes, configuration, out error);
                Assert.IsNotNull(node);
                string value = node.ChildNodes[0].Attributes["value"].Value;
                Assert.AreEqual("1", value);
            }
            catch (Exception ex)
            {
                if (node != null) Assert.Fail(string.Format("Error {0} {1}", ex.Message, node.InnerText));
                else
                    Assert.Fail(string.Format("Error {0} ", ex.Message));
            }

        }
    }
}