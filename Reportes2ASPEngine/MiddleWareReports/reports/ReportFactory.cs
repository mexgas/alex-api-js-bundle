using System;
using System.Collections.Generic;
using System.Text;
using MiddleWareReports.reports.specialreports;
using MiddleWareReports.reports.agentreports;


namespace MiddleWareReports
{
    /// <summary>
    /// Creates instances of the various reports of the application
    /// </summary>
    public class ReportFactory
    {        
        /// <summary>
        /// Creates an instance of a report based on its report id
        /// </summary>
        /// <param name="reportNumber">Id of the report</param>
        /// <returns>An instance of the report</returns>
        public static GenericReport getReportName(int reportNumber)
        {
            switch (reportNumber)
            {
                case 0: //Without Report
                    return new GenericReport(); //""
                case 1000: //FILE
                    return null; //"File"
                case 2000: //AGT
                    return null; //"Agent"
                case 2010:
                    return new RepAgentGI();
                case 2020:
                    return new RepAgentSession();
                case 2030:
                    return new RepAgentNotReady();
                case 2040:
                    return new RepAgentNotReadyDet();
                case 2050:
                    return new RepAgentKPI();               
                case 2060:
                    return new RepAgentSessionByInterval();                
                case 2070: //Reporte Estados de agente y llamadas por intervalo Errescuer
                    return new RepAgentCallStatusesByInterval();
                case 2080:
                    return new RepDetailAgent();
                case 2090:
                    return new RepViewAgentGISpecial();
                case 3000: //IN
                    return null; //"Inbound"
                case 3010:
                    return new RepInCallsDetail();
                case 3020:
                    return new RepInCalls();
                case 3030:
                    return new RepInNotTransferred();
                case 3040:
                    return new RepInDispositions();
                case 3060:
                    return new RepIneffectiveness();
                case 3070:
                    return new RepInChangeFlow();
                case 3080:
                    return new RepInBill01900();
                case 3100:
                    return new RepInDIDResume();
                case 3110:
                    return new RepInRejectedCalls();
                case 3120:
                    return new RepInSubDispositions();
                case 3130: // Chats
                    return null;
                case 3131:
                    return new RepACDChats();
                case 3132:
                    return new RepChatsNotContacted();
                case 3133:
                    return new RepChatsDetail();
                case 3134:
                    return new RepAvgAnswerTimeChats();
                case 3135:
                    return new RepChatsEffectiveness();
                case 3136:
                    return new RepChatsAndCallsGeneral();
                case 3140: // Times
                    return null;
                case 3141: //Abandoned
                    return new RepInAbnd();
                case 3142: //Answered
                    return new RepInAnsw();
                case 4000: //OUT
                    return null; //"OutBound"
                case 4010://Dial Detail Report
                    return new RepOutDialDetail();
                case 4020:
                    return new RepOutCallsDetail();
                case 4030://Answered Calls Report                    
                    return new RepOutCalls();
                case 4040:
                    return new RepOutDispositions();               
                case 4050:
                    return new RepOutDials();
                case 4060:
                    return new RepOutCallBilling();
                case 4070:
                    return new RepOutCallsByTelephone();
                case 4090:
                    return new RepOutKPI();
                case 4100:
                    return new RepOutSubDispositions(); 
                case 4110:
                    return new RepOutCallBacks();
                case 4120: //Calls with Transference
                    return new RepCallXfer();
                case 4130: //Answered Calls by Status
                    return new RepOutAnswCalls();
                case 4140: //Answered Calls On Chat Detail
                    return new RepOutCallsOnChatDetail();
                case 4150:
                    return new RepSpecialAbndCamp();
                case 4160:
                    return new RepOutDispositionsContacOwner();
		case 4170:
                    return new RepOutManagementBase(); //reporte de errescuer gestion de base 
                case 4180: //Reporte de errescuer RepDialingResultsDetail
                    return new RepDialingResultsDetail();
		case 4190:
                    return new RepAnsweredCallsByDialingRetries();
                case 4220: //Telephone Numbers by State Report
                    return new RepSpecialTelephoneNumbersByState();
                case 4230://Telephone Numbers by Record/List Report
                    return new RepSpecialTelephoneNumbersByRegistry();
                case 4240://Dialing Results Report
                    return new RepSpecialDialingResults();
                case 4250://Answered and Transfer calls
                    return new RepOutAnswAndXferCalls();
                case 6000: //IVR
                    return null; //"IVR"
                case 6010:
                    return new RepIVRDetail();
                case 6020:
                    return new RepIVRGeneral();
                case 6030:
                    return new RepIVRFirstOption();
                case 6040:
                    return new RepIVRByOptions();
                case 6050: //IVR Surveys Report
                    return new RepIVRSurveys();
                case 7000: //ESP
                    return null; //"ESP" 
                case 7010: //Abandon reports
                    return new RepSpececialAbnd();
                case 7020: //Agent summary
                    return new RepSpececialAgent();
                case 7030: //Movements per campaign
                    return new RepSpececialCamMovs();
                case 7040: //RepSpececialPromises
                    return new RepSpececialPromises();
                case 7050: //RepSpececialAgtPerformance
                    return new RepSpececialAgtPerformance();
                case 7060: //RepSpecialCallKeyHistory
                    return new RepSpecialCallKeyHistory();
                case 7070:
                    return new RepMKTAgentes();
                case 7080:
                    return new RepMKTDiario();
                case 7090:
                    return new RepSpececialAbndPercentage();
                case 7100:
                    return new RepSpececialAbndProfiles();
                case 7110:
                    return new RepSpececialAbndTimes();
                case 7140:
                    return new RepMKTIntervalos();
                case 8010:
                    return new RepTrunkBusy();
                case 8020:
                    return new RepOutTrunkBusy();
                case 8030:
                    return new RepInTrunkBusy();
                case 8040:
                    return new RepSpecialTimes();
                case 8061:
                    return new RepAVRSAgent();
                case 8062:
                    return new RepAVRSSupervisor();
                case 8063:
                    return new RepAVRSSection();
                case 8064:
                    return new RepAVRSQuestion();
                case 8071:
                    return new RepAVRSQuestionDetail();
                case 8072:
                    return new RepAVRSRateDetail();
               /* case 8080:
                    return new RepAVRSDisposition();*/
                case 8081:
                    return new RepAVRSAgentChat();//RepAVRSAgentChat();
                case 8082:
                    return new RepAVRSQuestionChat();
                case 8083:
                    return new RepAVRSRateChat();
                case 8084:
                    return new RepAVRSDetailChat();
                case 9000:
                    return null;
                case 9010:
                    return new RepCRMXTemplates();
                case 9011:
                    return new CRMxView();
                case 10010://reporte emailACD
                    return new RepEmailACD();
                case 10020://reporte email detalle ACD
                    return new RepEmailAgente();
                case 10030://reporte email detail
                    return new RepEmailDetail();
                case 10040://reporte email general
                    return new RepEmailGeneral();
                case 11010://reporte twitter ACD
                    return new RepTwitterACD();
                case 11020://reporte twitter agent
                    return new RepTwitterAgente();
                case 11030://reporte twitter detail
                    return new RepTwitterDetail();
                case 11040://reporte twitter general
                    return new RepTwitterGeneral();
                default:
                    throw new ReportNotFoundException("Report Not Found"); //"";
            }
        }
    }
}
