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
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
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
		SET @Sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
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
		SET @Sql = 'insert into ccTimeZoneArea (id_country, area, location, tz_standard, tz_daylight, call_record)
 select id_country, area, location, tz_standard, tz_daylight, call_record from (
	values (4,327,''AR'',64,32,null), 
  (4,986,''ID'',128,64,null),(4,930,''IN'',32,16,null),(4,332,''NY'',32,16,null),
  (4,680,''NY'',32,16,null),(4,838,''NY'',32,16,null),(4,929,''NY'',32,16,null),(4,934,''NY'',32,16,null),
  (4,445,''PA'',32,16,null)
 ) as timezone(id_country, area, location, tz_standard, tz_daylight, call_record) where area not in (select area from ccTimeZoneArea where id_country = 4)'
		EXEC (@Sql)
		
	-- *********************** END 	121.03-5_20190430 *********************** ---
		
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
