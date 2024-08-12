/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 137 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	------------------------------Begin Frida
	set @process = 'create table RepSpecialRecordingsDownload'
	set @sql = '
	if not exists (select * from sys.tables where name = N''RepSpecialRecordingsDownload'')
    begin
	CREATE TABLE RepSpecialRecordingsDownload (
		date DATETIME NOT NULL,
		adminId SMALLINT NOT NULL,
		admin_name  VARCHAR(80),
		grab_id BIGINT,
		generalId SMALLINT,
		inboundId SMALLINT,
		inboundCampaign VARCHAR(40),
		campaignId SMALLINT,
		outboundCampaign VARCHAR(40),
		disposition VARCHAR(150),
		subDisposition	VARCHAR(150)
	)
	end
	'
	EXEC(@sql)

	set @process = ' CREATE TABLE ccRecordingsDownload  '
	set @sql = '
	if not exists (select * from sys.tables where name = N'ccRecordingsDownload')
    begin
        CREATE TABLE ccRecordingsDownload (
		date DATETIME NOT NULL,
		adminId int,
		grab_Id BIGINT,
		cam_id int,
		CampType smallint
		)
    end
	'
	EXEC(@sql)

	set @process = ' insert into ReportHighUse ccspRepSpecialRecordingsDownload '
	set @sql = '
	if not exists(select * from ReportHighUse where nameSp=''ccspRepSpecialRecordingsDownload'')
	begin 
	insert into ReportHighUse (nameSp) values (''ccspRepSpecialRecordingsDownload'')
	end
	'
	EXEC(@sql)

	set @process = 'insert into Filters Filters adminIds'
	set @sql = '
	if not exists(select id from Filters where id = 15 and type = 36)
	begin
		insert into Filters (id,name,type,xmlParentNode,xmlChildNode) values (15,''adminIds'',36,''AdminIds'',''AdminId'')
	end
	'
	EXEC(@sql)

	set @process = 'insert into FiltersMenus adminids'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''adminids'' )
	begin
		insert into FiltersMenus (name) values (''adminids'')
	end
	'
	EXEC(@sql)

	set @process = 'insert into FiltersMenus campaigns'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''campaigns'' )
	begin
		insert into FiltersMenus (name) values (''campaigns'')
	end
	'
	EXEC(@sql)

	set @process = 'insert into FiltersMenus acds'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''acds'' )
	begin
		insert into FiltersMenus (name) values (''acds'')
	end
	'
	EXEC(@sql)

	set @process = 'insert into FiltersMenus groupby'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''groupby'' )
	begin
		insert into FiltersMenus (name) values (''groupby'')
	end
	'
	EXEC(@sql)

	set @process = 'insert into FiltersMenus text'
	set @sql = '
	if not exists (select * from FiltersMenus where name=''text'' )
	begin
		insert into FiltersMenus (name) values (''text'')
	end
	'
	EXEC(@sql)

	set @process = 'INSERT INTO ReportsFiltersMenus date '
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''date'')
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(7230,N''date'') 
	end
	'
	EXEC(@sql)

	set @process = 'INSERT INTO ReportsFilters campaigns'
	set @sql = '
	if not exists (select * from ReportsFilters where id=7230 and filterName=''campaigns'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Recordings Download'',''campaigns'',7230) 
	end
	'
	EXEC(@sql)

	set @process = 'INSERT INTO ReportsFilters acds'
	set @sql = '
	if not exists (select * from ReportsFilters where id=7230 and filterName=''acds'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Recordings Download'',''acds'',7230) 
	end
	'
	EXEC(@sql)

	set @process = 'INSERT INTO ReportsFilters adminids'
	set @sql = '
	if not exists (select * from ReportsFilters where id=7230 and filterName=''adminids'')
	begin
		INSERT INTO ReportsFilters(reportName,filterName,id) VALUES(''Recordings Download'',''adminids'',7230) 
	end
	'
	EXEC(@sql)

	set @process = ' insert into ReportsFiltersMenus adminids'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''adminids'')
	begin
		insert into ReportsFiltersMenus (idReport,filterMenuName,showFilter) values (7230,''adminids'',1)
	end
	'
	EXEC(@sql)

	set @process = 'insert into ReportsFiltersMenus campaigns '
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''campaigns'')
	begin
		insert into ReportsFiltersMenus (idReport,filterMenuName,showFilter) values (7230,''campaigns'',1)
	end
	'
	EXEC(@sql)


	set @process = 'insert into ReportsFiltersMenus acds'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=7230 and filterMenuName=''acds'')
	begin
		insert into ReportsFiltersMenus (idReport,filterMenuName,showFilter) values (7230,''acds'',1)
	end
	'
	EXEC(@sql)

	set @process = 'create table orColumnsByReport '
	set @sql = '
	if not exists (select * from sys.tables where name = N''orColumnsByReport'')
    begin
        create table orColumnsByReport(idReport int, columns varchar(255))
    end
	'
	EXEC(@sql)

	set @process = ' insert into orColumnsByReport report 7230'
	set @sql = '
	if not exists (select * from orColumnsByReport where idReport=7230 and columns=''campaignId|inboundId'')
	begin
		insert into orColumnsByReport (idReport,columns) values (7230,''campaignId|inboundId'')
	end
	'
	EXEC(@sql)

	set @process = ' DROP PROCEDURE ccspRepSpecialRecordingsDownload '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepSpecialRecordingsDownload'')
    begin
        DROP PROCEDURE ccspRepSpecialRecordingsDownload;
    end
	'
	EXEC(@sql)

	set @process = 'CREATE PROC ccspRepSpecialRecordingsDownload '
	set @sql = '
	
