set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 75
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	
    SET @process = 'CW-4643 Se cambio el nivel de grito'
	SET @sql = 'ALTER PROCEDURE [dbo].[trsp_InsertRecNode] @grabId INT, @type INT = 0
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
		SELECT @isHistory = 0, @callType = rec.tipo_llamada, @Prefijo = rec.Prefijo, @manual = CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END, @shoutlevel = isnull(rec.id_nivel_grito,-1), @rating = isnull(total_forma, 0), @callID = cal_id, @CDATE = rec.finicio
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
	ELSE
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

	--Languages 0 spanish 1 english
	--SELECT @shoutlevel = CASE WHEN @language = 0 THEN substring(@shoutlevel, 0, @start) ELSE substring(@shoutlevel, (@start + 1), (LEN(@shoutlevel) - 1)) END

	SELECT @Template = formatos.nombre, @supervisor = (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)
	FROM RIA_FORMATOS AS formatos
	INNER JOIN RIA_FORMACALIF formatosCalif ON formatosCalif.id_formato = formatos.id_formato
	INNER JOIN RIA_GRABACION grabacion ON grabacion.grab_id = formatosCalif.id_grabacion
	INNER JOIN ccUsers supervisor ON supervisor.User_id = formatosCalif.id_supervisor
	WHERE grabacion.grab_id = @grabId AND formatosCalif.tipo = 1

	IF @isHistory = 0
	BEGIN
		SET @xml = (
				SELECT *
				FROM (
					SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Inbound'' AS ''@C02'', inb.descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04'', isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10'', rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16'', isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.description, '''') AS ''@C20'', rec.calif_id AS ''@C21'', rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26'', @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
					FROM ria_grabacion rec
					INNER JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
					LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
					LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
					LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id
					INNER JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id
					WHERE rec.grab_id = @grabId
					
					UNION
					
					SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Outbound'' AS ''@C02'', inb.cam_descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04'', isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10'', rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16'', isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.Description, '''') AS ''@C20'', rec.calif_id AS ''@C21'', rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26'', @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
					FROM ria_grabacion rec
					INNER JOIN cccamps inb ON rec.cam_id = inb.cam_id AND rec.tipo_llamada = 2
					LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
					LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
					LEFT JOIN ccTipoCalifOUT AS e ON rec.calif_id = e.calif_id
					INNER JOIN ccRIACampsGraph grap ON grap.cam_id = inb.cam_id
					WHERE rec.grab_id = @grabId
					) x
				FOR XML path(''R02'')
				)
	END
	ELSE
	BEGIN
		SET @xml = (
				SELECT *
				FROM (
					SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Inbound'' AS ''@C02'', inb.descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04'', isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10'', rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16'', isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.description, '''') AS ''@C20'', rec.calif_id AS ''@C21'', rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26'', @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
					FROM RIA_GRABACIONCONSULTA rec
					INNER JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
					LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
					LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
					LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id
					INNER JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id
					WHERE rec.grab_id = @grabId
					
					UNION
					
					SELECT convert(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'', rec.grab_id AS ''@C01'', ''Outbound'' AS ''@C02'', inb.cam_descripcion AS ''@C03'', isnull(@shoutLevel, -1) AS ''@C04'', isnull(usr.LOGIN,''N/A'') AS ''@C05'', convert(VARCHAR(23), rec.finicio, 126) AS ''@C06'', pos.Computer AS ''@C07'', convert(NVARCHAR(10), rec.duracion) AS ''@C08'', rec.ani AS ''@C09'', rec.dni AS ''@C10'', rec.cal_key AS ''@C11'', @manual AS ''@C12'', isnull(usr.[User_id],0) AS ''@C13'', rec.cal_id AS ''@C14'', rec.cam_id AS ''@C15'', CONVERT(CHAR(8), DATEADD(second, rec.duracion, 0), 108) AS ''@C16'', isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, - 1) AS ''@C17'', isnull(@rating, 0) AS ''@C18'', rec.id_repositorio AS ''@C19'', isnull(e.Description, '''') AS ''@C20'', rec.calif_id AS ''@C21'', rec.video AS ''@C22'', isnull(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno,''N/A'') AS ''@C23'', isnull(@supervisor, '''') AS ''@C24'', isnull(@Template, '''') AS ''@C25'', grap.graphic_id AS ''@C26'', @Prefijo AS ''@C27'', rec.cam_id AS ''@CID'', rec.tipo_llamada AS ''@CType''
					FROM RIA_GRABACIONCONSULTA rec
					INNER JOIN cccamps inb ON rec.cam_id = inb.cam_id AND rec.tipo_llamada = 2
					LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
					LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * - 1
					LEFT JOIN ccTipoCalifOUT AS e ON rec.calif_id = e.calif_id
					INNER JOIN ccRIACampsGraph grap ON grap.cam_id = inb.cam_id
					WHERE rec.grab_id = @grabId
					) x
				FOR XML path(''R02'')
				)
	END

	IF @xml IS NOT NULL
	BEGIN
		SELECT @crmNode = node
		FROM ccCRMNodes
		WHERE [type] = @callType AND cal_id = @callID

		IF @crmNode IS NOT NULL
		BEGIN
			UPDATE ccCRMNodes
			SET grab_id = @grabId
			WHERE [type] = @callType AND cal_id = @callID

			SET @sqlCRM = N'' set @xml.modify(''''insert'' + + CONVERT(NVARCHAR(max), @crmNode) + '' into(/R02)[1]'''') ''

			EXECUTE sp_executesql @sqlCRM, N''@xml XML Output,@crmNode XML'', @xml OUTPUT, @crmNode
		END
	END

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
	EXEC (@sql)

	SET @process = 'CW-4643 Drop SP ccspGalatea_Finder '
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspGalatea_Finder'')
    begin
        DROP PROCEDURE ccspGalatea_Finder;
    end'
	EXEC (@sql)

	SET @process = 'CW-4643 Create SP ccspGalatea_Finder '
	SET @sql = 'CREATE PROCEDURE [dbo].[ccspGalatea_Finder]
