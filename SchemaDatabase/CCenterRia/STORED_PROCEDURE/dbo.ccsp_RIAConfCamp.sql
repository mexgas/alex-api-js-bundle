CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
				@User_id smallint
				AS
				set nocount on
				 select a1.cam_id, cam_Descripcion
				  , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
				  , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
				  , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
				  , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
				  , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
				  , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
				  DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
					 ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
				  ,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
				  ,isnull(sipHdrFormat, '') sipHdrFormat
				  ,cam_inter_cancelled
				  ,prefijo				  
				  from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
				  inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
				  where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
				  order by cam_descripcion
				 return(0)
				 set nocount off