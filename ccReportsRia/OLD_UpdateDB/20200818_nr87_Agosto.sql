SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 87

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-4316 verifica si existe la vista'
        SET @sql = 'if exists (select * FROM sys.views where name = N''ccWgByAcdView'')
    begin
        DROP VIEW ccWgByAcdView
    end'
        EXEC(@sql)



		SET @process = 'CW-4316 Se agrega nueva vista'
        SET @sql = 'CREATE VIEW [dbo].[ccWgByAcdView]
AS
SELECT A.Inbound_id, A.descripcion, B.IDWG, A.IDArea, C.User_id
FROM ccinbound A
INNER JOIN ccRIACampEspWG B ON A.Inbound_id=B.IdCampEsp AND tipo=0
INNER JOIN ccriaworkgroupusers C ON C.IDWG = B.IDWG
INNER JOIN ccUserView D ON D.User_id = C.User_id AND TipoUser_id=2'
        EXEC(@sql)


        SET @process = 'CW-4316 se modifica sp ccspRepCatalogos'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepCatalogos]
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
		select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
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
	
		--insert into @tempwork
		--select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

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

	-- AVRS TEMPLATE-SECTION
if @type = 15 	begin
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
if @type = 16 	begin
	SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
	FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
									FROM RIA_FORMATOS
									WHERE activo = 1
									group by id_formato) as t
	ON f.id_formato = t.id_formato AND f.version = t.version
	order by f.nombre
end

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
		SELECT 0 as [min], 100 as [max],''score'' as dbColumn
	end
end'
        EXEC(@sql)


        SET @process = 'CW-4316 se modifica sp ccspRepInCalls'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off
set ANSI_WARNINGS off

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()


DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin

declare @starttime datetime
declare @number int
set @starttime = @from
set @number = 0

create table [#callsin](
row int identity,
dateStartDetail datetime,
dateEndDetail datetime,
timegroup datetime,
timegroup_next datetime,
time_endque datetime,
time_ring datetime,
time_dialog datetime,
time_notes datetime,
time_end_call datetime,
phone_in varchar(30),
cal_id int,
dni_id int,
Inbound_id int,
User_id int,
ntotal int,
ninitial int,
nout_hour int,
nout_service int,
nabnd int,
nno_agent int,
nque int,
ntimeout int,
noverflow int,
nxfer int,
nxfer_que int,
nabnd_xfer int,
nabnd_ring int,
nno_answer int,
nabnd_dialog int,
nanswer int,
nlost int,
nmsg int,
nabnd_tres int,
nansw_tres int,
tque_max int,
tque int,
txfer int,
tdialog int,
tnotes int,
tring int,
tresp int,
nMoh int,
nWHag int,
nWHcl int)

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenSession](
[user_id] [smallint] NOT NULL,
[login] [datetime] NOT NULL,
[logout] [datetime] NULL default(getdate()),
[extension] [varchar](7) NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenInCall](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[dni_id] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[ntotal] [smallint] NOT NULL,
[ninitial] [smallint] NOT NULL,
[nout_hour] [smallint] NOT NULL,
[nout_service] [smallint] NOT NULL,
[nabnd] [smallint] NOT NULL,
[nno_agent] [smallint] NOT NULL,
[nque] [smallint] NOT NULL,
[ntimeout] [smallint] NOT NULL,
[noverflow] [smallint] NOT NULL,
[nxfer] [smallint] NOT NULL,
[nxfer_que] [smallint] NOT NULL,
[nabnd_xfer] [smallint] NOT NULL,
[nabnd_ring] [smallint] NOT NULL,
[nno_answer] [smallint] NOT NULL,
[nabnd_dialog] [smallint] NOT NULL,
[nanswer] [smallint] NOT NULL,
[nlost] [smallint] NOT NULL,
[nmsg] [smallint] NOT NULL,
[nabnd_tres] [smallint] NOT NULL,
[nansw_tres] [smallint] NOT NULL,
[tque_max] [smallint] NOT NULL,
[tque] [int] NOT NULL,
[txfer] [int] NOT NULL,
[tdialog] [int] NOT NULL,
[tnotes] [int] NOT NULL,
[tring] [int] NOT NULL,
[tresp] [int] NOT NULL,
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]


