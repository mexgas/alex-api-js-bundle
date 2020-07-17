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
RIGHT JOIN @relationCamSup relation on relation.cam_id = A.cam_id
INNER join ccCamps camps on camps.cam_id=relation.cam_id

END'
		EXEC(@sql)
		
		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql = ''
		EXEC(@sql)
		
		
		set @process = ''
		set @sql = ''
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
