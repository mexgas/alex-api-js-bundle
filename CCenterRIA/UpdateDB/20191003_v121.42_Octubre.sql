/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/28
Description: 

Database: CCenterRia
Required version: 121.41

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
SET @versionfix = 41
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 41
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccoDialerCamp_I'' and object_id = OBJECT_ID(N''ccoDialerCamp''))
    begin
        CREATE NONCLUSTERED INDEX [IX_ccoDialerCamp_I]
ON [dbo].[ccoDialerCamp] ([cam_id])
INCLUDE ([dialer_id])
    end


'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccusers_II'' and object_id = OBJECT_ID(N''ccUsers''))
    begin
        CREATE NONCLUSTERED INDEX IX_ccusers_II
ON [dbo].[ccUsers] ([TipoUser_id])
INCLUDE ([User_id],[TipoStatusAge_id])

    end'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER TRIGGER [dbo].[tg_ccUsers_Consulta] ON [dbo].[ccUsers] 
after delete
NOT for Replication
as begin
set nocount on
insert into ccusers_Consulta (User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoStatusAge_id, Password, 
 TipoUser_id, Status, TipoLLamadas, Sexo, filter, CanChangeStatus, fCreate, DialMask, 
 XferMask, LastPasswordChange, IDArea, NotReadyRestricted, startStopRecording)
select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoStatusAge_id, Password, 
 TipoUser_id, Status, TipoLLamadas, Sexo, filter, CanChangeStatus, fCreate, DialMask, 
 XferMask, LastPasswordChange, IDArea, NotReadyRestricted, startStopRecording
from deleted
set nocount off
end'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER TRIGGER [dbo].[tMD5Users] ON [dbo].[ccUsers]
FOR INSERT, UPDATE
NOT for Replication
AS
if (substring(COLUMNS_UPDATED(),1,1) & 64) > 0 
 begin
	if (select len(password) from inserted) = 33 and (select ascii(right(password, 1)) from inserted) = 126
	 begin	
	 	update ccUsers set password = left(i.password, 32)
		from ccUsers u inner join inserted i on u.user_id = i.user_id
		where len(i.password) = 33
	 end
	 
	else
	 begin
		update ccUsers set password = dbo.md5(i.password)
		from ccUsers u inner join inserted i on u.user_id = i.user_id
		where len(i.password) <> 32 AND len(dbo.md5(i.password)) = 32
	 end
 end'
	exec (@sql)



	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CheckDATA]
AS
set nocount on
 
delete ccInboundAgentes with(rowlock) where user_id not in (select user_id from ccusers where  TipoUser_id=1 and Status=1 and (IDArea is not null or IDArea>0))
delete ccCampsAgente with(rowlock) where user_id not in (select user_id from ccusers where  TipoUser_id=1 and Status=1 and (IDArea is not null or IDArea>0))
update ccPosicion set user_id = 0

set nocount off'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
@cal_id INT
AS
DECLARE @disconnectCause AS VARCHAR(250)
--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTA ACTIVO
DECLARE @callout_id AS INT
declare @today datetime
declare @logDial_id int




IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
BEGIN
	--OBTIENE EL CALLOUT_ID A TRAVES DEL CAL_ID
	SELECT @callout_id=callout_id FROM ccoCallsOut WHERE cal_id = @cal_id
	--VERIFICA SI EL CALLOUT_ID EXISTE
	IF @callout_id IS NOT NULL
	BEGIN

		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)

		--SE OBTIENE EL MESAJE DE ERROR DEL CARRIER A TRAVES DEL CALLOUT_ID
		SELECT top 1 @disconnectCause=disconnectCause,@logDial_id=logDial_id
		FROM ccoLogDials
		WHERE callout_id = @callout_id and fecha>=@today
		order by logDial_id desc

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
END'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
@Tipo as tinyint=0
AS

declare @mToday as smalldatetime

select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
if @Tipo = 0
begin
  SELECT cam_id, cam_descripcion,
    0 as pContesta,
    0 as pOcupado,
    0 as pNoContesta,
    0 as pFaxModem,
    0 as pNoService,
    0 as Marcaciones, 0 as Contestan,  0 as Ocupado, 0 as NoContesta, 0 as FaxModem, 0 as NoService
  FROM ccCamps
  order by cam_id
end