CREATE TABLE #times(
[ID] INT primary key,
[Start] DATETIME,
[Stop] DATETIME
)

create nonclustered index ix_times on #times(
[Start] DESC,
[Stop] DESC
)
create nonclustered index ix_times2 on #times([Start] DESC)

while @number <= (datediff(mi,@starttime,@to)/15)
begin
	insert into #times
	SELECT [Hour] = @number,
	StartTime = DATEADD(mi, @number*15, @starttime),
	EndTime = DATEADD(mi, (@number+1)*15, @StartTime)

	set @number = @number +1
end

insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,User_id,ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
SELECT      cal_inicio as dateStartDetail,
	dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as dateEndDetail,
	case when datepart(mi,cal_inicio) between 0 and 14 then convert(varchar(13),cal_inicio,121) + '':00:00.000''
			when datepart(mi,cal_inicio) between 15 and 29 then convert(varchar(13),cal_inicio,121) + '':15:00.000''
		when datepart(mi,cal_inicio) between 30 and 44 then convert(varchar(13),cal_inicio,121) + '':30:00.000''
		when datepart(mi,cal_inicio) between 45 and 59 then convert(varchar(13),cal_inicio,121) + '':45:00.000'' end as timegroup,
	case when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		between 0 and 14 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':15:00.000''
	when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		between 15 and 29 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':30:00.000''
	when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		between 30 and 44 then convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio),121) + '':45:00.000''
	when datepart(mi,dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio))
		between 45 and 59 then  convert(varchar(13),dateadd(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas+60),0),cal_inicio) ,121) + '':00:00.000'' end as timegroup_next
	,DATEADD(ss,isnull(sum(cal_twait),0),cal_inicio) as time_endque
	,DATEADD(ss,isnull(sum(cal_twait + cal_txfer),0),cal_inicio) as time_ring
	,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring),0),cal_inicio) as time_dialog
	,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog),0),cal_inicio) as time_notes
	,DATEADD(ss,isnull(sum(cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas),0),cal_inicio) as time_end_call
	,isnull(max(cal_Ani),0) as phone_in,cal_id,cin.dni_id,Inbound_id,[User_id]
	,COUNT(cal_id)AS ntotal
	,ISNULL(COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END),0) AS ninitial
	,ISNULL(COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END),0) AS nout_hour
	,ISNULL(COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END),0) AS nout_service
	,ISNULL(COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd
	,ISNULL(COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0) AS nno_agent
	,ISNULL(COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END),0) AS nque
	,ISNULL(COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0) AS ntimeout
	,ISNULL(COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0) AS noverflow
	,ISNULL(COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nxfer
	,ISNULL(COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END),0) AS nxfer_que
	,ISNULL(COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END),0) AS nabnd_xfer
	,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END),0) AS nabnd_ring
	,ISNULL(COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),0) AS nno_answer
	,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END),0) AS nabnd_dialog
	,ISNULL(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) AS nanswer
	,ISNULL(COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0) AS nlost
	,ISNULL(COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END),0) AS nmsg
	,ISNULL(COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nabnd_tres
	,ISNULL(COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),0) AS nansw_tres
	,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
	,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
	,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
	,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
	,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
	FROM ccCallsIn cin with (nolock, index(IX_ccCallsIn))
	left join ccdnis dnis on dnis.dni_id = cin.dni_id
	WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
	group by cal_id,[User_id],Inbound_id,cal_inicio,cin.dni_id


delete #callsin WHERE timegroup>=@from AND timegroup<@to AND INBOUND_ID>0
AND ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0

select * into #callsin2 from #callsin where datediff(mi,timegroup,timegroup_next)>15


