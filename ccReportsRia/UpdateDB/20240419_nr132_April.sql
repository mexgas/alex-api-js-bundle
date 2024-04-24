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
SET @version = 132 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	----------------------------------------------- Ulises Espinosa Begin ----------------------------------------------------------------------------------
	set @process = 'Insert translations by segments report'
	set @sql = 'if not exists (select 1 from TranslatedReports where id = 13030)
	BEGIN
		insert into TranslatedReports values (13030,''resultado1|resultado_de_envio1|resultado2|resultado_de_envio2|resultado3|resultado_de_envio3|resultado4|resultado_de_envio4|resultado5|resultado_de_envio5|resultado6|resultado_de_envio6|resultado7|resultado_de_envio7|resultado8|resultado_de_envio8|resultado9|resultado_de_envio9|resultado10|resultado_de_envio10'')
	END'
	EXEC(@sql)

	set @process = 'Insert into filter'
	set @sql = 'IF not exists ( select 1 from Filters where name = ''segmentoMC'' )
	BEGIN
	INSERT INTO Filters(id,[name], [type], xmlParentNode, xmlChildNode) 
		Values (35, ''segmentoMC'',35,''SegmentoMC'',''SegmentosMC'')
	END'
	EXEC(@sql)

	set @process = 'Insert into ReportsFilters'
	set @sql = 'IF not exists(select 1 from ReportsFilters where id = 13030)
	BEGIN
	INSERT INTO ReportsFilters values(''Segments detail'',''SegmentoMC'',13030)
	END'
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus'
	set @sql = 'IF not exists(select 1 from ReportsFiltersMenus where idReport = 13030)
	BEGIN
	INSERT INTO ReportsFiltersMenus(idReport,filterMenuName,showFilter) VALUES (13030, ''date'', 1), (13030,''filterby'',1)
	END'
	EXEC(@sql)

	SET @process = 'si existe se elimina el sp ccspRepCatalogos'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCatalogos'')
	begin
		DROP PROCEDURE ccspRepCatalogos;
	end'
	EXEC(@sql)

	set @process = 'Se crea nuevamente el sp ccspRepCatalogos'
	set @sql = '	CREATE   PROCEDURE [dbo].[ccspRepCatalogos]
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
	IF @type = 34 	BEGIN
		select SegmentId as Id,Name as description, ''SegmentId'' as dbColumn from ccSmsSegments
	END
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

	set @process = 'Creacion de la tabla RepSMSDayReportBySegments'
	set @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''RepSMSDayReportBySegments'')
