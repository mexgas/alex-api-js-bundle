SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 104

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-5452 Drop Column Disposition2 Section'
	SET @sql = 'IF EXISTS(SELECT * FROM SYS.columns WHERE name=''Disposition2'' AND OBJECT_ID = OBJECT_ID(''RepAVRSSection''))
BEGIN
		ALTER TABLE RepAVRSSection DROP COLUMN Disposition2
END
'
	EXEC (@sql)

	SET @process = 'CW-5452 add TemplateSection Filter (filters) '
	SET @sql = '	update Filters set name=''TemplateSection'', xmlParentNode=''TemplateSection'',xmlChildNode=''TemplateSection'' where type=15'
	EXEC (@sql)

	SET @process = 'CW-5452 Add new columns to RepAVRSSection'
	SET @sql = 'if not exists (select * from sys.columns where name = ''TemplateSection'' and Object_ID = Object_ID(N''RepAVRSSection''))
		begin
		ALTER TABLE RepAVRSSection
		ADD TemplateSection varchar(100);
		END
	if not exists (select * from sys.columns where name = ''templateSectionId'' and Object_ID = Object_ID(N''RepAVRSSection''))
		begin
		ALTER TABLE RepAVRSSection
		ADD templateSectionId int;
		END'
	EXEC (@sql)

	SET @process = 'CW-5452 create new table RIA_FORMATOCONC'
	SET @sql = 'IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = N''RIA_FORMATOCONCEPTO'')
create table RIA_FORMATOCONCEPTO(id int identity, templateId int, sectionId int, primary Key (id))
'
	EXEC (@sql)

	SET @process = 'CW-5452 Drop Column AvgDisposition Section'
	SET @sql = 'IF EXISTS(SELECT * FROM SYS.columns WHERE name=''score'' AND OBJECT_ID = OBJECT_ID(''RepAVRSSection''))
BEGIN
ALTER TABLE RepAVRSSection DROP COLUMN score
END	'

	EXEC (@sql)

	SET @process = 'CW-5452 Drop Column Disposition2 Question'
	SET @sql = 'IF EXISTS(SELECT * FROM SYS.columns WHERE name=''Disposition2'' AND OBJECT_ID = OBJECT_ID(''RepAVRSQuestion''))
BEGIN
		ALTER TABLE RepAVRSQuestion  DROP COLUMN Disposition2
END'

	EXEC (@sql)

	SET @process = 'CW-5452 Drop Column AvgDisposition Question'
	SET @sql = '
IF EXISTS(SELECT * FROM SYS.columns WHERE name=''score'' AND OBJECT_ID = OBJECT_ID(''RepAVRSQuestion''))
BEGIN
ALTER TABLE RepAVRSQuestion  DROP COLUMN score
END'

	EXEC (@sql)

	SET @process = 'CW-5452 update DetailReports and GroupByReports 8063'
	SET @sql = '
UPDATE DetailReports
set showColumnsDetail=''date|userId|user|agentName|supervisorUser|Supervisor|Template|Section|avgDisposition|cam_id|campaignAcd|media''
where id=8063

update GroupByReports set
columns=''Template|Section|count(templateSectionId):Dispositions|avg(avgDisposition):avgDisposition|TemplateSection''
,groupByColumns=''Template|Section|TemplateSection''
where id=8063

UPDATE DetailReports
SET dbColumnFilter=''templateSectionId''
WHERE id=8063'
	EXEC (@sql)


	SET @process = 'CW-5452 update DetailReports and GroupByReports 8064'
	SET @sql = 'UPDATE DetailReports
SET showColumnsDetail=''date|userId|user|agentName|supervisorUser|Supervisor|Template|Section|question|avgDisposition|cam_id|campaignAcd|media''
WHERE id=8064

UPDATE DetailReports SET dbColumnFilter=''questionId'' where id=8064