delete #callsin where datediff(mi,timegroup,timegroup_next) > 15

insert into #callsin(dateStartDetail,dateEndDetail,timegroup,timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call,phone_in,cal_id,dni_id,Inbound_id,[User_id],ntotal,ninitial,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tdialog,tnotes,tring,tresp,nMoh,nWHag,nWHcl)
select
	dateStartDetail,dateEndDetail,convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,time_endque,time_ring,time_dialog,time_notes,time_end_call
	,phone_in,cal_id,t.dni_id,Inbound_id,[User_id]
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntotal else 0 end as ntotal
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ninitial else 0 end as ninitial
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_hour else 0 end as nout_hour
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nout_service else 0 end as nout_service
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd else 0 end as nabnd
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_agent else 0 end as nno_agent
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nque else 0 end as nque
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then ntimeout else 0 end as ntimeout
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then noverflow else 0 end as noverflow
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer else 0 end as nxfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nxfer_que else 0 end as nxfer_que
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_xfer else 0 end as nabnd_xfer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_ring else 0 end as nabnd_ring
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nno_answer else 0 end as nno_answer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_dialog else 0 end as nabnd_dialog
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nanswer else 0 end as nanswer
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nlost else 0 end as nlost
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nmsg else 0 end as nmsg
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nabnd_tres else 0 end as nabnd_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nansw_tres else 0 end as nansw_tres
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then tque_max else 0 end as tque_max
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,dateStartDetail,time_endque)
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < time_endque then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= time_endque and  th.stop > time_endque then datediff(ss,th.start,time_endque)
			when th.start > dateStartDetail and th.stop < time_endque then datediff(ss,th.start,th.stop) else  0 end as tque
	,case when th.start <= time_endque and  th.stop > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,time_endque,time_ring)
			when th.start <= time_endque and  th.stop > time_endque and th.stop < time_ring then datediff(ss,time_endque,th.stop)
			when th.start > time_endque and th.start <= time_ring and  th.stop > time_ring then datediff(ss,th.start,time_ring)
			when th.start > time_endque and th.stop < time_ring then datediff(ss,th.start,th.stop) else  0 end as txfer               ,case when th.start <= time_dialog and  th.stop > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,time_dialog,time_notes)
			when th.start <= time_dialog and  th.stop > time_dialog and th.stop < time_notes then datediff(ss,time_dialog,th.stop)
			when th.start > time_dialog and th.start <= time_notes and  th.stop > time_notes then datediff(ss,th.start,time_notes)
			when th.start > time_dialog and th.stop < time_notes then datediff(ss,th.start,th.stop) else  0 end as tdialog
	,case when th.start <= time_notes and  th.stop > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,time_notes,time_end_call)
			when th.start <= time_notes and  th.stop > time_notes and th.stop < time_end_call then datediff(ss,time_notes,th.stop)
			when th.start > time_notes and th.start <= time_end_call and  th.stop > time_end_call then datediff(ss,th.start,time_end_call)
			when th.start > time_notes and th.stop < time_end_call then datediff(ss,th.start,th.stop) else  0 end as tnotes
	,case when th.start <= time_ring and  th.stop > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,time_ring,time_dialog)
			when th.start <= time_ring and  th.stop > time_ring and th.stop < time_dialog then datediff(ss,time_ring,th.stop)
			when th.start > time_ring and th.start <= time_dialog and  th.stop > time_dialog then datediff(ss,th.start,time_dialog)
			when th.start > time_ring and th.stop < time_dialog then datediff(ss,th.start,th.stop) else  0 end as tring
	,case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tresp,dateStartDetail))
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= dateadd(ss,tresp,dateStartDetail) and  th.stop > dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tresp,dateStartDetail))
			when th.start > dateStartDetail and th.stop < dateadd(ss,tresp,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end as tresp
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nMoh else 0 end as nMoh
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHag else 0 end as nWHag
	,case when th.start > dateStartDetail and th.stop > dateEndDetail then nWHcl else 0 end as nWHcl
	from #callsin2 t
	join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
	left join ccdnis dnis on dnis.dni_id = t.dni_id
	where  datediff(ss,th.start,timegroup_next)>0
	order by cal_id

drop table #callsin2


-- Session Time
insert into #ccGenSession
select [user_id], [login], logout,extension
from(select a.extension, a.user_id, a.fecha as ''login'',
(select max(Fecha)
from ccLogLogin b with(nolock)
where b.user_id = a.user_id and
b.tipomov = 0 and
b.fecha >= a.fecha and
b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
	from ccLogLogin with(nolock)
	where user_id = b.user_id and
	tipomov = 1 and
	fecha > a.fecha)) as ''logout''
from ccLogLogin a
where a.tipomov=1
and fecha >= @from
and fecha <= @to) as sessiontime
order by user_id, login

