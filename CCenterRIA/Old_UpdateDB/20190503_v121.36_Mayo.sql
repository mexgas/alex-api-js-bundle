/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

Se agrega la tarea
CW-2831
CW-2645 
CW-2556
CW-2543
CW-2863 Alter ccsp_RIAGetCampsNvosCB

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 36

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 35
BEGIN
	BEGIN TRAN

	BEGIN TRY
		SET @process = 'CW-2831 Alter ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
@cal_id INT
AS
DECLARE @disconnectCause AS VARCHAR(250)
--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTA ACTIVO
DECLARE @callout_id AS INT
IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
BEGIN
	--OBTIENE EL CALLOUT_ID A TRAVES DEL CAL_ID
	SELECT @callout_id=callout_id FROM ccoCallsOut WHERE cal_id = @cal_id
	--VERIFICA SI EL CALLOUT_ID EXISTE
	IF @callout_id IS NOT NULL
	BEGIN
		--SE OBTIENE EL MESAJE DE ERROR DEL CARRIER A TRAVES DEL CALLOUT_ID
		SELECT @disconnectCause=disconnectCause
		FROM ccoLogDials
		WHERE callout_id = @callout_id

		WHILE PATINDEX(''%[^0-9]%'',@disconnectCause) <> 0
		BEGIN
		    --ELIMINA LAS LETRAS PARA DEJAR SOLO NUMEROS
		    SET @disconnectCause = STUFF(@disconnectCause,PATINDEX(''%[^0-9]%'',@disconnectCause),1,'''')
		END

		--VALIDA QUE EXISTA UN MENSAJE DE ERROR PARA EL CODIGO
		IF EXISTS (SELECT message_description FROM ccGalateaCustomErrorMessages WHERE message_id = @disconnectCause)
		BEGIN
			--REGRESA MENSAJE ASOCIADO AL CODIGO DE ERROR
			SELECT message_description
			FROM ccGalateaCustomErrorMessages
			WHERE message_id = @disconnectCause
		END
		ELSE
		BEGIN
			--REGRESA MENSAJE DE ERROR NO ENCONTRADO SI AL MOMENTO DE CONSULTAR NO EXISTE UN ERROR
			IF @disconnectCause IS NULL
			BEGIN
				SELECT ''ERROR_NOT_FOUND'' ''message_description''
			END
			ELSE
			BEGIN
				--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA UNO ASOCIADO AL COIGO DE ERROR
				SELECT message_description
				FROM ccGalateaCustomErrorMessages
				WHERE message_id = ''DEFAULT''
			END
		END
	END
	ELSE
	BEGIN
		--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA EN CCOLOGDIALS EL CALLOUT_ID
		SELECT message_description
		FROM ccGalateaCustomErrorMessages
		WHERE message_id = ''DEFAULT''
	END
END
ELSE
BEGIN
	--REGRESA UN MENSAJE PREDETERMINADO PARA INFORMAR QUE EL SETTING ESTE DESHABILITADO
	SELECT ''SETTING_DISABLED'' ''message_description''
END
						'

		EXEC (@Sql)

		SET @process = 'CW-2645 ST_2019_01_31 ALter SP ccsp_OUTUpdateDialJob'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id int,
@CallResultDial tinyint,
@isTCPA bit =0
as
set nocount on
/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/
declare @nOcupado tinyint, @nNoContesta tinyint, @nFax tinyint, @nContestadora tinyint
declare @nShortCall tinyint, @nOtro tinyint, @cam_NoInt_ocupado tinyint, @cam_NoInt_graba tinyint
declare @cam_ocupado smallint, @cam_inter_ocupado smallint, @cam_nocontesto smallint
declare @cam_graba smallint, @cam_inter_graba smallint, @cam_inter_nocontesto smallint
declare @cam_fax smallint, @cam_inter_fax smallint
declare @DateNextDial smalldatetime, @DateNewDial smalldatetime, @cam_id smallint
declare @ExisteWT tinyint, @cam_NoInt_fax tinyint, @cam_NoInt_nocontesto tinyint,@cal_status tinyint
declare @sSQL nvarchar(max), @Telefono varchar(15)

SELECT @cam_id=cam_id, @nOcupado=IsNull(nOcupado, 0), @nNoContesta=IsNull(nNoContesta,0),
	@nFax=IsNull(nFax, 0), @nContestadora=IsNull(nContestadora, 0),@nShortCall=IsNull(nShortCall,0),
	@nOtro=IsNull(nOtro,0),@DateNextDial=cal_fechaDial
FROM ccoWorkingTable WHERE callout_id = @callout_id

select @ExisteWT=case when @cam_id is not null then 1 else 0 end

select @cal_status= case when @isTCPA=1 then 0 else 1 end--si esta en modo TCPA no generar callbacks

IF @CallResultDial=20 -- CONTACTADO
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=1 BEGIN-- CONTESTO 
	IF @isTCPA=1 BEGIN	
		UPDATE ccoWorkingTable SET cal_status=@cal_status WHERE callout_id = @callout_id
	END
	ELSE BEGIN
		if (select abandonCallback from ccCamps where cam_id = @cam_id) = 1 begin
			EXEC ccsp_OUTCancelDialJOB @callout_id, 1, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		end
		else begin
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		end
	END
	return(0)
END

else IF @CallResultDial in (2,12) BEGIN -- OCUPADO 
	SELECT @cam_ocupado =cam_ocupado, @cam_inter_ocupado=cam_inter_ocupado, @cam_NoInt_ocupado=cam_NoInt_ocupado, @nOcupado= @nOcupado+1
	FROM ccCamps WHERE cam_id=@cam_id
	
	IF @cam_ocupado=1 BEGIN-- Opcion Ocupado HABILITADA	 
		IF @nOcupado>@cam_NoInt_ocupado or @nShortCall>4 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT
		
		SELECT @DateNewDial=dateadd(mi, @cam_inter_ocupado, getdate())
		-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
		IF @DateNewDial>@DateNextDial BEGIN	-- Nueva fecha de Call BACk
			UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_fechaDial=@DateNewDial, cal_status=@cal_status WHERE callout_id = @callout_id
			return(0)
		 END
			-- Mantiene la fecha de Call BACK
		UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_status=@cal_status, cal_telefono=@Telefono  WHERE callout_id = @callout_id
		return(0)
	 END

-- ELSE: Opcion Ocupado DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
  END

else IF @CallResultDial in (3,5,8) BEGIN-- NO CONTESTA 
	--select NO Contesta
	SELECT @cam_nocontesto =cam_nocontesto, @cam_inter_nocontesto=cam_inter_nocontesto, @cam_NoInt_nocontesto=cam_NoInt_nocontesto, @nNoContesta=@nNoContesta+1
	FROM ccCamps WHERE cam_id=@cam_id

	--SELECT @cam_nocontesto, @cam_inter_nocontesto, @cam_NoInt_nocontesto, @nNoContesta
	IF @cam_nocontesto=1 BEGIN-- Opcion NoContesta HABILITADA	 
				IF @nNoContesta>@cam_NoInt_nocontesto or @nShortCall>4 BEGIN --select No Contesta Habilitada
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_nocontesto, getdate())		
		UPDATE ccoWorkingTable SET nNoContesta =@nNoContesta, cal_status=@cal_status, cal_telefono=@Telefono, 
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id
		return(0)
	 END

	-- Opcion NoContesta DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

else IF @CallResultDial=4 BEGIN-- Fax/Modem 
	SELECT @cam_fax =cam_fax, @cam_inter_fax=cam_inter_fax, @cam_NoInt_fax=cam_NoInt_fax, @nFax=@nFax +1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_fax=1 BEGIN-- Opcion Fax/Modem HABILITADA	 
		IF @nFax>@cam_NoInt_fax or @nShortCall>4 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nFax=case when nFax < 255 then isnull(nFax,0)+1 else nFax end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_fax, getdate())

		-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
		UPDATE ccoWorkingTable SET nFax =@nFax, cal_status=@cal_status, cal_telefono=@Telefono,
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id

		return(0)
	 END

	-- Opcion Fax/Modem DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

else IF @CallResultDial=11 BEGIN-- Maquina Contestadora 
	SELECT @cam_graba =cam_graba, @cam_inter_graba=cam_inter_graba, @cam_NoInt_graba=cam_NoInt_graba, @nContestadora=@nContestadora+1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_graba=1 -- Opcion Maquina Contestadora HABILITADA
	 BEGIN
		IF @nContestadora>@cam_NoInt_graba or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		 -- Change priority and obtain the next telephone
		 update ccoCallsOutSource set nContestadora=case when nContestadora < 255 then isnull(nContestadora,0)+1 else nContestadora end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_graba, getdate())

		-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
		UPDATE ccoWorkingTable SET nContestadora =@nContestadora, cal_status=@cal_status, cal_telefono=@Telefono,
		cal_fechaDial= case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id
		return(0)
	 END

	-- Opcion Maquina Contestadora DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

else IF @CallResultDial in (10,90) BEGIN--No Dial Tone, otros, NoService 
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

else if @CallResultDial > 13 and @CallResultDial <> 51 begin--Dial Result not register
	exec ccsp_OUTUpdateDialJob @callout_id=@callout_id,@CallResultDial=8,@isTCPA=@isTCPA
 end


return(0)
set nocount off	'

		EXEC (@Sql)

		SET @process = 'CW-2556 ST_2018_12_35 some area codes are missing (USA)'
		SET @Sql = '  declare @table table(id_country	smallint, area	varchar(10), location	varchar(50),tz_standard	int,tz_daylight	int,call_record	bit )

  insert into @table 
  select 4,327,''AR'',64,32,null
  union
  select 4,986,''ID'',128,64,null
  union
  select 4,930,''IN'',32,16,null
  union
  select 4,332,''NY'',32,16,null
  union
  select 4,680,''NY'',32,16,null
  union
  select 4,838,''NY'',32,16,null
  union
  select 4,929,''NY'',32,16,null  
  union
  select 4,934,''NY'',32,16,null
  union
  select 4,445,''PA'',32,16,null
  
  insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
  select A.id_country, A.area, A.location, A.tz_standard, A.tz_daylight, A.call_record from @table A
  left join ccTimeZoneArea B on A.id_country=B.id_country and A.area=B.area and A.location=B.location and a.tz_standard=B.tz_standard and A.tz_daylight=B.tz_daylight
  where B.id_country is null'

		EXEC (@Sql)

		SET @process = 'CW-2909 CenterwareWS call history date'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
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
if @action = 1  begin
	if(@startDate = '''' or @startDate is null)
	begin
	 set @startDate = (select top 1 cal_inicio from ccCallsIn order by cal_Inicio)
	end
	if(@endDate = '''' or @endDate is null)
	begin
	 set @endDate = (select top 1 cal_inicio from ccCallsIn order by cal_Inicio desc)
	end
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
  where cal_id >= @call_id and c.cal_Inicio >= @startDate and c.cal_Inicio <= @endDate
  order by cal_Inicio
  end

-- OUTBOUND x cal_id
else if @action = 2   begin
	if(@startDate = '''' or @startDate is null)
	begin
	 set @startDate = (select top 1 cal_inicio from ccoCallsOut order by cal_Inicio)
	 --select @startDate
	end
	if(@endDate = '''' or @endDate is null)
	begin
	 set @endDate = (select top 1 cal_inicio from ccoCallsOut order by cal_Inicio desc)
	 --select @endDate
	end
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
  where cal_id >= @call_id and c.cal_Inicio >= @startDate and c.cal_Inicio <= @endDate
  order by cal_Inicio
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
      isnull(b.user_id,0) as user_id, isnull(login,''''),
      isnull(e.description,'''') as disposition,
      d.descripcion as call_status,
      cal_tDialog as call_tDialog,cal_inicio as call_date,
      cal_tNotas as WrapUp,cal_tXfer as Xfer,
      cal_tRing as Ringing,cal_manual as CallManual,
      c.cal_key as callKey,list_id,
      isnull(e.calif_id,'''') as dispositionId,
      isnull(f.califSubDesc,'''') as subDisposition,
      isnull(f.califSub_id,'''') as subDispositionId,
      rowNum,
      cs.Dato1,
      cs.Dato2,
      cs.Dato3,
      cs.Dato4,
      cs.Dato5
    from (
    select ROW_NUMBER() OVER ( ORDER BY cal_id ) AS rowNum,
      c.callout_id,cal_id,c.cam_id,c.cal_telefono,cal_tDialog ,cal_inicio,cal_tNotas,
      cal_tXfer,cal_tRing ,cal_manual,c.cal_key,c.statusCall_id,c.calif_id,c.califSub_id,c.user_id
     from ccocallsout c with(nolock,index(IX_ccoCallsOut_3)) where cam_id=@camId
     --and cal_Inicio >= @date and cal_Inicio<GETDATE()
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
    select @countRegistry = count(*)   from ccocallsout c with(nolock,index(IX_ccoCallsOut_3)) where cam_id=@camId
    --and cal_Inicio >= @date and cal_Inicio<GETDATE()
    select @RowsPerPage as pagesize, @PageNumber as  currentpage, @countRegistry/cast(@RowsPerPage as float) as totalpages
  end
end'

		EXEC (@Sql)

		-- *********************** END 	121.03-5_20190430 *********************** ---
		-- *********************** Begin 121.03-6_20190513 *********************** ---
		SET @process = 'CW-2543 Insert setting 213'
		SET @Sql = 'IF NOT EXISTS (SELECT * FROM ccSettings WHERE setting_id = 213)
BEGIN
	INSERT INTO ccSettings (setting_id, valor, descripcion, STATUS, Tipo, detalle, description, bLoadSettings, validate)
	VALUES (213, ''0'', ''Marcar números a 10 dígitos al utilizar un ANI local predeterminado.'', 1, ''X'', ''0 - Marcacion normal / 1 - Marcacion de ANI local a 10 digitos'', ''Set dialing format according to custom local ANI numbers.'', 0, ''^[0-1]$'')
END'

		EXEC (@Sql)

		SET @process = 'CW-2543 --ALTER PROCEDURE ccsp_Limpia'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_Limpia] @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = ''''
AS
SET NOCOUNT ON

DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, 
@specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
DECLARE @checkLd_In_ANILst SMALLINT 
set @checkLd_In_ANILst=0
/***
 4  as res lista Negra
 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
 3 as res Number notExists
 1 as res Longitud invalida
 0 as res Numero correcto
 
***/
SELECT @tel = dbo.limpia(@tel)

SELECT @lon = len(@tel)

SELECT @pais = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 104

SELECT @cldLocal = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 17

SELECT @extLen = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 108

SELECT @validateTel = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 206

SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213


IF @lon > 1
BEGIN
	IF @validateTel = 1
	BEGIN --Setting 206 para no validar longitud ni listas negras
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	IF @extLen = @lon
	BEGIN -- Setting 108 validar el tamaño longitud del telefono
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList

			RETURN (0)
		END

		SELECT 0 AS res, @tel AS tel -- Extension

		RETURN (0)
	END
END

DECLARE @telTemp AS VARCHAR(15)

SELECT @telTemp = @tel

IF @pais = 1
BEGIN ---Mexico
	IF @lon = 3 AND @tel = ''911''
	BEGIN
		SELECT 4 AS res, @tel AS tel --Lista Negra

		RETURN (0)
	END

	IF (@lon < 10)
	BEGIN
		SELECT 1 AS res, @tel AS tel --Longitud invalida

		RETURN (0)
	END

	IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
	BEGIN
		SELECT 2 AS res, @tel AS tel --Digitos incorrectos

		RETURN (0)
	END

	IF left(@tel, 3) = ''001''
	BEGIN
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	SELECT @tel = right(@tel, 10)

	IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList

		RETURN (0)
	END
	
	If (@Camp > 0 AND @checkLd_In_ANILst = 1)
	BEGIN
		If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.	
		BEGIN
			SELECT 0 AS res, @tel AS tel	
			RETURN (0)
		END

		IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
		ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
	END


	SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal)

	IF LEFT(@tel, 1) = ''E''
	BEGIN
		SELECT 3 AS res, @telTemp AS tel --No encontrado

		RETURN (0)
	END

	SELECT 0 AS res, @tel AS tel

	RETURN (0)
END
ELSE IF @pais = 2
BEGIN --Argentina 
	SET @tel = dbo.completa(@tel, @pais, @cldLocal)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.fnClearPhoneArg(@tel)

	IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos      
	END

	RETURN (0)
END
ELSE IF @pais = 3
BEGIN --Colombia  
	IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 4
BEGIN --USA 
	EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

	RETURN (0)
END
ELSE IF @pais = 5
BEGIN --Chile  
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 6
BEGIN --Venezuela    
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 7
BEGIN --Reino Unido
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 8
BEGIN --Arabia saudita   
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10, 11))
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama 
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp --Longitud Invalida   
	END
	ELSE IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList      
	END
	ELSE
	BEGIN
		SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
		END

		SELECT 0 AS res, @tel AS tel
	END

	RETURN (0)
END
'

		EXEC (@Sql)

		-- *********************** END 121.03-6_20190513 *********************** ---
		-- *********************** BEGIN 121.03-6_20190515*********************** ---
		SET @process = 'CW-2910 CenterwareWS Agent Status Function'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory] @action SMALLINT
	,@call_id INT = 0
	,@startDate VARCHAR(30) = NULL
	,@endDate VARCHAR(30) = NULL
	,@state INT = 0
	,@multipleCall_id AS VARCHAR(500) = NULL
	,@multipleUser_id AS VARCHAR(500) = NULL
	,@agentId INT = 0
	,@camId INT = 0
	,@PageNumber INT = 1
	,@isCount BIT = false
	,@userName AS VARCHAR(20) = ''''
	,@password AS VARCHAR(33) = ''''
AS
DECLARE @RowsPerPage INT

SET @RowsPerPage = 500

-- INBOUND x cal_id
IF @action = 1
BEGIN
	IF (
			@startDate = ''''
			OR @startDate IS NULL
			)
	BEGIN
		SET @startDate = (
				SELECT TOP 1 cal_inicio
				FROM ccCallsIn
				ORDER BY cal_Inicio
				)
	END

	IF (
			@endDate = ''''
			OR @endDate IS NULL
			)
	BEGIN
		SET @endDate = (
				SELECT TOP 1 cal_inicio
				FROM ccCallsIn
				ORDER BY cal_Inicio DESC
				)
	END

	SELECT TOP 500 cal_id AS call_id
		,c.inbound_id
		,isnull(a.descripcion, '''') AS acdGroup
		,cal_ani AS phoneNumber
		,isnull(b.user_id, 0) AS [user_id]
		,isnull(LOGIN, '''') AS LOGIN
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_key AS callKey
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
		,cal_tmoh AS hold
	FROM cccallsin c WITH (NOLOCK)
	LEFT JOIN ccInbound a ON (c.Inbound_id = a.Inbound_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalif e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSub f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id >= @call_id
		AND c.cal_Inicio >= @startDate
		AND c.cal_Inicio <= @endDate
	ORDER BY cal_Inicio
END
		-- OUTBOUND x cal_id
ELSE IF @action = 2
BEGIN
	IF (
			@startDate = ''''
			OR @startDate IS NULL
			)
	BEGIN
		SET @startDate = (
				SELECT TOP 1 cal_inicio
				FROM ccoCallsOut
				ORDER BY cal_Inicio
				)
			--select @startDate
	END

	IF (
			@endDate = ''''
			OR @endDate IS NULL
			)
	BEGIN
		SET @endDate = (
				SELECT TOP 1 cal_inicio
				FROM ccoCallsOut
				ORDER BY cal_Inicio DESC
				)
			--select @endDate
	END

	SELECT TOP 500 cal_id AS call_id
		,c.cam_id
		,isnull(a.cam_descripcion, '''') AS Campaign
		,c.cal_telefono AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '''')
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_manual AS CallManual
		,c.cal_key AS callKey
		,list_id
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
		,cal_tmoh AS hold
	FROM ccocallsout c WITH (NOLOCK)
	LEFT JOIN ccocallsoutsource cs ON (cs.callout_id = c.callout_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id >= @call_id
		AND c.cal_Inicio >= @startDate
		AND c.cal_Inicio <= @endDate
	ORDER BY cal_Inicio
END
ELSE IF @action = 3
BEGIN --Session time
	DECLARE @fecha_ini DATETIME
	DECLARE @fecha_fin DATETIME

	IF (
			@startDate IS NULL
			OR @endDate IS NULL
			)
		OR (
			@startDate = ''''
			OR @endDate = ''''
			)
	BEGIN
		SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(30), getdate()))

		SELECT @fecha_fin = dateadd(ss, - 1, dateadd(dd, 1, convert(DATETIME, convert(VARCHAR(11), getdate()))))
	END
	ELSE
	BEGIN
		SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(30), @startDate))

		SELECT @fecha_fin = convert(DATETIME, convert(VARCHAR(30), @endDate))
	END

	SELECT user_id
		,LOGIN
		,logout
		,datediff(ss, LOGIN, logout) AS logintime
	FROM (
		SELECT a.user_id
			,a.fecha AS ''login''
			,(
				SELECT isnull(max(Fecha), getdate())
				FROM ccLogLogin b WITH (NOLOCK)
				WHERE b.user_id = a.user_id
					AND b.tipomov = 0
					AND b.fecha >= a.fecha
					AND b.fecha <= (
						SELECT isnull(min(fecha), ''99991231 23:59:59.998'')
						FROM ccLogLogin WITH (NOLOCK)
						WHERE user_id = b.user_id
							AND tipomov = 1
							AND fecha > a.fecha
						)
				) AS ''logout''
		FROM ccLogLogin a
		WHERE a.tipomov = 1
			AND fecha >= @fecha_ini
			AND fecha <= @fecha_fin
		) AS sessiontime
	ORDER BY user_id
		,LOGIN
END
ELSE IF @action = 4
BEGIN -- Estados de los agentes
	SELECT User_id
		,tStatus
		,fecha
	FROM cclogagentesdia WITH (NOLOCK)
	WHERE TipoStatusAge_id = @state
		AND fecha >= @startDate
		AND fecha < @endDate
	ORDER BY User_id
		,fecha
END
ELSE IF @action = 5
BEGIN -- Sinlge Call id Inbound
	SELECT TOP 500 cal_id AS call_id
		,c.inbound_id
		,isnull(a.descripcion, '''') AS acdGroup
		,cal_ani AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '''') AS LOGIN
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_key AS callKey
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
	FROM cccallsin c WITH (NOLOCK)
	LEFT JOIN ccInbound a ON (c.Inbound_id = a.Inbound_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalif e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSub f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleCall_id, '','')
			)
END
ELSE IF @action = 6
BEGIN -- Single call_id Outbound
	SELECT TOP 500 cal_id AS call_id
		,c.cam_id
		,isnull(a.cam_descripcion, '''') AS Campaign
		,c.cal_telefono AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '''')
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_manual AS CallManual
		,c.cal_key AS callKey
		,cs.list_id
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
	FROM ccocallsout c WITH (NOLOCK)
	LEFT JOIN ccocallsoutsource cs(NOLOCK) ON (cs.callout_id = c.callout_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleCall_id, '','')
			)
END
ELSE IF @action = 7
BEGIN --Status Agente
	SELECT tipostatusAge_id
		,tstatus
		,dateadd(ss, (- 1 * tstatus), fecha)
		,IdCampEsp
		,Tipo
	FROM cclogagentesdia WITH (NOLOCK)
	WHERE user_id = @agentId
		AND fecha >= @startDate
		AND fecha < @endDate
	ORDER BY fecha
END
ELSE IF @action = 8
BEGIN
	SELECT tipostatusAge_id
		,tstatus
		,dateadd(ss, (- 1 * tstatus), fecha) fecha
		,IdCampEsp
		,Tipo
		,user_id
	FROM cclogagentesdia WITH (
			INDEX (IX_ccLogAgentesDia_4)
			,NOLOCK
			)
	WHERE user_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleUser_id, '','')
			)
		AND fecha BETWEEN @startDate
			AND @endDate
	ORDER BY user_id
		,fecha
END
ELSE IF @action = 9
BEGIN --Call History by CamId and day
	DECLARE @date DATETIME
		,@countRegistry BIGINT

	IF @PageNumber <= 0
		SET @PageNumber = 1
	SET @date = convert(DATETIME, convert(NVARCHAR(11), GETDATE(), 121))

	IF @isCount = 0
	BEGIN ---Datos para la informacion
		SELECT cal_id AS call_id
			,c.cam_id
			,isnull(a.cam_descripcion, '''') AS Campaign
			,c.cal_telefono AS phoneNumber
			,isnull(b.user_id, 0) AS user_id
			,isnull(LOGIN, '''')
			,isnull(e.description, '''') AS disposition
			,d.descripcion AS call_status
			,cal_tDialog AS call_tDialog
			,cal_inicio AS call_date
			,cal_tNotas AS WrapUp
			,cal_tXfer AS Xfer
			,cal_tRing AS Ringing
			,cal_manual AS CallManual
			,c.cal_key AS callKey
			,list_id
			,isnull(e.calif_id, '''') AS dispositionId
			,isnull(f.califSubDesc, '''') AS subDisposition
			,isnull(f.califSub_id, '''') AS subDispositionId
			,rowNum
			,cs.Dato1
			,cs.Dato2
			,cs.Dato3
			,cs.Dato4
			,cs.Dato5
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY cal_id
					) AS rowNum
				,c.callout_id
				,cal_id
				,c.cam_id
				,c.cal_telefono
				,cal_tDialog
				,cal_inicio
				,cal_tNotas
				,cal_tXfer
				,cal_tRing
				,cal_manual
				,c.cal_key
				,c.statusCall_id
				,c.calif_id
				,c.califSub_id
				,c.user_id
			FROM ccocallsout c WITH (
					NOLOCK
					,INDEX (IX_ccoCallsOut_3)
					)
			WHERE cam_id = @camId
				--and cal_Inicio >= @date and cal_Inicio<GETDATE()
			) AS c
		LEFT JOIN ccocallsoutsource cs ON (cs.callout_id = c.callout_id)
		LEFT JOIN ccusers b ON (c.user_id = b.user_id)
		LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
		LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
		LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
		LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
		WHERE rowNum BETWEEN ((@PageNumber - 1) * @RowsPerPage) + 1
				AND @RowsPerPage * (@PageNumber)
	END
	ELSE
	BEGIN --Numero de paginas y registros actuales
		SELECT @countRegistry = count(*)
		FROM ccocallsout c WITH (
				NOLOCK
				,INDEX (IX_ccoCallsOut_3)
				)
		WHERE cam_id = @camId

		--and cal_Inicio >= @date and cal_Inicio<GETDATE()
		SELECT @RowsPerPage AS pagesize
			,@PageNumber AS currentpage
			,@countRegistry / cast(@RowsPerPage AS FLOAT) AS totalpages
	END
END
ELSE IF (@action = 10)
BEGIN -- get agent status (Logged in or Logged out)
	DECLARE @isLoggedIn AS INT
	DECLARE @lastLogIn_Out AS DATETIME
	DECLARE @status AS INT

	SELECT @status = tipostatusage_id
	FROM ccUsers
	WHERE User_id = @agentId
		AND TipoUser_id = 1

	--SELECT @status
	IF (@status = 3)
	BEGIN
		SELECT @isLoggedIn = 1

		SELECT @lastLogIn_Out = max(fecha)
		FROM ccLogLogin
		WHERE fecha >= convert(DATE, getdate())
			AND User_id = @agentId
			AND TipoMov = 1 -- Login
	END
	ELSE IF (@status = 0)
	BEGIN
		SELECT @isLoggedIn = @status

		SELECT @lastLogIn_Out = max(fecha)
		FROM ccLogLogin
		WHERE fecha >= CONVERT(DATE, getdate())
			AND User_id = @agentId
			AND TipoMov = 0 --Logout 
	END

	SELECT @isLoggedIn
		,@lastLogIn_Out
END
ELSE IF (@action = 11) -- verify User
BEGIN
	DECLARE @response AS INT

	SELECT @response = User_id
	FROM ccUsers
	WHERE LOGIN = @username
		AND password = dbo.md5(@password)

	SELECT isnull(@response, '''')
END'

		EXEC (@sql)

		SET @process = 'CW-2910 CenterwareWS Agent Status Function'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory] @action SMALLINT
	,@call_id INT = 0
	,@startDate VARCHAR(30) = NULL
	,@endDate VARCHAR(30) = NULL
	,@state INT = 0
	,@multipleCall_id AS VARCHAR(500) = NULL
	,@multipleUser_id AS VARCHAR(500) = NULL
	,@agentId INT = 0
	,@camId INT = 0
	,@PageNumber INT = 1
	,@isCount BIT = false
	,@userName AS VARCHAR(20) = ''''
	,@password AS VARCHAR(33) = ''''
AS
DECLARE @RowsPerPage INT

SET @RowsPerPage = 500

-- INBOUND x cal_id
IF @action = 1
BEGIN
	IF (
			@startDate = ''''
			OR @startDate IS NULL
			)
	BEGIN
		SET @startDate = (
				SELECT TOP 1 cal_inicio
				FROM ccCallsIn
				ORDER BY cal_Inicio
				)
	END

	IF (
			@endDate = ''''
			OR @endDate IS NULL
			)
	BEGIN
		SET @endDate = (
				SELECT TOP 1 cal_inicio
				FROM ccCallsIn
				ORDER BY cal_Inicio DESC
				)
	END

	SELECT TOP 500 cal_id AS call_id
		,c.inbound_id
		,isnull(a.descripcion, '''') AS acdGroup
		,cal_ani AS phoneNumber
		,isnull(b.user_id, 0) AS [user_id]
		,isnull(LOGIN, '''') AS LOGIN
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_key AS callKey
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
		,cal_tmoh AS hold
	FROM cccallsin c WITH (NOLOCK)
	LEFT JOIN ccInbound a ON (c.Inbound_id = a.Inbound_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalif e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSub f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id >= @call_id
		AND c.cal_Inicio >= @startDate
		AND c.cal_Inicio <= @endDate
	ORDER BY cal_Inicio
END
		-- OUTBOUND x cal_id
ELSE IF @action = 2
BEGIN
	IF (
			@startDate = ''''
			OR @startDate IS NULL
			)
	BEGIN
		SET @startDate = (
				SELECT TOP 1 cal_inicio
				FROM ccoCallsOut
				ORDER BY cal_Inicio
				)
			--select @startDate
	END

	IF (
			@endDate = ''''
			OR @endDate IS NULL
			)
	BEGIN
		SET @endDate = (
				SELECT TOP 1 cal_inicio
				FROM ccoCallsOut
				ORDER BY cal_Inicio DESC
				)
			--select @endDate
	END

	SELECT TOP 500 cal_id AS call_id
		,c.cam_id
		,isnull(a.cam_descripcion, '''') AS Campaign
		,c.cal_telefono AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '''')
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_manual AS CallManual
		,c.cal_key AS callKey
		,list_id
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
		,cal_tmoh AS hold
	FROM ccocallsout c WITH (NOLOCK)
	LEFT JOIN ccocallsoutsource cs ON (cs.callout_id = c.callout_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id >= @call_id
		AND c.cal_Inicio >= @startDate
		AND c.cal_Inicio <= @endDate
	ORDER BY cal_Inicio
END
ELSE IF @action = 3
BEGIN --Session time
	DECLARE @fecha_ini DATETIME
	DECLARE @fecha_fin DATETIME

	IF (
			@startDate IS NULL
			OR @endDate IS NULL
			)
		OR (
			@startDate = ''''
			OR @endDate = ''''
			)
	BEGIN
		SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(30), getdate()))

		SELECT @fecha_fin = dateadd(ss, - 1, dateadd(dd, 1, convert(DATETIME, convert(VARCHAR(11), getdate()))))
	END
	ELSE
	BEGIN
		SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(30), @startDate))

		SELECT @fecha_fin = convert(DATETIME, convert(VARCHAR(30), @endDate))
	END

	SELECT user_id
		,LOGIN
		,logout
		,datediff(ss, LOGIN, logout) AS logintime
	FROM (
		SELECT a.user_id
			,a.fecha AS ''login''
			,(
				SELECT isnull(max(Fecha), getdate())
				FROM ccLogLogin b WITH (NOLOCK)
				WHERE b.user_id = a.user_id
					AND b.tipomov = 0
					AND b.fecha >= a.fecha
					AND b.fecha <= (
						SELECT isnull(min(fecha), ''99991231 23:59:59.998'')
						FROM ccLogLogin WITH (NOLOCK)
						WHERE user_id = b.user_id
							AND tipomov = 1
							AND fecha > a.fecha
						)
				) AS ''logout''
		FROM ccLogLogin a
		WHERE a.tipomov = 1
			AND fecha >= @fecha_ini
			AND fecha <= @fecha_fin
		) AS sessiontime
	ORDER BY user_id
		,LOGIN
END
ELSE IF @action = 4
BEGIN -- Estados de los agentes
	SELECT User_id
		,tStatus
		,fecha
	FROM cclogagentesdia WITH (NOLOCK)
	WHERE TipoStatusAge_id = @state
		AND fecha >= @startDate
		AND fecha < @endDate
	ORDER BY User_id
		,fecha
END
ELSE IF @action = 5
BEGIN -- Sinlge Call id Inbound
	SELECT TOP 500 cal_id AS call_id
		,c.inbound_id
		,isnull(a.descripcion, '''') AS acdGroup
		,cal_ani AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '''') AS LOGIN
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_key AS callKey
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
	FROM cccallsin c WITH (NOLOCK)
	LEFT JOIN ccInbound a ON (c.Inbound_id = a.Inbound_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalif e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSub f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleCall_id, '','')
			)
END
ELSE IF @action = 6
BEGIN -- Single call_id Outbound
	SELECT TOP 500 cal_id AS call_id
		,c.cam_id
		,isnull(a.cam_descripcion, '''') AS Campaign
		,c.cal_telefono AS phoneNumber
		,isnull(b.user_id, 0) AS user_id
		,isnull(LOGIN, '''')
		,isnull(e.description, '''') AS disposition
		,d.descripcion AS call_status
		,cal_tDialog AS call_tDialog
		,cal_inicio AS call_date
		,cal_tNotas AS WrapUp
		,cal_tXfer AS Xfer
		,cal_tRing AS Ringing
		,cal_manual AS CallManual
		,c.cal_key AS callKey
		,cs.list_id
		,isnull(e.calif_id, '''') AS dispositionId
		,isnull(f.califSubDesc, '''') AS subDisposition
		,isnull(f.califSub_id, '''') AS subDispositionId
	FROM ccocallsout c WITH (NOLOCK)
	LEFT JOIN ccocallsoutsource cs(NOLOCK) ON (cs.callout_id = c.callout_id)
	LEFT JOIN ccusers b ON (c.user_id = b.user_id)
	LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
	LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
	LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
	LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
	WHERE cal_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleCall_id, '','')
			)
END
ELSE IF @action = 7
BEGIN --Status Agente
	SELECT tipostatusAge_id
		,tstatus
		,dateadd(ss, (- 1 * tstatus), fecha)
		,IdCampEsp
		,Tipo
	FROM cclogagentesdia WITH (NOLOCK)
	WHERE user_id = @agentId
		AND fecha >= @startDate
		AND fecha < @endDate
	ORDER BY fecha
END
ELSE IF @action = 8
BEGIN
	SELECT tipostatusAge_id
		,tstatus
		,dateadd(ss, (- 1 * tstatus), fecha) fecha
		,IdCampEsp
		,Tipo
		,user_id
	FROM cclogagentesdia WITH (
			INDEX (IX_ccLogAgentesDia_4)
			,NOLOCK
			)
	WHERE user_id IN (
			SELECT value
			FROM fn_RIASplitDelimited(@multipleUser_id, '','')
			)
		AND fecha BETWEEN @startDate
			AND @endDate
	ORDER BY user_id
		,fecha
END
ELSE IF @action = 9
BEGIN --Call History by CamId and day
	DECLARE @date DATETIME
		,@countRegistry BIGINT

	IF @PageNumber <= 0
		SET @PageNumber = 1
	SET @date = convert(DATETIME, convert(NVARCHAR(11), GETDATE(), 121))

	IF @isCount = 0
	BEGIN ---Datos para la informacion
		SELECT cal_id AS call_id
			,c.cam_id
			,isnull(a.cam_descripcion, '''') AS Campaign
			,c.cal_telefono AS phoneNumber
			,isnull(b.user_id, 0) AS user_id
			,isnull(LOGIN, '''')
			,isnull(e.description, '''') AS disposition
			,d.descripcion AS call_status
			,cal_tDialog AS call_tDialog
			,cal_inicio AS call_date
			,cal_tNotas AS WrapUp
			,cal_tXfer AS Xfer
			,cal_tRing AS Ringing
			,cal_manual AS CallManual
			,c.cal_key AS callKey
			,list_id
			,isnull(e.calif_id, '''') AS dispositionId
			,isnull(f.califSubDesc, '''') AS subDisposition
			,isnull(f.califSub_id, '''') AS subDispositionId
			,rowNum
			,cs.Dato1
			,cs.Dato2
			,cs.Dato3
			,cs.Dato4
			,cs.Dato5
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY cal_id
					) AS rowNum
				,c.callout_id
				,cal_id
				,c.cam_id
				,c.cal_telefono
				,cal_tDialog
				,cal_inicio
				,cal_tNotas
				,cal_tXfer
				,cal_tRing
				,cal_manual
				,c.cal_key
				,c.statusCall_id
				,c.calif_id
				,c.califSub_id
				,c.user_id
			FROM ccocallsout c WITH (
					NOLOCK
					,INDEX (IX_ccoCallsOut_3)
					)
			WHERE cam_id = @camId
				--and cal_Inicio >= @date and cal_Inicio<GETDATE()
			) AS c
		LEFT JOIN ccocallsoutsource cs ON (cs.callout_id = c.callout_id)
		LEFT JOIN ccusers b ON (c.user_id = b.user_id)
		LEFT JOIN cccamps a ON (c.cam_id = a.cam_id)
		LEFT JOIN ccStatusLLamada d ON (c.statusCall_id = d.statusCall_id)
		LEFT JOIN ccTipoCalifOUT e ON (c.calif_id = e.calif_id)
		LEFT JOIN ccTipoCalifSubOUT f ON (c.califSub_id = f.califSub_id)
		WHERE rowNum BETWEEN ((@PageNumber - 1) * @RowsPerPage) + 1
				AND @RowsPerPage * (@PageNumber)
	END
	ELSE
	BEGIN --Numero de paginas y registros actuales
		SELECT @countRegistry = count(*)
		FROM ccocallsout c WITH (
				NOLOCK
				,INDEX (IX_ccoCallsOut_3)
				)
		WHERE cam_id = @camId

		--and cal_Inicio >= @date and cal_Inicio<GETDATE()
		SELECT @RowsPerPage AS pagesize
			,@PageNumber AS currentpage
			,@countRegistry / cast(@RowsPerPage AS FLOAT) AS totalpages
	END
END
ELSE IF (@action = 10)
BEGIN -- get agent status (Logged in or Logged out)
	DECLARE @isLoggedIn AS INT
	DECLARE @lastLogIn_Out AS DATETIME
	DECLARE @status AS INT

	SELECT @status = tipostatusage_id
	FROM ccUsers
	WHERE User_id = @agentId
		AND TipoUser_id = 1

	--SELECT @status
	IF (@status = 3)
	BEGIN
		SELECT @isLoggedIn = 1

		SELECT @lastLogIn_Out = max(fecha)
		FROM ccLogLogin
		WHERE fecha >= convert(datetime,convert(varchar(10),getdate(),121))
			AND User_id = @agentId
			AND TipoMov = 1 -- Login
	END
	ELSE IF (@status = 0)
	BEGIN
		SELECT @isLoggedIn = @status

		SELECT @lastLogIn_Out = max(fecha)
		FROM ccLogLogin
		WHERE fecha >= convert(datetime,convert(varchar(10),getdate(),121))
			AND User_id = @agentId
			AND TipoMov = 0 --Logout 
	END

	SELECT @isLoggedIn
		,@lastLogIn_Out
END
ELSE IF (@action = 11) -- verify User
BEGIN
	DECLARE @response AS INT

	SELECT @response = User_id
	FROM ccUsers
	WHERE LOGIN = @username
		AND password = dbo.md5(@password)

	SELECT isnull(@response, '''')
END'

		EXEC (@sql)

		-- *********************** END 121.03-6_20190515 *********************** ---
		-- *********************** BEGIN 121.03-6_20190521 *********************** ---
		SET @process = 'CW-2946 CenterwareWS Security Layer '
		SET @sql = '
if not exists (select * from sys.tables where name = N''CsCenterwareWS_ApiKey'')
    begin
		CREATE TABLE [dbo].[CsCenterwareWS_ApiKey] (
				[Api_id] [int] IDENTITY(1, 1) NOT NULL
				,[APIkey] [varchar](32) NOT NULL
				,[Description] [varchar](50) NOT NULL
				) ON [PRIMARY]
    end'

		EXEC (@Sql)

		SET @process = 'CW-2946 CenterwareWS Security Layer'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_CsCenterwareWS_ApiKey'')
    begin
        DROP PROCEDURE ccsp_CsCenterwareWS_ApiKey
    end'

		EXEC (@sql)

		SET @process = 'CW-2946 CenterwareWS Security Layer'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_CsCenterwareWS_ApiKey]
	-- Add the parameters for the stored procedure here
	@action INT
	,@apiKey VARCHAR(32) = ''''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@action = 1) -- verify API key
	BEGIN
		DECLARE @response AS INT

		SELECT @response = len(apikey)
		FROM CsCenterwareWS_ApiKey
		WHERE APIkey = @apiKey COLLATE Latin1_General_CS_AS 

		SELECT isnull(@response, '''')
	END

	ELSE IF (@action = 2) -- verify setting
	BEGIN
		SELECT valor
		FROM ccSettings
		WHERE setting_id = 214
	END
END'

		EXEC (@sql)

		SET @process = 'CW-2946 CenterwareWS Security Layer'
		SET @sql = 'IF NOT EXISTS (
		SELECT setting_id
		FROM ccSettings
		WHERE setting_id = 214
		)
BEGIN
	INSERT INTO ccSettings (
		setting_id
		,valor
		,descripcion
		,STATUS
		,Tipo
		,detalle
		,description
		,bLoadSettings
		,validate
		)
	VALUES (
		214
		,0
		,''Parametro API key en CsCenterwareWS''
		,0
		,''ADM''
		,''0 inactivo, 1 activo. Api key en CsCenterwareWS_ApiKey''
		,''API key parameter in CsCenterwareWS''
		,0
		,''^[0-1]$''
		)
END'

		EXEC (@sql)

		SET @process = 'CW-2843 Alter ccsp_ExtAppsCamList'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCamList] @action SMALLINT, @area INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
    IF @area = 0
	   SELECT a1.inbound_id, descripcion, a1.STATUS
	   FROM ccinbound a1
	   JOIN ccRIAinboundGraph a2 ON (a1.inbound_id = a2.inbound_id)
	   JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	   WHERE a3.type_id = 1
	   ORDER BY descripcion
    ELSE
	   SELECT DISTINCT a1.inbound_id, descripcion, a1.STATUS
	   FROM ccinbound a1
	   JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	   JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	   WHERE a3.type_id = 1 AND (@area IS NULL OR IDArea = @area)
	   ORDER BY descripcion

    RETURN (0)
END

IF @action = 2
BEGIN
    IF @area = 0
	   SELECT a1.cam_id, cam_descripcion, cam_activo
	   FROM ccCamps a1
	   JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	   JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	   WHERE a3.type_id = 1
	   ORDER BY cam_descripcion
    ELSE
	   SELECT DISTINCT a1.cam_id, cam_descripcion, cam_activo
	   FROM ccCamps a1
	   JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	   JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	   WHERE a3.type_id = 1 AND (@area IS NULL OR IDArea = @area)
	   ORDER BY cam_descripcion

    RETURN (0)
END

SET NOCOUNT OFF'

		EXEC (@Sql)

		-- *********************** END 121.03-6_20190521 *********************** ---
		-- *********************** BEGIN 121.03-6_20190527 *********************** ---

		 set @process = 'cw-2963 Webservice Unavailable Options'
 		 set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetUnavailableTypes'')
    begin
        DROP PROCEDURE ccsp_GetUnavailableTypes;
    end'
 		 EXEC(@SQL)

 		 set @process = 'cw-2963 Webservice Unavailable Options'
 		 set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GetUnavailableTypes] @action INT
	,@startDate DATETIME =  null
	,@endDate DATETIME = null
	,@unavailable_id VARCHAR(300) = null
AS
IF (@action = 0)
BEGIN
	SELECT TipoNotReady_id AS [unavailable_id]
		,Descripcion AS [description]
		,Time_Acum AS [MaxTime]
		,Time_xEv AS [MaxTimePerEvent]
		,Pas_Sup AS [AdminPw]
		,NextStatus AS [NextStatus]
		,IsSup AS [AdminOnly]
		,StatusTipoNotReady AS [UnavailableStatus]
	FROM ccTipoNotReady
END

IF (@action = 1)
BEGIN
	DECLARE @tabla TABLE (notReadyId INT PRIMARY KEY)

	INSERT INTO @tabla
	SELECT value
	FROM dbo.fn_RIASplitDelimited(@unavailable_id, '','')
	
	SELECT TipoNotReady_id
		,SUM(tStatus)
	FROM ccLogAgentesNotReady A WITH (NOLOCK)
	INNER JOIN @tabla B ON A.TipoNotReady_id = B.notReadyId
	WHERE fecha >= @startDate
		AND fecha <= @enddate
	GROUP BY TipoNotReady_id
END
' 		
 		EXEC(@sql)

-- *********************** END 121.03-6_20190527 *********************** ---



SET @process = 'CW-2863 Alter ccsp_RIAGetCampsNvosCB'
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

	create table #temccocallsoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
	if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
	end
	else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
	end

	end
	else begin
	if @Tipo = 2
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
		from ccCamps cam with(nolock)
		join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
		where cam.cam_id = @cam_id
	else
		if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
		end
		else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo = 1 and cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and cam_activo=1
		end
	end



	insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
	group by cam_id


	
	if (select count(*) from #Tcamps2)>0 begin

	insert into #temccocallsoutsource(cam_id,Pend)
	SELECT ccos.cam_id, count(ccos.cam_id) as Pend
	FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
	join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
	WHERE cal_status in(0, 7)
	GROUP BY ccos.cam_id

	insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
	SELECT A.cam_id,
	count(case cal_status when 0 then 1 else null end) as New,
	count(case cal_status when 1 then 1 else null end) as Cb,
	count(case cal_status when 2 then 1 else null end) as Pro,
	count(case cal_status when 3 then 1 else null end) as Fin
	FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
	join #Tcamps2 B on A.cam_id = B.cam_id
	GROUP BY A.cam_id	

	
	if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
	end
	else begin
		While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
		set rowcount 1
		select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
		set rowcount 0
		EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
		end
	end

	begin Tran updateccCampsNvosCB

		delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
		where CampNvosCB.id = tcamp.cam_id

		INSERT into ccCampsNvosCB 
		SELECT cams.cam_id, cams.cam_descripcion,
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		isNull(cams.procesando,0) cam_procesando,
		isNull(cams.cam_tipojobs,0) cam_tipojobs,
		isNull(wt.Fin,0) Fin,
		isNull(cams.cantidad,0) cantidad,
		getdate()
		FROM #Tcamps2 cams with(nolock)
		LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
		LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id		

	COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	else
		SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,cc.aggressionFactor
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #temccocallsoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'
		EXEC (@Sql)

		-- *********************** END 121.03-6_20190529 *********************** ---

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