else if @Tipo = 1
begin
  select cam_id, L.Campana,
    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
    ((L.NoService*100)/ L.Marcaciones) as pNoService,
    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
    ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
  from (
  select cam_id, '''' as Campana,
    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Marcaciones
    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
    ,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
    ,count(case tipoResDial_id when 11 then 1 else null end) as buzon
    ,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
    ,count(case tipoResDial_id when 12 then 1 else null end) as congestion

  from ccoLogDials with(nolock)
  Where fecha >  @mToday
  group by cam_id
  ) L order by Campana

end

else if @Tipo = 2
begin
  select cam_id, L.Campana,
    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
    ((L.NoService*100)/ L.Marcaciones) as pNoService,
    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
  from (
  select C.cam_id as cam_id, cam_descripcion as Campana,
    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
    count(*) as Marcaciones
  from ccoLogDials L with(nolock)
  inner join ccCamps C on L.cam_id=C.cam_id
  Where fecha >  @mToday
  group by C.cam_id, cam_descripcion
  ) L order by Campana
end
'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE dbo.ccsp_OUTResetJobs 
				@camid AS INT= 0
AS
BEGIN

	CREATE TABLE #TempccoLogDials
	( 
				 callout_id INT, cam_id SMALLINT, fecha DATETIME
	);
	DECLARE @today DATETIME;

	SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
	set @today=dateadd(dd,-1,@today)

	IF @camid = 0
	BEGIN
		INSERT INTO #TempccoLogDials
			   SELECT callout_id, cam_id, MAX(fecha) AS fecha
			   FROM ccoLogDials AS ld WITH(NOLOCK)
			   WHERE fecha >= @today
			   GROUP BY callout_id, cam_id;
	END;
		 ELSE
		IF @camid > 0
		BEGIN
			INSERT INTO #TempccoLogDials
				   SELECT callout_id, cam_id, MAX(fecha) AS fecha
				   FROM ccoLogDials AS ld WITH(NOLOCK)
				   WHERE cam_id = @camid AND 
						 fecha >= @today
				   GROUP BY callout_id, cam_id;
		END;

	-- CALLBACKS Se han marcado recientemente
	UPDATE ccoWorkingTable WITH(ROWLOCK)
	  SET cal_status = 1
	FROM ccoWorkingTable wt
		 INNER JOIN
		 #TempccoLogDials ld
		 ON wt.callout_id = ld.callout_id
	WHERE wt.cal_status = 2 AND 
		  ld.fecha > DATEADD(d, -1, GETDATE());

	IF @camid = 0
	BEGIN
		-- NUEVAS - Nunca se han marcado
		UPDATE ccoWorkingTable WITH(ROWLOCK)
		  SET cal_status = 0
		WHERE cal_status = 2;
	END;
		 ELSE
	BEGIN  
		-- NUEVAS - Nunca se han marcado
		UPDATE ccoWorkingTable WITH(ROWLOCK)
		  SET cal_status = 0
		WHERE cal_status = 2 AND 
			  cam_id = @camid;
	END;

	DROP TABLE #TempccoLogDials;
END;'
	exec (@sql)

	set @process = 'CW-3448 Bloqueo'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
@callout_id INT
AS
DECLARE @disconnectCause AS VARCHAR(250)
--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTA ACTIVO
declare @today datetime
declare @logDial_id int




IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
BEGIN
	--VERIFICA SI EL CALLOUT_ID EXISTE
	IF @callout_id IS NOT NULL
	BEGIN

		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)

		--SE OBTIENE EL MESAJE DE ERROR DEL CARRIER A TRAVES DEL CALLOUT_ID
		SELECT top 1 @disconnectCause=disconnectCause,@logDial_id=logDial_id
		FROM ccoLogDials
		WHERE callout_id = @callout_id and fecha>=@today
		order by logDial_id desc

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
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_recordingStatus]
@callType int,
@id int,
@action int ,
@recordLocalization int
AS
begin

SET NOCOUNT ON
	if @action=0 begin
		declare @time int
		if @callType=0 begin
			select @time=cal_tDialog from ccoCallsOut with(nolock) where cal_id=@id
		end
		else begin
			select @time=cal_tDialog from ccCallsIn with(nolock) where cal_id=@id
		end
		select case when @time>0 then 1 else 0 end as result
	end
	else if @action=1 begin
		if @callType=0 begin
			update ccoCallsOut with(rowlock) set file_moved=@recordLocalization where cal_id=@id
		end
		else begin
			update ccCallsIn with(rowlock) set file_moved=@recordLocalization where cal_id=@id
		end
	end
end'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ResetAgents] AS

SET NOCOUNT ON

Update ccPosicion Set User_id= 0
update ccUsers set TipoStatusAge_id=0 where TipoUser_id=1 and (IDArea is not null or IDArea>0)
'
	exec (@sql)

	set @process = 'CW-3494 Timeout en la base datos en Issues and Answer'
	set @sql = 'ALTER PROCEDURE dbo.ccsp_RIAAdmPrioridadTelefonos 
				@cam_id INT, @prioridad VARCHAR(8), @callbacks BIT= 0, @Type TINYINT
AS
BEGIN

	--Actualiza la prioridad en la tabla
	IF @Type = 3
	BEGIN
		INSERT INTO ccCampsPrioridadTel
		VALUES( @cam_id, ''12345NNN'' );
	END;

	IF @Type = 2
	BEGIN

		IF NOT EXISTS
		(
			SELECT *
			FROM ccCampsPrioridadTel
			WHERE cam_id = @cam_id
		)
		BEGIN
			INSERT INTO ccCampsPrioridadTel
			VALUES( @cam_id, @prioridad );
		END;
			 ELSE
		BEGIN
			UPDATE ccCampsPrioridadTel
			  SET prioridad = @prioridad
			WHERE cam_id = @cam_id;
		END;

		IF @callbacks = 1
		BEGIN
			--Ahora cambia todos los registros en ccoCallsoutsource.  Solo nuevos
			UPDATE ccoCallsoutsource
			  SET dial_tels = @prioridad
			WHERE cam_id = @cam_id AND 
				  callout_id IN
			(
				SELECT callout_id
				FROM ccoWorkingTable
				WHERE cam_id = @cam_id AND 
					  cal_status = 0
			);
		END;
			 ELSE
		BEGIN
			UPDATE ccoCallsoutsource
			  SET dial_tels = @prioridad
			WHERE cam_id = @cam_id;
		END;
	END;
	IF @Type = 1
	BEGIN
		SELECT ccCamps.cam_id, Prioridad
		FROM ccCamps, ccCampsPrioridadTel
		WHERE ccCamps.cam_id = @cam_id AND 
			  ccCampsPrioridadTel.cam_id = @cam_id;
	END;
END;'
	exec (@sql)


	
	
			
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