update s
set s.logout = (select dateadd(ss,-1,isnull(min(login),getdate())) from #ccGenSession where [login]>s.[login] and [user_id] = s.[user_id])
from #ccGenSession s
where logout is null

select DATEADD(ss,-sum(tStatus),min(fecha)) as dateStartDetail,min(fecha) as dateEndDetail,
	convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
		when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
		when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
		when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end) AS timegroup
	,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
		when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
		when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
		when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end) as timegroup_next
		,[User_id]
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE 0 END),0) AS tunknown
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE 0 END),0) AS tnot_av
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE 0 END),0) AS tav
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE 0 END),0) AS tprob
		,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE 0 END),0) AS tother
		,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
		into #timeDetailAgent
	from ccLogAgentesDia
	WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
	GROUP BY
	convert(smalldatetime,case when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 0 and 14 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000''
		when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 15 and 29 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':15:00.000''
		when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 30 and 44 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':30:00.000''
		when datepart(mi,DATEADD(ss,-tStatus,fecha)) between 45 and 59 then convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':45:00.000'' end)
	,convert(smalldatetime,case when datepart(mi,fecha) between 0 and 14 then convert(varchar(13),fecha,121) + '':15:00.000''
		when datepart(mi,fecha) between 15 and 29 then convert(varchar(13),fecha,121) + '':30:00.000''
		when datepart(mi,fecha) between 30 and 44 then convert(varchar(13),fecha,121) + '':45:00.000''
		when datepart(mi,fecha) between 45 and 59 then convert(varchar(13),dateadd(hh,1,fecha),121) + '':00:00.000'' end), [User_id]


select * into #timeDetailAgent2 from #timeDetailAgent where datediff(mi,timegroup,timegroup_next)>15

delete #timeDetailAgent where datediff(mi,timegroup,timegroup_next) > 15

insert into #timeDetailAgent (dateStartDetail,dateEndDetail,timegroup,timegroup_next,User_id,tunknown,tnot_av,tav,tprob,tother,nother)
select
	min(dateStartDetail),min(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next,[User_id]
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tunknown,dateStartDetail))
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= dateadd(ss,tunknown,dateStartDetail) and  th.stop > dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tunknown,dateStartDetail))
			when th.start > dateStartDetail and th.stop < dateadd(ss,tunknown,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tunknown
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tnot_av,dateStartDetail))
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= dateadd(ss,tnot_av,dateStartDetail) and  th.stop > dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tnot_av,dateStartDetail))
			when th.start > dateStartDetail and th.stop < dateadd(ss,tnot_av,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tnot_av
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tav,dateStartDetail))
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= dateadd(ss,tav,dateStartDetail) and  th.stop > dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tav,dateStartDetail))
			when th.start > dateStartDetail and th.stop < dateadd(ss,tav,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tav
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tprob,dateStartDetail))
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= dateadd(ss,tprob,dateStartDetail) and  th.stop > dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tprob,dateStartDetail))
			when th.start > dateStartDetail and th.stop < dateadd(ss,tprob,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tprob
	,isnull(sum(case when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,dateadd(ss,tother,dateStartDetail))
			when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,dateStartDetail,th.stop)
			when th.start > dateStartDetail and th.start <= dateadd(ss,tother,dateStartDetail) and  th.stop > dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,dateadd(ss,tother,dateStartDetail))
			when th.start > dateStartDetail and th.stop < dateadd(ss,tother,dateStartDetail) then datediff(ss,th.start,th.stop) else  0 end),0) as tother
	,isnull(sum(case when th.start > dateStartDetail and th.stop > dateEndDetail then nother else 0 end),0) as nother
