/*
Autor: Omar Mejia
Descripcion:


Version requerida: 47
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 48
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW - 1702 drop procedure CountRecorderByCampId'
	set @Sql= 'if exists (select * from sys.procedures where name=''CountRecorderByCampId'')
	drop procedure CountRecorderByCampId'
	EXEC(@sql)

 	set @process = 'CW-1702 Version xxx.xxx --Create Table para registrar los movimientos de cambio de nombre'
    set @Sql= 'if not exists (select * from sys.tables where name = N''LogRenameRecording'')
	    begin       
			create table LogRenameRecording(
				id int identity(1,1),
				userID int,
				camId int,
				OldNameRec varchar(max),
				NewNameRec varchar(max),
				DateRename DateTime
			)
	    end'
        EXEC(@Sql)        

	set @process = 'CW - 1702 SP -- Alter ria_grabacion para saber si la grabacion a sido renombrada'
	set @Sql= 'if not exists (select * from sys.columns where name = N''HasBeenToRename'' and Object_ID = Object_ID(N''ria_grabacion''))
	    begin
			alter table ria_grabacion add HasBeenToRename int null
		end'
	EXEC(@sql)


	set @process = 'CW - 1702 Se agrega el campo prefijo a ria_grabacion '
	set @Sql= '
		if not exists (select * from sys.columns where name = N''Prefijo'' and Object_ID = Object_ID(N''ria_grabacion''))
	    begin
			alter table ria_grabacion add  Prefijo varchar(max) null
		end
'
EXEC(@sql)

	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		begin
		DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		end'
	EXEC(@sql)

	set @process = 'CW - 1702 Se agrega prefijo a la tabla ccInbound de CCRecorderRIA, tabla ccCamps de CCRecorderRIA'
	set @sql='if not exists (select * from sys.columns where name = N''prefijo'' and Object_ID = Object_ID(N''ccCamps'')) begin
			    alter table ccCamps ADD prefijo varchar(40) null
			end'
	EXEC(@sql)	

	set @process = 'CW - 1702 Se agrega prefijo a la tabla ccInbound de CCRecorderRIA, tabla ccCamps de CCRecorderRIA'
	set @sql='if not exists (select * from sys.columns where name = N''prefijo'' and Object_ID = Object_ID(N''ccInbound'')) begin
			    alter table ccInbound ADD prefijo varchar(40) null
			end'
	EXEC(@sql)

	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)
	

	set @process = 'CW - 1702 UPDATE column HasBeenToRename'
	set @Sql= 'update RIA_GRABACION set HasBeenToRename = 0 where HasBeenToRename is null'
	EXEC(@sql)

	set @process = 'SP -- CountRecorderByCampId'
	set @Sql= 'create procedure [dbo].[CountRecorderByCampId]
@cam_id int,
@tipoLLamada int

as
select count(*) from ria_grabacion where cam_id = @cam_id and tipo_llamada = @tipoLLamada and (HasBeenToRename = 0 OR HasBeenToRename IS NULL)
	'
	EXEC(@sql)


set @process = 'CW - 1702 Modificacion del trsp_AdmRecSearchCallIdStr '
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
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
							grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ISNULL(a.prefijo,'''''''')
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
							grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
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
								grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
				left join cctipocalifsubout k on k.califSub_id=a.califSub_id
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
				left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
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
								grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh ,''''''''
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
									grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ''''''''
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
									id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
						select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (e.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh , ''''''''
						from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
						left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
						left join cctipocalifsubout k on k.califSub_id=a.califSub_id
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
						left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
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






	set @process = 'CW - 1702 Se agrega el campo prefijo a ria_grabacion '
	set @Sql= '
		if not exists (select * from sys.columns where name = N''Prefijo'' and Object_ID = Object_ID(N''ria_grabacion''))
	    begin
			alter table ria_grabacion add  Prefijo varchar(max) null
		end'
	EXEC(@sql)

	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		begin
		DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		end'
	EXEC(@sql)

	set @process = 'CW - 1702 Se agrega prefijo a la tabla ccInbound de CCRecorderRIA'
	set @Sql= '
	if not exists (select * from sys.columns where name = N''prefijo'' and Object_ID = Object_ID(N''ccInbound''))
	     begin
		    alter table ccInbound ADD prefijo varchar(40) null
	end'
	EXEC(@sql)



	set @process = 'CW - 1702 Se agrega prefijo a la tabla ccCamps de CCRecorderRIA'
	set @Sql= '
if not exists (select * from sys.columns where name = N''prefijo'' and Object_ID = Object_ID(N''ccCamps''))
	begin
	    alter table ccCamps ADD prefijo varchar(40) null
	end'
EXEC(@sql)



	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
				ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)

	set @process = 'CW - 1702 UPDATE column HasBeenToRename'
	set @Sql= 'update RIA_GRABACION set HasBeenToRename = 0'
	EXEC(@sql)


 	set @process = 'CW - 1702 SP -- trsp_InsertRecNode'
	set @Sql= 'ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int=0

as
begin

  declare @shoutLevel as nvarchar(20)
 declare @language as int
 declare @start as int
 declare @callType int

 declare @xml as xml
 declare @crmNode as xml
 declare @manual as nvarchar(10)
 declare @rating as nvarchar(20)
 declare @sqlCRM nvarchar(2000)
 declare @supervisor as nvarchar(50)
 declare @template as nvarchar(50)
 declare @callID as nvarchar(50)
 declare @isHistory bit
 declare @Prefijo varchar(50)
 set @Prefijo = ''''

 declare @table as nvarchar(20)
 set @table=''RIA''

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
  C16-----> Duration Recording as 00:00:00
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
  C27----->Prefix recording
 */

 select @language= valor from ccSettings where setting_id = 27



 if exists (select *  from ria_grabacion where grab_id = @grabId   ) begin
		select @isHistory=0,@callType=rec.tipo_llamada
	  ,@Prefijo = rec.Prefijo
	  ,@manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from ria_grabacion rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end
 else begin
	 select
	 @isHistory=1,
	 @callType=rec.tipo_llamada,  @manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from RIA_GRABACIONCONSULTA rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end


 --Languages 0 spanish 1 english
 select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


 select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
   RIA_FORMATOS as formatos
   inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
   inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
   inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
   where grabacion.grab_id=@grabId and formatosCalif.tipo=1

