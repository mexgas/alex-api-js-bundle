/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	CW-2092 ccsp_GalateaCallbacksDays Returns days with callbacks made by an agent
Database: CCenterRia
Required version: 120.21

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 31
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix = 25
	begin
		begin tran
		begin try		

	set @process = 'CW-2167 -- DROP PROCEDURE ccsp_LoadGraphics'
    	set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_LoadGraphics'')
    begin
        DROP PROCEDURE ccsp_LoadGraphics;
    end'
	EXEC(@sql)

	set @process = 'CW-2092 ccsp_GalateaCallbacksDays Returns days with callbacks made by an agent'
    set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_GalateaCallbacksDays]--[dbo].[ccsp_GalateaCallbacksDays] 40
				@userID int
				AS
				declare @currentDay datetime=getdate(),
				@rangeDays int 

				select @rangeDays=valor from ccSettings where setting_id=35

				-- Returns days with callbacks made by an agent
				SELECT cal_fusercallback Day
				FROM ccoCallBacks cb
				WHERE user_id = @userID
				and cal_fusercallback between @currentDay and dateadd(dd,@rangeDays,getdate())
				order by Day'
    EXEC(@Sql)

	
	set @process = 'CW-2167 ccsp_LoadGraphics Add IsStartStopRecording for callBacks Acd'
    set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	DECLARE @AuthorizationPlayStopRec TABLE(value bit)
	DECLARE @realValue bit
 
	INSERT INTO @AuthorizationPlayStopRec 
	exec ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType

	select @realValue=value from @AuthorizationPlayStopRec

	if (@callType=1)
	begin		
		select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage ,
		case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
		isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
		a2.ShowCalifWnd as ShowDisposition,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording,
		isnull(a2.editableDtmf, 0) as isEditDtmf
		from ccRIAInboundGraph a1 
		inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
		 inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
		 left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id		
	 end	
	 else
	 begin
		select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
		case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
		case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
		a2.cam_ShowCalifWnd as ShowDisposition,
		a2.callBackSurveyAgent,a2.callBackSurveyClient,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording
		from ccRIACampsGraph a1 
		inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
		inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
		left outer join (select top 1 M.cam_id, coalesce(msgFile+'','','''') as msgFile 
		from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
		where M.cam_id = @Id and type = 8) b 
		on (a2.cam_id = b.cam_id) 
		where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
	 end	
END'
    EXEC(@Sql)

	set @process = 'CW-2093 ccsp_GalateaCallbacks Returns the total of callbacks by hour on especific day'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_GalateaCallbacks]
				@dateCallBack datetime
				AS
				-- Returns the total of callbacks by hour on especific day
				IF OBJECT_ID(''tempdb..#CallBackHours'') IS NOT NULL
				BEGIN
					DROP TABLE #CallBackHours
				END

				CREATE TABLE #CallBackHours (Hour int, callback int )

				INSERT INTO #CallBackHours
				select  DATEPART(HOUR, cal_fcallback) ''Hour'', 1
				from ccoCallsOut
				where convert(date, cal_fcallback) = @dateCallBack

				SELECT  CAST(Hour AS smallint) Hour, SUM(callback) ''CallBacks'' FROM #CallBackHours
				GROUP BY Hour
				ORDER BY Hour
				'
    EXEC(@Sql)

	set @process = 'Setting_id 204 Configuration of Galatea integration service'
    set @Sql= 'IF not exists (SELECT * FROM ccSettings WHERE setting_id = 204)
	INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
	VALUES	(204, ''0.0.0.0|1337|1338|1'', ''Configuración de Galatea integration service'',	1,''AGT'',
			''IP|WebSocketServerPort|SocketServerPort|Autorun'',
			'' Galatea Integration Service configuration'',	1, ''.*'')'
    EXEC(@Sql)

		set @process = 'Setting_id 204 Configuration of Galatea integration service'
    set @Sql= 'IF exists (SELECT * FROM ccSettings WHERE setting_id = 204)
	UPDATE  ccSettings set valor=''0.0.0.0|1337|1338|1'', detalle=''IP|WebSocketServerPort|SocketServerPort|Autorun'' WHERE setting_id = 204'
    EXEC(@Sql)

		set @process = 'ccsp_AgentGetStartStopPermission Return Allowed tag '
    set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_AgentGetStartStopPermission]
					@age_id int,
					@cam_id int,
					@call_type int
					AS
					BEGIN
						SET NOCOUNT ON;

						declare @agentRec int, @valor as int
						set @valor = 0
						set @agentRec = (select isnull(startStopRecording,0) from ccusers (nolock) where [User_id] = @age_id)

						IF @agentRec = 1
						BEGIN
							---------- Entra agente con permiso de StartStopRecording
							IF @call_type = 1 ------- Revisamos especialidad
								set @valor = (select isnull(startStopRecording,0) from ccInbound (nolock) where Inbound_id = @cam_id)
							ELSE ------- Revisamos Campaña
								set @valor = (select isnull(startStopRecording,0) from ccCamps (nolock) where cam_id = @cam_id)
						END

						select @valor Allowed
					END'
	EXEC(@Sql)
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