UPDATE GroupByReports SET
columns=''Template|Section|question|count(avgDisposition):Dispositions|avg(avgDisposition):avgDisposition''
WHERE id=8064'
	EXEC (@sql)


		SET @process = 'CW-5452 DetailReports templateSectionId '
		SET @sql = 'update DetailReports set dbColumnFilter = ''templateSectionId'' where id=8063'
		EXEC (@sql)

		SET @process = 'CW-5452 delete disposition2'
		SET @sql = 'if exists (select * from sys.columns where name=''disposition2'' and object_id=object_id(''RepAVRSQuestionChat''))
		begin
			alter table RepAVRSQuestionChat drop column disposition2
		end'
		EXEC (@sql)

		SET @process = 'CW-5452 update DetailReports 8082'
		SET @sql = 'update DetailReports set showColumnsDetail = ''date|userId|user|agentName|Template|question|avgDisposition|inboundId|inbound'' where id=8082'
		EXEC (@sql)


	SET @process = 'CW-5452 Report Filters Catalog'
	SET @sql = 'if not exists(select * from Filters  where id in(31,32)) begin
	insert into Filters values(31,''concepto'',31,''Conceptos'',''Concepto'')
	insert into Filters values(32,''question'',32,''Questions'',''Questions'')
end
if not exists(select * from ReportsFilters  where id=8064 and filterName in(''concepto'',''Template'')) begin
	insert into ReportsFilters values(''Section'',''concepto'',8064)
	insert into ReportsFilters values(''Section'',''Template'',8064)
end
update ReportsFilters set reportName=''Section'' where id=8064


	IF EXISTS (SELECT * FROM ReportsFilters WHERE id=8063)
	BEGIN
		DELETE FROM ReportsFilters WHERE id=8063
	END

	if not exists(select * from ReportsFilters  where id=8063 and filterName in(''templateSection''))
	begin
		insert into ReportsFilters values(''Section'',''TemplateSection'',8063)
	END'
	EXEC (@sql)

SET @process = 'CW-5452 SP ccspRepAVRSSection'
SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAVRSSection]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
DELETE FROM dbo.RepAVRSSection with(rowlock)
where date >= @from AND date <= @to


