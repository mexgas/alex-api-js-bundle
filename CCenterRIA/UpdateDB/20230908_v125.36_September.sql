/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.31

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

--- Validacion para cuando pasamos a una nueva version LTS
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

	
	SET @process = 'DEV2-253 se agrega tradcucción (cancelada en diálogo) a la tabla ccTypeProcessPreview '
	SET @sql = '
	if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 13)
		begin
			insert into ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (13, ''CancelledByEngaged'',''systemTranslated_CancelledByEngaged'')
		end'
	EXEC(@sql)

	SET @process = 'DEV2-253 se agrega tradcucción (cancelada) a la tabla ccTypeProcessPreview '
	SET @sql = '
	if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 14)
		begin
			insert into ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (14, ''Cancelled'',''systemTranslated_Cancelled'')
		end'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_GetPreviewHistory '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GetPreviewHistory'')
    begin
        DROP PROCEDURE ccsp_GetPreviewHistory;
    end'
	EXEC(@sql)
	
	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_GetPreviewHistory '
	SET @sql = '
	CREATE Proc [dbo].[ccsp_GetPreviewHistory]( @callOut_Id int ,@initialRow smallint,@finalRow smallint)
		AS
		declare @initialDate datetime, @finalDate datetime
		set @finalDate= GETDATE()
		set @initialDate = (select DATEDIFF(day,30,@finalDate))

		declare @temTable table (callOut_id int, dialResult varchar(50),disposition varchar(100),date datetime)
		insert into @temTable 
					select co.callout_id as callOut_id, 
					trd.descTranslate dialResult,
					ISNULL( tco.Description,'''') as calificacion,
					ld.fecha as fecha
					from ccoCallsOut co 
					left join ccoLogDials ld on co.callout_id = ld.callout_id
					left join cctipoResultadoDial trd ON ld.tipoResDial_id = trd.tiporesdial_id
					LEFT JOIN cctipocalifout tco ON tco.calif_id = co.calif_id
					where co.callout_id = @callOut_Id and co.cal_id = ld.cal_id  and ld.fecha >= @initialDate and ld.fecha <=@finalDate and ld.tipoResDial_id != 13  and (ld.tipoResDial_id != 14 and ld.canceledNoAgents=1)
					and cast(co.cal_Inicio as varchar) = cast(ld.fecha as varchar)

					union 
					select rppr.callout_id,
					tpp.descripcion,
					'''',
					rppr.reg_date
					from RegProcessPreviewRecord rppr
					join ccTypeProcessPreview tpp on rppr.process= tpp.typeProcess_id
					where rppr.process NOT IN (1,5,7,14) and rppr.callout_id = @callOut_Id and rppr.reg_date >= @initialDate and rppr.reg_date <=@finalDate
			

		SELECT  * FROM    
				( SELECT    ROW_NUMBER() OVER ( ORDER BY date ) AS RowNum, *
				  FROM      @temTable 
				) AS RowConstrainedResult
		WHERE   RowNum >= @initialRow
			AND RowNum <= @finalRow 
		ORDER BY RowNum	'
	EXEC(@sql)
	
	--------------------------------------------------------------------START HL----------------------------------------------------------------------------------------
	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_AgentSetCallStatus '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_AgentSetCallStatus'')
    begin
        DROP PROCEDURE ccsp_AgentSetCallStatus;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_AgentSetCallStatus - no eliminar en WT cuando camp = Preview(6)'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
		@callout_id INT, 
		@cal_id     INT, 
		@TipoCall   TINYINT, -- 1= IN,  2=Out
		@TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
		@cal_tXfer  TINYINT    = 0, 
		@cal_tring  SMALLINT   = 0, 
		@user_id    SMALLINT   = 0, 
		@extension  VARCHAR(5) = '''', 
		@isChatCall BIT        = 0
	AS
		 SET NOCOUNT ON
		 DECLARE @RecicleSIC TINYINT

		 SELECT @RecicleSIC = ISNULL(valor, 0)
		 FROM ccSettings
		 WHERE setting_id = 60

		 DECLARE @ANI_x VARCHAR(19)
		 DECLARE @cal_inicio DATETIME
		 DECLARE @callout_id_IN INT
		 DECLARE @cal_key VARCHAR(20)
		 DECLARE @cam_id INT
		 DECLARE @cal_telefono VARCHAR(30)
		 DECLARE @surveycamid INT
		 DECLARE @inbound_id INT
		 IF @TipoMov = 4 OR @TipoMov = 14 -- DIALOG OnDialog
			 BEGIN
				 IF @TipoCall = 2
					 BEGIN
						 IF @TipoMov = 4
							 BEGIN
								 UPDATE ccoCallsOUT WITH(ROWLOCK)
								   SET cal_Inicio = GETDATE(), 
									   statusCall_id = 13, 
									   cal_manual = CASE
														WHEN @isChatCall = 1
														THEN 3
														ELSE cal_manual
													END
								 WHERE cal_id = @cal_id
						 END
							 ELSE
							 IF @TipoMov = 14
								 UPDATE ccoCallsOUT WITH(ROWLOCK)
								   SET statusCall_id = 13, 
									   cal_tRing = @cal_tring, 
									   user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
									   cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
								 WHERE cal_id = @cal_id
						SELECT @cam_id=cam_id FROM ccoWorkingTable nolock WHERE callout_id = @callout_id
						IF @RecicleSIC = 0 AND (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) != 6
						BEGIN
							DELETE ccoWorkingTable WITH(ROWLOCK) WHERE callout_id = @callout_id
							DELETE ccoCallPriorityOrder WITH(ROWLOCK) WHERE callout_id = @callout_id
						END
						 UPDATE ccoCallBacks
						   SET [status] = 1, 
							   schedulerStatus = 1, 
							   cal_fcallback = cal_inicio
						 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
						 WHERE a.callout_id = b.callout_id
							   AND b.callout_id = @callout_id
							   AND b.cal_id = @cal_id
							   AND [status] = 0
							   AND statusCall_id = 13

						 -- calcula el costo de la llamada
						 EXEC ccsp_CstoCalculaCosto @cal_id

						 RETURN(0)
				 END
				 IF @TipoMov = 4
					 UPDATE ccCallsIN WITH(ROWLOCK)
					   SET statusCall_id = 13
					 WHERE cal_id = @cal_id

					 ELSE
					 IF @TipoMov = 14
						 UPDATE ccCallsIN WITH(ROWLOCK)
						   SET statusCall_id = 13, 
							   cal_tRing = @cal_tring, 
							   user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
							   cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
						 WHERE cal_id = @cal_id

				 -- Elimina callback generado por abandono
				 SELECT @ANI_x = cal_ani, 
						@cal_inicio = cal_inicio
				 FROM cccallsin WITH (INDEX(PK_ccCallsIn))
				 WHERE cal_id = @cal_id

				 SELECT @callout_id_IN = callout_id
				 FROM ccRIAUpdateCallBack_Abandon
				 WHERE cal_ani = @ANI_x

				 UPDATE ccoCallBacks WITH(ROWLOCK)
				   SET [status] = 1, 
					   schedulerStatus = 1, 
					   cal_fcallback = @cal_inicio
				 WHERE callout_id = @callout_id_IN
					   AND [status] = 0

				 DELETE ccoWorkingTable WITH(ROWLOCK)
				 WHERE callout_id IN
				 (
					 SELECT DISTINCT
							(callout_id)
					 FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
					 WHERE cal_ani = @ANI_x
				 )

				 DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
				 WHERE cal_ANI = @ANI_x

				 RETURN(0)
		 END
		 IF @TipoMov = 7 --OTHER OFFHook_OnXfer
			 BEGIN
				 IF @cal_id <= 0
					 RETURN(0)
				 IF @TipoCall = 2
					 BEGIN
						 UPDATE ccoCallsOUT WITH(ROWLOCK)
						   SET statusCall_id = 16
						 WHERE cal_id = @cal_id
						 -- calcula el costo de la llamada

						 UPDATE ccoCallBacks
						   SET [status] = 2, 
							   schedulerStatus = 1, 
							   cal_fcallback = cal_inicio
						 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
						 WHERE a.callout_id = b.callout_id
							   AND b.callout_id = @callout_id
							   AND b.cal_id = @cal_id
							   AND [status] = 0
							   AND statusCall_id = 16

						 EXEC ccsp_CstoCalculaCosto 
							  @cal_id

						 RETURN(0)
				 END
				 UPDATE ccCallsIN WITH(ROWLOCK)
				   SET statusCall_id = 16
				 WHERE cal_id = @cal_id

				 SELECT @ANI_x = cal_ani, 
						@cal_inicio = cal_inicio
				 FROM cccallsin WITH (INDEX(PK_ccCallsIn))
				 WHERE cal_id = @cal_id

				 SELECT @callout_id_IN
				 FROM ccRIAUpdateCallBack_Abandon
				 WHERE cal_ani = @ANI_x

				 UPDATE ccoCallBacks WITH(ROWLOCK)
				   SET [status] = 2, 
					   schedulerStatus = 1, 
					   cal_fcallback = @cal_inicio
				 WHERE callout_id = @callout_id_IN
					   AND [status] = 0

				 RETURN(0)
		 END
		 IF @TipoMov = 9 --RING CallNoAnswered
			 BEGIN
				 IF @TipoCall = 2
					 BEGIN
						 UPDATE ccoCallsOUT WITH(ROWLOCK)
						   SET statusCall_id = 15, 
							   cal_tXFer = @cal_txFer, 
							   cal_tRing = @cal_tring
						 WHERE cal_id = @cal_id

						 -- calcula el costo de la llamada

						 UPDATE ccoCallBacks
						   SET [status] = 2, 
							   schedulerStatus = 1, 
							   cal_fcallback = cal_inicio
						 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
						 WHERE a.callout_id = b.callout_id
							   AND b.callout_id = @callout_id
							   AND b.cal_id = @cal_id
							   AND [status] = 0
							   AND statusCall_id = 15

						 EXEC ccsp_CstoCalculaCosto @cal_id
				 END

				 UPDATE ccCallsIN WITH(ROWLOCK)
				   SET statusCall_id = 15, 
					   cal_tXFer = @cal_txFer, 
					   cal_tRing = @cal_tring
				 WHERE cal_id = @cal_id

				 SELECT @ANI_x = cal_ani, 
						@cal_inicio = cal_inicio
				 FROM cccallsin WITH (INDEX(PK_ccCallsIn))
				 WHERE cal_id = @cal_id

				 SELECT @callout_id_IN
				 FROM ccRIAUpdateCallBack_Abandon
				 WHERE cal_ani = @ANI_x

				 UPDATE ccoCallBacks WITH(ROWLOCK)
				   SET [status] = 2, 
					   schedulerStatus = 1, 
					   cal_fcallback = @cal_inicio
				 WHERE callout_id = @callout_id_IN
					   AND [status] = 0

				 RETURN(0)
		 END
		 SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_GalateaGetPreviewData '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaGetPreviewData'')
    begin
        DROP PROCEDURE ccsp_GalateaGetPreviewData;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_GalateaGetPreviewData - nolock'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @option int = null,
		@callout_id int = null,
        @user_id smallint = null

        AS
        set nocount on

		if(@option = 1 or @option is null)
		begin
			declare @typePreview varchar = null

			select @typePreview= valor from ccSettings (nolock)
			where setting_id=248 and Status=1

			select ''previewData''=
			 case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
			 ISNULL(P.Headers,'''')+''~''+
			 ISNULL(O.Dato1,'''')+''~''+
			 ISNULL(O.Dato2,'''')+''~''+
			 ISNULL(O.Dato3,'''')+''~''+
			 ISNULL(O.Dato4,'''')+''~''+
			 ISNULL(O.Dato5,'''')+''~''+
			 ISNULL(P.Dato6,'''')+''~''+
			 ISNULL(P.Dato7,'''')+''~''+
			 ISNULL(P.Dato8,'''')+''~''+
			 ISNULL(P.Dato9,'''')+''~''+
			 ISNULL(P.Dato10,'''')+''~''+
			 ISNULL(P.Dato11,'''')+''~''+
			 ISNULL(P.Dato12,'''')+''~''+
			 ISNULL(P.Dato13,'''')+''~''+
			 ISNULL(P.Dato14,'''')+''~''+
			 ISNULL(P.Dato15,'''')+''~''+
			 ISNULL(O.cal_telefono2,'''')+''~''+
			 ISNULL(O.cal_telefono3,'''')+''~''+
			 ISNULL(O.cal_telefono4,'''')+''~''+
			 ISNULL(O.cal_telefono5,'''')+''~''+
			 ISNULL(cast(O.cal_Key as varchar),'''')+''~''+
			 ISNULL(cast(O.cal_telefono as varchar),'''')+''~''+
			 @typePreview+''~'',
			 C.previewDiscard
				   from ccoCallsOutSource O (nolock)
			INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
			INNER JOIN ccCamps C (nolock) on P.cam_id = C.cam_id
			JOIN ccUsers U (nolock) on U.TipoUser_id=1
			Where callout_id=@callout_id and U.User_id=@user_id
		end

		if(@option = 2)
		begin
			select COUNT(*) from ccoCallsOutSource nolock where callout_id = @callout_id
		end
        set nocount off'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PROCEDURE ccsp_OUTUpdateDialJob '
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_OUTUpdateDialJob'')
    begin
        DROP PROCEDURE ccsp_OUTUpdateDialJob;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccsp_OUTUpdateDialJob - CONTESTA no eliminar en WT cuando camp = Preview(6)'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
		@callout_id     INT,
		@CallResultDial TINYINT,
		@isTCPA         BIT     = 0
		AS
			 SET NOCOUNT ON

		/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
		++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

			 DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
			 DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
			 DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
			 DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
			 DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
			 DECLARE @DateNextDial SMALLDATETIME, @DateNewDial SMALLDATETIME, @cam_id SMALLINT
			 DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
			 DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)

			 SELECT @cam_id = cam_id,
					@nOcupado = ISNULL(nOcupado, 0),
					@nNoContesta = ISNULL(nNoContesta, 0),
					@nFax = ISNULL(nFax, 0),
					@nContestadora = ISNULL(nContestadora, 0),
					@nShortCall = ISNULL(nShortCall, 0),
					@nOtro = ISNULL(nOtro, 0),
					@DateNextDial = cal_fechaDial
			 FROM ccoWorkingTable with(nolock)
			 WHERE callout_id = @callout_id

			 SELECT @ExisteWT = CASE WHEN @cam_id IS NOT NULL THEN 1 ELSE 0 END
			 SELECT @cal_status = CASE WHEN @isTCPA = 1 THEN 0 ELSE 1 END--si esta en modo TCPA no gene|rar callbacks

			 IF @CallResultDial = 20 BEGIN-- CONTACTADO
				EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
				RETURN(0)
			 END
			 else IF @CallResultDial = 1 BEGIN-- CONTESTO
				IF @isTCPA = 1 BEGIN
						UPDATE ccoWorkingTable with(rowlock) SET cal_status = @cal_status WHERE callout_id = @callout_id
				END
				ELSE BEGIN
					IF (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) = 6
						RETURN(0)
					IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
						BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
					END
					ELSE BEGIN
						EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
					END
				END
				RETURN(0)
			 END
			 ELSE IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
				SELECT @cam_ocupado = cam_ocupado,
					@cam_inter_ocupado = cam_inter_ocupado,
					@cam_NoInt_ocupado = cam_NoInt_ocupado,
					@nOcupado = @nOcupado + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

					IF @cam_ocupado = 1 BEGIN -- Opcion Ocupado HABILITADA
						IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4 BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
							RETURN(0)
						END


						SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
						IF @prioridadLlamada is null BEGIN
							SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
							INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
						END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
						WHERE callout_id = @callout_id


						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

						-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
						IF @DateNewDial > @DateNextDial BEGIN	-- Nueva fecha de Call BACk
							UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
							WHERE callout_id = @callout_id
							RETURN(0)
						END
						-- Mantiene la fecha de Call BACK
						UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
						WHERE callout_id = @callout_id
						RETURN(0)
					END

					-- ELSE: Opcion Ocupado DESHABILITADA
					EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
					RETURN(0)
				 END
				 ELSE IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
					--select NO Contesta
					SELECT @cam_nocontesto = cam_nocontesto,
						@cam_inter_nocontesto = cam_inter_nocontesto,
						@cam_NoInt_nocontesto = cam_NoInt_nocontesto,
						@nNoContesta = @nNoContesta + 1
					FROM ccCamps
					WHERE cam_id = @cam_id

					IF @cam_nocontesto = 1 BEGIN-- Opcion NoContesta HABILITADA
						IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4 BEGIN --select No Contesta Habilitada
							EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
							RETURN(0)
						END

						SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
						IF @prioridadLlamada is null BEGIN
							SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
							INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
						END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
						ELSE nNoContesta END
						WHERE callout_id = @callout_id


						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

						UPDATE ccoWorkingTable with(rowlock) SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono,
							cal_fechaDial = CASE
												WHEN @DateNewDial > @DateNextDial
												THEN @DateNewDial
												ELSE cal_fechaDial
											END
						WHERE callout_id = @callout_id
						RETURN(0)
					END

					-- Opcion NoContesta DESHABILITADA
					EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
					RETURN(0)
				END
			ELSE IF @CallResultDial = 4 BEGIN-- Fax/Modem
				SELECT @cam_fax = cam_fax,
					@cam_inter_fax = cam_inter_fax,
					@cam_NoInt_fax = cam_NoInt_fax,
					@nFax = @nFax + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

				IF @cam_fax = 1 BEGIN-- Opcion Fax/Modem HABILITADA
						IF @nFax > @cam_NoInt_fax OR @nShortCall > 4 BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
							RETURN(0)
						END

						SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
						IF @prioridadLlamada is null BEGIN
							SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
							INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
						END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
						WHERE callout_id = @callout_id

						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock)  SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

						-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
						UPDATE ccoWorkingTable with(rowlock) SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono,
							cal_fechaDial = CASE
												WHEN @DateNewDial > @DateNextDial
												THEN @DateNewDial
												ELSE cal_fechaDial
											END
						WHERE callout_id = @callout_id
						RETURN(0)
				END

				-- Opcion Fax/Modem DESHABILITADA
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial = 11 BEGIN-- Maquina Contestadora
				SELECT @cam_graba = cam_graba,
					@cam_inter_graba = cam_inter_graba,
					@cam_NoInt_graba = cam_NoInt_graba,
					@nContestadora = @nContestadora + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

				IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
					IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4 BEGIN
						EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
						RETURN(0)
					END

					SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
					IF @prioridadLlamada is null BEGIN
						SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
						INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
					END

					-- Change priority and obtain the next telephone
					UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
					WHERE callout_id = @callout_id

					set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
					UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

					SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
					+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
					+ CAST(@callout_id AS VARCHAR(15))

					EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

					SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

					-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
					UPDATE ccoWorkingTable with(rowlock) SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono,
						cal_fechaDial = CASE
											WHEN @DateNewDial > @DateNextDial
											THEN @DateNewDial
											ELSE cal_fechaDial
										END
					WHERE callout_id = @callout_id
					RETURN(0)
				END

				-- Opcion Maquina Contestadora DESHABILITADA
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial IN(10, 90) BEGIN--No Dial Tone, otros, NoService
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
			   EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
			END

		RETURN(0)
		SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP FUNCTION fn_getDialingMode'
	SET @sql = '
	IF EXISTS ( SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[fn_getDialingMode]'')
		AND type IN (N''FN'', N''IF'', N''TF'', N''FS'', N''FT'') )
    begin
        DROP FUNCTION [dbo].[fn_getDialingMode];
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE FUNCTION fn_getDialingMode - reestablecer Preview (256)'
	SET @sql = '
		CREATE FUNCTION [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
		returns nvarchar(9)
		as
		begin
			declare @valor nvarchar(9), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1), @cal_odbc bit
			set @keepDial=''0''

			-- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
			if @call_id is null
			 begin
				select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
					on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
				where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
				and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
				order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
			 end

			if @cam_id is null
			 begin
				select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id, @cal_odbc = cal_odbc
				from ccocallsout O with(nolock,index(PK_ccoCallsOut))
				where O.cal_id = @call_id
			 end
			else
			 begin
				select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cal_odbc = cal_odbc
				from ccocallsout O with(nolock,index(PK_ccoCallsOut))
				where O.cal_id = @call_id
			 end

			select @valor=isnull((select case when campType=6 then ''100'' when progDial=2 then ''010'' when progDial=1 then ''001'' else ''000'' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
			 + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), ''000000'')

			if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
			or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
				set @keepDial=''1''

			select @valor = @valor + @keepDial + case @cal_manual when 1 then ''10'' when 2 then ''01'' else ''00'' end
		
			  select @valor=substring(@valor, 1, 3) +
			  case @TipoDialingMode when 6 then ''1'' else substring(@valor, 4, 1) end + substring(@valor, 5, 2) +
			  case @TipoDialingMode when 3 then ''1'' else substring(@valor, 7, 1) end + substring(@valor, 8, 2)
		  
		 return @valor
		end'
	EXEC(@sql)

	SET @process = 'DEV2-253 Remove Duplicates ccoCallsPreviewData'
	SET @sql = '
		WITH cte AS (SELECT cal_key,cam_id,TotalData,ROW_NUMBER() OVER (PARTITION BY cal_key,cam_id,TotalData ORDER BY TotalData desc) rownum FROM ccoCallsPreviewData NOLOCK)
		DELETE FROM cte WHERE rownum>1'
	EXEC(@sql)

	SET @process = 'DEV2-253 DROP PK ccoCallsPreviewData'
	SET @sql = '
		IF (SELECT OBJECTPROPERTY(OBJECT_ID(''PK_ccoCallsPreviewData_cam_id_cal_Key''), ''IsPrimaryKey'')) IS NOT NULL
		BEGIN
			ALTER TABLE ccoCallsPreviewData DROP CONSTRAINT PK_ccoCallsPreviewData_cam_id_cal_Key; 
		END'
	EXEC(@sql)

	SET @process = 'DEV2-253 ADD PK ccoCallsPreviewData '
	SET @sql = '
		ALTER TABLE ccoCallsPreviewData ADD CONSTRAINT PK_ccoCallsPreviewData_cam_id_cal_Key PRIMARY KEY CLUSTERED (cam_id,cal_Key);'
	EXEC(@sql)
	---------------------------------------------------------------------END HL-----------------------------------------------------------------------------------------
	
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