/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/04/11
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara
Required version: 36

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 37

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = 'INSERT -------- ReportsFiltersMenus'
		set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport = 6050) begin
insert into ReportsFiltersMenus values (6050, ''date'')
insert into ReportsFiltersMenus values(6050, ''filterby'')
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- ReportsTotals'
		set @Sql= 'if not exists(select * from ReportsTotals where id = 6050) begin
insert into ReportsTotals values (6050, '')
end'
		EXEC(@Sql)

		set @process = 'CREATE TABLE -------- RepIVRSurveys'
		set @Sql= 'if not exists (select * from sys.tables where name = N''RepIVRSurveys'')
begin
create table RepIVRSurveys
(
[date] datetime not null,
[userId] smallint not null,
[login] varchar(20) not null,
[scriptId] int not null,
[surveyId] int not null,
[survey] varchar(MAX) not null,
[calId] int not null,
[calKey] varchar(20) not null,
[campaignId] [int] NOT NULL,
[inboundId] [int] NOT NULL,
[campACDDescription] varchar(40) not null,
[questionId] int not null,
[questionDescription] varchar(MAX) not null,
[question_Count] varchar(MAX) not null,
[Count] varchar(MAX) not null,
[year] int not null,
[month] int not null,
[day] int not null,
[hour] int not null,
[minutes] int not null
)
end'
		EXEC(@Sql)

		set @process = 'ADD COLUMN -------- PivotReports'
		set @Sql= 'if not exists (select * from sys.columns where name = N''isGroupPivot'' and Object_ID = Object_ID(N''PivotReports''))
begin
	alter table PivotReports add isGroupPivot bit
end'
		EXEC(@Sql)

		set @process = 'UPDATE -------- PivotReports'
		set @Sql= 'update PivotReports set isGroupPivot = 1'
		EXEC(@Sql)

		set @process = 'INSERT -------- PivotReports'
		set @Sql= 'if not exists(select * from PivotReports where id = 6050)
begin
insert into PivotReports values (6050, ''question_Count'', ''date|userId|login|scriptId|surveyId|survey|calId|calKey|campaignId|inboundId|campACDDescription|year|month|day|hour|minutes'', ''max'', 0)
end'
		EXEC(@Sql)

		set @process = 'VALIDATE PROCEDURE -------- ccsp_IVRInCalls'
		set @Sql= 'if exists (select * from sys.procedures where name = N''GetPivotColumns'')
begin
    drop procedure GetPivotColumns
end'
		EXEC(@Sql)

		set @process = 'CREATE PROCEDURE -------- GetPivotColumns'
		set @Sql= 'CREATE PROCEDURE [dbo].[GetPivotColumns]	
@id int	
AS
BEGIN
SELECT [columns],complementColumns,pivotFunction,isGroupPivot 
FROM dbo.PivotReports 
WHERE id = @id
END'
		EXEC(@Sql)

		set @process = 'VALIDATE PROCEDURE -------- ccspRepCatalogos'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepCatalogos'')
begin
    drop procedure ccspRepCatalogos
end'

		set @process = 'CREATE PROCEDURE -------- ccspRepCatalogos'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range
,@userId int =0 ---- se agrega parametro para filtros

AS
declare @tablatemp table (id int,
			description varchar(100) null)
declare @tempwork table
(idwg int)

if @action = 0
begin


-- CAMPAIGNS
if @type = 1
begin

if @userId <> 0 begin

insert into @tablatemp
select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
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
if @type = 2
begin
Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
from ccTipoResultadoDial
order by descripcion
end

-- WORKGROUPS
if @type = 3
begin
if @userId <> 0 begin

insert into @tempwork
select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

select distinct catwor.IDWG as id,catwor.WGName as description,''workgroupId'' as dbColumn from ccRIAWorkGroupUsers wgu
inner join ccRIACat_WorkGroup catwor on wgu.IDWG = catwor.IDWG
left join @tempwork temp on wgu.IDWG = temp.idwg
where catwor.StatusWorkGroup = 1
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
if @type = 4
begin
if @userId <> 0 begin

insert into @tablatemp
select distinct wgu.User_id,caesp.IDArea  from ccUsers us
inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
left join ccUsers caesp on wgu.IDWG = caesp.User_id
where us.[User_id] = @userId

