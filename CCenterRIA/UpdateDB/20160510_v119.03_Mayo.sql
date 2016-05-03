/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2016/04/11
Description:



Database: CCenterRia
Required version: 119.03

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 118 sin fix
set @versionfix = 3
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'ADD COLUMN -- ccInbound'
		set @sql='if not exists (select * from sys.columns where name = N''agts_notavailable'' and Object_ID = Object_ID(N''ccInbound''))
begin
    ALTER TABLE ccInbound ADD agts_notavailable varchar(15)
end'
		EXEC(@sql)

		set @process = 'VALIDATE PROCEDURE -- ccsp_RIAUpdateEspecConfig'
		set @sql='if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateEspecConfig'')
begin
    DROP procedure ccsp_RIAUpdateEspecConfig
end'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE -- ccsp_RIAUpdateEspecConfig'
		set @sql='CREATE procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint,
@descripcion varchar(50) = null,
@Status tinyint = null,
@tNotas int = null,
@tMaxWaitCall int = null,
@nMaxQue int = null,
@tel_maxwait varchar(15) = null,
@tel_MaxQueue varchar(15) = null,
@tel_outservice varchar(15) = null,
@tel_noct varchar(15) = null,
@ShowCalifWnd bit = null,
@StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@queuePosition bit = null,
@tMaxQueueCallBack smallint = null,
@stopRecording bit = null,
@dialPrefixOverflow varchar(10) = null,
@OpriorityT smallint= null,
@callerIdDesc varchar(15) = null,
@chat tinyint = null,
@inactiveChatTime smallint = null,
@maxChats tinyint = null,
@chatDomain varchar(max) = null,
@chatQueue smallint = null,
@chatTime smallint = null,
@dRestrictPlay bit = null,
@callBackSurveyAgent bit = null,
@callBackSurveyClient bit = null,
@agts_notavailable varchar(15) = null
as
set nocount on
UPDATE ccInbound SET
descripcion = isnull(@descripcion,descripcion),
Status = isnull(@status,status),
tNotas = isnull(@tNotas,tNotas),
tMaxWaitCall = isnull(@tMaxWaitCall,tMaxWaitCall),
nMaxQue = isnull(@nMaxQue,nMaxQue),
tel_maxwait = isnull(@tel_maxwait,tel_maxwait),
tel_MaxQueue = isnull(@tel_MaxQueue,tel_MaxQueue),
tel_outservice = isnull(@tel_outservice,tel_outservice),
tel_noct = isnull(@tel_noct,tel_noct),
bnocturno = case when isnull(@tel_noct,''0'')=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
StartTimerOnHangUp = isnull(@StartTimerOnHangUp,StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey,editableCallKey),
queuePosition = isnull(@queuePosition,queuePosition),
tMaxQueueCallBack = isnull(@tMaxQueueCallBack,tMaxQueueCallBack),
stopRecording = isnull(@stopRecording, stopRecording),
dialPrefixOverflow = isnull(@dialPrefixOverflow, dialPrefixOverflow),
OpriorityT = isnull(@OpriorityT, OpriorityT),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
chat = isnull(@chat,chat),
inactiveChatTime = isnull(@inactiveChatTime,inactiveChatTime),
maxChats = isnull(@maxChats,maxChats),
chatQueueOverflow = isnull(@chatQueue,isnull(chatQueueOverflow,15)),
chatTimeOverflow = isnull(@chatTime,isnull(chatTimeOverflow,300)),
startStopRecording = isnull(@dRestrictPlay,startStopRecording),
callBackSurveyAgent = isnull(@callBackSurveyAgent,callBackSurveyAgent),
callBackSurveyClient = isnull(@callBackSurveyClient,callBackSurveyClient),
agts_notavailable = isnull(@agts_notavailable,agts_notavailable)
where inbound_id = @inbound_id

if not exists( select inbound_id from ccinbound where inbound_id <> @inbound_id and chatDomain = @chatDomain ) begin
if isnull(@chatDomain,'''') <> '''' begin
	update ccinbound set chatDomain = @chatDomain where inbound_id = @inbound_id
end
end
else begin
raiserror(''Domain already in another ACD Group'',15,4)
end


if @ShowCalifWnd = 1
begin
If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
	begin
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
	where inbound_id = @inbound_id
	select 1
	return(0)
	end

select 0
return(0)
end

else
UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
where inbound_id = @inbound_id
return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'INSERT -------- ccMenus'
		set @sql='if not exists(select * from ccMenus where menu_id = 6050) begin
insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release) values (6050, ''Encuestas de IVR|IVR Surveys'', 6000, ''B'', 6, 3, '''', ''4624fb0c3f01a4f7ffa2f345efb45a3b85a52092a63a80618efbff0e040db499'')
end'
		EXEC(@sql)

		set @process = 'ADD COLUMN -------- ivroptions'
		set @sql='if not exists (select * from sys.columns where name = N''questionId'' and Object_ID = Object_ID(N''ivroptions''))
begin
    --Use DDL or DML as you need
	alter table ivroptions add questionId int
end'
		EXEC(@sql)

		set @process = 'ADD COLUMN -------- IVROptions'
		set @sql='-- When column does not exists
if not exists (select * from sys.columns where name = N''surveyId'' and Object_ID = Object_ID(N''ivroptions''))
begin
--Use DDL or DML as you need
alter table ivroptions add surveyId int
end'
		EXEC(@sql)

		set @process = 'ALTER COLUMN -------- IVRCallsIn'
		set @sql='if not exists (select * from sys.columns where name = N''cal_id'' and Object_ID = Object_ID(N''IVRCallsIn''))
begin
--Use DDL or DML as you need
alter table IVRCallsIn add cal_id int
end'
		EXEC(@sql)

		set @process = 'VALIDATE PROCEDURE -------- ccsp_IVRInCalls'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_IVRInCalls'')
begin
    drop procedure ccsp_IVRInCalls
end'
		EXEC(@Sql)

		set @process = 'CREATE PROCEDURE -------- ccsp_IVRInCalls'
		set @Sql= 'CREATE Procedure [dbo].[ccsp_IVRInCalls]
@action tinyint = 0 ,
@ani varchar(30) = null ,
@idIvr int = 0 , 
@option varchar(5)= null ,
@saveType tinyInt = null,
@dnis varchar(50) = null,
@name varchar(50) = null,
@questionId int = 0,
@surveyId int = 0,
@calId int = 0
-- saveType 1 es menu 2 es dato
-- accion 1 siempre @ani  -> @idIvr
-- accion 2 siempre @idIvr @opcionDigitada -> nada
AS
IF @action = 1 
BEGIN
IF @ani IS NOT NULL 
BEGIN
INSERT  INTO IVRCallsIn(cal_ani,date,dnis,cal_id) values(@ani,getDate(),isnull(@dnis,''''), isnull(@calId,0));
Select ''ID''=scope_identity()
END
END
ELSE IF @action = 2 
BEGIN
IF @option IS NOT NULL AND @idIvr IS NOT NULL
BEGIN
INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0))
select 0
END
END'
		EXEC(@Sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)
		

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off