CREATE PROC ccspRepSpecialRecordingsDownload
@action AS TINYINT, 
@from AS DATETIME = NULL, 
@to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
IF @to IS NULL
	SELECT @to = getdate()
IF @action = 1
BEGIN
  DELETE FROM RepSpecialRecordingsDownload  WHERE date >= @from AND date < @to


;with grab as(
	select  ccrd.date ,ccrd.adminId,
		A.grab_id, ccrd.CampType as tipo_llamada, A.calif_id, A.califSub_id,A.cam_id
	from ccRecordingsDownload ccrd
	inner join RIA_GRABACION A with(nolock) on ccrd.grab_Id=A.grab_id
	where ccrd.date between @from and @to
	union
	select ccrd.date ,ccrd.adminId,
		A.grab_id, ccrd.CampType as tipo_llamad, A.calif_id, A.califSub_id,A.cam_id
	from ccRecordingsDownload ccrd
	inner join  RIA_GRABACIONCONSULTA  A with(nolock) on ccrd.grab_Id=A.grab_id
	where ccrd.date between @from and @to
), 
	califTotal as (
	select grab_id
	,isnull(calif.Description,''N/A'') as calificacion
	,isnull(sub.califSubDesc,''N/A'') as subCalif
	from grab
	left join cctipocalifout calif on calif.calif_id = grab.calif_id
	left join cctipocalifsubout sub on sub.califSub_id = grab.califSub_id
	where grab.tipo_llamada=2
	union
	select grab_id
	,isnull(calif.Description,''N/A'') as calificacion
	,isnull(sub.califSubDesc,''N/A'') as subCalif
	from grab
	left join cctipocalif calif on calif.calif_id = grab.calif_id
	left join cctipocalifsub sub on sub.califSub_id = grab.califSub_id
	where grab.tipo_llamada=1
),
total as(
	select
	ccr.date,
	ccr.grab_id,
	c.cam_id,c.cam_descripcion,2 as CampType,
	ccr.adminId
	,ccr.tipo_llamada
	from cccamps c
	inner join grab ccr on ccr.cam_id= c.cam_id
	where ccr.tipo_llamada = 2 and ccr.date between @from and @to
	union
	select 
	ccr.date,
	ccr.grab_id,
	Inbound_id,descripcion,1 as CampType
	,ccr.adminId
	,ccr.tipo_llamada
	from 
	ccinbound i
	inner join grab ccr on ccr.cam_id = i.Inbound_id
	where ccr.tipo_llamada = 1 and ccr.date between @from and @to
)

