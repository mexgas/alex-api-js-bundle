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

		set @process = 'drop PROCEDURE -------- ccspSurveyIVR'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccspSurveyIVR'') drop procedure ccspSurveyIVR'
		EXEC(@Sql)

		set @process = 'create table -- Survey'
		set @sql='if not exists (select * from sys.tables where name = N''Survey'') begin
		create table Survey (
			surveyId int IDENTITY(1,1) NOT FOR REPLICATION NOT NULL PRIMARY KEY,
			description varchar(80) NOT NULL,
      		scriptId int NOT NULL default (0),
			active int NOT NULL default (1)
			)
		end'
		EXEC(@sql)

		set @process = 'create table -- SurveyQuestion'
		set @sql='if not exists (select * from sys.tables where name = N''SurveyQuestion'') begin
		CREATE TABLE SurveyQuestion(
			questionId int IDENTITY(1,1) NOT FOR REPLICATION NOT NULL PRIMARY KEY,
			description varchar(80) NOT NULL,
			active int NOT NULL default (1)
			)
		end'

		EXEC(@sql)

		set @process = 'create table -- SurveyAnswer'
		set @sql='if not exists (select * from sys.tables where name = N''SurveyAnswer'') begin
		CREATE TABLE SurveyAnswer(
			answerId int IDENTITY(1,1) NOT FOR REPLICATION NOT NULL PRIMARY KEY,
			description varchar(80) NOT NULL,
			active int NOT NULL default (1),
			digit int NOT NULL
			)
		end'

		EXEC(@sql)

		set @process = 'create table -- relationSurveyQuestion'
		set @sql='if not exists (select * from sys.tables where name = N''relationSurveyQuestion'') begin
		CREATE TABLE relationSurveyQuestion(
			surveyId int FOREIGN KEY REFERENCES Survey(surveyId),
			questionId int  FOREIGN KEY REFERENCES SurveyQuestion(questionId),
			orden int NULL
			)
		end'

		EXEC(@sql)

		set @process = 'create table -- relationQuestionAnswer'
		set @sql='if not exists (select * from sys.tables where name = N''relationQuestionAnswer'') begin
		CREATE TABLE relationQuestionAnswer(
			surveyId int FOREIGN KEY REFERENCES Survey(surveyId),
			questionId int  FOREIGN KEY REFERENCES SurveyQuestion(questionId),
			answerId int  FOREIGN KEY REFERENCES SurveyAnswer(answerId)
			)
		end'

		EXEC(@sql)

		set @process = 'ADD COLUMN -- ccInbound'
		set @sql='if not exists (select * from sys.columns where name = N''agts_notavailable'' and Object_ID = Object_ID(N''ccInbound'')) ALTER TABLE ccInbound ADD agts_notavailable varchar(15)'
		EXEC(@sql)

		set @process = 'ADD COLUMN -------- ivroptions'
		set @sql='if not exists (select * from sys.columns where name = N''questionId'' and Object_ID = Object_ID(N''ivroptions'')) alter table ivroptions add questionId int'
		EXEC(@sql)

		set @process = 'ADD COLUMN -------- IVROptions'
		set @sql='if not exists (select * from sys.columns where name = N''surveyId'' and Object_ID = Object_ID(N''ivroptions'')) alter table ivroptions add surveyId int'
        EXEC(@sql)

		set @process = 'ADD COLUMN -------- IVROptions'
		set @sql='if not exists (select * from sys.columns where name = N''cal_id'' and Object_ID = Object_ID(N''ivroptions'')) alter table ivroptions add cal_id int'
		EXEC(@sql)

		set @process = 'Add Column ccTipoCalifOUT.contactOwner'
		set @sql='if not exists (select * from sys.columns where name = N''contactOwner'' and Object_ID = Object_ID(N''ccTipoCalifOUT'')) ALTER TABLE ccTipoCalifOUT ADD [contactOwner] [bit] NULL'
    	EXEC(@sql)

		set @process = 'Add Column ccTipoCalifSubOUT.contactOwner'
		set @sql='if not exists (select * from sys.columns where name = N''contactOwner'' and Object_ID = Object_ID(N''ccTipoCalifSubOUT'')) ALTER TABLE ccTipoCalifSubOUT ADD [contactOwner] [bit] NULL'
    	EXEC(@sql)

    	set @process = 'INSERT -------- ccMenus (6050)'
		set @sql='if not exists(select * from ccMenus where menu_id = 6050  and type=3) begin
		insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release) values (6050, ''Encuestas de IVR|IVR Surveys'', 6000, ''B'', 6, 3, '''', ''4624fb0c3f01a4f7ffa2f345efb45a3b85a52092a63a80618efbff0e040db499'')
		end'
		EXEC(@sql)

		set @process = 'insert into -- ccMenus 4150'
		set @sql='if not exists(select * from ccMenus where menu_id=4150 and type=3)
		INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
		values (4150,''Abandono por campaña|Abandoned calls by campaign'', 4000, ''B'', 4, 3, '''', ''229820a611c3b1d998336cda7aacb07d5a3ca43ae05ace1fddbc6841331cd7ed47dec3af93ff486ce7a5a71bff8c2a56990d13c117549e9f28741a29affec142'')'
		EXEC(@sql)

		set @process = 'insert into -- ccMenus 4160'
		set @sql='if not exists(select * from ccMenus where menu_id=4160  and type=3)
			INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
		values (4160,''Calificaciones por hora|Dispositions by hour'', 4000, ''B'', 4, 3, '''', ''54d108e6439d9428e2b8fd3e9f91fdee5f952d3162915efc1d9a9ceeb67ab3264e6299676240becbca206e8e78bdf663'')'
		EXEC(@sql)

		set @process = 'insert into -- ccMenus 86'
		set @sql='if not exists(select * from ccMenus where menu_id=86)
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, release)
      values (86, ''Encuentas|Surveys'', 80, ''B'', 85, 1, ''d1fcffe459da1ffcf96b682518980981f372441edaa94120af5f7e10fe1c5069'')'
    EXEC(@sql)


    set @process = 'CREATE PROCEDURE -- ccspSurveyIVR'
    set @sql='CREATE procedure [dbo].[ccspSurveyIVR]
@action as tinyint,@surveyId int =0,@description varchar(80) = null,@scriptId int=null,@isActive bit=null,  
@questionId int =0,@answerId int=0,@digit tinyint=null,@ids varchar(400)=null,@orden varchar(400)=null
AS  
  
declare @sql nvarchar(max)
declare @coma varchar(10)
declare @id int
set @coma='',''  
set @id=0  
if @action = 1 begin --INSERT and Update Survey   
 select @id=surveyId from Survey where description=@description  
 if @id > 0 and @id<>@surveyId begin  
  select -1 as surveyId  
  return (0)  
 end  
 if @surveyId=0 begin     
  insert into Survey(description,scriptId,active) values(@description,@scriptId,1)  
  select @surveyId=IDENT_CURRENT(''Survey'')    
 end  
 else begin     
  update Survey set description=isnull(@description,description),scriptId=isnull(@scriptId,scriptId),active=isnull(@isActive,active) where surveyId=@surveyId     
 end  
 select @surveyId   
 return 0  
end  
else if @action = 2 begin --INSERT and Update SurveyQuestion  
 select @id=questionId from SurveyQuestion where description=@description  
 if @id > 0 and @id<>@questionId begin  
  select -1 as questionId  
  return (0)  
 end  
 if @questionId=0 begin    
  insert into SurveyQuestion(description,active) values(@description,1)  
  select @questionId=IDENT_CURRENT(''SurveyQuestion'')    
 end  
 else begin  
  update SurveyQuestion set description=isnull(@description,description),active=isnull(@isActive,active) where questionId=@questionId     
 end  
 select @questionId   
 return 0  
end  
else if @action = 3 begin --INSERT and Update SurveyAnswer  
 select @id=answerId from SurveyAnswer where description=@description  
 if @id > 0 and @id<>@answerId begin  
  select -1 as questionId  
  return (0)  
 end  
 if @answerId=0 begin  
  insert into SurveyAnswer(description,active,digit) values(@description,1,@digit)  
  select @answerId=IDENT_CURRENT(''SurveyAnswer'')
 end  
 else begin  
  update SurveyAnswer set description=isnull(@description,description),active=isnull(@isActive,active),digit=isnull(@digit,digit) where answerId=@answerId     
 end  
 select @answerId   
 return 0  
end  
else if @action = 4 begin --insert relationSurveyQuestion   
 set @sql =''insert into relationSurveyQuestion(surveyId,questionId,orden)  
 select ''+convert(nvarchar(max),@surveyId)+'',A.Value,C.Value from dbo.fn_RIASplitDelimited(''''''+@ids+'''''',''''''+@coma+'''''') A  
left join relationSurveyQuestion B on A.Value=B.questionId and B.surveyId=''+convert(nvarchar(max),@surveyId)+'' 
left join dbo.fn_RIASplitDelimited(''''''+@orden+'''''',''''''+@coma+'''''') C on C.Id=A.Id
where B.questionId is null''  
exec (@sql)   
end  
else if @action = 5 begin --insert relationQuestionAnswer  
 set @sql =''insert into relationQuestionAnswer(surveyId,questionId,answerId)  
 select ''+convert(nvarchar(max),@surveyId)+'',''+convert(nvarchar(max),@questionId)+'',A.Value from dbo.fn_RIASplitDelimited(''''''+@ids+'''''',''''''+@coma+'''''') A  
left join relationQuestionAnswer B on A.Value=B.answerId and B.questionId=''+convert(nvarchar(max),@questionId)+''  
where B.answerId is null''   
 exec(@sql)   
end  
else if @action = 6 begin --delete relationSurveyQuestion   
 set @sql =''delete from relationSurveyQuestion where questionId in(''+@ids+'') and surveyId=''+convert(nvarchar(max),@surveyId)  
 exec(@sql)   
end  
else if @action = 7 begin --delete relationQuestionAnswer   
 set @sql =''delete from relationQuestionAnswer where surveyId=''  
 +convert(nvarchar(max),@surveyId)+'' and questionId=''+convert(nvarchar(max),@questionId) +  
 '' and answerId in(''+@ids+'') ''  
 exec(@sql)  
end  
else if @action = 8 begin    
 select surveyId,description,scriptId from Survey where active=1  
end  
else if @action = 9 begin   
 select questionId,description from SurveyQuestion where active=1  
end  
else if @action = 10 begin   
 select answerId,description,digit from SurveyAnswer where active=1  
end  
else if @action = 11 begin   
 select a.questionId,b.description,A.orden from relationSurveyQuestion A left join SurveyQuestion B on a.questionId = b.questionId where a.surveyId=@surveyId and B.active=1  order by A.orden
end  
else if @action = 12 begin   
 select A.answerId,B.description,B.digit from relationQuestionAnswer A left join SurveyAnswer B on A.answerId=B.answerId  where a.surveyId=@surveyId  and a.questionId=@questionId
end
else if @action = 13 begin   
 select S.scriptId,S.description,a.questionId,b.description,isnull(rQA.answerId,0),isnull(SA.description,''''),isnull(SA.digit,-1)
  from relationSurveyQuestion A 
  inner join SurveyQuestion B on a.questionId = b.questionId 
  inner join Survey S on S.surveyId=A.surveyId
  left join relationQuestionAnswer rQA on rQA.questionId=A.questionId
  left join SurveyAnswer SA on SA.answerId=rQA.answerId
  where a.surveyId=@surveyId and B.active=1  
  order by A.orden
end'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE -- ccsp_RIAUpdateEspecConfig'
		set @sql='ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
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


		set @process = 'ALTER PROCEDURE -- ccsp_IVRInCalls'
		set @sql='ALTER procedure [dbo].[ccsp_IVRInCalls]
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
        INSERT  INTO IVRCallsIn(cal_ani,date,dnis) values(@ani,getDate(),isnull(@dnis,''''));
        Select ''ID''=scope_identity()
    END
END
ELSE IF @action = 2
BEGIN
    IF @option IS NOT NULL AND @idIvr IS NOT NULL
    BEGIN
        INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId, cal_id) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0),isnull(@calId,0))
        select 0
    END
    ELSE select -1
END'
		EXEC(@Sql)

		set @process = 'ALTER SP-- ccsp_RIACATQualifications'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIACATQualifications]
@qualif_id varchar(max),
@Description varchar(40)=null,
@order varchar(3)=null,
@canReprogram varchar(1)=null,
@Type smallint,
@CamEspId smallint,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@endConversation varchar(1)=null
AS
set nocount on
declare @sql nvarchar(1000)

if @Type=0
begin
  if @CamEspId=0
    begin
      SELECT calif_id, description FROM ccTipoCalif WITH(NOLOCK) WHERE Calif_Status=1 and description=@qualif_id
      return(0)
  end
  SELECT calif_id, description FROM ccTipoCalifOUT  WHERE CalifOut_Status=1 and description=@qualif_id
  return(0)
end

if @Type=1 -- Load cctipoCalif
begin
  Select C.calif_id, C.Description, C.orden, cast(C.canReprogram as int) as canReprogram, 0 as contactOwner, cast(count(R.califRel_id)as tinyint) hasSub
  ,isnull(C.EndConversation,0) conversationEnd
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, cast(C.canReprogram as int)  ,C.EndConversation--, cast(C.contactOwner as int)
  order by 2
  return(0)
end

If @Type=2 -- Load cctipoCalifOUT
begin
  Select C.calif_id, C.Description, cast(C.canReprogram as int) as canReprogram, C.orden,
  cast(C.keepDial as int) as keepDial, cast(C.autocallback as int) autocallback,  cast(count(R.califRel_id)as tinyint) hasSub,cast(isnull(C.contactOwner,0) as int) as contacOwner
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, cast(C.canReprogram as int), C.orden, cast(C.keepDial as int), cast(C.autocallback as int), cast(isnull(C.contactOwner,0) as int)
  order by 2
  return(0)
end

If @Type=3 -- New cctipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
    begin
      select 2
      return(0)
    end
  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@Description)
  begin
      update ccTipoCalif set orden=@order, CanReprogram=isnull(@canReprogram,0),EndConversation=isnull(@endConversation,0), Calif_Status=1--, contactOwner= isnull(@contactOwner,0)
      where description=@Description
      return(0)
  end
  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation)--, contactOwner
  select isnull(max(calif_id), 0) + 1,@Description, @order, isnull(@canReprogram,0), isnull(@endConversation,0) from ccTipoCalif --, isnull(@contactOwner,0)
  return(0)
 end

If @Type=4 -- Update cctipoCalif
  begin
    If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
      set @Description=null

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), EndConversation=isnull(@endConversation,EndConversation)--, contactOwner=isnull(@contactOwner,contactOwner)
    where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

    return(0)
  end

If @Type=5 -- elimina calif
  begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
    return(0)
  end

If @Type=6 -- New cctipoCalifOUT
 begin
 If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@Description)
  begin
  select 2
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@Description)
 begin
  update ccTipoCalifOut set orden=@order, CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0)
  where description=@Description
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram,keepDial, autocallback, contactOwner)
 select isnull(max(calif_id), 0) + 1, @Description, @order , 0, @canReprogram, isnull(@keepDial,0), isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0) from ccTipoCalifOut
 return(0)
 end

If @Type=7 -- Update cctipoCalifOUT
 begin
 If exists(select Description from ccTipoCalifOUT where CalifOut_Status=1 and Description=@Description)
  set @Description=null

 UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
 canReprogram=isnull(@canReprogram, canReprogram), keepDial=isnull(@keepDial,keepDial), autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner)
 where calif_id=@qualif_id

 if @keepDial is not null
  begin
  update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
  end
 return(0)
 end

If @Type=8 -- elimina calif OUT
 begin
 delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
 return(0)
 end

If @Type=9
 begin
 select o.cam_id, cam_descripcion , c.calif_id, co.description as Calificacion, canReprogram, orden, cast(autoCallback as tinyint) autoCallback
 from ccCamps o left join ccCalifCamp c on o.cam_id=c.cam_id and c.tipo=1
 inner join ccTipoCalifOUT co on c.calif_id=co.calif_id
 where co.CalifOut_Status=1 and o.cam_id=@CamEspId
 order by 4
 return(0)
 end

If @Type=10
 begin
 select i.inbound_id as cam_id, descripcion, c.calif_id, ci.description as Calificacion, orden, cast(ci.canreprogram as integer) canreprogram, cast(isnull(ci.EndConversation,0) as integer) EndConversation
 from ccInbound i left join ccCalifCamp c on i.inbound_id=c.cam_id and c.tipo=0
 inner join ccTipoCalif ci on c.calif_id=ci.calif_id
 where ci.Calif_Status=1 and inbound_id=@CamEspId
 order by 4
 return(0)
 end
set nocount off'
		EXEC(@sql)


		set @process = 'ALTER SP -- ccsp_RIAsubCalif'
		set @sql='ALTER procedure [dbo].[ccsp_RIAsubCalif]
@action tinyint = 0,
@tipo tinyint = null, -- 0:Outbound / 1:Inbound
@calif_id varchar(max) = nulesol,
@califSub_id varchar(max) = null,
@califSubDesc varchar(40) = null,
@canReprogramSub tinyint = null,
@orden varchar(3) = null,
@idTipoLista int = null,
@keepDial tinyint = null,
@autoCallback tinyint = null,
@contactOwner tinyint = null,
@endConversation tinyint = null
as
set nocount on
begin try
 declare @sxML as varchar(max), @xml as xml, @succesValue varchar(2), @succesType varchar(2)
 set @xml = cast(''<?xml version="1.0"?> <MainSubQualificationLoad/>'' as xml)
 set @xml.modify(''insert element action {""} as last into (/MainSubQualificationLoad)[1]'')
 set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/MainSubQualificationLoad/action)[1]'')

 if @action = 0
  begin
  select @succesValue=0, @succesType=1 -- No se ingreso el action
  goto Success
  end

 if @action=1 -- Muestra info de Inbound
  begin
  set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort", isnull(endConversation,0) as "qualification!1!endConversation",
  isnull(0,0) as "qualification!1!contactOwner"
  from cctipocalif where Calif_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", isnull(O.EndConversation,0) "qualifRelation!1!endConversation"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select top 1 calif_id from cctipocalif where Calif_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram, 0) as "subQualification!1!canReprogram", isnull(orden, 0) as "subQualification!1!sort", isnull(EndConversation, 0) as "subQualification!1!endConversation"
  from cctipocalifSub where CalifSub_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

  select @xml
  return(0)
  end

 if @action=2 -- Muestra Info de Outbound
  begin
  set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort",
  autoCallback as "qualification!1!AutoCB", keepDial as "qualification!1!keepDial", contactOwner as "qualification!1!contactOwner"
  from cctipocalifOUT where CalifOut_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=0 and R.calif_id in (select top 1 calif_id from cctipocalifOUT where CalifOUT_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram,0) as "subQualification!1!canReprogram", isnull(orden,0) as "subQualification!1!sort",
  isnull(autoCallback,0) as "subQualification!1!AutoCB", isnull(keepDial,0) as "subQualification!1!keepDial", isnull(contactOwner,0) as "subQualification!1!contactOwner"
  from cctipocalifSubOUT where CalifSubOut_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

  select @xml
  return(0)
  end

  if @tipo is null
  begin
  select @succesValue=0, @succesType=2 -- No se ingreso el tipo
  goto Success
  end

 if @action=3 -- Muestra relacion de Calificaciones con subCalificaciones
  begin
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')

  if @tipo=0
   begin
   select @sxML = cast((select * from (select 1 as tag, null as parent,
   R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
   isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", autoCallback "qualifRelation!1!autoCallback"
   from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
   where R.tipoSubRel=0 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x
   order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
   select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
   select @xml
   return(0)
   end

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
  isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
  select @xml
  return(0)
  end

 if @action=4 -- Alta de subcalificaciones
  begin
  if isnull(@califSubDesc, '''')=''''
   begin
   select @succesValue=0, @succesType=6 -- No se ingreso el nombre de la subcalificacion
   goto Success
   end

  if @tipo=0
   begin
   if exists(select califSub_id from cctipocalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc)
    begin
    select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
    goto Success
    end

   insert cctipocalifSubOUT (califSubDesc, canReprogram, orden, idTipoLista, califSubOut_Status, keepDial, autoCallback, contactOwner)
   select @califSubDesc, @canReprogramSub, @orden, @idTipoLista, 1, @keepDial, @autoCallback, isnull(@contactOwner,0)
   select @succesType=scope_identity(), @succesValue=1
   goto Success
   end

  if exists(select califSub_id from cctipocalifSub where califSub_Status=1 and califSubDesc=@califSubDesc)
   begin
   select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
   goto Success
   end
  insert cctipocalifSub (califSubDesc,orden,canReprogram,califSub_Status,EndConversation)--,contactOwner
        select @califSubDesc, @orden, @canReprogramSub, 1,isnull(@endConversation, 0)--,isnull(@contactOwner,0)
  select @succesType=scope_identity(), @succesValue=1
  goto Success
  end

 if @action=5 -- baja de subcalificaciones
  begin
   delete cctipoSubCalifRel where tipoSubRel=@tipo and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))

  if @tipo=0
   begin
   update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
  select @succesValue=1
  goto Success
  end

 if @action=6 -- Actualizacion de subcalificaciones
  begin
   if @tipo=0
   begin
   if not exists(select califSub_id from cctipocalifSubOUT where califSub_id = cast(@califSub_id as smallint))
    begin
    select @succesValue=0, @succesType=4 -- La subCalificacion no existe
    goto Success
    end

   update cctipocalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogramSub, canReprogram),
    orden=isnull(@orden, orden), idTipoLista=isnull(@idTipoLista, idTipoLista), keepDial=isnull(@keepDial, keepDial),
    autoCallback=isnull(@autoCallback, autoCallback), contactOwner= isnull(@contactOwner,0) where califSub_id = cast(@califSub_id as smallint)
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  if not exists(select califSub_id from cctipocalifSub where califSub_id = cast(@califSub_id as smallint))
   begin
   select @succesValue=0, @succesType=4 -- La subCalificacion no existe
   goto Success
   end

  if @canReprogramSub=1
         begin
   declare @asignada bit, @can bit
   select @asignada=IB.inbound_id, @can=IB.cam_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
      join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id where califSub_id = cast(@califSub_id as smallint)
            if @asignada is not null and @can is null
       begin
       select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
       goto Success
       end
         end

  update cctipocalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@orden, orden),
   canReprogram=isnull(@canReprogramSub, canReprogram), EndConversation = isnull(@endConversation, 0) where califSub_id = cast(@califSub_id as smallint)

  exec ccsp_RIACATQualifications @Type = 4, @CamEspId = 0, @canReprogram = @canReprogramSub, @qualif_id = @califSub_id
  select @succesValue=1
  goto Success
  end

 if @action=7 -- Asignacion de Calfs / SubCalfs
  begin
  if @tipo=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
  (select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 and not exists (select IB.cam_id from cctipocalif CO
  join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 join ccInbound IB on IB.Inbound_id = CF.cam_id
  where IB.cam_id is not null and CO.calif_id in (select value from dbo.fn_RIASplitDelimited (@calif_id, '','')))
   begin
   select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
   goto Success
   end

  insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
  select C.value calif_id, S.value califSub_id, @tipo Tipo
  from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
   cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C
  where cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
  and C.value is not null and S.value is not null

if @tipo=0
    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
    select @succesValue=1
    goto Success
end
 if @action=8 -- Desasignacion de Calfs / SubCalfs
    begin
    delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
    (select cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10))
   from dbo.fn_RIASplitDelimited (@califSub_id, '','') S cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C)
    if @tipo=0
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
      select @succesValue=1
      goto Success
  end

  return(0)
end try
begin catch
  select @succesValue=0, @succesType=0 -- error no controlado
  goto Success
end catch
Success: -- <success value=''n'' type=''n''/>
set @xml.modify(''insert element success {""} as last into (/MainSubQualificationLoad)[1]'')
set @xml.modify(''insert attribute value {sql:variable("@succesValue")} as last into (/MainSubQualificationLoad/success)[1]'')
if isnull(@succesType, 0) <> 0
begin
  set @xml.modify(''insert attribute type {sql:variable("@succesType")} as last into (/MainSubQualificationLoad/success)[1]'')
end
select @xml
return(0)
set nocount off'

		EXEC(@sql)

		set @process = 'ALTER SP --ccsp_RIAADMGetCalifDay'
		set @sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = null
AS
set nocount on
create table #CalifTemp (
id int identity,
tipo integer,
Cam_id varchar(50),
Calificacion varchar(50),
subCalificacion varchar(50) null,
calif_id smallint null,
Total int,
iTotal4Campaign int null)

declare @typeACD smallint --= 0
declare @today datetime
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

set @today = convert(datetime, convert (varchar(11), getdate(), 101))
select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
@nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

---------------OUT ----------------------------
if @type=0 begin
  insert into #CalifTemp
  select 0 as tipo,co.cam_id as cam_id,
  case when co.statuscall_id = 13
      then case when description is not null
      then description else @nIdioma end
  else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
    else ''cw:'' + @nIdioma
    end end as Calificacion
  ,0 as subCalificaion,
  co.calif_id,count(*) cantidad,0 as iTotal4Campaign
  from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
  left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
  left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
  left join ccCamps ci on ci.cam_id = co.cam_id
  where co.cal_inicio > @today
  group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

  select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
  case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
  from #CalifTemp
  group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

end
---------------IN ----------------------------
else if @type = 1 begin

  if @typeACD = 0 begin  --Calls
  insert into #CalifTemp
   select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
		,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
		,count(*) as total,0 as iTotal4Campaign
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		left join ccInbound cci on cci.inbound_id = ci.inbound_id
		left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
		group by description, cci.inbound_id,ci.calif_id

    if (select valor from ccSettings where setting_id = 78) = 0 begin
      update #CalifTemp set iTotal4Campaign = 0
    end
    else begin
	update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
      from (
        select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
      inner join #CalifTemp c on t.cam_id = c.cam_id
    end
  end
  else if @typeACD = 1 begin--Chats
	insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
	select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
		case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		a.disposition as calif_id, count(disposition) as Total
        from ccriachats a
        left join ccTipoCalif b on a.disposition=b.calif_id
      where a.chatDate > @today and
	  a.chatStatus=4 and a.inboundId=@inbound_id
    group by inboundId, [description],disposition
  end
  else if @typeACD = 3 begin ---Mail
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
	select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
	case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
	relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
	from conversation conver
	inner join message mess on mess.conversationId = conver.conversationId
	left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	where mess.date > @today and
	conver.inboundId=@inbound_id and mess.messageStatusId >= 5
	group by conver.inboundId,relmesdis.dispositionId,disp.Description

  end
  else if @typeACD = 4 begin --calif twetter
    insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
	select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
	case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
	relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
	from conversationTwitter conver
	inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
	left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	where mess.date > @today and
	conver.inboundId=@inbound_id and mess.messageStatusId >= 5
	group by conver.inboundId,relmesdis.dispositionId,disp.Description

  end
  select camtemp.tipo,camtemp.cam_id,
	case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
	camtemp.subcalificacion,camtemp.calif_id,camtemp.total
	from #CalifTemp camtemp
    left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
end
-------------------SUBCALIFICACIONES IN-------------------
else if @type = 2 begin
  if @typeACD = 0 begin --Calls
    select @typeACD as tipo,cci.inbound_id as cam_id,  [description] as Calificacion,
	isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
    from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
	left join ccTipoCalif ca on ci.calif_id = ca.calif_id
    left join ccInbound cci on cci.inbound_id = ci.inbound_id
    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
    where ci.cal_inicio > @today
	and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
  end
  else if @typeACD = 1 begin --Chat
    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
		isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
		 from ccriachats a
		 left join ccTipoCalif b on a.disposition=b.calif_id
		 left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
		 where a.chatDate > @today and
		a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
		group by inboundId, [description],ctcs.califSubDesc
  end
  else if @typeACD = 3 begin --Mail
	select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
	isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
	from conversation conver
	inner join message mess on mess.conversationId = conver.conversationId
	left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
	where mess.date > @today and
	mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
	group by conver.inboundId,disp.Description,subDisp.califSubDesc


  end
  else if @typeACD = 4 begin --Twitter
    select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
	isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
	from conversationTwitter conver
	inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
	left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
	where mess.date > @today and
	mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
	group by conver.inboundId,disp.Description,subDisp.califSubDesc
  end

end
-------------------SUBCALIFICACIONES OUT-------------------
else if @type = 4 begin
  select 0 as tipo,co.cam_id as cam_id,
  case when co.statuscall_id = 13
    then case when description is not null
    then description else @nIdioma end
  else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
  end as Calificacion,
  isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad
  from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
  left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
  left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
  left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
  left join ccCamps ci on ci.cam_id = co.cam_id
  where co.cal_inicio > @today
  and co.cam_id = @inbound_id
  and co.calif_id = @calif_id
  group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end


drop table #CalifTemp
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER SP -- ccsp_ExtAppsCallHistory Montepio'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(30) = null,@endDate varchar(30) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,@multipleUser_id as varchar(500) = null,
@agentId int = 0,@camId int=0,@PageNumber int=1,@isCount bit=false

AS
declare @RowsPerPage int
set @RowsPerPage=500


-- INBOUND x cal_id
if @action = 1	begin
	select top 500
		cal_id as call_id,
		c.inbound_id,
		isnull(a.descripcion,'''') as acdGroup,
		cal_ani as phoneNumber,
		isnull(b.user_id,0) as [user_id],
		isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,
		d.descripcion as call_status,
		cal_tDialog as call_tDialog,
		cal_inicio as call_date,
		cal_tNotas as WrapUp,
		cal_tXfer as Xfer,
		cal_tRing as Ringing,
		cal_key as callKey,
		isnull(e.calif_id,'''') as dispositionId,
		isnull(f.califSubDesc,'''') as subDisposition,
		isnull(f.califSub_id,'''') as subDispositionId
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
	where cal_id >= @call_id
	end

-- OUTBOUND x cal_id
else if @action = 2 	begin
	select top 500
		cal_id as call_id,
		c.cam_id,
		isnull(a.cam_descripcion,'''') as Campaign,
		c.cal_telefono as phoneNumber,
		isnull(b.user_id,0) as user_id,
		isnull(login,''''),
		isnull(e.description,'''') as disposition,
		d.descripcion as call_status,
		cal_tDialog as call_tDialog,
		cal_inicio as call_date,
		cal_tNotas as WrapUp,
		cal_tXfer as Xfer,
		cal_tRing as Ringing,
		cal_manual as CallManual,
		c.cal_key as callKey,
		list_id,
		isnull(e.calif_id,'''') as dispositionId,
		isnull(f.califSubDesc,'''') as subDisposition,
		isnull(f.califSub_id,'''') as subDispositionId
	from ccocallsout c with(nolock)
	left join ccocallsoutsource cs on (cs.callout_id = c.callout_id)
	left join ccusers b on (c.user_id = b.user_id)
	left join cccamps a on (c.cam_id = a.cam_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
	left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
	where cal_id >= @call_id
end

else if @action = 3 begin --Session time

	declare @fecha_ini datetime
	declare @fecha_fin datetime

	if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
		select @fecha_ini = convert(datetime,convert(varchar(30),getdate()))
		select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))
	end
	else begin
		select @fecha_ini = convert(datetime,convert(varchar(30),@startDate))
		select @fecha_fin = convert(datetime,convert(varchar(30),@endDate))
	end

	select user_id, login, logout, datediff(ss,login,logout) as logintime
	from(select a.user_id, a.fecha as ''login'',
			(select isnull(max(Fecha),getdate())
				from ccLogLogin b with(nolock)
				where b.user_id = a.user_id and
				b.tipomov = 0 and
				b.fecha >= a.fecha and
				b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
							from ccLogLogin with(nolock)
							where user_id = b.user_id and
							tipomov = 1 and
							fecha > a.fecha)) as ''logout''
			from ccLogLogin a
			where a.tipomov=1
			and fecha >= @fecha_ini
			and fecha <= @fecha_fin) as sessiontime
	order by user_id, login
end

else if @action = 4 begin -- Estados de los agentes
	select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
end

else if @action = 5 begin-- Sinlge Call id Inbound

	select top 500
		cal_id as call_id,
		c.inbound_id,
		isnull(a.descripcion,'''') as acdGroup,
		cal_ani as phoneNumber,
		isnull(b.user_id,0) as user_id,
		isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,
		d.descripcion as call_status,
		cal_tDialog as call_tDialog,
		cal_inicio as call_date,
		cal_tNotas as WrapUp,
		cal_tXfer as Xfer,
		cal_tRing as Ringing,
		cal_key as callKey,
		isnull(e.calif_id,'''') as dispositionId,
		isnull(f.califSubDesc,'''') as subDisposition,
		isnull(f.califSub_id,'''') as subDispositionId
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
	where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') )
end

else if @action = 6 begin-- Single call_id Outbound

select top 500
	cal_id as call_id,
	c.cam_id,
	isnull(a.cam_descripcion,'''') as Campaign,
	c.cal_telefono as phoneNumber,
	isnull(b.user_id,0) as user_id,isnull(login,''''),
	isnull(e.description,'''') as disposition,
	d.descripcion as call_status,
	cal_tDialog as call_tDialog,
	cal_inicio as call_date,
	cal_tNotas as WrapUp,
	cal_tXfer as Xfer,
	cal_tRing as Ringing,
	cal_manual as CallManual,
	c.cal_key as callKey,
	cs.list_id,
	isnull(e.calif_id,'''') as dispositionId,
	isnull(f.califSubDesc,'''') as subDisposition,
	isnull(f.califSub_id,'''') as subDispositionId
from ccocallsout c with(nolock)
left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
left join ccusers b on (c.user_id = b.user_id)
left join cccamps a on (c.cam_id = a.cam_id)
left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') )
end

else if @action = 7 begin--Status Agente
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha), IdCampEsp, Tipo
	from cclogagentesdia with(nolock)
	where user_id = @agentId
	and fecha >= @startDate
	and fecha < @endDate
	order by fecha
end

else if @action = 8 begin
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) fecha, IdCampEsp, Tipo, user_id
	from cclogagentesdia with(index(IX_ccLogAgentesDia_4),nolock)
	where user_id in (select value from fn_RIASplitDelimited(@multipleUser_id,'',''))
	and fecha between @startDate
	and @endDate
	order by user_id,fecha
end
else if @action = 9 begin --Call History by CamId and day

	declare @date dateTime,@countRegistry bigint
	if @PageNumber<=0 set @PageNumber=1

	set @date=convert(datetime,convert(nvarchar(11),GETDATE(),121))

	if @isCount = 0 begin ---Datos para la informacion

		select cal_id as call_id,
			c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,
			c.cal_telefono as phoneNumber,
			isnull(b.user_id,0) as user_id,	isnull(login,''''),
			isnull(e.description,'''') as disposition,
			d.descripcion as call_status,
			cal_tDialog as call_tDialog,cal_inicio as call_date,
			cal_tNotas as WrapUp,cal_tXfer as Xfer,
			cal_tRing as Ringing,cal_manual as CallManual,
			c.cal_key as callKey,list_id,
			isnull(e.calif_id,'''') as dispositionId,
			isnull(f.califSubDesc,'''') as subDisposition,
			isnull(f.califSub_id,'''') as subDispositionId,
			rowNum
		from (
		select ROW_NUMBER() OVER ( ORDER BY cal_id ) AS rowNum,
			c.callout_id,cal_id,c.cam_id,c.cal_telefono,cal_tDialog ,cal_inicio,cal_tNotas,
			cal_tXfer,cal_tRing ,cal_manual,c.cal_key,c.statusCall_id,c.calif_id,c.califSub_id,c.user_id
		 from ccocallsout c with(nolock,index(IX_ccoCallsOut_3)) where cam_id=@camId and cal_Inicio >= @date and cal_Inicio<GETDATE()
		) as c
		left join ccocallsoutsource cs on (cs.callout_id = c.callout_id)
		left join ccusers b on (c.user_id = b.user_id)
		left join cccamps a on (c.cam_id = a.cam_id)
		left join ccStatusLLamada d on  (c.statusCall_id = d.statusCall_id )
		left join ccTipoCalifOUT e on  (c.calif_id = e.calif_id )
		left join ccTipoCalifSubOUT f on  (c.califSub_id = f.califSub_id)
		where  rowNum BETWEEN ((@PageNumber-1)*@RowsPerPage)+1 AND @RowsPerPage*(@PageNumber)
	end
	else begin--Numero de paginas y registros actuales
		select @countRegistry = count(*)	 from ccocallsout c with(nolock,index(IX_ccoCallsOut_3)) where cam_id=@camId and cal_Inicio >= @date and cal_Inicio<GETDATE()
		select @RowsPerPage as pagesize, @PageNumber as  currentpage, @countRegistry/cast(@RowsPerPage as float) as totalpages
	end
end'
		EXEC(@sql)

		set @process = 'ALTER SP -- ccsp_ExtAppsCamList'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCamList]
@action smallint,
@area int =0
AS
set nocount on
if @action = 1
 begin
	if @area = 0
		select a1.inbound_id, descripcion
		from ccinbound a1 join ccRIAinboundGraph a2 on (a1.inbound_id = a2.inbound_id)
		join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1
		order by descripcion
	else
		select distinct a1.inbound_id, descripcion
		from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
		join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@area, 0)
		order by descripcion
	return(0)
 end
if @action = 2
 begin
	if @area = 0
	    select a1.cam_id, cam_descripcion,cam_activo
		from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
		join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a3.type_id = 1
		order by cam_descripcion
	else
		select distinct a1.cam_id, cam_descripcion,cam_activo
        from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
        join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
        where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@area, 0)
        order by cam_descripcion
	return(0)
 end
set nocount off'
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

if @actualVersion = @version and @actualVersionFix = @versionfix begin
	begin tran
	begin try

		set @process = 'create table optionIVR -----------'
    set @sql='if not exists (select * from sys.tables where name = N''optionIVR'')
    begin
create table optionIVR
(dtmf varchar(10),
tag varchar(10),
camID int,
type int)
end'
		EXEC(@sql)

    set @process = 'CREATE UNIQUE INDEX AK_optionIVR_dtmf_tag_camID-----------'
    set @sql='if not exists (select * from sys.indexes where name = N''AK_optionIVR_dtmf_tag_camID'' and object_id = OBJECT_ID(N''optionIVR''))
    begin
    CREATE UNIQUE INDEX AK_optionIVR_dtmf_tag_camID
ON optionIVR (dtmf, tag, camID)
    end'
		EXEC(@sql)

    set @process = 'alter table ccCamps -----------'
    set @sql='if not exists (select * from sys.columns where name = N''funcEspDtmf'' and Object_ID = Object_ID(N''ccCamps''))
    begin
    alter table ccCamps
add funcEspDtmf int default(0)

update cccamps set funcEspDtmf = 0
    end
	'
		EXEC(@sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
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
  ,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey, a1.funcEspDtmf
  from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
  inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
  where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
  order by cam_descripcion
 return(0)
 set nocount off'
		EXEC(@sql)

	set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig] -----------'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null,
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null,
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null
as
set nocount on
UPDATE ccCamps SET
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf )
Where cam_id = @cam_id

if @cam_ShowCalifWnd = 1
 begin
 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
  begin
  select 0
  return(0)
  end

 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
 where cam_id = @cam_id
 select 1
 return(0)
  end

--else
UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'
		EXEC(@sql)

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