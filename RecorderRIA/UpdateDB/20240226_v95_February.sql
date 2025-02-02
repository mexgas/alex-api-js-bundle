set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 95
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

   ---------------------------------------BEGIN KR087000 Modificaciones Recordings Manager Exportacion Automatica ---------------------------------------------------------

   	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_ExportManagerAutomatic'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_ExportManagerAutomatic'')
    begin
        DROP PROCEDURE trsp_ExportManagerAutomatic;
    end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_GetParametersExportService'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_GetParametersExportService'')
    begin
        DROP PROCEDURE trsp_GetParametersExportService;
    end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_SaveAVRSExportParameters'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_SaveAVRSExportParameters'')
    begin
        DROP PROCEDURE trsp_SaveAVRSExportParameters;
    end'
	EXEC(@sql)

    SET @process = 'DEV1-474 KR087000 create table ccConfigurationExportManagerAutomatic'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccConfigurationExportManagerAutomatic'') begin
create table ccConfigurationExportManagerAutomatic(
	ccConfigurationExportId bigint Not null identity primary key,
	DateStartExport datetime null,
	DateEndExport  datetime null,
	Json varchar(4000) not null,	
	ExportStatus tinyint not null--0 Create,1 Process ,2 End,3 Cancelada
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccExportStatusConfiguration'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccExportStatusConfiguration'') begin
create table ccExportStatusConfiguration(
	ExportStatusId tinyint not null primary key,
	Description varchar(150) not null
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccExportManagerAutomatic'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccExportManagerAutomatic'') begin
create table ccExportManagerAutomatic(
	GrabId bigint Not null,
	ccConfigurationExportId bigint not null,
	DateDownload datetime not null,
	StatusId tinyint not null,
	FOREIGN KEY (ccConfigurationExportId) REFERENCES ccConfigurationExportManagerAutomatic(ccConfigurationExportId)
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccStatusExportManager'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccStatusExportManager'') begin
create table ccStatusExportManager(
	StatusId tinyint not null primary key,
	Description varchar(150) not null
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 update TREC_PARAMETROS par_id=65'
	SET @sql = 'update TREC_PARAMETROS 
set par_valor=''1'' 
where par_id=65 and par_valor=''C:\Centerware/Sites/CWAdminEngine/AVRSExportRecs'''
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Add insert ccStatusExportManager y ccExportStatusConfiguration'
	SET @sql = 'if not exists(select * from ccStatusExportManager) begin
	insert into ccStatusExportManager values(0,''Scheduled'')
	insert into ccStatusExportManager values(1,''Downloaded'')
	insert into ccStatusExportManager values(2,''Export error'')
	insert into ccStatusExportManager values(3,''Cancelled'')
end
if not exists(select * from ccExportStatusConfiguration) begin
	insert into ccExportStatusConfiguration values(0,''Create'')
	insert into ccExportStatusConfiguration values(1,''Process'')
	insert into ccExportStatusConfiguration values(2,''End'')
	insert into ccExportStatusConfiguration values(3,''Cancelada'')
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Add TREC_PARAMETROS par_id 77 y 78'
	SET @sql = 'if not exists(select * from TREC_PARAMETROS where par_id =77) begin
	insert into TREC_PARAMETROS values(77,''Configuracion Automatica descarga Ftp AvrsExport'','''',''Configuracion formato Json para exportar grabaciones'');
end
if not exists(select * from TREC_PARAMETROS where par_id =78) begin
	insert into TREC_PARAMETROS values(78,''Id Export Configuration'',''0'',''Id de la tabla ccConfigurationExportManagerAutomatic'');
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 alter COLUMN TREC_PARAMETROS par_valor'
	SET @sql = 'alter table TREC_PARAMETROS ALTER COLUMN par_valor varchar(4000);'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 alter Sp trsp_AdmRecSearchCallIdStr'
	SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
@Sup_id int,
@callIdList as nvarchar(max),
@UserList varchar(MAX) =null,
@IDWGList varchar(MAX) =null,
@TypeCall int = null,
@CampaingsList varchar(MAX) =null,
@ACDList varchar(MAX) =null,
@DispositionList varchar(MAX) =null,
@SubdispositionList varchar(MAX) =null

AS
BEGIN

SET NOCOUNT ON

declare @sql1 nvarchar(max)

declare @callIdTmp table (callId int primary key)
declare @grabIdTmp table (grabId bigint primary key)
			
insert into @callIdTmp
select distinct value  from dbo.fn_RIASplitDelimited(@callIdList,'','')

insert into @grabIdTmp
select distinct A.grab_id from RIA_GRABACION A
inner join @callIdTmp B on A.cal_id=B.callId
union
select distinct A.grab_id from RIA_GRABACIONCONSULTA A
inner join @callIdTmp B on A.cal_id=B.callId


--Tabla con toda la informaciom
CREATE TABLE #tempRiAAllInfo(
	cal_id int,
	tipo_llamada smallint,
	cam_id smallint,
	calif_id smallint,
	duracion int,
	id_nivel_grito int,
	[user_id] int,
	finicio datetime,
	ani varchar (100),
	dni varchar (100),
	cal_key varchar (100),
	cal_manual tinyint,
	posicion int,
	computer varchar(100),
	total_forma int,
	id_repositorio tinyint,
	score varchar (100),
	formato_duracion varchar(15),
	grab_id bigint,
	IDWG varchar (800),
	califSub_id varchar(800),
	cal_tMoh smallint,
	Prefijo varchar(max)
)

CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
(
[finicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


create table #auxOutbound(
   	cal_id int,
	tipo_llamada smallint,
	cam_id smallint,
	calif_id smallint,
	duracion int,
	id_nivel_grito int,
	[user_id] int,
	finicio datetime,
	ani varchar (100),
	dni varchar (100),
	cal_key varchar (100),
	cal_manual tinyint,
	posicion int,
	computer varchar(100),
	total_forma int,
	id_repositorio tinyint,
	score varchar (100),
	formato_duracion varchar(15),
	grab_id bigint,
	IDWG varchar (800),
	califSub_id  varchar(800),
	cal_tMoh smallint,
	Prefijo varchar(max)
	)

--Segmento de Calificaciones
create table #tempRiaFormaCalif6( id_grabacion bigint, total_forma int)

;with formatCalifMax as (
	select id_formato,id_grabacion,max(version) as version from ria_formacalif 	A
	inner join @grabIdTmp t on A.id_grabacion=t.grabId
	group by id_grabacion,id_formato	
)

insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
select r.id_grabacion, avg(r.total_forma) as total_forma
from ria_formacalif r
inner join formatCalifMax t on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
group by r.id_grabacion



--Segmento de Supervisor
create table #tempCampEspWG6(
IdCampEsp smallint,
Tipo smallint,
[user_id] smallint,
IDWG smallint)

CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6]
(
[user_id] ASc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]




insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id,IDWG)
	select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id,a.IDWG
from ccRIACampEspWG a
inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG

--Segmento de usurios asociados al supervisor
create table #tempComplete6(
IdCampEsp smallint,
Tipo smallint,
[user_id] int,
IDWG smallint)

CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6]
(
[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]



if @UserList is not null and @UserList <> ''''
BEGIN
	set @sql1=''insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
			select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
			from ccRIACampEspWG a  inner join
			(select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in
			(select  distinct a.IDWG from ccRIACampEspWG a
						inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
			)and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
			) b on a.IDWG=b.IDWG''
	exec (@sql1)

END
else
BEGIN
	insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
	select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
	from  ccRIACampEspWG a  inner join
	(select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in
		(select  distinct a.IDWG from ccRIACampEspWG a
			inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
			)and user_id <> @Sup_id
	) b on a.IDWG=b.IDWG
END


if @TypeCall is not null and @TypeCall <> ''''
	BEGIN
		if @TypeCall=1 -- Only Inbound
			BEGIN
				set @sql1 =''
				insert into #tempRiAAllInfo
				select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
							finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
							isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
							isnull (z.total_forma,0) as total_forma,a.id_repositorio,
							isnull (f.description,'''''''')  AS score,
							CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
							grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
				inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
				where''
				if @IDWGList is not null and @IDWGList <> ''''
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

				if @ACDList is not null and @ACDList <> ''''
					set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=1''
				print @sql1
				exec (@sql1)

				set @sql1 =''
				insert into #tempRiAAllInfo
				select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
							finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
							isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
							isnull (z.total_forma,0) as total_forma,a.id_repositorio,
							isnull (f.description,'''''''')  AS score,
							CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
							grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
				inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
				where''
				if @IDWGList is not null and @IDWGList <> ''''
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

				if @ACDList is not null and @ACDList <> ''''
					set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=1''
				--print @sql1
				exec (@sql1)

				if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
					begin
						set @sql1 =''
						insert into #tempRiAAllInfo
						select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (f.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
						inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
						where''

						if @IDWGList is not null and @IDWGList <> ''''
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


						if @ACDList is not null and @ACDList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

						if @DispositionList is not null and @DispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

						if @SubdispositionList is not null and @SubdispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

						set @sql1 = @sql1 + '' and a.tipo_llamada=1''
						--print @sql1
						exec (@sql1)

						set @sql1 =''
						insert into #tempRiAAllInfo
						select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
									finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
									isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
									isnull (z.total_forma,0) as total_forma,a.id_repositorio,
									isnull (f.description,'''''''')  AS score,
									CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
									grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
						inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
						where''

						if @IDWGList is not null and @IDWGList <> ''''
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

						if @ACDList is not null and @ACDList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

						if @DispositionList is not null and @DispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

						if @SubdispositionList is not null and @SubdispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

						set @sql1 = @sql1 + '' and a.tipo_llamada=1''
						--print @sql1
						exec (@sql1)
					end
			END
		ELSE
			BEGIN --Only Outbound
				set @sql1 =''
				insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
								finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
				select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (e.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
				left join cctipocalifsubout k on k.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
				where''

				if @IDWGList is not null and @IDWGList <> ''''
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

				if @CampaingsList is not null and @CampaingsList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=2''
				--print @sql1
				exec (@sql1)

				insert into #tempRiAAllInfo
				select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
								finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
				inner join #tempComplete6 U  on a.user_id=U.user_id

				insert into #tempRiAAllInfo
				select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
								finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
				inner join #tempCampEspWG6 U  on a.user_id=U.user_id


				if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
					begin
						set @sql1 =''
						insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
									finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
									id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
						select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (e.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
						left join cctipocalifsubout k on k.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
						where''

						if @IDWGList is not null and @IDWGList <> ''''
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

						if @CampaingsList is not null and @CampaingsList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

						if @DispositionList is not null and @DispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

						if @SubdispositionList is not null and @SubdispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

						set @sql1 = @sql1 + '' and a.tipo_llamada=2''
						--print @sql1
						exec (@sql1)

						insert into #tempRiAAllInfo
						select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
										finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
										id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
						inner join #tempComplete6 U  on a.user_id=U.user_id

						insert into #tempRiAAllInfo
						select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
										finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
										id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
						inner join #tempCampEspWG6 U  on a.user_id=U.user_id

					end
			END
	END
ELSE
	BEGIN --NOT Inbound or Outbound this mean both
				set @sql1 =''
				insert into #tempRiAAllInfo
				select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
							finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
							isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
							isnull (z.total_forma,0) as total_forma,a.id_repositorio,
							isnull (f.description,'''''''')  AS score,
							CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
							grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ISNULL(a.prefijo,'''''''')
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
				inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
				where''
				if @IDWGList is not null and @IDWGList <> ''''
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

				if @ACDList is not null and @ACDList <> ''''
					set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=1''
				--print @sql1
				exec (@sql1)

				set @sql1 =''
				insert into #tempRiAAllInfo
				select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
							finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
							isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
							isnull (z.total_forma,0) as total_forma,a.id_repositorio,
							isnull (f.description,'''''''')  AS score,
							CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
							grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
				inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
				where''
				if @IDWGList is not null and @IDWGList <> ''''
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

				if @ACDList is not null and @ACDList <> ''''
					set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=1''
				--print @sql1
				exec (@sql1)

				set @sql1 =''
				insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
								finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh,prefijo)
				select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (e.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
				left join cctipocalifsubout k on k.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
				where''

				if @IDWGList is not null and @IDWGList <> ''''
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

				if @CampaingsList is not null and @CampaingsList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=2''
			
				print @sql1
				exec (@sql1)
				
				insert into #tempRiAAllInfo
				select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
								finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
				inner join #tempComplete6 U  on a.user_id=U.user_id

				insert into #tempRiAAllInfo
				select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
								finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
								id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
				inner join #tempCampEspWG6 U  on a.user_id=U.user_id

				
				if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) ) = 0
				begin
						set @sql1 =''
						insert into #tempRiAAllInfo
						select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (f.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh ,''''''''
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
						inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
						where''

						if @IDWGList is not null and @IDWGList <> ''''
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


						if @ACDList is not null and @ACDList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

						if @DispositionList is not null and @DispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

						if @SubdispositionList is not null and @SubdispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

						set @sql1 = @sql1 + '' and a.tipo_llamada=1''
						--print @sql1
						exec (@sql1)

						set @sql1 =''
						insert into #tempRiAAllInfo
						select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
									finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
									isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
									isnull (z.total_forma,0) as total_forma,a.id_repositorio,
									isnull (f.description,'''''''')  AS score,
									CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
									grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ''''''''
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
						inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
						where''

						if @IDWGList is not null and @IDWGList <> ''''
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


						if @ACDList is not null and @ACDList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

						if @DispositionList is not null and @DispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

						if @SubdispositionList is not null and @SubdispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

						set @sql1 = @sql1 + '' and a.tipo_llamada=1''
						--print @sql1
						exec (@sql1)

						set @sql1 =''
						insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
									finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
									id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh, prefijo)
						select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (e.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh , ''''''''
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
						left join cctipocalifsubout k on k.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
						where''

						if @IDWGList is not null and @IDWGList <> ''''
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

						if @CampaingsList is not null and @CampaingsList <> ''''
							set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

						if @DispositionList is not null and @DispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

						if @SubdispositionList is not null and @SubdispositionList <> ''''
							set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

						set @sql1 = @sql1 + '' and a.tipo_llamada=2''
						print @sql1
						exec (@sql1)

						insert into #tempRiAAllInfo
						select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
										finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
										id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
						inner join #tempComplete6 U  on a.user_id=U.user_id

						insert into #tempRiAAllInfo
						select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
										finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
										id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
						inner join #tempCampEspWG6 U  on a.user_id=U.user_id

				end

	END



--Seleccionar info de tabla global
select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
		finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
		id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh,Prefijo
from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc

drop table #tempRiaFormaCalif6
drop table #tempCampEspWG6
drop table #tempComplete6
drop table #tempRiAAllInfo
drop table #auxOutbound

END
	'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Alter SP trsp_AdmRecSearchNodeWorkgroup Remove Index'
	SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
@User_id int,
@WG_id int = 0
AS
BEGIN
	SET NOCOUNT ON;

	if @User_id in( 0,1)
	begin
		select IDWG,WGName from ccRIACat_WorkGroup nolock
	end
	else
	if @WG_id = 0
	begin
		select distinct IDWG,WGName from (
		select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
		on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG /*and c.StatusWorkGroup = 1*/
		where a.user_id = @User_id
		union --camp history
		select distinct a.IDWG,WGName
		from ccRIACampEspWGConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where cast(a.IdCampEsp as varchar(6))+''&''+cast(a.Tipo as varchar(6)) in (
		select distinct cast(a.IdCampEsp as varchar(6))+''&''+cast(a.Tipo as varchar(6)) from ccRIACampEspWGConsulta a
		inner join  ccRIAWorkGroupUsersConsulta b with (nolock) on b.User_id = @User_id and a.IDWG = b.IDWG)
		union --user history
		select distinct a.IDWG,WGName
		from ccRIAWorkGroupUsersConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where user_id in (
		select user_id from ccRIAWorkGroupUsersConsulta where IDWG in (
		select distinct a.IDWG from ccRIACampEspWGConsulta a
		inner join  ccRIAWorkGroupUsersConsulta b with (nolock) on b.User_id = @User_id and a.IDWG = b.IDWG))
		)x
		order by 1
	end
	else
		select IDWG,WGName from ccRIACat_WorkGroup nolock where IDWG = @WG_id
END'
	EXEC(@sql)

	

	SET @process = 'DEV1-474 KR087000 create SP trsp_ExportManagerAutomatic'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_ExportManagerAutomatic] @action int
,@grabIds varchar(max)='''',@ccConfigurationExportId bigint=0,@ExportStatus tinyint=0,@StatusId tinyint=0
AS
BEGIN
	declare @sql varchar(max)
	declare @grabIdTmp table (grabId bigint not null)
	if @action=0 begin -- Insert Status
		if @grabIds='''' or @ccConfigurationExportId=0 begin
		return
		end

		insert into @grabIdTmp
		select convert(bigint, value) grabId from dbo.fn_RIASplitDelimited(@grabIds,'','')
		
		insert into ccExportManagerAutomatic
		select T.grabId,@ccConfigurationExportId ccConfigurationExportId,getdate() DateDownload,0 StatusId
		from @grabIdTmp T
		left join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId
		where E.ccConfigurationExportId is null

		update ccConfigurationExportManagerAutomatic set ExportStatus=1 
		where ccConfigurationExportId=@ccConfigurationExportId and ExportStatus=0
	end
	else if @action=1 begin --GetStatus ccExportManagerAutomatic
		select ExportStatus from ccConfigurationExportManagerAutomatic where ccConfigurationExportId=@ccConfigurationExportId
	end
	else if @action=2 begin --Update Status ccExportManagerAutomatic
		insert into @grabIdTmp
		select convert(bigint, value) grabId from dbo.fn_RIASplitDelimited(@grabIds,'','')
		
		insert into ccExportManagerAutomatic
		select T.grabId,@ccConfigurationExportId ccConfigurationExportId,getdate() DateDownload,@StatusId StatusId
		from @grabIdTmp T
		left join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId
		where E.ccConfigurationExportId is null

		update E set
		E.StatusId=@StatusId
		--select T.grabId,@ExportStatus
		from @grabIdTmp T
		inner join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId	
	end
	else if @action=3 begin --Update Status ccExportManagerAutomatic
		
		select isnull(min(GrabId),0) GrabId from ccExportManagerAutomatic 
		where StatusId=0 and ccConfigurationExportId=@ccConfigurationExportId
	end
	else if @action=4 begin --Update Status ccExportManagerAutomatic
		
		update ccConfigurationExportManagerAutomatic set ExportStatus=@ExportStatus 
		where ccConfigurationExportId=@ccConfigurationExportId

		if @ExportStatus=2 begin
			update ccExportManagerAutomatic set StatusId=3 where ccConfigurationExportId=@ccConfigurationExportId and StatusId=0
		end
	end

END'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create procedure trsp_GetParametersExportService'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_GetParametersExportService]
AS
BEGIN

DECLARE  @avrs_enviroment AS INT

SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

IF @avrs_enviroment = 2
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,67,77,78)
			Union
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,'''' FROM RIA_GRABACION
			union
			select @@Servername+''|''+valor as par_valor,66 as par_id,descripcion as par_descripcion from ccsettings where setting_id=8
		)x
		ORDER BY x.par_id
	END
ELSE
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67,77,78)
			UNION
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
			FROM TREC_GRABACION)x
			ORDER BY x.par_id
	END	
END'
	EXEC(@sql)


	SET @process = 'DEV1-474 KR087000 create procedure trsp_SaveAVRSExportParameters'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters] @export_mode AS INT, @netcred_id 
	AS INT = - 1, @net_user AS VARCHAR(100) = '''', @net_password AS VARCHAR(100) = '''', 
	@net_sever AS VARCHAR(max) = '''', @net_path AS VARCHAR(max) = '''', @ftp_user AS VARCHAR(
		100) = '''', @ftp_password AS VARCHAR(100) = '''', @ftp_sever AS VARCHAR(max) = '''', 
	@ftp_path AS VARCHAR(max) = '''', @ftp_port AS INT = - 1, @ftp_protocol AS INT = - 1, 
	@time_export AS VARCHAR(100) = '''', @grabid_start AS INT = - 1, @csv_log AS INT = - 1, 
	@delete_rec AS INT = - 1, @export_format AS INT = 1, @export_encrypted AS BIT = 0, 
	@file_encrypted AS BIT, @AutomaticConfigurationDto VARCHAR(max) = ''''
	,@DateStartExport	datetime null,@DateEndExport	datetime =null
AS
BEGIN
	DECLARE @repo_Id AS INT
	declare @ccConfigurationExportId bigint=0

	IF LEN(@time_export) > 0
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @time_export
		WHERE par_id = 33
	END

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_format
	WHERE par_id = 35

	-- Update FTP Parameters
	IF @export_mode = 1
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_path
		WHERE par_id = 41

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_protocol
		WHERE par_id = 42

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_sever
		WHERE par_id = 43

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_user
		WHERE par_id = 44

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_password
		WHERE par_id = 45

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_port
		WHERE par_id = 46		
		
	END
	ELSE
	BEGIN
		-- Update NetBios parameters
		DECLARE @avrs_enviroment AS INT
		
		SELECT @avrs_enviroment=par_valor
		FROM TREC_PARAMETROS
		WHERE par_id = 29
				

		IF @avrs_enviroment = 2
		BEGIN
			UPDATE RIA_NETWORKCREDENTIALS
			SET [domain] = @net_sever, [user] = @net_user, [password] = @net_password
			WHERE id = @netcred_id
		END
		ELSE
		BEGIN
			UPDATE TREC_NETWORKCREDENTIALS
			SET [domain] = @net_sever, [user] = @net_user, [password] = @net_password
			WHERE id = @netcred_id
		END

		UPDATE TREC_PARAMETROS
		SET par_valor = @net_path
		WHERE par_id = 36
	END

	

	IF @grabid_start <> - 1
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @grabid_start
		WHERE par_id = 40
	END

	UPDATE TREC_PARAMETROS
	SET par_valor = @csv_log
	WHERE par_id = 50

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_mode
	WHERE par_id = 51

	UPDATE TREC_PARAMETROS
	SET par_valor = @delete_rec
	WHERE par_id = 57

	UPDATE TREC_PARAMETROS
	SET par_valor = @file_encrypted
	WHERE par_id = 61

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_encrypted
	WHERE par_id = 62

	if @AutomaticConfigurationDto<>'''' begin
		UPDATE TREC_PARAMETROS
		SET par_valor =case when @AutomaticConfigurationDto='''' then par_valor else  @AutomaticConfigurationDto end
		WHERE par_id = 77
		select @ccConfigurationExportId=case when par_valor='''' then 0 else  convert(bigint,par_valor) end 
		from TREC_PARAMETROS WHERE par_id = 78

		if @ccConfigurationExportId=0 begin		
			insert into ccConfigurationExportManagerAutomatic(DateStartExport,DateEndExport,Json,ExportStatus)
			values(@DateStartExport,@DateEndExport, @AutomaticConfigurationDto,0) 
			select @ccConfigurationExportId=@@IDENTITY
		end
		else begin
			declare @ExportStatus tinyint 
			select @ExportStatus=ExportStatus from ccConfigurationExportManagerAutomatic
			where ccConfigurationExportId=@ccConfigurationExportId
			if @ExportStatus =0 begin--Create
				update ccConfigurationExportManagerAutomatic set [Json]=@AutomaticConfigurationDto where ccConfigurationExportId=@ccConfigurationExportId
			end
			else if @ExportStatus =1 begin--Process
				update ccExportManagerAutomatic set StatusId=3 where ccConfigurationExportId=@ccConfigurationExportId
				update ccConfigurationExportManagerAutomatic set ExportStatus =3 where ccConfigurationExportId=@ccConfigurationExportId
				set @ExportStatus=3
			end
			if @ExportStatus in(2,3) begin--2 End,3 Cancelada
				insert into ccConfigurationExportManagerAutomatic(DateStartExport,DateEndExport,Json,ExportStatus)
				values(@DateStartExport,@DateEndExport, @AutomaticConfigurationDto,0) 
				select @ccConfigurationExportId=@@IDENTITY				
			end		
		end
		UPDATE TREC_PARAMETROS
		SET par_valor =convert(varchar(100),@ccConfigurationExportId)
		WHERE par_id = 78
	end
END'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 '
	SET @sql = ''
	EXEC(@sql)

	---------------------------------------END KR087000 Modificaciones Recordings Manager Exportacion Automatica ---------------------------------------------------------


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