;with formato as(
SELECT id_formato,nombre,MAX(version)AS version FROM dbo.RIA_FORMATOS WHERE activo = 1 and tipo=1 GROUP BY id_formato,nombre),
		dataResume as(
		select convert(date, f.fecha_calif) as [date],
			f.age_id as userId,
			a.Login as [user],
			(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName,
			f.id_calificador as supervisorId,
			s.Login as supervisorUser,
			(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor,
			f.id_formato as templateId
			,t.nombre as Template
			,c.id_concepto as sectionId
			,c.con_descripcion as Section
			,w.id as templateSectionId
			,(t.nombre + '' '' + c.con_descripcion)+'' ''+convert(varchar(10),w.id)  as templateSection
			,r.peso AS score
			,f.id_grabacion as idMedia
			,case f.tipo
				when 1 then ''systemTranslated_Recording''
				when 2 then ''systemTranslated_Chat''
				when 3 then ''systemTranslated_Email''
				when 4 then ''systemTranslated_Twitter''
			end as media,
			f.cam_id as cam_id,
			f.tipo_llamada as tipoLlamada,
			(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END) AS campaignAcd
			,f.id_forma
			from RIA_RESULTADOSFORMA r
		INNER JOIN RIA_FORMACALIF f ON f.id_forma = r.id_forma
		INNER JOIN formato t ON t.id_formato= f.id_formato
		INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
		INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
		inner join RIA_FORMATOCONCEPTO w ON w.sectionId = c.id_concepto and w.templateId = c.id_formato
		INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
		INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
		left join cccamps AS e ON f.cam_id = e.cam_id and  f.tipo_llamada=2
		left join ccinbound AS u ON f.cam_id = u.Inbound_id and  f.tipo_llamada=1
		WHERE f.fecha_calif >= @from AND f.fecha_calif <= @to
		)

INSERT INTO dbo.RepAVRSSection([date],userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section,templateSectionId,templateSection,avgDisposition,idMedia,media,cam_id,tipoLlamada,campaignAcd,idForma,year,month,day,hour,minutes,Dispositions)
		select [date],userId, [user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section,templateSectionId,templateSection
		,avg(score) score, idMedia,media,cam_id,tipoLlamada,campaignAcd,id_forma,
		YEAR([date]) AS [year],
		MONTH([date]) AS [month],
		DAY([date]) AS [day],
				0 AS [hour],
				0 AS [minute]
		,avg(score) score
		from dataResume
		group by  [date], userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section,templateSectionId,templateSection,
		idMedia,media,cam_id,tipoLlamada,campaignAcd,id_forma
END'
EXEC (@sql)


SET @process = 'CW-5452 SP ccspRepCatalogos'
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccspRepCatalogos]
	@type as tinyint,
	@action tinyint = 0 -- 0 Filter select; 1 Filters Range
	,@userId int =0 ---- se agrega parametro para filtros

	AS
	declare @tablatemp table (id int, description varchar(100) null)
	declare @tempwork table (idwg int)

	if @action = 0
	begin


		-- CAMPAIGNS
	if @type = 1 begin

		if @userId <> 0 begin

			insert into @tablatemp
			select distinct caesp.IdCampEsp,'' '' as description  from ccUserView us
			inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
			inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
			where us.[User_id] = @userId

			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp
				inner join @tablatemp A on camp.cam_id = A.id

		end
		else begin
			SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
				from ccCamps camp

		end
	end


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
	if @type = 7 begin
		if @userId <> 0 begin

				insert into @tablatemp
				select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
				inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
				inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
				where us.[User_id] = @userId


				SELECT inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound B
					inner join @tablatemp A on B.inbound_id = A.id
					return
			end
			else begin
				select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
					from ccinbound
			end
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

	end
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
	EXEC (@sql)

	SET @process = 'CW-5452 Insert RepAVRSQuestion'
	SET @sql =
	'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestion]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()
if @action = 1 BEGIN

--SELECT * FROM RepAVRSQuestion
DELETE FROM dbo.RepAVRSQuestion with(rowlock)
where date >= @from AND date < @to
;with pregunta as(
SELECT id_pregunta,enunciado_pregunta FROM dbo.RIA_PREGUNTAS GROUP BY id_pregunta,enunciado_pregunta),
  dataResume as(
select
convert(date, f.fecha_calif) as [date]
    ,f.age_id as userId
    ,a.Login as [user]
    ,(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName
    ,f.id_calificador as supervisorId
    ,s.Login as supervisorUser
    ,(s.apellidopaterno+'' ''+s.apellidomaterno+'' ''+s.nombres) AS Supervisor
    ,f.id_formato as templateId
    ,q.nombre as Template
    ,c.id_concepto as sectionId
    ,c.con_descripcion as Section
    ,p.id_pregunta AS questionId
    ,p.enunciado_pregunta AS Question
    ,r.peso AS score
    ,f.id_grabacion as mediaId
    ,case f.tipo
        when 1 then ''systemTranslated_Recording''
        when 2 then ''systemTranslated_Chat''
        when 3 then ''systemTranslated_Email''
        when 3 then ''systemTranslated_Twitter''
    end as media
    ,f.cam_id as cam_id
    ,(CASE WHEN f.tipo_llamada = 2 THEN e.cam_descripcion ELSE u.descripcion END) AS campaignAcd

from RIA_RESULTADOSFORMA r
  INNER JOIN dbo.RIA_FORMACALIF f ON f.id_forma = r.id_forma
  INNER JOIN RIA_FORMATOS q ON q.id_formato = f.id_formato
  INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
  INNER JOIN RIA_CONCEPTOS c ON p.id_concepto = c.id_concepto
  INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
  INNER JOIN dbo.ccUserView s ON f.id_calificador = s.User_id
  INNER JOIN cccamps AS e ON f.cam_id = e.cam_id and  f.tipo_llamada=2
  INNER JOIN ccinbound AS u ON f.cam_id = u.Inbound_id and  f.tipo_llamada=1
  WHERE f.fecha_calif >= @from AND f.fecha_calif <= @to
  )

  INSERT INTO dbo.RepAVRSQuestion ([date],userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avgDisposition,mediaId,media,cam_id,campaignAcd,Dispositions)
  select [date],userId, [user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question, avg(score) score, mediaId, media,cam_id,campaignAcd, avg(score) score
  from dataResume
  group by  [date], userId,[user],agentName,supervisorId,supervisorUser,Supervisor,templateId,Template,sectionId,Section, questionId, Question,
  mediaId,media,cam_id,campaignAcd
  SELECT * FROM DetailReports
END'
	EXEC (@sql)

SET @process='CW-5452 MasterSP'
set @sql = 'ALTER procedure [dbo].[ReportsMasterProcess]

			as

			set nocount on

			declare @replicationName varchar(max)
			declare @SubProcessNameReports varchar(max)
			declare @dateStart datetime, @dateSP datetime
			declare @schedule_id int,@scheduleTime int
			declare @isSunday tinyint,  @hourSunday tinyint,@minSunday tinyint

			declare @sessionKIll table(id int, sessionId int)
			declare @i int,@count int
			declare @sessionId int
			declare @SQL varchar(max)
			declare @name sysname
			declare @descError nvarchar(max)

			set @dateStart = getdate()
			set @scheduleTime = 10


			print ''---Get schedule_id and @scheduleTime ----''
			select @schedule_id=C.schedule_id, @scheduleTime=C.freq_subday_interval
				FROM msdb.dbo.sysjobs A
				LEFT OUTER JOIN msdb.dbo.sysjobschedules B  ON A.job_id = B.job_id
				INNER JOIN msdb.dbo.sysschedules C ON C.schedule_id = B.schedule_id
				where A.name=''ReportsMasterProcess''



			print ''---Kill Process Replication Merge Agent----''
			while exists(SELECT	s.session_id AS SessionID
				from [master].sys.dm_exec_sessions  as s
				LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
				where s.session_id in(
				select distinct r.blocking_session_id
				FROM [master].sys.dm_exec_sessions AS s
				INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
				WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
				)
				and s.[program_name] like ''%Replication Merge Agent%''
				and DB_NAME(p.dbid)=''CCReportsRIA''
			) begin
				insert into @sessionKIll(id,sessionId)

				SELECT	ROW_NUMBER() OVER(ORDER BY s.session_id) AS Row#, s.session_id AS SessionID
				from [master].sys.dm_exec_sessions  as s
				LEFT OUTER JOIN [master].sys.sysprocesses p	ON s.session_id = p.spid
				where s.session_id in(
				select distinct r.blocking_session_id
				FROM [master].sys.dm_exec_sessions AS s
				INNER JOIN [master].sys.dm_exec_requests AS r ON r.session_id = s.session_id
				WHERE    r.session_id != @@SPID and  r.blocking_session_id   <>0
				)
				and s.[program_name] like ''%Replication Merge Agent%''
				and DB_NAME(p.dbid)=''CCReportsRIA''

				select * from @sessionKIll

				select @i=1,@count =COUNT(*) from @sessionKIll
				while @i<=@count begin
					select @sessionId=sessionId from @sessionKIll where id=@i
					SET @SQL = ''KILL '' + CAST(@sessionId as varchar(max))
					begin try
						EXEC (@SQL)
					end try
					begin catch
						print @SQL+ '' is proccess end''
					end catch
					set @i=@i+1
				end
				delete from @sessionKIll
			end

			print ''--------------- Get Jobs Replication ------------------------------''
			create table #replications ([name] nvarchar(100), flag bit)

			;

			with jobNotStart as(
			select distinct A.[name] from msdb.dbo.sysjobs A
				inner join PublicationLowLoad B on A.[name] like ''%''+B.namePublication+''%''
				where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
			--union all
			--select distinct A.[name] from msdb.dbo.sysjobs A
			--	inner join PublicationHighLoad B on A.[name] like ''%''+B.namePublication+''%''
			--	where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
			)

			insert into #replications
			select distinct A.[name],0 from msdb.dbo.sysjobs A
				where A.[name] like ''%CCReportsRIA- 0%'' and A.[name] like ''%CCenterRIA%''
				and A.name not in(select name from jobNotStart)

			insert into #replications
			select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%CCReportsRIA- 0%'' and [name] like ''%CCRecorderRIA%'' order by [name]

			select @count=count(*) from #replications

			while(select count(*) from #replications with(nolock) where flag = 0) > 0 and datediff(ss,@dateStart,getdate())<(@scheduleTime*60)
			begin
				set rowcount 1
					select @replicationName = [name]
					from #replications with(nolock)
					where flag = 0
				set rowcount 0

				if (
					SELECT top 1 sjh.run_status
				  FROM msdb.dbo.sysjobhistory                sjh
				  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
				  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)
				  WHERE
				  j.name = @replicationName
				  order by sjh.instance_id desc
				) <>4
				or not exists(SELECT top 1 sjh.run_status
				  FROM msdb.dbo.sysjobhistory                sjh
				  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
				  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)
				  WHERE
				  j.name = @replicationName
				  order by sjh.instance_id desc	)

				begin
					exec msdb.dbo.sp_start_job @job_name = @replicationName
					print ''sp_start_job ''+@replicationName
				end
				else begin
					print ''Job is Init ''+@replicationName
				end

				update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

				WAITFOR DELAY ''00:00:03''

				while (
					SELECT top 1 sjh.run_status
				  FROM msdb.dbo.sysjobhistory                sjh
				  inner join msdb.dbo.sysjobs j on j.job_id=sjh.job_id
				  inner join msdb.dbo.sysjobs_view sj  on  (sj.job_id = sjh.job_id)
				  WHERE
				  j.name = @replicationName
				  order by sjh.instance_id desc
				) = 4
				begin
					WAITFOR DELAY ''00:00:01''
					print ''In Progress Job in ReplicationName: ''+@replicationName
					if datediff(ss,@dateStart,getdate())>((@scheduleTime*60)/@count) begin
						print ''Stop Job in ReplicationName: ''+@replicationName
						break
					end
				end
				print ''Progress End Job in ReplicationName: ''+@replicationName
			end

			drop table #replications

			print ''--------------------------- Comienzo de subprocesos de reportes ---------------------------''

			/*C?digo del Job para la generaci?n de los reportes como subproceso.*/

			EXEC msdb.dbo.sp_start_job @job_name = ''ReportsMasterSubProcess''

			PRINT ''EXEC sp_start_job ReportsMasterSubProcess''

			print ''--------------------------- Termino subprocesos de reportes ---------------------------''


			declare @tableArticle table(nameArticle [sysname],objectId int)
			declare @tableTrigger table(id int identity, nameArticle [sysname])

			insert into @tableArticle(nameArticle,objectId)
			SELECT Art.name nameArticle,t.object_id FROM dbo.sysmergepublications P
			inner join dbo.sysmergearticles Art on Art.pubid=P.pubid
			inner join sys.tables t on t.name=Art.name

			insert into @tableTrigger
			select t.name as nameTrigger from @tableArticle Art
			inner join sys.triggers  t on Art.objectId=t.parent_id
			where name not like ''MSmerge_%''

			select @i=1,@count =count(*) from @tableTrigger
			while @i<=@count
			begin
				select @name = nameArticle  from @tableTrigger where id=@i
				set @sql =''DROP TRIGGER ''+ @name
				exec (@sql)
				set @i = @i+1
			end

			print ''--------------------------- DROP TRIGGER Tables ---------------------------''

insert into RIA_FORMATOCONCEPTO
SELECT
	t.id_formato AS ''ID Formato'', c.id_concepto as ''id concepto''
	FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato, nombre, MAX(version) as version
									FROM RIA_FORMATOS
									WHERE activo = 1
									group by id_formato, nombre) as t
	ON f.id_formato = t.id_formato AND f.version = t.version inner join RIA_CONCEPTOS c
	on t.id_formato = c.id_formato and t.version = c.version

left join RIA_FORMATOCONCEPTO as a on a.templateId = t.id_formato  and a.sectionId = c.id_concepto
where a.id is null

			print ''---#reinitmergepullsubscription----''
			declare @lastTenMinuteFirst datetime
			declare @id int
			declare @publisher_reinit nvarchar(max)
			declare @publisher_db_reinit nvarchar(max)
			declare @publication_reinit nvarchar(max)
			declare @upload_first_reinit nvarchar(max)

			set @lastTenMinuteFirst = dateadd(minute,-@scheduleTime*2,getdate())

			create table #reinitmergepullsubscription(
			id int not null identity,
			publisher nvarchar(max) not null,
			publisher_db nvarchar(max)not null,
			publication nvarchar(max) not null,
			upload_first nvarchar(max) not null,
			[status] bit not null
			)

			insert into #reinitmergepullsubscription
			select distinct s.name, ma.publisher_db, ma.publication, ''false'', 0
			from distribution.dbo.MSmerge_history mh
			left outer join distribution.dbo.MSrepl_errors me
			on (mh.error_id = me.id)
			left outer join distribution.dbo.MSmerge_agents ma
			on (mh.agent_id = ma.id)
			left outer join master.sys.servers s
			on (ma.publisher_id = s.server_id)
			where
			(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
			mh.comments like  ''%The Merge Agent failed because the schema of the article at the Publisher does not match the schema of the article at the Subscriber%'')
			and mh.time >= @lastTenMinuteFirst
			and ma.subscriber_db = ''CCReportsRIA''

			while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
				begin
					set rowcount 1
					select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
					from #reinitmergepullsubscription
					where [status] = 0
					set rowcount 0

					exec sp_reinitmergepullsubscription  @publisher = @publisher_reinit,    @puSblisher_db = @publisher_db_reinit,    @publication = @publication_reinit,    @upload_first = @upload_first_reinit

					update #reinitmergepullsubscription
					set [status] = 1
					where id = @id
				end

			drop table #reinitmergepullsubscription

			if DATEDIFF(ss,@dateStart,getdate())>@scheduleTime*60 begin
				set @scheduleTime=@scheduleTime+1
				if  @scheduleTime < 59 begin
					EXEC msdb.dbo.sp_update_schedule @schedule_id=@schedule_id,@freq_subday_interval = @scheduleTime
				end
			end
		'
exec (@sql)

SET @process = 'CW-5452 ccspRepAVRSQuestionChat'
SET @sql = 'ALTER PROCEDURE  [dbo].[ccspRepAVRSQuestionChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN
	DELETE FROM dbo.RepAVRSQuestionChat with(rowlock)
	where date >= @from AND date < @to

;with formato as(
select id_formato,nombre, max(version) as version from dbo.RIA_FORMATOS WHERE activo = 1 and tipo=2 group by id_formato,nombre),
 dataResume as(

		select
		convert(date, f.fecha_calif) AS [date],
		a.User_id as userId,
		a.Login as [user],
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agentName,
		t.id_formato as templateId,
		t.nombre as template,
		--c.id_concepto as sectionId,
		--c.con_descripcion as Section,
		p.id_pregunta as questionId,
		p.enunciado_pregunta as question,
		w.peso As Dispositions,
		w.peso AS avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound
		--chats.chatId as chatId
 from RIA_FORMACALIF_CHAT f
--inner join dbo.RIA_FORMATOS2 as t ON t.id_formato= f.id_formato
INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
inner join formato t on f.id_formato = t.id_formato
inner join RIA_CONCEPTOS c on c.id_formato=t.id_formato and c.version=t.version
INNER JOIN RIA_PREGUNTAS p ON c.id_concepto = p.id_concepto
INNER JOIN dbo.ccriachats chats ON f.id_chat=chats.chatId
INNER JOIN ccinbound AS i ON chats.inboundId = i.Inbound_id
INNER JOIN RIA_RESULTADOSFORMA_CHAT w ON w.id_pregunta = p.id_pregunta
WHERE f.fecha_calif >=@from and f.fecha_calif < @to)

	INSERT INTO dbo.RepAVRSQuestionChat ([date], userId, [user],agentName, templateId, template,
		questionId, question, Dispositions,avgDisposition,	inboundId, inbound)
	select [date], userId, [user],agentName, templateId, template,
		questionId,	question,Dispositions,avgDisposition,	inboundId,inbound
	from dataResume
	group by [date], userId, [user], agentName,templateId, template,
		questionId,	question,Dispositions,avgDisposition,	inboundId,inbound
END
'
EXEC (@sql)
		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

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