insert into RepSpecialRecordingsDownload
select 
t.date
,t.adminId
,case when CHARINDEX('' '',u.Nombres) > 0 then left(u.Nombres,CHARINDEX('' '',u.Nombres)-1)  + '' '' + u.ApellidoPaterno else  u.Nombres  + '' '' + u.ApellidoPaterno end admin_Name
,t.grab_id
,t.cam_id as generalId
,case when t.tipo_llamada = 1 then t.cam_id else 0 end as inboundId
,case when t.tipo_llamada = 1 then t.cam_descripcion else '''' end as inboundCampaign
,case when t.tipo_llamada = 2 then t.cam_id else 0 end as campaingId
,case when t.tipo_llamada = 2 then t.cam_descripcion else '''' end as outboundCampaign
,ct.calificacion
,ct.subCalif
from total t
inner join ccUsers u on u.User_id = t.adminId
inner join califTotal ct on ct.grab_id=t.grab_id


END
	'
	EXEC(@sql)

	set @process = 'DROP PROCEDURE ccspRepCatalogos '
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepCatalogos'')
    begin
        DROP PROCEDURE ccspRepCatalogos;
    end
	'
	EXEC(@sql)

	set @process = 'CREATE PROCEDURE  ccspRepCatalogos'
	set @sql = 'CREATE  PROCEDURE ccspRepCatalogos
	@type as tinyint,
	@action tinyint = 0 -- 0 Filter select; 1 Filters Range
	,@userId int =0 ---- se agrega parametro para filtros
	,@menuId INT = 0

	AS
	declare @tablatemp table (id int, description varchar(100) null)
	declare @tempwork table (idwg int)
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @condition NVARCHAR(300) = '''';
	DECLARE @columnName NVARCHAR(100) = '''';
	DECLARE @consult NVARCHAR (2000) = '''';

	if @action = 0
	BEGIN
	IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
	BEGIN
		CREATE TABLE #filters ([Type] VARCHAR(200))
	END

		-- CAMPAIGNS
	IF @type = 1 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName =	''campaignId'';
		END

		SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)	
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
				where us.[User_id] = @userId ''
				+ @consult + '' inner join @tablatemp A on camp.cam_id = A.id'' + @condition;
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
	END


		-- DIAL RESULTS
	if @type = 2 begin
		Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
		from ccTipoResultadoDial
		order by descripcion
	end

		-- WORKGROUPS
	if @type = 3 begin
		if @userId <> 0 begin
			select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
			from ccWgByAcdView v
			inner join ccriacat_workgroup c on c.IDWG=v.IDWG
			where USER_ID= @userId
			return
		end
		else  begin
			select idwg as id, wgname as description, ''workgroupId'' as dbColumn
			from ccRIACat_WorkGroup
			group by idwg, wgname	select * from ccRIACat_WorkGroup
			order by wgname
		end
	end


	-- AREAS
	if @type = 4 begin
	if @userId <> 0 begin

		insert into @tablatemp
		select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
		inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
		where us.[User_id] = @userId

		select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
		from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
		return
	end
		else begin

			select idArea as id, AreaName as description, ''areaId'' as dbColumn
			from ccRIACat_Areas
			group by idArea, AreaName
			order by AreaName
		end
	end

	-- DISPOSITIONS OUT
	if @type = 5 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalifOut
		order by [description]
	end

		-- USER
	if @type = 6 	begin
		if @userId <> 0 begin

				insert into @tempwork
						select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

				select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

				inner join @tempwork awg on wgu.IDWG = awg.idwg
				where us.TipoUser_id = 1 and [status] = 1

				return
			end

			else begin

				SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
				FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
				ORDER BY description
			end
	end

		-- ACDS**************
	IF @type = 7 BEGIN

		INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
		IF EXISTS (SELECT * FROM #filters)
		BEGIN
			SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
			SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
		END
		ELSE BEGIN
			SET @columnName = ''inboundId'';
		END

		SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
			FROM ccinbound B''

		IF @userId <> 0 BEGIN

			SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId;''
				+ @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;'';		
		END
		ELSE BEGIN
			SET @SQL = @consult + @condition;
		END
		EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
	end

		-- DIDS
	if @type = 8 	begin
		select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
		union
		select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
		from ccdnis
	end

		--DISPOSITIONS IN
	if @type = 9 begin
		SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
		FROM ccTipoCalif
		order by [description]
	end

		--SUBDISPOSITIONS IN
	if @type = 10	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM ccTipoCalifSub
		order by [description]
	end

		--PROVIDER
	if @type = 11 begin
		SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
		FROM cstoProvedor
		order by [description]
	end

		-- UNAVAILABLES
	if @type = 12 begin
		SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
		FROM cctiponotready
		order by descripcion
	end

		-- DIALERS
	if @type = 13 begin
		SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
		FROM ccoDialers
		order by descripcion
	end

		-- CallTYpes
	if @type = 14	begin
			SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
			FROM ccStatusLlamada
		order by descripcion
	end

		-- SUBDISPOSITIONS OUT
	if @type = 21	begin
		SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
		FROM cctipocalifsubout
		order by [description]
	end

		--AVRS TEMPLATE-SECTION
	if @type = 15 	begin
		SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
		FROM RIA_FORMATOCONCEPTO fc
		INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato, nombre) as rf
		ON rf.id_formato = fc.templateId
		inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
		order by fc.id
	END

	--exec dbo.ccspRepCatalogos @type=15,@action=0

		--AVRS TEMPLATES
	if @type = 16 	begin
		SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
		FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
										FROM RIA_FORMATOS
										WHERE activo = 1
										group by id_formato) as t
		ON f.id_formato = t.id_formato AND f.version = t.version
		order by f.nombre
	end

		--AVRS TEMPLATES
	if @type = 31 	begin
		SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
		FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
										FROM RIA_CONCEPTOS
										group by id_concepto) as t
		ON c.id_concepto = t.id_concepto AND c.version = t.version
		order by c.con_descripcion
	END

		--AVRS QUESTIONS
	if @type = 23 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END


	--AVRS QUESTIONS CHAT
	if @type = 24 	begin
		SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
		FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
										FROM RIA_PREGUNTAS
										group by id_pregunta) as t
		ON p.id_pregunta = t.id_pregunta
		order by p.enunciado_pregunta
	END

		-- AVRS SUPERVISOR
	if @type = 17 	begin
		SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
		FROM ccUserView
		WHERE [status] = 1
		and TipoUser_id = 2
		ORDER BY [login]
	end

		--Status Call
	if @type = 25 	begin
		select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
		from ccstatusllamada
		order by [descripcion]
	end

		--Survey
	if @type = 26 	begin
		select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
		from Survey
		order by [description]
	end

	--dialType
	if @type = 29 begin
		select dialId as id, [description] as description, ''dialId'' as dbcolumn
		from dialType
		order by [description]
	end

		--dial
	if @type = 30 	begin
		select id as id, [description] as description, ''dialId'' as dbcolumn
		from Dials
		order by [description]
	end

	if @type = 33 begin
		if @userId <> 0 begin
 			insert into @tablatemp
			select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
			inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat = 0
			where us.[User_id] = @userId

			SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound B
			inner join @tablatemp A on B.inbound_id = A.id
			return
		end
		else begin
			select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
			from ccinbound where chat = 0
		end
	end
	IF @type = 34 	
	BEGIN
		SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
		FROM TipoReadyAuxiliar
		ORDER BY [description]
	END
	IF @type = 35 	
	BEGIN
		select SegmentId as Id,Name as description, ''SegmentId'' as dbColumn from ccSmsSegments
	END
	if @type = 36 begin
		if @userId <> 0 begin

				insert into @tempwork
						select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

				select distinct us.User_id as id, us.Login as description,  ''adminId'' as dbcolumn from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

				inner join @tempwork awg on wgu.IDWG = awg.idwg
				where us.TipoUser_id = 2 and [status] = 1

				return
			end

			else begin

				SELECT [user_id] as id, [login] AS description, ''adminId'' as dbColumn
				FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 2
				ORDER BY description
			end
	end
	end --Action 0

	IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
	BEGIN
		DROP TABLE #filters;
	END

	-----------------------------------------------------------
	if @action = 1 begin
		-- TRUNKS
		if @type = 13
		begin
			SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
		end

		-- AVRS DISPOSITION
		if @type = 18
		begin
			SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
		end

		-- AVG DISPOSITION
		if @type = 19
		begin
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end

		-- SCORE
		if @type = 20
		begin
			SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
		end
	end'
	EXEC(@sql)
	
	------------------------------END Frida
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
