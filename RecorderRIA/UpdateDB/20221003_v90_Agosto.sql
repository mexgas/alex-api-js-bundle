set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 90
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
	begin tran
	begin try


	set @process = 'CW-7007 se pone N/A califacacion y subcalificacion @C28 alter SP trsp_InsertRecNode'
	set @Sql = 'Alter PROCEDURE [dbo].[trsp_InsertRecNode] @grabId INT, @type INT = 0, @rateEvaluationFormatKolob BIT = 0 
AS
BEGIN
DECLARE @shoutLevel AS NVARCHAR(20)
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
			SELECT @isHistory = 1, @callType = rec.tipo_llamada, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END, @shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio
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
			SELECT @isHistory = 1, @callType = rec.tipo_llamada, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END, @shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio
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

--Languages 0 spanish 1 english
--SELECT @shoutlevel = CASE WHEN @language = 0 THEN substring(@shoutlevel, 0, @start) ELSE substring(@shoutlevel, (@start + 1), (LEN(@shoutlevel) - 1)) END

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
				SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Inbound'' AS ''@C02'', inb.descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04'', isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10'', rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16'', isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.description, ''N/A'') AS ''@C20'', rec.calif_id AS ''@C21'', rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26'', @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
					,isnull(subDisposition.califSubDesc,''N/A'') as ''@C28''
				FROM @riaGrabacion rec
				INNER JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
				LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
				LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
				LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id
					LEFT JOIN cctipocalifsub AS subDisposition ON rec.califSub_id = subDisposition.califSub_id
				INNER JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id
				WHERE rec.grab_id = @grabId

				UNION

				SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Outbound'' AS ''@C02'', inb.cam_descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04'', isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10'', rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16'', isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.Description, ''N/A'') AS ''@C20'', rec.calif_id AS ''@C21'', rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26'', @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
					,isnull(subDisposition.califSubDesc,''N/A'') as ''@C28''
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
		--select @xml
END'
	EXEC(@Sql)

	-------------------------------------------- BEGIN URIEL CABRERA TT4259_Finder Bug ---------------------------------
	SET @process = 'TT4259_Finder_Bug - ALTER procedure [ccsp_BaseXmngr]'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
					@action int = 0,
					@option int = 0,
					@idService int = 0,
					@name varchar(25) = NULL,
					@top varchar(max) = NULL,
					@ids varchar(max)=null,
					@dateStart dateTime= null,
					@grabIds varchar(4000) = null

					AS
					declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
					declare @parameterDefinition nvarchar(max)
					declare @status tinyint

					set @sql = ''''
					if @action in(1,6) begin--obtiene los nodos a insertar en BX
						if @option = 2 begin
							if @action = 1 set @status =0
							else if @action = 6 set @status = 2

							set @parameterDefinition =N''@status int, @top int''

							set @sql=''declare @basexName varchar(max)

					select @basexName=Xname from ccBaseXDB where serviceId=2 and isFull=0;

					with node ( grab_id,xmlString,dateNode)
					AS(
						select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
						,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
						from ria_RecNode A with(nolock)
						where A.status =@status
						union
						select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
						,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
						from ria_RecNodeHistory A with(nolock)
						where A.status =@status
					)

					select node.grab_id,node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
					left join ccBaseXDB baseX on baseX.serviceId=2  and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
					order by baseX.Xname''
						--print(@sql)
						--exec(@sql)
						EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top

						end
					end
					if @action in(2,7) begin--actualiza los nodos insertados en BX
						if @option = 2 begin
							if @action = 2 set @status=0
							else if @action = 7 set @status = 2
							set @parameterDefinition =N''@status int''
							set @sql=''update ria_RecNode with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''		
							
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
							set @sql=''update RIA_RecNodeHistory with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''
							
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
						end
					end
					else if @action = 3 begin--trae el nombre de la base de datos en BX
						select Xname from ccBaseXDB where serviceId = @option and isFull=0
					end
					else if @action = 4 --inserta el nombre del xml en BX
					begin
						insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, @dateStart, @name,0)
					end
					else if @action = 11 begin--trae el nombre de la base de datos en BX
						if @option =2 begin
							SELECT ISNULL(min(node.value(''(/R02/@CDATE)[1]'',''datetime'')),GETDATE()) as node FROM RIA_RecNode where status = 0
						end
						end
					else if @action =12 begin
						declare @replicationName nvarchar(500)
							select @replicationName = name from msdb.dbo.sysjobs where name like ''%-CCRecorderRIA- 0'' and name like ''%SpecialAVRS%''
							exec msdb.dbo.sp_start_job @job_name = @replicationName
							while(
							SELECT count(*) FROM msdb.dbo.sysjobactivity ja
							LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
							INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
							INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
							WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
							AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
						) > 0
						begin
							WAITFOR DELAY ''00:00:10''
						end
					end

					else if @action = 13 begin
						set @sql = ''''
						select @tableName=''RIA_RecNode'',@tableNameHistory=''RIA_RecNodeHistory'',@columnId=''grab_id''
						set @sql=''
						;
						with duplicateIds as(
						select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
						union
						select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
						)

						select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
						inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
						group by A.''+@columnId+'',A.dateIn
						Having count(*)>1
						order by Xname
						''
						exec (@sql)

					end'
	EXEC(@Sql)
-------------------------------------------- END URIEL CABRERA TT4259_Finder Bug ---------------------------------


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