BEGIN
    CREATE TABLE [dbo].[RepSMSDayReportBySegments](
	id_credito bigint NOT NULL,
	credito nvarchar(40),
	fecha_foto datetime, --fecha actual 
	meses_vencidos int,
	seg_cuenta varchar(15),
	fila varchar(100),
	locacion varchar(20),
	dia_corte nvarchar(100),
	SegmentId int,
	segmentoMC varchar(8),
	semana varchar(12),
	dia_semana varchar(12),
	telefonos1 varchar(50),
	resultado1 varchar(50),
	resultado_de_envio1 varchar(50),
	telefonos2 varchar(50),
	resultado2 varchar(50),
	resultado_de_envio2 varchar(50),
	telefonos3 varchar(50),
	resultado3 varchar(50),
	resultado_de_envio3 varchar(50),
	telefonos4 varchar(50),
	resultado4 varchar(50),
	resultado_de_envio4 varchar(50),
	telefonos5 varchar(50),
	resultado5 varchar(50),
	resultado_de_envio5 varchar(50),
	telefonos6 varchar(50),
	resultado6 varchar(50),
	resultado_de_envio6 varchar(50),
	telefonos7 varchar(50),
	resultado7 varchar(50),
	resultado_de_envio7 varchar(50),
	telefonos8 varchar(50),
	resultado8 varchar(50),
	resultado_de_envio8 varchar(50),
	telefonos9 varchar(50),
	resultado9 varchar(50),
	resultado_de_envio9 varchar(50),
	telefonos10 varchar(50),
	resultado10 varchar(50),
	resultado_de_envio10 varchar(50)
) ON [PRIMARY]
GO
END;'
	EXEC(@sql)

	SET @process = 'si existe se elimina el sp ccspRepSMSDayReportBySegments'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepSMSDayReportBySegments'')
	begin
		DROP PROCEDURE ccspRepSMSDayReportBySegments;
	end'
	EXEC(@sql)

	set @process = 'Se crea nuevamente el sp ccspRepSMSDayReportBySegments'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspRepSMSDayReportBySegments] 
	@action AS TINYINT = 1, 
	@from AS DATETIME,  
	@to AS DATETIME
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN	
	select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN

	DELETE FROM RepSMSDayReportBySegments WHERE fecha_foto between @from AND @to;
	--select * from smsccoLogDial

	;with SMSBySegments as(
	select ROW_NUMBER() OVER (PARTITION BY srm.id_credito ORDER BY a.phone) rownumber,
			srm.id_credito,
			srm.credito credito,
			convert(date,a.smsDate,121) as fecha_foto,
			srm.MESES_VENCIDOS,
			srm.SEG_CUENTA,
			srm.FILA,
			srm.LOCACION,
			srm.DIA_CORTE,
			ss.segmentId,
			srm.SegmentoMC,
			(DATEPART(WEEK, DATEADD(DAY, -1, a.smsDate)) - DATEPART(WEEK, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, a.smsDate), 0))) + 1) AS Semana,
			DATEPART(DW, GETDATE()) AS DiaSemana,
			a.phone as Phone,
			''systemTranslated_Resultado_ID_'' + cast(srm.RESULTADO_ID as varchar)  resultado,
			''systemTranslated_Resultado_Envio_'' + cast(a.statusSystemsId as varchar)  resultado_de_envio		
	from smsccoLogDial a with (nolock)
	inner join SmsRemesasMuñozDay srm on srm.TDCT = a.callkey
	inner join ccSmsSegments ss on ss.name = srm.SegmentoMC
	where a.smsDate between @from and @to
	)
	
	Insert into RepSMSDayReportBySegments
	select
		id_credito,
		credito,
		fecha_foto,
	max(MESES_VENCIDOS) meses_vencidos,
	max(SEG_CUENTA) seg_cuenta,
	max(FILA) fila,
	max(LOCACION) locacion,
	max(DIA_CORTE) dia_corte,
	max(segmentId) as SegmentId,
	max(SegmentoMC) segmentoMC,
	max(Semana) as semana,
	max(DiaSemana) as dia_semana,
	max(case when rownumber=1 then Phone else '''' end) telefonos1 ,
	max(case when rownumber=1 then resultado else '''' end) resultado1 ,
	max(case when rownumber=1 then resultado_de_envio else '''' end) resultado_de_envio1 ,
	max(case when rownumber=2 then Phone else '''' end) telefonos2 ,
	max(case when rownumber=2 then resultado else '''' end) resultado2 ,
	max(case when rownumber=2 then resultado_de_envio else '''' end) resultado_de_envio2 ,
	max(case when rownumber=3 then Phone else '''' end) telefonos3 ,
	max(case when rownumber=3 then resultado else '''' end) resultado3 ,
	max(case when rownumber=3 then resultado_de_envio else '''' end) resultado_de_envio3 ,
	max(case when rownumber=4 then Phone else '''' end) telefonos4 ,
	max(case when rownumber=4 then resultado else '''' end) resultado4 ,
	max(case when rownumber=4 then resultado_de_envio else '''' end) resultado_de_envio4 ,
	max(case when rownumber=5 then Phone else '''' end) telefonos5 ,
	max(case when rownumber=5 then resultado else '''' end) resultado5 ,
	max(case when rownumber=5 then resultado_de_envio else '''' end) resultado_de_envio5 ,
	max(case when rownumber=6 then Phone else '''' end) telefonos6 ,
	max(case when rownumber=6 then resultado else '''' end) resultado6 ,
	max(case when rownumber=6 then resultado_de_envio else '''' end) resultado_de_envio6 ,
	max(case when rownumber=7 then Phone else '''' end) telefonos7 ,
	max(case when rownumber=7 then resultado else '''' end) resultado7 ,
	max(case when rownumber=7 then resultado_de_envio else '''' end) resultado_de_envio7 ,
	max(case when rownumber=8 then Phone else '''' end) telefonos8 ,
	max(case when rownumber=8 then resultado else '''' end) resultado8 ,
	max(case when rownumber=8 then resultado_de_envio else '''' end) resultado_de_envio8 ,
	max(case when rownumber=9 then Phone else '''' end) telefonos9 ,
	max(case when rownumber=9 then resultado else '''' end) resultado9 ,
	max(case when rownumber=9 then resultado_de_envio else '''' end) resultado_de_envio9 ,
	max(case when rownumber=10 then Phone else '''' end) telefonos10 ,
	max(case when rownumber=10 then resultado else '''' end) resultado10 ,
	max(case when rownumber=10 then resultado_de_envio else '''' end) resultado_de_envio10
	from SMSBySegments
	group by id_credito,fecha_foto,credito
END'
	EXEC(@sql)
	-------------------------------------------------- Ulises Espinosa End -----------------------------------------------------------------------------------

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
