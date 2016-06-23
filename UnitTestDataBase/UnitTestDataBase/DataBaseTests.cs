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

        [TestMethod()]
        public void existsColumfuncEspDtmf()
        {
            string query = "select count(*) from syscolumns where name='funcEspDtmf' and OBJECT_NAME(syscolumns.id)='cccamps'";
            try
            {
                bool res = (int)db.executeScalar(query) > 0;
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1}", query, ex.Message));
            }
        }

        [TestMethod()]
        public void existsTableOptionIVR()
        {
            string query = "select count(*) from sys.tables where name='optionIVR'";
            try
            {
                bool res = (int)db.executeScalar(query) > 0;
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1}", query, ex.Message));
            }
        }

        [TestMethod()]
        public void executeCCSP_GetCampsNvosCBOneCampType1()
        {
            string query = "exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=1,@user_id=1";
            string error = string.Empty;
            try
            {
                List<Object[]> list = db.executeListObject(query, out error);
                bool res = list.Count == 1;
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1} {2}", query, error, ex.Message));
            }
        }

        [TestMethod()]
        public void executeCCSP_GetCampsNvosCBOneCampType2()
        {
            string query = "exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id=1";
            string error = string.Empty;
            try
            {
                List<Object[]> list = db.executeListObject(query, out error);
                bool res = list.Count > 0;
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1} {2}", query, error, ex.Message));
            }
        }


        [TestMethod()]
        public void executeCCSP_GetCampsNvosCBAllCamp()
        {
            string query = "exec ccsp_RIAGetCampsNvosCB @cam_id=0,@Tipo=2,@user_id=0";
            string error = string.Empty;
            try
            {
                List<Object[]> list = db.executeListObject(query, out error);
                bool res = list.Count > 0;
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1} {2}", query, error, ex.Message));
            }
        }

        [TestMethod()]
        public void executeCCSP_GetCampsNvosCBAndccsp_OUTGetNewJobs()
        {
            string query1 = "exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id=1";
            string query2 = "exec ccsp_OUTGetNewJobs @cam_id=1";
            string error = string.Empty;
            try
            {
                List<Object[]> list = db.executeListObject(query1, out error);
                bool res = list.Count > 0;
                Assert.IsTrue(res);
            }
            catch (Exception ex)
            {
                Assert.Fail(string.Format("Error DB: {0} ,{1} {2}", query1, error, ex.Message));
            }
        }

    }
}