if @isHistory=0 begin

 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27''
	   from
	   ria_grabacion rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27''
	   from
	  ria_grabacion rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end
 else begin
	 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27''
	   from
	   RIA_GRABACIONCONSULTA rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27''
	   from
	  RIA_GRABACIONCONSULTA rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end

if @xml is not null begin
	select @crmNode = node from ccCRMNodes where [type]= @callType and cal_id=@callID
	if @crmNode is not null begin
		update ccCRMNodes set grab_id=@grabId where [type]=@callType and cal_id=@callID
		set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
		execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
	end

  if exists(select * from RIA_RecNodeHistory where grab_id=@grabId) begin
	update RIA_RecNodeHistory set node =@xml,[status]=2 where grab_id = @grabId
  end
  else if not exists(select * from ria_RecNode where grab_id=@grabId) begin
	insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
  end
  else begin
	update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId
	end
	--select @xml
 end
end
	'
	EXEC(@sql)



 	set @process = 'SP -- trsp_GetFilesAnalisisGritos'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
--@idRepositorios as varchar(32),
@sExtension as varchar(10) = ''.vox''
AS

declare @Integrado as int
declare @FInicio as datetime
declare @sSql1 as nvarchar(max)
declare @sSql2 as nvarchar (max)
declare @sSql3 as nvarchar(max) 
declare @sSql as nvarchar (max)
declare @dLenAnt as tinyint
declare @dLenNew as tinyint
declare @Encriptado as int
declare @ENC  as varchar(4)


set @FInicio = dateadd(MINUTE, -1, getdate())
set @sSql = N''
set @sSql3 = N''
set @sExtension = (select par_valor from trec_parametros where par_id = 54)

select @integrado = par_valor from trec_parametros where par_id = 29
select @Encriptado = par_valor from trec_parametros where par_id = 15

--AVRS Integrada
if (@integrado = 1)

	BEGIN

		set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
		set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
		set @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1)''

	END

--AVRS Standalone
else if(@integrado = 0)

	BEGIN

		set @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
		set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
		set @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1)''

	END

