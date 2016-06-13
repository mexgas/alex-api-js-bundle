using Microsoft.VisualStudio.TestTools.UnitTesting;
using TestCommons;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using TestCommons.util;

namespace TestCommons.Tests
{
    [TestClass()]
    public class DataBaseTests
    {
        private Logger log;
        private DataBase db;

        [TestInitialize]
        public void TestInitialize()
        {
            log = new Logger("TestDB");
            db = DataBase.getInstance(log);
        }

        [TestCleanup]
        public void TestCleanup()
        {
            log.close(true);
        }

        [TestMethod()]
        public void testConnexionTest()
        {

            bool resultado = db.testConnexion();
            Assert.IsTrue(resultado);
        }

        [TestMethod()]
        public void getVersionCCenterRIA()
        {
            string query = "exec ccsp_getVersion 'BD'";
            int expRes = 119;
            try
            {
                int resultado = (int)db.executeScalar(query);
                Assert.AreEqual(resultado, expRes);
            }
            catch (Exception ex)
            {
                Assert.Fail("Error DB: " + query + " " + ex.Message);
            }
        }


        [TestMethod()]
        public void execGarbageCollector()
        {
            string error = string.Empty;
            string query = "exec ccsp_ResetGarbageCollector";
            try
            {
                bool res = db.executeNonQuery(query, out error);
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1} {2}", query, error, ex.Message));
            }
        }




    }
}