@action int,
@grabIds varchar(max)=null,
@grabId int =null,
@userId int =0,	
@markTime int=null,
@markId int=null
AS
BEGIN

    SET NOCOUNT ON;
	declare @sql varchar(max)

	if @action=1 begin
		select id_repositorio as repositoryId,dirvirtual_audio as pathAudio,dirvirtual_video as pathVideo,ruta_repositorio as pathRepositoryAudio from TREC_REPOSITORIOS
	end
	else if @action=2 begin
		set @sql=''
		;
		with grab as (
		select grab_id,cal_id,tipo_llamada from RIA_GRABACION where grab_id in(''+@grabIds+'')
		union
		select grab_id,cal_id,tipo_llamada from RIA_GRABACIONCONSULTA where grab_id in(''+@grabIds+'')
		)

		select mark.id_marca as markId, grab.grab_id as grabId,b.login as userName, mark.user_id as [userId],mark.marca as mark,convert(bit,case when b.TipoUser_id =1 then 0 else 1 end ) as IsAdmin
		from RIA_MARCAS mark 
		inner join grab on grab.cal_id=mark.call_id and grab.tipo_llamada=mark.tipo_llamada
		inner join ccUsers b on b.user_id = mark.user_id
		order by grab.grab_id,mark.tipo_marca 
		''
		--print @sql
		exec (@sql)
	end
	else if @action =3 begin
		select cast(case when par_valor =''1'' then 1 else 0 end as bit) as isEncrypt from TREC_PARAMETROS where par_id=15
	end
	else if @action =4 begin
		set @sql=''declare @nameFolder table (callType int,nameFolder varchar(100),prefijo varchar(2))
	insert into @nameFolder values(1,''''INBOUND'''',''''I_'''')
	insert into @nameFolder values(2,''''OUTBOUND'''',''''O_'''')
	declare @ext varchar(30)

	select @ext = case when par_valor=''''1'''' then ''''.wav.enc'''' else ''''.wav'''' end from TREC_PARAMETROS where par_id=15
		;
		with grab as (
		select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACION where grab_id in(''+@grabIds+'')
		union
		select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACIONCONSULTA where grab_id in(''+@grabIds+'')
		)
		
		select grab.grab_id as grabId,grab.id_repositorio as repositoryId,rep.dirvirtual_audio as virtualAudio
		,rep.ruta_repositorio+''''\''''+f.nameFolder+''''\''''+ cast(cal_id/10000 as varchar(100))+''''\'''' as pathRep,
		f.prefijo+cast(cal_id as varchar(100))	+ case when subFijo<>'''''''' then ''''_''''+subFijo else '''''''' end + @ext as [fileAudio]
		from grab 
		inner join TREC_REPOSITORIOS rep on grab.id_repositorio=rep.id_repositorio
		inner join @nameFolder f on f.callType=grab.tipo_llamada  
		order by repositoryId
		''
		--print @sql
		exec (@sql)
	end
	else if @action =5 begin
		select top 1 id_repositorio as repositoryId,rep.ruta_repositorio as pathRep, Cred.domain, Cred.[user], Cred.[password]
		from TREC_REPOSITORIOS Rep
		inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
		inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
		where Cred.type = 1 and status=1
	end
	else if @action=6 begin
		declare @cal_id int,@tipo_llamada int

		select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACION where grab_id=@grabId

		if @cal_id is null and @tipo_llamada is null begin
			select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACIONCONSULTA where grab_id=@grabId
		end			   
		insert RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grabId,@userId,CONVERT(varchar, DATEADD(ss, @markTime , 0), 8),2,@tipo_llamada,@cal_id )
		select cast( @@IDENTITY  as int) as markId
	end
	else if @action=7 begin
		delete from RIA_MARCAS  where id_marca=@markId
	end
	else if @action=8 begin	
		select par_valor as hexKey from TREC_PARAMETROS where par_id=75
	end
  
END
'
	EXEC (@sql)
	

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