--AVRS XION
else if(@integrado = 2)
	BEGIN
		
		if @Encriptado = 1
			begin
				set @ENC = ''.enc''
			end
		else
			begin
				set @ENC = ''''
			end

		Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20)) + 
		case COALESCE(Prefijo,'''') when '''' then '''' else ''_''+Prefijo end + @sExtension+ @ENC extension,
		isnull(tipo_llamada,0) tipo_llamada, id_repositorio,COALESCE(Prefijo,'''') as Prefijo
		from ria_grabacion NOLOCK where  ( finicio < @FInicio) 	and (id_nivel_grito is NULL or id_nivel_grito=-1) 
		and cal_id in ( select cal_id from ccRIAWorkGroup_Calid)
		order by finicio asc
		return(0)

END

set @sSql = @sSql1 + @sSql2 + N'' order by finicio asc''
exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio
	
	'
	EXEC(@sql) 	


	
 	set @process = 'SP -- trsp_ConsultaRepositorio'
	set @Sql= '
ALTER PROCEDURE [dbo].[trsp_ConsultaRepositorio]
@id_repositorio tinyint =1 ,
@action tinyint  =1
AS
BEGIN
if @action = 1
	begin
		SELECT     Cast(id_repositorio as Int ) as id_repositorio, ruta_repositorio, ruta_local
		FROM       TREC_REPOSITORIOS
		WHERE      id_repositorio=@id_repositorio
	end
if @action = 2
	begin
		SELECT     Cast(id_repositorio as Int ) as id_repositorio, ruta_repositorio, ruta_local,ruta_local_imagenes
		FROM       TREC_REPOSITORIOS
	end
END



	'
	EXEC(@sql)


	
 	set @process = 'SP --RecordingsToRename '
	set @Sql= '
CREATE procedure [dbo].[RecordingsToRename]
@action int,
@cam_id int = 0,
@tipo_llamada int = 0,
@userID int =0,
@oldName varchar(max) ='''',
@newName varchar(max) = '''',
@cal_id int = 0,
@prefijo varchar(maX) = ''''

as
--Trae todas las grabaciones de una campaña que no se han renombrado 
if @action = 1
	begin
		declare @extension varchar(max)
		select @extension =par_valor from trec_parametros where par_id = 54

		declare @Encriptado varchar(max)
		select @Encriptado = case par_valor When 1 then ''.enc'' when 0 then '''' end 
		from trec_parametros where par_id = 15


		select Cast(cal_id as int) Cal_id , Cast(id_repositorio as int) as Id_Repositorio
		,tipo_llamada as Tipo_Llamada ,@extension as Extension,@Encriptado as Encriptado,Cast(cam_id as int) as Cam_Id
		from RIA_GRABACION where cam_id = @cam_id and tipo_llamada = @tipo_llamada and (HasBeenToRename = 0 OR HasBeenToRename IS NULL)
	end
	--registra el cambio de nombre en la base de datos y modifica ria_recnode para que se pueda encontrar la grabacion en el finder
if @action = 2
	begin

		declare @tipo varchar(max)
		select @tipo = SUBSTRING(@oldName,1,1)		
		declare @PrefijocampOrAcd varchar(max)	
			
			select 	@PrefijocampOrAcd
		if @tipo = ''I''  
			begin
				select @PrefijocampOrAcd=prefijo from ccinbound where Inbound_id = @cam_id
			end
		
		if @tipo = ''O''
			begin
				select @PrefijocampOrAcd=prefijo  from cccamps where cam_id = @cam_id 
			end
		
		UPDATE RIA_GRABACION SET Prefijo =@PrefijocampOrAcd, HasBeenToRename = 1 where
		cal_id = @cal_id and tipo_llamada = case @tipo When ''I'' then 1 when ''O'' then 2 end   
				
	
		declare @grabId varchar(max)
		select @grabId = grab_id from RIA_GRABACION where cal_id = @cal_id and tipo_llamada = case @tipo When ''I'' then 1 when ''O'' then 2 end 
		
		select 	@grabId
		--AGREGA EL ATRIBBUTO C27 
		declare @resul int
		select @resul = count(node.value(''(/R02/@C27)[1]'', ''nvarchar(max)''))  from RIA_RecNode where grab_id = @grabId
		if(@resul = 0)
			begin
				UPDATE RIA_RecNode SET node.modify(''insert attribute C27 { }  into (/R02)[1]'')
				where grab_id = @grabId
			end
		
		--Actualiza el nodo en ria_recnode para que pueda ser consultado
		UPDATE RIA_RecNode 
		SET node.modify(''replace value of (/R02/@C27)[1]  with sql:variable("@PrefijocampOrAcd") ''),
		status = 2
		where grab_id = @grabId
		
		insert into LogRenameRecording (userID,camId,OldNameRec,NewNameRec,DateRename) values(@userID,@cam_id,@oldName,@newName,GETDATE())

	end
		
		
if @action = 3
	if @tipo_llamada = 1
	begin
		UPDATE ccInbound set prefijo = @prefijo where Inbound_id = @cam_id 
		select ''inbound''
	end
	if @tipo_llamada = 2
	begin
	select @cam_id
	select @prefijo
		UPDATE ccCamps set prefijo = @prefijo where cam_id = @cam_id 
		select ''camps''
	end
'
	EXEC(@sql)



 	set @process = 'SP -- trsp_AdmRecSearchRecs '
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
@grabIds nvarchar(max)

AS
BEGIN

SET NOCOUNT ON

	declare @sql nvarchar(max)
	declare @isEncrypted bit

	select @isEncrypted=par_valor from TREC_PARAMETROS where par_id=15


	select id_repositorio, ruta_repositorio
	into #tmpRepositorios
	from TREC_REPOSITORIOS
	where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential =
		(select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio


	set @sql=''select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + 
		case a.Tipo_llamada when 2 then 	
			case camp.prefijo when '''''''' then '''''''' else ''''_'''' + camp.prefijo end 	
			else
			case acds.prefijo when '''''''' then '''''''' else ''''_'''' + acds.prefijo end 				
		end + ''''.wav'''' +
		case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio
		from RIA_GRABACION a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		left join cccamps camp on a.cam_id = camp.cam_id
		left join ccinbound acds on a.cam_id = acds.Inbound_id
		where a.grab_id in(''+@grabIds+'')
		union
		select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
		case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
		case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) +
	    case a.Tipo_llamada when 2 then 	
			case camp.prefijo when '''''''' then '''''''' else ''''_'''' + camp.prefijo end 	
			else
			case acds.prefijo when '''''''' then '''''''' else ''''_'''' + acds.prefijo end 				
		end + ''''.wav'''' +
		case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudior
		from RIA_GRABACIONCONSULTA a
		inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
		left join cccamps camp on a.cam_id = camp.cam_id
		left join ccinbound acds on a.cam_id = acds.Inbound_id
		where a.grab_id in(''+@grabIds+'')''

	exec (@sql)

	drop table #tmpRepositorios

END
'
EXEC(@sql)

	set @process = 'Alter SP ReportsMasterProcessAVRS'
	set @Sql= 'ALTER procedure [dbo].[ReportsMasterProcessAVRS] as

declare @replicationName nvarchar(100)
declare @numOfReplications int
declare @minReplication int

set nocount on

set @replicationName = ''''
set @numOfReplications = 0
set @minReplication = 600

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag from msdb.dbo.sysjobs where [name] like ''%CCRecorderRIA- 0%'' and [name] like ''%CCenterRia%'' order by [name]

select @numOfReplications = count(*)
from #replications with(nolock)

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0
	
	if not exists(
		SELECT * FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) 

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock) 	set flag = 1	where [name] = @replicationName

	WAITFOR DELAY ''00:00:01''

	while exists(
		SELECT * FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) 
	begin
		WAITFOR DELAY ''00:00:01''
	end
end

drop table #replications
-------------------------Para busquedas en finder

if not exists (select * from sys.indexes where name = N''IX_ccRIAWorkGroupUsersConsulta2'' and object_id = OBJECT_ID(N''ccRIAWorkGroupUsersConsulta''))
begin
	CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta]
		(
			[IDWG] ASC,
			[User_id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
end
-----------------------


declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-120,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,120,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select distinct s.name, ma.publisher_db, ma.publication, ''true'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where 
(mh.comments like ''%You must reinitialize the subscription (without upload)%'' or
mh.comments like  ''%Start the Snapshot Agent to generate the snapshot for this publication%'')
--and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''CCRecorderRIA''
--order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		--EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit
		EXEC sp_reinitmergesubscription @publication = @publication_reinit, @subscriber = @publisher_reinit, @subscriber_db = ''CCRecorderRIA'', @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@sql)
	
	
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

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
