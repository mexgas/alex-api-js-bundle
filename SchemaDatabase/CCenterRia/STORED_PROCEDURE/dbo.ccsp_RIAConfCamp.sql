CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint,
@campID int =null
AS
set nocount on
declare @tableExistsRec table (camId int primary key,existRec bit)
declare @camByUser table (camId int primary key,isCheck bit)
declare @camId int,@id int;

IF Not EXISTS
    (
        SELECT *
        FROM ccUsers_Roles
        WHERE User_id = @User_id
                AND Rol_id = 7
    )begin
    insert into @camByUser 
    select *,0 from dbo.fGet_CampAcd_Area (@User_id, 1) B 
    where @campID is null or cam_id=@campID
end
else begin
    insert into @camByUser 
    select cam_id,0 from ccCamps 
    where (IDArea>0 or IDArea is null)
    and (@campID is null or cam_id=@campID)
end


while exists(select * from @camByUser where isCheck=0)
begin
    select top 1 @camId=camId  from @camByUser where isCheck=0 
    if exists(select cam_id from ccoCallsOut where cam_id=@camId) begin
        insert into @tableExistsRec values(@camId,1)
    end
    else begin
        insert into @tableExistsRec values(@camId,0)
    end

    update  @camByUser  set isCheck=1 where camId=@camId
end


            

select a1.cam_id, cam_Descripcion
, cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
, cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
, detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
, cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
, stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, 
cam_maxqueue as queSize,
DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
    ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
,isnull(sipHdrFormat, '') sipHdrFormat
,cam_inter_cancelled
,prefijo,   enbleprefix = case when existRec = 0 then 1 else 0 end,
isnull(exitAssisted, 0) exitAssisted, isnull(previewDiscard, 0) PreviewDiscard
from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
inner join @tableExistsRec a4 on a1.cam_id=a4.camId
--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
order by cam_descripcion
return(0)
set nocount off