from #timeDetailAgent2 t
inner join #times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0
group by th.start,th.stop,[User_id]

drop table #timeDetailAgent2

select ROW_NUMBER() OVER(ORDER BY xTimeDetail.timegroup,xTimeDetail.[user_id] ) AS Row,
	xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
	,ISNULL(calls.txfer,0) as txfer,ISNULL(tdialog,0) as tdialog,ISNULL(tnotes,0) as tnotes,ISNULL(tring,0) as tring
	,ISNULL(nMoh,0) as nMoh,ISNULL(nWHag,0) as nWHag,ISNULL(nWHcl,0) as nWHcl
	,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
				FROM #ccGenSession
				WHERE [user_id]=xTimeDetail.[user_id]
					AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
	),0)AS t1
	,ISNULL((SELECT top 1 900
					FROM #ccGenSession
					WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
		),0)AS t2
	,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
					FROM #ccGenSession
					WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<DATEADD(mi,15,xTimeDetail.timegroup)
		),0)AS t3
	,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(mi,15,xTimeDetail.timegroup))
					FROM #ccGenSession
					WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(mi,15,xTimeDetail.timegroup)AND logout>DATEADD(mi,15,xTimeDetail.timegroup)
		),0)AS t4
	into #agentInformation
	from (select min(dateStartDetail) as dateStartDetail,min(dateEndDetail) as dateEndDetail,timegroup,timegroup_next,[User_id]
		,sum(tunknown) as tunknown,sum(tnot_av) as tnot_av,sum(tav) as tav,sum(tprob) as tprob,sum(tother) as tother,sum(nother) as nother
		from #timeDetailAgent
		group by timegroup,timegroup_next,user_id
		)xTimeDetail