select distinct idArea as id, AreaName as description, ''areaId'' as dbColumn
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
if @type = 5
begin
SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
FROM ccTipoCalifOut
order by [description]
end

-- USE
if @type = 6
begin
if @userId <> 0 begin

insert into @tempwork
		select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUsers us
inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

inner join @tempwork awg on wgu.IDWG = awg.idwg
where us.TipoUser_id = 1 and [status] = 1

return
end

else begin

SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
FROM ccUsers B WHERE [status] = 1 and TipoUser_id = 1
ORDER BY description
end
end

-- ACDS**************
if @type = 7
begin
if @userId <> 0 begin
	insert into @tablatemp
	select distinct caesp.IdCampEsp,'''' as description  from ccUsers us
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
if @type = 8
begin
select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
from ccdnis
end

--DISPOSITIONS IN
if @type = 9
begin
SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
FROM ccTipoCalif
order by [description]
end

--SUBDISPOSITIONS IN
if @type = 10
begin
SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
FROM ccTipoCalifSub
order by [description]
end

--PROVIDER
if @type = 11
begin
SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
FROM cstoProvedor
order by [description]
end

-- UNAVAILABLES
if @type = 12
begin
SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
FROM cctiponotready
order by descripcion
end

-- DIALERS
if @type = 13
begin
SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
FROM ccoDialers
order by descripcion
end

-- CallTYpes
if @type = 14
begin
SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
FROM ccStatusLlamada
order by descripcion
end

-- SUBDISPOSITIONS OUT
if @type = 21
begin
SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
FROM cctipocalifsubout
order by [description]
end

-- AVRS TEMPLATE-SECTION
if @type = 15
begin
SELECT c.id_concepto as id, (t.nombre+''-''+c.con_descripcion) as description, ''sectionId'' as dbColumn
FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,nombre,MAX(version) as version
							FROM RIA_FORMATOS
							WHERE activo = 1
							group by id_formato,nombre) as t
ON f.id_formato = t.id_formato AND f.version = t.version INNER JOIN RIA_CONCEPTOS c
ON t.id_formato = c.id_formato AND t.version = c.version
order by f.nombre
end

-- AVRS TEMPLATES
if @type = 16
begin
SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
							FROM RIA_FORMATOS
							WHERE activo = 1
							group by id_formato) as t
ON f.id_formato = t.id_formato AND f.version = t.version
order by f.nombre
end

-- AVRS SUPERVISOR
if @type = 17
begin
SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
FROM ccUsers
WHERE [status] = 1
and TipoUser_id = 2
ORDER BY [login]
end

--Status Call
if @type = 26
begin
select User_id as id, [Login] as description, ''userId'' as dbcolumn
from ccUsers
where TipoUser_id = 1
order by [Login]
end

--Survey
if @type = 27
begin
select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
from Survey
order by [description]
end
end
-----------------------------------------------------------
if @action = 1
begin
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
SELECT 0 as [min], 100 as [max],''score'' as dbColumn
end
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- Filters'
		set @Sql= 'if not exists(select * from Filters where id in (28,29)) begin
insert into Filters values(28, ''agent'', 26, ''Agents'', ''Agent'')
insert into Filters values(29, ''survey'', 27, ''Surveys'', ''Survey'')
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- ReportsFilters'
		set @Sql= 'if not exists(select * from ReportsFilters where id = 6050) begin
insert into ReportsFilters values(''IVR Surveys'', ''acds'', ''6050'')
insert into ReportsFilters values(''IVR Surveys'', ''campaigns'', ''6050'')
insert into ReportsFilters values(''IVR Surveys'', ''agent'', ''6050'')
insert into ReportsFilters values (''IVR Surveys'', ''survey'', 6050)
end'
		EXEC(@Sql)

		set @process = 'VALIDATE PROCEDURE -------- ccspRepIVRSurveys'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccspRepIVRSurveys'')
begin
    drop procedure ccspRepIVRSurveys
end'

		set @process = 'CREATE PROCEDURE -------- ccspRepIVRSurveys'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepIVRSurveys]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
  if @from is null
    select @from = convert(datetime,convert(varchar(14),getdate(),121)+ ''00'',121)
  if @to is null  
    select @to = getdate()


delete RepIVRSurveys with(rowlock)
  where [date] between @from and @to


insert RepIVRSurveys select [date],userId,[login],scriptId,surveyId,survey,calId,calKey,campaignId,inboundId,campACDDescription,
questionId,questionDescription,question_Count,[Count],[year],[month],[day],[hour],[minutes]
from
(
  select 
  convert(datetime,convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121) as [date],
  isnull(cci.User_id, 0) as ''userId'',
  isnull(ccu.Login, ''No agent'') as ''login'',
  isnull(ivro.IVR_id, 0) as ''scriptId'',
  isnull(s.surveyId, 0) as ''surveyId'',
  isnull(s.description, '''') as ''survey'',
  isnull(cci.cal_id, 0) as ''calId'',
  isnull(cci.cal_Key, '''') as ''calKey'',
  0 as ''campaignId'',
  isnull(cci.Inbound_id, '''') as ''inboundId'',
  ''ACD - '' + isnull(ccin.descripcion,'''') as ''campACDDescription'',
  isnull(ivro.questionId, 0) as ''questionId'',
  isnull(sq.description,'''') as ''questionDescription'',
  isnull(sq.description,'''')+ ''_Count'' as ''question_Count'',
  case when sa.answerId is null and isnull(ivro.selectedOption,'') ='' then ''No option''
    when sa.answerId is null then ivro.selectedOption 
    when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description
    when sa.answerId is not null and isnull(ivro.selectedOption,'''') ='''' then ''No option''
  else ''Invalid'' end as ''Count'',
  datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
  datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
  datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
  datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
  datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
  from ccCallsIn cci with(nolock)
  inner join IVROptions ivro on cci.IVR_id = ivro.IVR_id
  inner join ccUsers ccu on cci.User_id = ccu.User_id
  inner join ccInbound ccin on cci.Inbound_id = ccin.Inbound_id
  left join Survey s on ivro.IVR_id = s.scriptId
  left join relationQuestionAnswer rqa on s.surveyId = rqa.surveyId
  left join SurveyQuestion sq on ivro.questionId = sq.questionId
  left join SurveyAnswer sa on rqa.answerId = sa.answerId
  where cal_inicio between @from and @to

  union all

  select
  convert(datetime,convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121) as [date],
  isnull(cco.User_id, 0) as ''userId'',
  isnull(ccu.Login, ''No agent'') as ''login'',
  isnull(ivro.IVR_id, 0) as ''scriptId'',
  isnull(s.surveyId, 0) as ''surveyId'',
  isnull(s.description, '''') as ''survey'',
  isnull(cco.cal_id, 0) as ''calId'',
  isnull(cco.cal_Key, '''') as ''calKey'',
  isnull(ccc.[cam_id], '''') as ''campaignId'',
  0 as ''inboundId'',
  ''Camp - '' + isnull(ccc.[cam_descripcion],'''') as ''campACDDescription'',
  isnull(ivro.questionId, 0) as ''questionId'',
  isnull(sq.description,'''') as ''questionDescription'',
  isnull(sq.description,'''')+ ''_Count'' as ''question_Count'',
  case when sa.answerId is null then ivro.selectedOption 
    when sa.answerId is not null and ivro.selectedOption = convert(varchar(5),sa.digit) then sa.description
    when sa.answerId is not null and isnull(ivro.selectedOption,'''') ='''' then ''No option''
  else ''Invalid'' end as ''Count'',
  datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
  datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
  datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
  datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
  datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
  from ccoCallsOut cco with(nolock)
  inner join IVROptions ivro on cco.cal_id = ivro.cal_id
  inner join ccUsers ccu on cco.User_id = ccu.User_id
  inner join ccCamps ccc on cco.cam_id = ccc.cam_id
  left join Survey s on ivro.IVR_id = s.scriptId
  left join relationQuestionAnswer rqa on s.surveyId = rqa.surveyId
  left join SurveyQuestion sq on ivro.questionId = sq.questionId
  left join SurveyAnswer sa on rqa.answerId = sa.answerId
  where cal_inicio between @from and @to
)surveys 

end'
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off