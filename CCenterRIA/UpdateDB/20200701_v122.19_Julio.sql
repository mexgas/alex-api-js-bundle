/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.18

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 19
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 18
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'Borra tabla de series que existia para el servicio viejo'
		set @sql = 'IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE'' AND TABLE_NAME = ''SeriesCOfetel'' )
		BEGIN
			drop table SeriesCOfetel
		END'
		EXEC(@sql)

		set @process = 'crea nueva tabla de cofeteltmp'
		set @sql = 'IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE'' AND TABLE_NAME = ''SeriesTmp'' )
		BEGIN
			CREATE TABLE [dbo].[SeriesTmp](
				[CLAVE CENSAL] [varchar](255) NULL,
				[POBLACION] [varchar](255) NULL,
				[MUNICIPIO] [varchar](255) NULL,
				[ESTADO] [varchar](255) NULL,
				[PRESUSCRIPCION] [varchar](255) NULL,
				[REGION] [varchar](255) NULL,
				[ASL] [varchar](255) NULL,
				[CLD] [varchar](255) NULL,
				[SERIE] [varchar](255) NULL,
				[NUMERACION INICIAL] [int] NULL,
				[NUMERACION FINAL] [int] NULL,
				[OCUPACION] [varchar](255) NULL,
				[TIPO DE RED] [varchar](255) NULL,
				[MODALIDAD] [varchar](255) NULL,
				[RAZON SOCIAL] [varchar](255) NULL,
				[FECHA ASIGNACION] [varchar](255) NULL,
				[FECHA CONSOLIDACION] [varchar](255) NULL,
				[FECHA MIGRACION] [varchar](255) NULL,
				[CLD ANTERIOR] [varchar](255) NULL
			) ON [PRIMARY]
		END'
		EXEC(@sql)	

		set @process = 'crea nuevo sp para las acciones del servicio de cofetel drop'
		set @sql = 'if exists (select * from sys.procedures where name = N''CofetelActions'')
	    begin
	        DROP PROCEDURE CofetelActions;
	    end'
		EXEC(@sql)

		set @process = 'crea nuevo sp para las acciones del servicio de cofetel'
		set @sql='
	        CREATE PROCEDURE [dbo].[CofetelActions]
		@type tinyint
		as
		if @type = 1
		begin
			truncate table SeriesTmp
		end
		
		if @type = 2
		begin
			truncate table Series
		end
		
		declare @ret bit
		set @ret = 1
		