right join
(select #callsin.timegroup as timegroup,
	#callsin.[user_id] as [user_id]
	,ISNULL(SUM(#callsin.txfer),0) as txfer
	,ISNULL(SUM(#callsin.tdialog),0) as tdialog
	,ISNULL(SUM(#callsin.tnotes),0) as tnotes
	,ISNULL(SUM(#callsin.tring),0) as tring
	,ISNULL(SUM(#callsin.nMoh),0) as nMoh
	,ISNULL(SUM(#callsin.nWHag),0) as nWHag
	,ISNULL(SUM(#callsin.nWHcl),0) as nWHcl
from #callsin
group by
	#callsin.timegroup, #callsin.[user_id]
) as calls on calls.timegroup = xTimeDetail.timegroup and xTimeDetail.[user_id]=calls.[user_id]
where xTimeDetail.timegroup is not null

drop table #timeDetailAgent

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccInboundAgentes.inbound_id
	, COUNT(DISTINCT #agentInformation.[user_id]) AS pos_max -- pos_tot
	, SUM((t1+t2+t3+t4) - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN ((t1+t2+t3+t4)- (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	FROM #agentInformation
	INNER JOIN ccInboundAgentes ON (#agentInformation.[user_id] = ccInboundAgentes.[user_id])
	WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
	GROUP BY timegroup, ccInboundAgentes.inbound_id

--Borrar lo que esta para no repetir
delete from [RepInCalls] with(rowlock)
where date >= @from AND date < @to

insert into [RepInCalls]
SELECT	timegroup as [date], ccInbound.inbound_id as inboundId, ccInbound.descripcion as inbound,isnull(xDetail.dni_id,0),
isnull(ccDnis.dni_descripcion,''S/DNIS'') as dnis, A.IDWG as workgroupId, C.WGName as workgroup, B.IDArea as areaId,
D.AreaName as area,
ntotal, nxfer,
nabnd_que, nxfer_que, nno_xfer, tque_max ,
tque, nque, nanswer, nno_answer, nlost, nabnd_xfer, nabnd_ring, nabnd_dialog, pos_tot, pos_time, SL_P_1, SL_P_2 , avg, SL,nMoh,
nWHag, nWHcl, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes]
,cal_id,phone_in,dateStartDetail,isnull(dni_numero,'''') as DniNumber
FROM (
SELECT cal_id,phone_in,isnull(dateStartDetail,'''') as dateStartDetail,
	ISNULL(xDetCall.tg, xDetSpec.tg ) as timegroup , ISNULL(xDetCall.inbound_id, xDetSpec.inbound_id) inbound_id,xDetCall.dni_id as dni_id,
	ISNULL(ntotal, 0) ntotal, ISNULL(nxfer, 0) nxfer, ISNULL(nabnd_que, 0) nabnd_que , ISNULL(nxfer_que, 0) nxfer_que,
	ISNULL(nno_xfer, 0) nno_xfer, ISNULL(tque_max, 0) tque_max , ISNULL(tque, 0) tque, ISNULL(nque, 0) nque,
	ISNULL(nanswer, 0) nanswer , ISNULL(nno_answer, 0) nno_answer, ISNULL(nlost, 0) nlost, ISNULL(nabnd_xfer, 0) nabnd_xfer ,
	ISNULL(nabnd_ring, 0) nabnd_ring, ISNULL(nabnd_dialog, 0) nabnd_dialog, ISNULL(pos_tot, 0) pos_tot , ISNULL(pos_time, 0) pos_time,
	ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2 , ISNULL(tque/ NULLIF(nque, 0), 0) avg,
	ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0) SL, ISNULL(nMoh, 0) nMoh, ISNULL(nWHag,0) nWHag, ISNULL(nWHcl,0) nWHcl
	FROM (SELECT cal_id,phone_in,dateStartDetail,timegroup as tg, inbound_id,dni_id, ntotal , nxfer, nabnd as nabnd_que, nxfer_que,
		(ninitial + nout_service + nout_hour + nno_agent + ntimeout + noverflow ) nno_xfer , tque_max,
		tque, NULLIF(nque, 0) nque , nanswer, nno_answer , nlost,
		(nabnd_xfer) nabnd_xfer , nabnd_ring, nabnd_dialog, nMoh, nWHag,
		nWHcl , (nansw_tres + nabnd_tres) AS SL_P_1 ,
		(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2
		FROM #callsin
		WHERE timegroup >= @from AND timegroup < @to) xDetCall
FULL OUTER JOIN (SELECT  timegroup as tg, inbound_id, pos_tot, pos_time
			FROM #ccGenInSpec
			WHERE timegroup >= @from AND timegroup < @to) xDetSpec
ON xDetCall.tg = xDetSpec.tg  AND xDetCall.inbound_id = xDetSpec.inbound_id ) xDetail
INNER JOIN ccInbound ON (xDetail.inbound_id = ccInbound.inbound_id) --and ccInbound.chat=0
LEFT OUTER JOIN ccDnis ON (xDetail.dni_id = ccDnis.dni_id)
INNER JOIN ccWgByAcdView A ON (A.Inbound_id = xDetail.inbound_id)
INNER JOIN ccRIAAreaWorkGroup B ON (B.IDWG = A.IDWG)
INNER JOIN ccriacat_workgroup C ON (C.IDWG = A.IDWG)
INNER JOIN ccriacat_areas D ON (D.IDArea = B.IDArea)
where ccInbound.inbound_id is not null 
order by ccInbound.descripcion, timegroup

drop table #times
drop table #callsin
drop table #agentInformation
drop table #ccGenInSpec
drop table #ccGenSession
drop table #ccGenInCall

end'
        EXEC(@sql)
		
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

