/*
Date: 2016/01/12
Description: 

 Drop PROCEDURE trsp_AdmRecSearchNodeWgAgent
 Drop PROCEDURE trsp_AdmRecSearchNodeWgCampACDCalif

 create Index IX_ccRIAWorkGroupUsersConsulta2
 
 Create PROCEDURE trsp_AdmRecSearchNodeWgAgent
 Create PROCEDURE trsp_AdmRecSearchNodeWgCampACDCalif
 
 Alter PROCEDURE trsp_AdmRecSearchAllRecs
 Alter PROCEDURE trsp_AdmRecSearchOneDay
 Alter PROCEDURA trsp_AdmGetRecordingsBackup

Database: CCRecorderRia
Required version: 30
*/

SET nocount ON
DECLARE @Version VARCHAR(10) 
DECLARE @Version_Actual VARCHAR(10)
DECLARE @Process VARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX)
DECLARE @errorGenerated VARCHAR(max)


/* Version to release (use the version of your own databse)*/
set @version = 31

/* Actual version (use your own script to do it) */
select @Version_Actual=par_valor from trec_parametros where par_id = 30

if @Version_Actual=@Version-1
BEGIN
BEGIN TRAN 
BEGIN TRY
	
	set @process = 'insert TREC_PARAMETROS --- Credential Replication'	 
	set @sql='if not exists(select * from TREC_PARAMETROS where par_id=73) 
	insert into TREC_PARAMETROS (par_id,par_descripcion,par_valor,par_detail) values(73,'''',''Credential Windows y SQL para replication'',''hostname\UserWindow|passWindow|userSQL|passSQL|hostaname'')'
	EXEC(@sql)
	
	set @process = 'trsp_AdmRecSearchNodeWgAgent - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchNodeWgAgent'') DROP PROCEDURE trsp_AdmRecSearchNodeWgAgent'
  	EXEC(@sql)

  	set @process = 'trsp_AdmRecSearchNodeWgCampACDCalif - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchNodeWgCampACDCalif'') DROP PROCEDURE trsp_AdmRecSearchNodeWgCampACDCalif'
  	EXEC(@sql)

  	set @process = 'create Index IX_ccRIAWorkGroupUsersConsulta2 -on ccRIAWorkGroupUsersConsulta'
  	set @sql='if not exists (select * from sys.indexes where name = N''IX_ccRIAWorkGroupUsersConsulta2'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta''))
	begin
		CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta]
			(
				[IDWG] ASC,
				[User_id] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
	end'
  	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_AdmRecSearchNodeWgAgent'		
	set @sql='Create PROCEDURE [dbo].[trsp_AdmRecSearchNodeWgAgent] 
@User_id int AS
BEGIN

	SET NOCOUNT ON

	select b.IDWG, c.WGName
	into #nodeWorkgroup
	from ccusers a 
	inner join ccRIAWorkGroupUsersConsulta b on b.user_id = @User_id
	inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
	where a.user_id = @User_id
	order by b.IDWG

	select a.User_id, a.Nombres + '' '' +  a.ApellidoPaterno+ '' '' +  a.ApellidoMaterno as [Nombres], b.IDWG 
	from ccUsers a
	inner join ccRIAWorkGroupUsersConsulta b on a.User_id = b.User_id
	left outer join #nodeWorkgroup c on b.IDWG = c.IDWG
	where a.TipoUser_id = 1
	union 
	select a.User_id, a.Nombres + '' '' +  a.ApellidoPaterno+ '' '' +  a.ApellidoMaterno as [Nombres], b.IDWG 
	from ccUsers a
	inner join ccRIAWorkGroupUsers b on a.User_id = b.User_id
	left outer join #nodeWorkgroup c on b.IDWG = c.IDWG
	where a.TipoUser_id = 1
	order by IDWG, User_id

	drop table #nodeWorkgroup

END'		
		EXEC(@sql)		

	set @process = 'Create PROCEDURE -- trsp_AdmRecSearchNodeWgCampACDCalif'		
	set @sql='Create PROCEDURE [dbo].[trsp_AdmRecSearchNodeWgCampACDCalif] 
  @User_id int AS
BEGIN

	SET NOCOUNT ON

	select b.IDWG, c.WGName
	into #nodeWorkgroup
	from ccusers a 
	inner join ccRIAWorkGroupUsersConsulta b on b.user_id = @User_id 
	inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
	where a.user_id = @User_id
	order by b.IDWG

	create table #tempFinal(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100),
	califSub_id smallint,
	califSubDesc varchar(100) 
    )  

	create table #tempInbound(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100)   
    )  
		  
	create table #tempOutbound(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100)  
    )  

	insert into #tempInbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
		select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.descripcion, isnull(d.frame,1) frame, 
		isnull(f.calif_id,0) as calif_id, isnull(g.Description,'''') as califDescription
		from ccRIACampEspWGConsulta a
		inner join ccInbound b on b.Inbound_id = a.idCampEsp
		left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		left join #nodeWorkgroup e on a.IDWG = e.IDWG
		left join ccCalifCamp f on b.cam_id = f.cam_id and f.tipo = 0
		left join ccTipoCalif g on f.calif_id = g.calif_id and g.Calif_Status = 1
		where a.Tipo = 0
		and e.IDWG is not null
		and a.idCampEsp is not null	
		and g.Description <> ''''
		order by IDWG, tipo, idCampEsp, calif_id

	insert into #tempOutbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
		select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.cam_descripcion as descripcion,
		isnull(d.frame,1) frame, isnull(f.calif_id,0) as calif_id, isnull(g.Description,'''') as califDescription
		from ccRIACampEspWGConsulta a
		inner join ccCamps b on b.cam_id = a.idCampEsp
		left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		left join #nodeWorkgroup e on a.IDWG = e.IDWG
		left join ccCalifCamp f on b.cam_id = f.cam_id and f.tipo = 1
		left join ccTipoCalifOUT g on f.calif_id = g.calif_id and g.CalifOut_Status = 1
		where a.Tipo = 1
		and e.IDWG is not null
		and a.idCampEsp is not null
		and g.Description <> ''''
		order by IDWG, tipo, idCampEsp, calif_id

	---Seccion Inbound

	insert into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'''') as califSubDesc from #tempInbound B
		inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
		inner join cctipocalifsub as C on C.califSub_id = A.califSub_id
		where  A.tipoSubRel=1
		and C.califSub_id=A.califSub_id	
		and C.califSubDesc <>''''


	insert  into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'''','''' from #tempInbound where calif_id not in (select distinct (calif_id) from #tempFinal)

	---Seccion Outbound

	insert into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'''') as califSubDesc from #tempOutbound B
		inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
		inner join cctipocalifsubout as C on C.califSub_id = A.califSub_id
		where  A.tipoSubRel=0
		and C.califSub_id=A.califSub_id
		and C.califSubDesc <>''''

	insert  into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'''','''' from #tempOutbound where calif_id not in (select distinct (calif_id) from #tempFinal)

	
	--Seleccion de Toda la Info
	select * from #tempFinal order by IDWG, tipo, idCampEsp, calif_id
	
	drop table #nodeWorkgroup
	drop table #tempInbound
	drop table #tempOutbound
	drop table #tempFinal
	
END'			
		EXEC(@sql)			
	
	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchAllRecs'		
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
@Sup_id int,
@Finicio datetime,
@Ffin datetime,
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
	cal_tMoh smallint
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
	cal_tMoh smallint
	)
		
--Segmento de Calificaciones
create table #tempRiaFormaCalif6(
id_grabacion bigint,
total_forma int)

insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
select r.id_grabacion, avg(r.total_forma) as total_forma
from ria_formacalif r
inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
group by r.id_grabacion


--Segmento de Supervisor
create table #tempCampEspWG6(
IdCampEsp smallint,
Tipo smallint,
[user_id] smallint)
 
CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6] 
(
[user_id] ASc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
 
insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id)
  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
from ccRIACampEspWGConsulta a
inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG		

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
			from ccRIACampEspWGConsulta a  inner join 
			(select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
			(select  distinct a.IDWG from ccRIACampEspWGConsulta a
						inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
			)and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
			) b on a.IDWG=b.IDWG''
	exec (@sql1)
				
END
else
BEGIN
	insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)  
	select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
	from  ccRIACampEspWGConsulta a  inner join
	(select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
		(select  distinct a.IDWG from ccRIACampEspWGConsulta a
			inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
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
							grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
				where'' 
				if @IDWGList is not null and @IDWGList <> '''' 
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				
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
							grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
				where'' 
				if @IDWGList is not null and @IDWGList <> '''' 
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
													
				if @ACDList is not null and @ACDList <> ''''
					set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''	
						
				if @DispositionList is not null and @DispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

				if @SubdispositionList is not null and @SubdispositionList <> ''''
					set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

				set @sql1 = @sql1 + '' and a.tipo_llamada=1''
				--print @sql1
				exec (@sql1)

				if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
					begin
						set @sql1 =''
						insert into #tempRiAAllInfo
						select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (f.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
						where''	
					
						if @IDWGList is not null and @IDWGList <> '''' 
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
										
						
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
									grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
						where''	
					
						if @IDWGList is not null and @IDWGList <> '''' 
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
												
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
								grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
				left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
				where'' 

				if @IDWGList is not null and @IDWGList <> '''' 
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						
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
				
				
				if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
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
										grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
						left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
						where''	
					
						if @IDWGList is not null and @IDWGList <> '''' 
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
																		
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
							grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
				where'' 
				if @IDWGList is not null and @IDWGList <> '''' 
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				
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
							grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
				left join cctipocalifsub p on p.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
				inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
				where'' 
				if @IDWGList is not null and @IDWGList <> '''' 
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
													
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
							    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
				select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (e.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
				left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
				where'' 

				if @IDWGList is not null and @IDWGList <> '''' 
					set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
								'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				else
					--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
					set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						
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

				if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
				begin
						set @sql1 =''
						insert into #tempRiAAllInfo
						select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
								finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
								isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
								isnull (z.total_forma,0) as total_forma,a.id_repositorio,
								isnull (f.description,'''''''')  AS score,
								CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
								grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
						where''	
					
						if @IDWGList is not null and @IDWGList <> '''' 
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
										
						
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
									grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
						left join cctipocalifsub p on p.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
						inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
						where''	
					
						if @IDWGList is not null and @IDWGList <> '''' 
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						
						
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
									id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
						select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (e.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
						left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
						where''	
					
						if @IDWGList is not null and @IDWGList <> '''' 
							set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
									'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						else
							set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
																		
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

	

--Seleccionar info de tabla global
select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
	   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
	   id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh 
from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc

drop table #tempRiaFormaCalif6
drop table #tempCampEspWG6
drop table #tempComplete6
drop table #tempRiAAllInfo
drop table #auxOutbound
	
END'		
	EXEC(@sql)		

	set @process = 'ALTER PROCEDURE -- trsp_AdmRecSearchOneDay'	
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
@Sup_id int

AS
BEGIN

declare @sql1 nvarchar(max)
declare @sql2 nvarchar(max)
declare @sqlUnion nvarchar(max)

--Tabla con toda la informaciom
  CREATE TABLE #tempRiAAllInfoOneDay(
			cal_id int,
			tipo_llamada smallint,
			cam_id smallint,
			calif_id smallint,
			duracion int,
			id_nivel_grito int,
			user_id int,
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
			cal_tMoh smallint
	)	

	CREATE CLUSTERED INDEX [IX_tempRiAAllInfoOneDaydate] ON [#tempRiAAllInfoOneDay]
	(		  
	  [finicio] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


	create table #auxOutboundOneDay(
       	    cal_id int,
			tipo_llamada smallint,
			cam_id smallint,
			calif_id smallint,
			duracion int,
			id_nivel_grito int,
			user_id int,
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
			cal_tMoh smallint
			)
			
  --Segmento de Calificaciones
  create table #tempRiaFormaCalifOneDay(
  id_grabacion bigint,
  total_forma int)

  insert into #tempRiaFormaCalifOneDay (id_grabacion,total_forma)
  select r.id_grabacion, avg(r.total_forma) as total_forma
  from ria_formacalif r
  inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
  on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
  group by r.id_grabacion
  

  --Segmento de Supervisor
  create table #tempCampEspWGfOneDay(
  IdCampEsp smallint,
  Tipo smallint,
  user_id smallint)
	 
  CREATE NONCLUSTERED INDEX [IX_tempCampEspWGfOneDay] ON [#tempCampEspWGfOneDay] 
  (
	[user_id] ASc
  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
     
  insert into #tempCampEspWGfOneDay (IdCampEsp,Tipo,user_id)
	  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
  from ccRIACampEspWGConsulta a
  inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG		
	
   --Segmento de usurios asociados al supervisor			     
  create table #tempCompleteOneDay(
  IdCampEsp smallint,
  Tipo smallint ,
  user_id smallint,
  IDWG smallint)                 

  CREATE NONCLUSTERED INDEX [IX_tempCompleteOneDayUser] ON [#tempCompleteOneDay] 
  (		  
   [user_id] ASC
  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
     
 
   insert into #tempCompleteOneDay  (IdCampEsp,Tipo,user_id,IDWG)  
   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
   from  ccRIACampEspWGConsulta a  inner join
   (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
		(select  distinct a.IDWG from ccRIACampEspWGConsulta a
		 inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
		 )and user_id <> @Sup_id
	) b on a.IDWG=b.IDWG

	--Seccion Inbound RIAGrabacion

	insert into #tempRiAAllInfoOneDay
		select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
				finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
				isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
				isnull (z.total_forma,0) as total_forma,a.id_repositorio,
				isnull (f.description,'''')  AS score,
				CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
				grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
		left join cctipocalifsub p on p.califSub_id=a.califSub_id
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
		left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
		inner join #tempCompleteOneDay U with (index(IX_tempCompleteOneDayUser)) on a.age_id=U.user_id  
		where a.finicio >=  dateadd(hour, -2, GetDate())-- Convert(nvarchar(11),Getdate(),120) 
		and a.tipo_llamada=1
		
		
	insert into #tempRiAAllInfoOneDay
		select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
				finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
				isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
				isnull (z.total_forma,0) as total_forma,a.id_repositorio,
				isnull (f.description,'''')  AS score,
				CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
				grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
		left join cctipocalifsub p on p.califSub_id=a.califSub_id
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
		left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWGfOneDay U with (index(IX_tempCampEspWGfOneDay)) on a.age_id=U.user_id  
		where a.finicio >=  dateadd(hour, -2, GetDate())--Convert(nvarchar(11),Getdate(),120) 
		and a.tipo_llamada=1
		

	--Seccion Outbound RIAGrabacion
	insert into #auxOutboundOneDay(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
						finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
						id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
			select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
						finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
						isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
						isnull (z.total_forma,0) as total_forma,a.id_repositorio,
						isnull (e.description,'''')  AS score,
						CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
						grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
			left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
			left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion			
			where a.finicio >=  dateadd(hour, -2, GetDate())--Convert(nvarchar(11),Getdate(),120) 
			and a.tipo_llamada=2
			
	
	
	insert into #tempRiAAllInfoOneDay
	select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
					finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
			        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
	inner join #tempCompleteOneDay U  on a.user_id=U.user_id

	insert into #tempRiAAllInfoOneDay
	select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
					finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
			        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
	inner join #tempCampEspWGfOneDay U  on a.user_id=U.user_id

	--Seleccionar info de tabla global
	select distinct a.cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
		   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
		   id_repositorio,score,formato_duracion,grab_id,cast(isnull(a.IDWG,'''') as nvarchar(max)) as IDWG,califSub_id,cal_tMoh
	into #tempFinal
	from #tempRiAAllInfoOneDay a with (index(IX_tempRiAAllInfoOneDaydate))
	order by finicio asc
	
	select
		t1.cal_id, t1.User_id, t1.tipo,
		stuff((
			select ''|'' +  cast(t.IDWG as varchar)
			from ccRIAWorkGroup_Calid t
			where t.cal_id = t1.cal_id
			order by t.IDWG
			for xml path('''')
			),1,1,'''') as wgList
	into #tempWgList
	from ccRIAWorkGroup_Calid t1
	left outer join #tempFinal tf on tf.cal_id = t1.cal_id
	where tf.user_id = t1.User_id
	and tf.tipo_llamada - 1 = t1.tipo
	group by t1.cal_id, t1.User_id, t1.tipo
	
	select distinct a.cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
		   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
		   id_repositorio,score,formato_duracion,grab_id,cast(isnull(b.wgList,'''') as nvarchar(max)) as IDWG,califSub_id,cal_tMoh
	from #tempFinal a
	left outer join #tempWgList b on a.cal_id = b.cal_id
	where a.user_id = b.user_id
	and a.tipo_llamada -1 = b.tipo
	order by finicio asc
	
	drop table #tempRiaFormaCalifOneDay
	drop table #tempCampEspWGfOneDay
	drop table #tempCompleteOneDay
	drop table #tempRiAAllInfoOneDay
	drop table #auxOutboundOneDay
	drop table #tempFinal
	drop table #tempWgList
	
END'			
	EXEC(@sql)	


	set @process = 'ALTER PROCEDURE -- trsp_AdmGetRecordingsBackup'		
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetRecordingsBackup]
			@startDate datetime,
			@endDate datetime
			AS
			BEGIN
				
				SELECT grab_id, isnull(status_audio,0),isnull(status_video,0), isnull(id_ruta_backup,0) 
				FROM TREC_BACKUPS 
				WHERE grab_id in  (
								  SELECT *  FROM (SELECT grab_id
								  FROM RIA_GRABACION
								  WHERE finicio between @startDate and @endDate 
								  UNION
								  SELECT grab_id
								  FROM RIA_GRABACIONCONSULTA
								  WHERE finicio between @startDate and @endDate) AS t )
				
			END'			
	EXEC(@sql)	
------------------ End Script @Sql ------------------

UPDATE trec_parametros SET par_valor = @version WHERE par_id = 30

COMMIT tran
END try

BEGIN catch	
	SELECT @errorGenerated = 'DB Script Version: ' + cast(@Version AS NVARCHAR) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)
	ROLLBACK tran
END catch
END

ELSE
 BEGIN
	SELECT 'Data base incorrect version ' + cast(@Version_Actual AS VARCHAR(5)) + ', please update to  ' + cast(@Version AS VARCHAR(5))
 END
SET nocount off