select @ret'
		EXEC(@sql)
		
		set @process = 'crea SP para pasar la info a tabla de series drop'
				set @sql = 'if exists (select * from sys.procedures where name = N''CofetelUpdateData'')
			    begin
			        DROP PROCEDURE CofetelUpdateData;
			    end'
		EXEC(@sql)

		set @process = 'crea SP para pasar la info a tabla de series'
		set @sql='
	        CREATE PROCEDURE [dbo].[CofetelUpdateData]
		@type tinyint
		as
		if @type = 1
		begin
			insert into Series
				select * from SeriesTmp
		end
		
		declare @ret bit
		set @ret = 1
		
		select @ret'
		EXEC(@sql)
		
		set @process = 'crea SP para pasar la info a tabla de series drop'
				set @sql = 'if exists (select * from sys.procedures where name = N''CofetelSettingsData'')
			    begin
				DROP PROCEDURE CofetelSettingsData;
			    end'
		EXEC(@sql)

		set @process = 'crea sp para leer parametros del servicio'
		set @sql = '
		CREATE PROCEDURE [dbo].[CofetelSettingsData]
		@type tinyint
		as
		if @type = 1
		begin
			select valor from ccsettings where setting_id = 172
		end
		
		'
		EXEC(@sql)

		set @process = 'actualiza datos para que corra el servicio'
		set @sql='update ccsettings set valor = ''2|4|0|01:00|vpn.nuxiba.com;22;cofeteluser;.BaY1voyT1'', detalle = ''Activo(0:apagado,1:Mensual,2:semanal,3:diario)|# Semana Ejecucion|Dia Ejecucion(1:LU,2:Ma,3:Mi,4:Ju,5:Vi,6:Sa,0:Do)|Hora Inicio(00:00)|credenciales FTP'' where setting_id = 172'
		EXEC(@sql)
        
		set @process = 'actualiza SP ccsp_DLRSaveDialResult'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
				@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
				@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
				@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(20)= '''', @call_TS VARCHAR(15)=
				''''
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
	DECLARE @logDial_id INT;
	DECLARE @tAnswerBitFinal AS DATETIME;

	SELECT @RecicleSIC = ISNULL(valor, 0)
	FROM ccSettings
	WHERE setting_id = 60;

	SELECT @tNow = GETDATE();

	SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);

	IF @call_id > 0 AND 
	   @tipoResDial_id = 1
	BEGIN
		INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
		TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
			   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy,
			   ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
			   fnGetTipoLlamada( @Telefono );
	END;
		 ELSE
	BEGIN
		INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
		TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
			   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy,
			   ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
			   @Telefono );
	END;

	SELECT @logDial_id = SCOPE_IDENTITY();

	IF @RecicleSIC = 1
	BEGIN
		UPDATE ccoWorkingTable WITH(ROWLOCK)
		  SET tipoResDial_id = @tipoResDial_id
		WHERE callout_id = @callout_id;
	END;

	SELECT @logDial_id;

	-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
	IF @call_id > 0 AND 
	   @tipoResDial_id = 1
	BEGIN
		UPDATE ccoCallsOut WITH(ROWLOCK)
		  SET cal_puerto = @Puerto, cal_manual = CASE
												 WHEN cal_manual = 1 THEN 2
													  ELSE cal_manual
												 END
		WHERE cal_id = @call_id AND 
			  cal_puerto = 0;

		EXEC ccsp_CstoCalculaCosto @call_id;

		IF @cal_key = ''''
		BEGIN
			SELECT @cal_key = cal_key
			FROM ccoCallsOutSource WITH(NOLOCK)
			WHERE @callout_id = callout_id;

			UPDATE ccologdials WITH(ROWLOCK)
			  SET cal_key = @cal_key
			WHERE logDial_id = @logDial_id;
		END;
	END;


	--2020-06-04 para marcaciones manuales no efectivas guarda el cal_id
					if @call_id > 0 and @tipoResDial_id != 1
					begin
						update ccologdials with(rowlock) set cal_id=@call_id where logDial_id=@logDial_id
					end

	-- inserta informacion para reportes de workgroup
	INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
		   SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
		   FROM ccRIACampEspWG
		   WHERE tipo = 1 AND 
				 IdCampEsp = @cam_id;

	-- Guarda configuracion de TipoDialingMode
	UPDATE ccoLogDials WITH(ROWLOCK)
	  SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
	WHERE logDial_id = @logDial_id;
	SET NOCOUNT OFF;
END;'
		EXEC(@sql)
		set @process = 'CW-4235 Galatea Valores negativos en columna de Asignadas'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetCampaignOutDialingStats'')
	    begin
	        DROP PROCEDURE ccsp_GalateaGetCampaignOutDialingStats;
	    end'
		EXEC(@sql)

		set @process = 'CW-4235 Galatea Valores negativos en columna de Asignadas'
		set @sql='
	       CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignOutDialingStats]
@Tipo as tinyint=0,
@cam_id as smallint = 0,
@sup_id as smallint=0
AS
BEGIN
declare @dateStart datetime,@dateEnd datetime
select @dateStart = convert(smalldatetime, convert(varchar(11), getdate() ), 101)  
set @dateEnd=DATEADD(dd,1,@dateStart)

declare @relationCamSup table(cam_id int primary key)

insert into @relationCamSup
select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id

;

WITH ResultDial AS (
select logDials.cam_id, count(*) as Calls,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
			count(case tipoResDial_id when 5 then 1 else null end) as NoTone,
			count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
			count(case tipoResDial_id when 11 then 1 else null end) as Machine,
			count(case tipoResDial_id when 12 then 1 else null end) as Congestion,
			count(case tipoResDial_id when 13 then 1 else null end) as Canceled		    
		    from ccoLogDials logDials with(nolock)
			inner join @relationCamSup  B ON logDials.cam_id = B.cam_id
where fecha between @dateStart and @dateEnd
--and logDials.cam_id in(1,3)
  group by logDials.cam_id
  
  )
 ,
  ResultAgent AS (
select A.cam_id, c.cam_descripcion Name,
count(case statuscall_id when 1 then 1 else null end) as Initial,
count(case statuscall_id when 2 then 1 else null end) as [OutofSchedule],
count(case statuscall_id when 3 then 1 else null end) as [OutofService],
count(case statuscall_id when 4 then 1 else null end) as [NoAgentsLoggedin],
count(case statuscall_id when 5 then 1 else null end) as [OnHold],
count(case statuscall_id when 6 then 1 else null end) as Abandoned,
count(case statuscall_id when 7 then 1 else null end) as [Timeoverflow],
count(case statuscall_id when 8 then 1 else null end) as [QueueSizeOverflow],
count(case statuscall_id when 9 then 1 else null end) as [WithMessage],
count(case statuscall_id when 10 then 1 else null end) as [Assigned Message],
count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned],
count(case statuscall_id when 13 then 1 else null end) as [Answered],
count(case statuscall_id when 14 then 1 else null end) as [Canceled Message]  
from ccoCallsOut A
inner join @relationCamSup  B ON A.cam_id = B.cam_id
inner join ccCamps c on a.cam_id = c.cam_id
where cal_Inicio  between @dateStart and @dateEnd
--and cam_id in(1,3)
group by A.cam_id, c.cam_descripcion
)

select  camps.cam_id, isnull(a.Calls, 0)Calls, isnull(a.Answer, 0)Answer, isnull(a.Busy, 0)Busy, isnull(a.NoAnswer, 0)NoAnswer, isnull(a.Fax, 0)Fax, isnull(a.NoService, 0)NoService, isnull(a.Other, 0)Other,
isnull(a.Canceled, 0)Canceled, isnull(a.Machine, 0)Machine, isnull(a.NoTone, 0) NoTone, isnull(a.Congestion, 0)Congestion,   isnull(B.Answered, 0)  Attended, isnull(B.Abandoned, 0) Abandon,isnull(B.Assigned, 0)Assigned,  
convert(decimal(5,2), isnull(( B.Abandoned*100.0)/nullif(A.Answer,0),0) )AbandonRate,camps.aggressionFactor
from ResultDial A
inner join ResultAgent B on A.cam_id=B.cam_id
inner JOIN @relationCamSup relation on relation.cam_id = A.cam_id
INNER join ccCamps camps on camps.cam_id=relation.cam_id
Order by camps.cam_descripcion
END'
		EXEC(@sql)
		
		set @process = 'Hunaku drop sp ccspHunaku_getAcdDefaultById'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspHunaku_getAcdDefaultById'')
	    begin
	        DROP PROCEDURE ccspHunaku_getAcdDefaultById;
	    end'
		EXEC(@sql)

		set @process = 'Hunaku sp que obtiene acd default  ccspHunaku_getAcdDefaultById'
		set @sql = 'create procedure ccspHunaku_getAcdDefaultById
				 @inbound_id integer
				 AS
					declare @nMaxQue smallint

					select @nMaxQue = nMaxQue from ccInbound where Inbound_id =@inbound_id

					if @nMaxQue is null 
					begin
						set @nMaxQue=0
						set @inbound_id=0
					end
					
					select @inbound_id  as inbound_id, 0 ''is900'', @nMaxQue as nMaxQue'
		EXEC(@sql)

		set @process = 'Hunaku drop sp ccspHunaku_update_cal_twait_callsOut'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspHunaku_update_cal_twait_callsOut'')
		    begin
		        DROP PROCEDURE ccspHunaku_update_cal_twait_callsOut;
		    end'
		EXEC(@sql)

		set @process = 'Hunaku sp que calcula tiempo de espera en cola  ccspHunaku_update_cal_twait_callsOut'
		set @sql = 'create procedure ccspHunaku_update_cal_twait_callsOut
			@cal_id int,
			@time_Wait int
			as
			update ccoCallsOut set cal_twait=@time_Wait where cal_id =@cal_id'
		EXEC(@sql)
   
   		set @process = 'Twitter drop sp ccsp_Multimedia'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Multimedia'')
		    begin
		        DROP PROCEDURE ccsp_Multimedia;
		    end'
		EXEC(@sql)

        set @process = 'Modificación a sp ccsp_Multimedia para regresar nombres correctos'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_Multimedia]
		@action int,@inboundId tinyint=0,@userId int =0,@meanContactTypeId tinyint = 1
		AS
		BEGIN

		SET NOCOUNT ON;

		if @action = 1 begin --Cuentas acd por tipo

			if @inboundId=0 begin
				select distinct A.inbound_id as Id,A.chat as mode,cast(A.status as bit) [Status],cast(isnull(b.isActive,0) as bit) IsActive,cast(isnull(B.numMessages,3) as int) MessageLimit,
					case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia
					,A.IDArea as AreaId
					from ccInbound A
					left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
					where isnull(A.IDArea,0)> 0 and B.meanContactTypeId=@meanContactTypeId
			end
			else begin
				select A.inbound_id as Id,A.chat as mode,cast(A.status as bit) [Status],cast(isnull(b.isActive,0) as bit) IsActive,cast(isnull(B.numMessages,3) as int) MessageLimit,
					case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia,
					A.IDArea as AreaId
					from ccInbound A
					left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
					where A.inbound_id = @inboundId and B.meanContactTypeId=@meanContactTypeId

			end
		end
		else if @action = 2 begin --Relacion entre agenetes y acd
			if @inboundId=0 and @userId = 0 begin --- Carga todas las relaciones
				select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
				from ccRIAWorkGroupUsers A
				inner join ccusers B on A.User_id=B.User_id
				inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
				inner join ccInbound D on C.idCampEsp = D.inbound_id
				left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
				where B.TipoUser_id=1 and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
				order by  C.idCampEsp
			end
			else if @inboundId>0 and @userId = 0 begin
				select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
				from ccRIAWorkGroupUsers A
				inner join ccusers B on A.User_id=B.User_id
				inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
				inner join ccInbound D on C.idCampEsp = D.inbound_id
				left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
				where B.TipoUser_id=1 and D.Inbound_id=@inboundId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
				order by  C.idCampEsp
			end
			else if @inboundId=0 and @userId > 0 begin
				select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
				from ccRIAWorkGroupUsers A
				inner join ccusers B on A.User_id=B.User_id
				inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
				inner join ccInbound D on C.idCampEsp = D.inbound_id
				left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
				where B.TipoUser_id=1 and B.User_id=@userId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
				order by  C.idCampEsp
			end
		end
		else if @action =3 begin -- Cargar relacion de agentes
			if	@userId is null or @userId=0 begin
				select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
					left join ccriacat_areas area (nolock) on area.idarea=us.idarea where TipoUser_id=1
			end
			else begin
			select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
					left join ccriacat_areas area (nolock) on area.idarea=us.idarea
					where TipoUser_id=1 and  us.User_id=@userId
			end
		end
		END'
		EXEC(@sql)

		set @process = 'Twitter drop sp ccsp_NetworkSocialAdminAccount'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_NetworkSocialAdminAccount'')
		    begin
		        DROP PROCEDURE ccsp_NetworkSocialAdminAccount;
		    end'
		EXEC(@sql)

		set @process = 'Modificación a sp ccsp_NetworkSocialAdminAccount para regresar nombres correctos'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount]
		@action int,
		@meanContactTypeId smallint = 2,
		@contactMeanId int=0,
		@name	varchar(30)=null,
		@conexionInfo	varchar(255)=null,
		@inboundId	int=0,
		@connUser	varchar(60)=null,
		@ConnPass	varchar(30)=null,
		@numMessages	tinyint=null,
		@timeAlertMessage	tinyint=null,
		@isActive bit =null,
		@UserId int =null,
		@idArea smallint =null,
		@maxMails tinyint =3,
		@answerTimeOut tinyint=null,
		@revisionTime varchar(10)=null,
		@daysTwitterRecord varchar(10)=null,
		@closeConversationTime varchar(10)=null
		AS
		BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

		declare @isActiveMail bit
		set @isActiveMail=0

		if @action = 1 begin--insert account twitter account
			DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
			if exists(select * from ContactMeanIn where conexionInfo = @conexionInfo and meanContactTypeId=@meanContactTypeId and inboundId<>@inboundId) begin
				select 0, ''Error: acount already exists''
				return -1
			end
			if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
			if @name is null set @name=''''
				--if @conexionInfo is null set @conexionInfo=''''
				if @connUser is null set @connUser=''''
				if @connPass is null set @connPass=''''
				if @numMessages is null set @numMessages=3
				if @timeAlertMessage is null set @timeAlertMessage=5
				if @isActive is null set @isActive=0
				if @answerTimeOut is null set @answerTimeOut=0
				if @closeConversationTime is null set @closeConversationTime=3

				--Twitter deja los token
				--conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
				if @meanContactTypeId= 2 begin

					if @conexionInfo is null begin
						set @conexionInfo=''usuarioID|token|tokenSecret''
						set @revisionTime=isnull(@revisionTime,''1'')
						set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
					end
					else begin
						insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
						set @conexionInfo=null

						SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

						SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
						SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
						SELECT @closeConversationTime=  isnull(@closeConversationTime,isnull(max(value),''3'')) FROM @tableConexionInfo where id=6
					end
					set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
				end


				insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
						values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
				select 1,''insert''
			end
			else begin
				select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
						@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
						@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@name=isnull(@name,name),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
						from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId

				--Twitter deja los token
				if @meanContactTypeId= 2 begin
					--usuarioID|token|tokenSecret|time|daysTwitterRecord|closeConversation
					insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
					set @conexionInfo=null

					SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

					SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
					SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5

					set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
				end



				update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
					numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
					closeConversationTime=@closeConversationTime
					where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
				select 1,''update''
			end
		end
		else if @action = 2 begin
			if @inboundId=0
				select cast(A.inboundId as smallint) as Id, A.conexionInfo as Credentials, A.connUser as AccountName, 
				A.ConnPass as Password, A.isActive as IsActive, A.name as Username from contactMeanIn A
				inner join ccInbound B on A.inboundId=B.Inbound_id
				and B.chat = case when A.meanContactTypeId=1 then 3 when A.meanContactTypeId=2 then 4 else -1 end
				where meanContactTypeId=@meanContactTypeId and isActive=1
			else
				select cast(A.inboundId as smallint) as Id, A.conexionInfo as Credentials, A.connUser as AccountName, 
				A.ConnPass as Password, A.isActive as IsActive, A.name as Username from contactMeanIn A
				inner join ccInbound B on A.inboundId=B.Inbound_id
				and B.chat = case when A.meanContactTypeId=1 then 3 when A.meanContactTypeId=2 then 4 else -1 end

				where meanContactTypeId=@meanContactTypeId and isActive=1 and inboundId=@inboundId
		end
		else if @action = 3 begin
			select A.name,A.connUser,A.numMessages,A.timeAlertMessage,A.answerTimeOut ,B.tNotas,B.descripcion,C.graphic_id,D.frame
			from ContactMeanIn A
			inner join ccinbound B on A.inboundId=B.Inbound_id
			inner join ccRIAinboundGraph C on C.Inbound_id=B.Inbound_id
			inner join ccRIAGraphics D on D.graphic_id=C.graphic_id
			where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
		end
		else if @action=4 begin
			--Estos es para Twitter
			--usuarioID|token|tokenSecret|time|daysTwitterRecord
			select isnull(max(conexionInfo),''usuarioID|token|tokenSecret|1|0'') from contactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
		end
		END'
		EXEC(@sql)

		set @process = 'Twitter drop sp ccspADMaddConversationTweet'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspADMaddConversationTweet'')
		    begin
		        DROP PROCEDURE ccspADMaddConversationTweet;
		    end'
		EXEC(@sql)

		set @process = 'Modificación a sp ccspADMaddConversationTweet para regresar nombres correctos'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspADMaddConversationTweet]
		@action int,
		@inboundId int = null,
		@clientId varchar(255)= null,
		@isFinished bit = 0,
		@screenNameClient varchar(100) = null,
		@screenNameInbound varchar(100) = null,
		@meanContactTypeId smallint = null,
		@twitId varchar(255) = null,
		@conversationId bigint = null,
		@date datetime=null,
		@replayId varchar(255)=null,
		@tipoTwitId tinyint=1,
		@messageId bigint = null,
		@dispositionId smallint=0,
		@subDispositionId smallint=0,
		@tWrapUp int =0

		as
		set nocount on

		declare @ninteration int ,@messageOutTwitterId bigint
		declare @userId int
		declare @isEndConversation bit


		if @action = 1 begin --Revisa que exista la conversacion
			select @conversationId =  isnull(max(conversationTwitterId),0) from conversationTwitter where isFinished = 0 and meanContactTypeId = 2 and ClientId = @clientId and inboundId=@inboundId
			if @conversationId = 0
				select cast(0 as bigint) as Id
			else begin
				declare @closeConversation tinyint
				declare @tRsponse datetime
				select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
				select @closeConversation = closeConversationTime from contactMeanIn where inboundId=@inboundId
				 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
					select  cast(0 as bigint)  as Id
				else
					select @conversationId as Id
			end
		    return 0
		end
		else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
		    --agregar tabla de messagetwit fecha de descarga
			if @replayId is null or @replayId=''''
				set @replayId= ''0''
		    insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
		    values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
		    set  @conversationId  = SCOPE_IDENTITY()
			insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
			set @messageId=SCOPE_IDENTITY()
			insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
			values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
		    select 0 as LastUserId,@conversationId as Id, @messageId as MessageId
		    return 0
		end
		else if @action = 3 begin --Nuevo mensaje Entrada
			---Revisa que no se contesto el twitt
			select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
			from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
			where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)

			insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
			set @messageId=SCOPE_IDENTITY()

			if  @messageOutTwitterId is null begin
				insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
				values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
				set @messageOutTwitterId=SCOPE_IDENTITY()
			end
			else begin
				update messageOutTwitter set messageInTwitterIdEnd=@messageId,[date]=@date,ninteration=@ninteration
				where messageOutTwitterId=@messageOutTwitterId
			end
			select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
			select @userId as LastUserId,@conversationId as Id, @messageId as MessageId
			return 0
		end
		else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
		    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
			select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
			select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
			return 0
		end
		else if @action = 5 begin --Ultimo mensaje en por ACD
		    select cast(isnull(max(twitId),0)as bigint) as Id, max(date) as Date from messageInTwitter as A
			inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
			where B.inboundId=@inboundId
			return 0
		end
		else if @action = 6 begin --Obtiene conversación dependiendo del replayId
			select @conversationId=conversationTwitterId  from messageOutTwitter where twitId=@replayId
			if @conversationId is not null begin
				select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
			end
			else begin
				select 0 as conversationId,''0'' as replayId
			end
			select @conversationId as conversationId,@replayId as replayId
			return 0
		end

		set nocount off'
		EXEC(@sql)

		

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
