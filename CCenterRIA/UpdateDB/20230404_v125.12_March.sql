/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 12
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------Begin H Longoria  ---------------------------------------------------------
	set @process = 'KR081001 Setting 246'
	set @sql = '
		if exists (select * from ccSettings where setting_id = 246 )
		begin
			delete ccSettings where setting_id=246;
		end
		
		insert ccSettings (setting_id,
			valor,
			descripcion,
			Status,
			Tipo,
			detalle,
			description,
			bLoadSettings,
			validate) values (246,''0'',''Continuar grabación al transferir a un IVR'',1,''GRL'',''0:desactivado, 1:activado'',''Continue recording when call is transfered to an IVR'',0,''/^[0-1]$/'');
	'
	EXEC(@sql)

	set @process = 'KR081000 SP ccsp_SaveRecorderData'
	set @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_SaveRecorderData'')
		begin
			DROP PROCEDURE ccsp_SaveRecorderData;
		end

		CREATE PROCEDURE [dbo].[ccsp_SaveRecorderData]
		@TipoCall tinyint,	-- 1= IN,  2=Out
		@cal_id int,
		@grabID int = null,
		@fecha datetime = null,
		@duracion int = null,
		@dialog int = null
		AS
			if @TipoCall = 1
				update ccCallsIn set rec_grabId = isnull(@grabID,rec_grabId),
				rec_fechaInicio = isnull(@fecha,rec_fechaInicio), 
				rec_duracion = isnull(@duracion,rec_duracion),
				cal_tDialog = isnull(@dialog,cal_tdialog) where cal_id = @cal_id

			if @TipoCall = 2
				update ccoCallsOut set rec_grabId = isnull(@grabID,rec_grabId),
				rec_fechaInicio = isnull(@fecha,rec_fechaInicio), 
				rec_duracion = isnull(@duracion,rec_duracion),
				cal_tDialog = isnull(@dialog,cal_tdialog) where cal_id = @cal_id
		
		'
	EXEC(@sql)

	set @process = 'KR081000 SP ccsp_AgentUpdateCallTimes'
	set @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_AgentUpdateCallTimes'')
		begin
			DROP PROCEDURE ccsp_AgentUpdateCallTimes;
		end

		CREATE PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]
		@IDCall int,
		@cal_tXfer smallint,
		@cal_tDialog smallint,
		@cal_tNotas smallint,
		@TipoCall tinyint,
		@cal_tRing smallint=0,
		@mtmoh smallint = 0,
		@isChatCall bit = 0,
		@isErroManualCall bit =0,
		@isTransferEngine bit =0
		AS
		set nocount on
		if @IDCall<=0 
			return(0)

		declare @tMinAVRS smallint
		declare @cal_manual int
		declare @minimoDialogo tinyint 
		select @minimoDialogo = valor from ccSettings where setting_id = 13

		set @cal_manual=0

		if @TipoCall=1 begin--INBOUND
		  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
			--el status 18 es para llamada cortada con transferencia en Reminder
			exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
		  end
		  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, 
		  cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
		  cal_tNotas=@cal_tNotas, 
		  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
		  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
		  Where cal_id= @IDCall

		  --Actualizar tiempo total de llamada
		  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

		  -- Elimina callback generado por abandono
  
		  if @isTransferEngine = 0  begin
		  Declare @ANI_x varchar(19)
		  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

		  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
		  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
		  end
		end
		else if @TipoCall=2 begin--OUTBOUND 
			Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
			cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
			@cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end,
			cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
			cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
			cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
			cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
			cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
			totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
			Where cal_id=@IDCall

			-- calcula el costo de la llamada
			exec ccsp_CstoCalculaCosto @IDCall
		  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

		 end

		select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

		if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
		  and not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) 
		  begin 
				insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
		end

		return(0)
 

		set nocount off
		
		'
	EXEC(@sql)
	---------------------------------------End H Longoria  ---------------------------------------------------------
	
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
