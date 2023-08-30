set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 94
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

       ---------------------------------------BEGIN KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------

    SET @process = 'KR091000 Alter SP trsp_InsertRecNode Add @C29-----> LLamada Grabada --@extraInfo 1 Record, 0 Dont Record'
	SET @sql = 'ALTER PROCEDURE [dbo].[trsp_InsertRecNode] @grabId INT, @type INT = 0, @rateEvaluationFormatKolob BIT = 0 
AS
BEGIN
DECLARE @shoutLevel AS int
DECLARE @language AS INT
DECLARE @start AS INT
DECLARE @callType INT
DECLARE @xml AS XML
DECLARE @crmNode AS XML
DECLARE @manual AS NVARCHAR(10)
DECLARE @rating AS NVARCHAR(20)
DECLARE @sqlCRM NVARCHAR(max)
DECLARE @supervisor AS NVARCHAR(50)
DECLARE @template AS NVARCHAR(50)
DECLARE @callID AS NVARCHAR(50)
DECLARE @isHistory BIT
DECLARE @Prefijo VARCHAR(50)
DECLARE @CDATE DATETIME
DECLARE @hasVideo tinyint
DECLARE @hasRecordCall AS bit

SET @Prefijo = ''''

DECLARE @table AS NVARCHAR(20)

SET @table = ''RIA''

/*
CDATE---> Date Generic
C01-----> grab_id
C02-----> Type of Recording (Inbound/Outbound)
C03-----> Camp/ACD descripcion
C04-----> ShoutLevel
C05-----> Agent Login
C06-----> Formated date
C07-----> Position Computer
C08-----> Duration
C09-----> Ani
C10-----> Dnis
C11-----> Calkey
C12-----> Manual
C13-----> User ID
C14-----> cal ID
C15-----> Cam /ACD ID
C16-----> Duration Reco@rding as 00:00:00
C17-----> Position Extension
C18-----> rating(Scoring Template)
C19-----> Reposiory ID
C20-----> Disposition
C21-----> Disposition ID
C22-----> Has Video
C23-----> Agent Full Name
C24-----> Supervisor Name
C25-----> Score Template
C26-----> graphic_id
C27-----> Prefix recording
C28-----> subDisposition
CID-----> CamId
CType---> Tipo de llamada
C29-----> LLamada Grabada --@extraInfo 1 Record, 0 Dont Record
*/
SELECT @language = valor
FROM ccSettings
WHERE setting_id = 27

IF EXISTS (
		SELECT *
		FROM ria_grabacion
		WHERE grab_id = @grabId
		)
BEGIN

IF (@rateEvaluationFormatKolob = 1)
	BEGIN
	SELECT @isHistory = 0, @callType = rec.tipo_llamada, @Prefijo = rec.Prefijo, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END,
	@shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio, @hasVideo = rec.video
	,@hasRecordCall=convert(bit, isnull(rec.extra_info,''1''))
	FROM ria_grabacion rec
	LEFT JOIN ria_tipo_gritos sho ON rec.id_nivel_grito = sho.id_nivel_grito
	LEFT JOIN (
		SELECT AVG(totalPoints) AS total_forma, grab_id  
		FROM RECORDERRIA_RECORDINGEVALUATION 
		WHERE deleted != 1 AND grab_id = @grabId GROUP BY grab_id
		) formCalif ON formCalif.grab_id = rec.grab_id
	WHERE rec.grab_id = @grabId
	END
ElSE
	BEGIN
	SELECT @isHistory = 0, @callType = rec.tipo_llamada, @Prefijo = rec.Prefijo, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END,
	@shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio, @hasVideo = rec.video
	,@hasRecordCall=convert(bit, isnull(rec.extra_info,''1''))
	FROM ria_grabacion rec
	LEFT JOIN ria_tipo_gritos sho ON rec.id_nivel_grito = sho.id_nivel_grito
	LEFT JOIN (
		SELECT TOP 1 total_forma, id_grabacion
		FROM ria_formacalif
		WHERE id_grabacion = @grabId
		ORDER BY fecha_calif DESC
		) formCalif ON formCalif.id_grabacion = rec.grab_id
	WHERE grab_id = @grabId
END

	

	IF(@hasVideo = 0 AND EXISTS (SELECT * FROM RIA_AgentVideo where callId=@callID and calltype = @callType))
	BEGIN 
		UPDATE RIA_GRABACION SET video = 1 where cal_id = @callID
		DELETE FROM RIA_AgentVideo WHERE callId = @callID and calltype = @callType
	END
END
ELSE
BEGIN
	IF (@rateEvaluationFormatKolob = 1)
		BEGIN
			SELECT @isHistory = 1, @callType = rec.tipo_llamada, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END
			, @shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio
			,@hasRecordCall=convert(bit, isnull(rec.extra_info,''1''))
			FROM RIA_GRABACIONCONSULTA rec
			LEFT JOIN ria_tipo_gritos sho ON rec.id_nivel_grito = sho.id_nivel_grito
			LEFT JOIN (
				SELECT AVG(totalPoints) AS total_forma, grab_id  
				FROM RECORDERRIA_RECORDINGEVALUATION 
				WHERE deleted != 1 AND grab_id = @grabId GROUP BY grab_id
				) formCalif ON formCalif.grab_id = rec.grab_id
			WHERE rec.grab_id = @grabId
		END
	ElSE
		BEGIN
			SELECT @isHistory = 1, @callType = rec.tipo_llamada, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END
			, @shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio
			,@hasRecordCall=convert(bit, isnull(rec.extra_info,''1''))
			FROM RIA_GRABACIONCONSULTA rec
			LEFT JOIN ria_tipo_gritos sho ON rec.id_nivel_grito = sho.id_nivel_grito
			LEFT JOIN (
				SELECT TOP 1 total_forma, id_grabacion
				FROM ria_formacalif
				WHERE id_grabacion = @grabId
				ORDER BY fecha_calif DESC
				) formCalif ON formCalif.id_grabacion = rec.grab_id
			WHERE grab_id = @grabId
		END
END

SELECT @Template = formatos.nombre, @supervisor = (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)
FROM RIA_FORMATOS AS formatos
INNER JOIN RIA_FORMACALIF formatosCalif ON formatosCalif.id_formato = formatos.id_formato
INNER JOIN RIA_GRABACION grabacion ON grabacion.grab_id = formatosCalif.id_grabacion
INNER JOIN ccUsers supervisor ON supervisor.User_id = formatosCalif.id_supervisor
WHERE grabacion.grab_id = @grabId AND formatosCalif.tipo = 1


declare @riaGrabacion table(
	[grab_id] [bigint] primary key,
	[finicio] [datetime] NOT NULL,
	[duracion] [int] NULL,
	[ani] [varchar](30) NOT NULL,
	[dni] [varchar](15) NULL,
	[tipo_llamada] [smallint] NULL,
	[cam_id] [smallint] NULL,
	[calif_id] [smallint] NULL,
	[cal_id] [int] NULL,
	[cal_key] [varchar](40) NOT NULL,
	[id_repositorio] [tinyint] NULL,
	[video] [int] NOT NULL,
	[age_id] [int] NULL,
	[cal_extension] [int] NULL,
	[califSub_id] [smallint] NOT NULL
)

insert into @riaGrabacion

select [grab_id],[finicio],[duracion],[ani],[dni],[tipo_llamada],[cam_id],[calif_id],[cal_id],[cal_key],
[id_repositorio],[video],[age_id],[cal_extension],[califSub_id]
FROM ria_grabacion rec
WHERE grab_id = @grabId
union
select [grab_id],[finicio],[duracion],[ani],[dni],[tipo_llamada],[cam_id],[calif_id],[cal_id],[cal_key],
[id_repositorio],[video],[age_id],[cal_extension],[califSub_id]
FROM RIA_GRABACIONCONSULTA 
WHERE grab_id = @grabId

SET @xml = (
			SELECT *
			FROM (
				SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Inbound'' AS ''@C02'', inb.descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04''
				, isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10''
				, rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16''
				, isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.description, ''N/A'') AS ''@C20'', rec.calif_id AS ''@C21''
				, rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26''
				, @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
				,isnull(subDisposition.califSubDesc,''N/A'') as ''@C28'', @hasRecordCall AS ''@C29''
				FROM @riaGrabacion rec
				INNER JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
				LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
				LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
				LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id
					LEFT JOIN cctipocalifsub AS subDisposition ON rec.califSub_id = subDisposition.califSub_id
				INNER JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id
				WHERE rec.grab_id = @grabId

				UNION

				SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Outbound'' AS ''@C02'', inb.cam_descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04''
				, isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10''
				, rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16''
				, isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.Description, ''N/A'') AS ''@C20'', rec.calif_id AS ''@C21''
				, rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26''
				, @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
				,isnull(subDisposition.califSubDesc,''N/A'') as ''@C28'', @hasRecordCall AS ''@C29''
				FROM @riaGrabacion rec
				INNER JOIN cccamps inb ON rec.cam_id = inb.cam_id AND rec.tipo_llamada = 2
				LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
				LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
				LEFT JOIN ccTipoCalifOUT AS e ON rec.calif_id = e.calif_id
					LEFT JOIN cctipocalifsubout AS subDisposition ON rec.califSub_id = subDisposition.califSub_id
				INNER JOIN ccRIACampsGraph grap ON grap.cam_id = inb.cam_id
				WHERE rec.grab_id = @grabId
				) x
			FOR XML path(''R02'')
			)

IF EXISTS (
		SELECT *
		FROM RIA_RecNodeHistory
		WHERE grab_id = @grabId
		)
BEGIN
	UPDATE RIA_RecNodeHistory
	SET node = @xml, [status] = 2
	WHERE grab_id = @grabId
END
ELSE IF NOT EXISTS (
		SELECT *
		FROM ria_RecNode
		WHERE grab_id = @grabId
		)
BEGIN
	IF @xml IS NOT NULL
		INSERT INTO ria_RecNode (grab_id, node, dateIn, [status])
		VALUES (@grabId, @xml, @CDATE, 0)
	ELSE
		INSERT INTO ria_RecNode (grab_id, node, dateIn, [status])
		VALUES (@grabId, @xml, @CDATE, - 1)
END
ELSE IF @xml IS NOT NULL
BEGIN
	UPDATE ria_RecNode
	SET node = @xml, [status] = 2
	WHERE grab_id = @grabId
END
	
END'
	EXEC(@sql)

	


---------------------------------------BEGIN KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------


    update trec_parametros set par_valor = @Version where par_id = 30
    set @Version_Actual=@Version_Actual+1

    select par_valor from trec_parametros where par_id = 30

    commit tran

    end try
    begin catch
        select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
        RAISERROR(@errorGenerated, 11, 1)
    rollback tran
    end catch
 end
 else begin
    select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end