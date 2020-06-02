/*
Autor: Raymundo González
Fecha: 2012/09/26
Descripcion: 
	Creación de indices para mejoras de tiempos en consultas
	Inserción en la tabla ccSettings para configuración de las dos llamadas del agente
	Modificación de la tabla ccmenus para extender la longitud del campo menu_descrip
	Actualizaciones de la tabla ccmenus en el campo menu_descrip para cambio de etiquetas
	Modificación del SP ccsp_RIAOUTInsertNewJOBS_WT_Camp para mejora de tiempo de ejecución
	Modificación del SP ccsp_RIA_mnuReciclar para mejora de tiempo de ejecución
	Modificación del SP ccsp_AgentSetCallStatus para mejora de tiempo de ejecución
	Modificación del Job CW Delete old records para mejora de tiempo de ejecución
	Creación del SP ccsp_ExtAppsDisposeCall	para calificar desde el Web Service
	Modificación del SP ccsp_ExtAppsCallHistory para devolver la actividad del agente al Web Service

Version requerida: 82
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '83'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

set @Sql='alter procedure dbo.ccsp_AgentGetCalificaciones
@InOut tinyint, --0 in, 1 out
@cam_id int --campaÏa
AS
set nocount on

IF @InOut = 0 
 BEGIN
	if exists(select calif.calif_id from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut)
	 begin
		select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.orden "selection!1!califorden", 
		null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", calif.orden "selection!1!califorden", 
		sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", cast(sb.orden as int) "subSelection!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut and sb.califsub_id is not null
		order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
		for xml explicit, type
	 end
	return(0)
 END

IF @InOut = 1
 BEGIN
	if exists(select calif.calif_id from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut)
	 begin
 		select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.keepDial "selection!1!keepOnDial", 
 		calif.orden "selection!1!califorden", null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!keepOnDial", 
 		null "subSelection!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", null "selection!1!keepOnDial", 
		calif.orden "selection!1!califorden", sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", sb.keepDial "subSelection!2!keepOnDial",
		cast(sb.orden as int) "subSelection!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = @InOut and sb.califsub_id is not null
		order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
		for xml explicit, type
	 end
	return(0)
 END

IF @InOut = 10
 BEGIN
 	select distinct S.califSub_id, S.califSubDesc, orden
 	from cctipoSubCalifRel R join cctipoCalifSub S on R.califSub_id = S.califSub_id
	where R.tipoSubRel=1 and S.califSub_Status=1 and R.calif_id=@cam_id
	order by S.orden, S.califSubDesc
	return(0)
 END

IF @InOut = 11
 BEGIN
 	select distinct S.califSub_id, S.califSubDesc, orden
 	from cctipoSubCalifRel R join cctipoCalifSubOut S on R.califSub_id = S.califSub_id
	where R.tipoSubRel=0 and S.califSubOut_Status=1 and R.calif_id=@cam_id
	order by S.orden, S.califSubDesc
	return(0)
 END

set nocount off'
		EXEC(@Sql)

			set @Sql = 'CREATE NONCLUSTERED INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] 
(
	[callout_id] ASC,
	[status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] 
(
	[callout_id] ASC,
	[cal_id] ASC,
	[statusCall_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] 
(
	[cam_id] DESC,
	[cal_status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] 
(
	[cam_id] DESC,
	[cal_status] ASC,
	[list_id]ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] 
(
	[cam_id] DESC,
	[cal_status] ASC,
	[tipoResDial_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] 
(
	[cam_id] DESC,
	[cal_status] ASC,
	[tipoResDial_id] ASC,
	[callout_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] 
(
	[cam_id] DESC,
	[cal_status] ASC,
	[tipoResDial_id] ASC,
	[calif_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] 
(
	[cam_id] DESC,
	[cal_status] ASC,
	[calif_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'

		EXEC(@Sql)

			set @Sql = 'INSERT INTO ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bloadSettings)
VALUES(120,''0'',''Habilitar dos llamadas para agente'',1,''AGT'',''Si esta activo el agente puede recibir una segunda llamada  de otra especialidad'',''If it is active the agent can receive a second call from another ACD'',0)'

		EXEC(@Sql)

			set @Sql = 'alter table ccmenus
	alter column menu_descrip varchar(250) NULL'

		EXEC(@Sql)

			set @Sql = 'update ccmenus set menu_descrip = ''Grupos ACD|ACD Groups'' where menu_id = 16
update ccmenus set menu_descrip = ''Configuración de Grupo ACD|ACD Group Configuration'' where menu_id = 17
update ccmenus set menu_descrip = ''Horarios de Grupo ACD|ACD Group Schedules'' where menu_id = 18
update ccmenus set menu_descrip = ''Mensajes de Grupo ACD|ACD Group Audio Messages'' where menu_id = 19
update ccmenus set menu_descrip = ''Calificación de Grupo ACD|ACD Group Disposition'' where menu_id = 21
update ccmenus set menu_descrip = ''Configuración de campaña de Grupo ACD|ACD Campaign Configuration'' where menu_id = 52
update ccmenus set menu_descrip = ''Lista negra por grupo ACD|Do Not Call List by ACD Group'' where menu_id = 62
update ccmenus set menu_descrip = ''Grupos ACD|ACD Groups'' where menu_id = 3000
update ccmenus set menu_descrip = ''Llamadas por Grupo ACD|Calls by ACD Group'' where menu_id = 3030
update ccmenus set menu_descrip = ''No trasferidas por Grupo ACD|Not Transferred by ACD Group'' where menu_id = 3060
update ccmenus set menu_descrip = ''Edición de Roles|Profile Edition'' where menu_id = 65
'
    EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

declare @prioridad varchar(8)

Delete ccUploadTemporal with(rowlock)
where cam_id = @camp_id

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select cs.callout_id
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock) 
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7))

update ccoCallsOutSource
set cal_Status = 4 
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock)
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7)

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select Cout.callout_id
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7))

update ccoCallsOutSource
set cal_Status = 4 
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7)

Insert ccoWorkingTable (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
	iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT callout_id, cam_id, 
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end,
list_id
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

Insert into ccoCallBacks
SELECT callout_id, user_id, cam_id, cal_key,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono1,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono2,cal_fechaDial,cal_fechaDial,NULL,0,1
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock)
SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) 
and cam_id = @camp_id

set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados / 
--				  3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings where setting_id = 60

If @Valor = 1
 begin
	declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
	select @Valor = valor from ccSettings where setting_id = 59
	
	If @Valor = 0 
	 begin
		select -2, ''No hay un limite para volver a reciclar''
		return(0)
	 end

	select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

	-- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
	select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')
	
	exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id
	If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
	begin
		select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
 		return(0)
	end

 end

if @type=0
 begin
	if @list_id = 0 begin
		update ccoCallsOutSource with(rowlock) 
		set dato5 = isnull(dato5, '''') 
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) where cam_id = @cam_id and cal_status = 1)
		
		update ccoCallBacks with(rowlock)
		set [status] = 3, schedulerStatus = 1
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) where cam_id = @cam_id and cal_status = 1)
		and [status] = 0

		update ccoWorkingTable with(rowlock) set cal_status = 0 where cam_id = @cam_id and cal_status = 1
	end
	else begin
		update ccoCallsOutSource with(rowlock) 
		set dato5 = isnull(dato5, '''') 
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id)

		update ccoCallBacks with(rowlock) 
		set [status] = 3, schedulerStatus = 1
		where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id)
		and [status] = 0

		update ccoWorkingTable with(rowlock) set cal_status = 0 where cam_id = @cam_id and cal_status = 1 and list_id = @list_id
	end

	return(0)
 end

if @type in(1,3)
 begin
	update ccoCallsOutSource with(rowlock)
	set dato5 = isnull(dato5, '''') where callout_id in (
	 select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_11),nolock)
	 where cam_id = @cam_id and cal_status = 1 and tiporesdial_id <> 1)

	update ccoCallBacks with(rowlock)
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
						 where cam_id = @cam_id 
						 and cal_status = 1 
						 and tiporesdial_id <> 1
						 and callout_id not in (select b.callout_id
											    from ccologdials a left join ccocallsout b with(index(IX_ccoCallsOut_1),nolock)
												on a.callout_id = b.callout_id
											    and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
											    where isnull(calif_id, 0) <> 0))
	and [status] = 0

	update ccoWorkingTable with(rowlock)
	set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id 
	and cal_status = 1 
	and tiporesdial_id <> 1
	and callout_id not in (select b.callout_id
						   from ccologdials a left join ccocallsout b with(index(IX_ccoCallsOut_1),nolock) 
						   on a.callout_id = b.callout_id
						   and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
						   where isnull(calif_id, 0) <> 0)
 end

if @type in(2,3)
 begin
	Set @SQL = ''update ccoCallsOutSource with(rowlock) set dato5 = isnull(dato5, '''''''') where callout_id in ('' +
	 ''select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_13),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''+'')'' + nchar(13)
	exec(@SQL)

	Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
	 ''where callout_id in ('' +
	 ''select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
	 ''and calif_id in ('' + @calif_id + ''))'' +
	 ''and [status] = 0''

	exec(@SQL)

	Set @SQL = ''update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
	 ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
	 + -- and tiporesdial_id = 1 '' +
	 ''and calif_id in ('' + @calif_id + '')''

	exec(@SQL)
 end

if @type = 4
 begin
	update ccoCallsOutSource with(rowlock) 
	set dato5 = isnull(dato5, '''') 
	where callout_id in (select callout_id 
					     from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)

	update ccoCallBacks with(rowlock) 
	set [status] = 3, schedulerStatus = 1
	where callout_id in (select callout_id 
						 from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock) 
						 where cam_id = @cam_id and cal_status = 3)
	and [status] = 0

	update ccoWorkingTable with(rowlock) set cal_status = 0, tiporesdial_id = 0 
	where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'

		EXEC(@Sql)

			set @Sql = 'ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)=''''
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int

if @TipoMov=4 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	end

	Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x

	return(0)
 end

if  @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id
		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id
	
	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end
	
	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'

		EXEC(@Sql)

			set @Sql = 'USE [msdb]

/****** Object:  Job [CW Delete old records]    Script Date: 08/17/2012 12:36:57 ******/
BEGIN TRANSACTION
/****** Object:  Job [CW Delete old records]    Script Date: 08/23/2012 12:14:36 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1

DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/17/2012 12:36:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 08/17/2012 12:36:58 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @meses int
set @meses = 8

truncate table cclogInfo
truncate table ccBorrardasReciclaje
truncate table ccUploadTemporal
truncate table ccLogCampsAgentesDia 

delete from cchistoriallistanegra where fecha < dateadd(mm, -@meses, getdate())
delete from ccRIAlog where operationDate < dateadd(mm, -@meses, getdate())

delete xxclientehistorial where fechaAct < dateadd(mm, -@meses, getdate())
delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(mm, -1, getdate())
delete ccRIAWorkGroup_Calid where timestamp < dateadd(mm, -1, getdate())
delete ccRIALogAgentesNotReady where fecha < dateadd(mm, -1, getdate())
delete ccRIAcallbacks where año < datepart(yy,getdate())
delete ccRIAcallbacks where mes < datepart(mm,getdate())

delete from ccLogAgentesDia where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogAgentesNotReady where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogLogin where fecha < dateadd(mm, -@meses, getdate())
delete from ccoLogDials where fecha < dateadd(mm, -@meses, getdate())
delete from ccoCallsOut where cal_inicio < dateadd(mm, -@meses, getdate())

update ccoCallBacks set [status] = 5, schedulerStatus = 1 
where callout_id in (select callout_id 
					 from ccoWorkingTable with(index(IX_ccoWorkingTable_3),nolock) 
					 where cal_fechadial < dateadd(mm, -@meses, getdate()))

delete from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate())
delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -@meses-1, getdate())
'', 
		@database_name=N''CCenterRia'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every Sunday at 1:30'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=13000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'

		EXEC(@Sql)

			Set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_ExtAppsDisposeCall]
@action as tinyint = 0,
@type as tinyint = 0,
@cal_id as smallint = 0,
@disposition as smallint = 0,
@subDisposition as smallint = 0,
@date as varchar(50) = '''',
@cam_id as smallint = 0
AS
declare @phone as varchar(15)
declare @msg as int
declare @needsCallback as int
set @msg = 0 --No hizo nada

if @action = 1 begin  -- Califica y reprograma
	if @type = 1 begin	-- Inbound
		
		if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la calif padre
			select @needsCallback = canReprogram from ccTipoCalif where calif_id = @disposition			
		end else begin -- Si no buscamos en la tabla de las subcalifs
			select @needsCallback = canReprogram from ccTipoCalifSub where califSub_id = @subDisposition			
		end

		if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
			if @date <> '''' begin
				declare @acd_id as smallint			
				declare @phoneT as varchar(15)

				select @phone = cal_ani, @acd_id = inbound_id from cccallsin with(nolock) where cal_id = @cal_id
				select @cam_id = isnull(cam_id,0) from ccinbound with(nolock) where inbound_id = @acd_id
				select @phoneT = dbo.Completa(@phone)

				if @cam_Id <> 0 begin -- Si hay campaña espejo reprogramamos
					select @phone = case when left(@phoneT,1) = ''E'' then @phone else @phoneT end
					-- Genera callback
					exec ccsp_InInsertaCallBack '''', @cam_id, @phone, @date, '''','''','''','''','''',1,0
					-- Actualiza calificacion
					update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
					set @msg =  2 -- Reprogramacion Inbound
				end else begin				
					set @msg =  5 -- No hay campaña espejo para el acd	
				end
			end else begin				
				set @msg = 6 -- Necesita repgoramacion pero no hay fecha
			end
		end else begin -- Si no necesita repgoramacion se actualiza la calificacion
			update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
			set @msg = 1 -- Actualizo calificacion 
		end
	end
	else begin -- Outbound

		if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la tabla calif padre
			select @needsCallback = canReprogram from ccTipoCalifOut where calif_id = @disposition
		end else begin -- Si no buscamos en la tabla de las subcalifs
			select @needsCallback = canReprogram from ccTipoCalifSubOut where califSub_id = @subDisposition
		end

		if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
			if @date <> '''' begin 
				declare @callout_id int
				declare @cal_key as varchar(33)
				
				select @phone = cal_telefono, @cam_id = cam_id, @callout_id = callout_id, @cal_key = cal_key from ccocallsout with(nolock) where cal_id = @cal_id
				exec ccsp_OUTInsertaCallBack @cal_id, @phone, @cam_id, @date, @callout_id, 1, 0, @cal_key
				update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
				set @msg =  4 -- Reprogramacion Outbound
			end else begin
				set @msg = 6 -- Necesita repgoramacion pero no hay fecha
			end
		end else begin -- Si no necesita repgoramacion se actualiza la calificacion
			update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
			set @msg = 3 -- Actualizo calificacion 
		end

	end	
	select @msg
end

if @action = 2 begin
	if @type = 1 begin
		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 0 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type		
	end
	else begin
 		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback", 
 		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 1 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where cam_id = @cam_id and tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type
	end
end

if @action = 3 begin
	if @type = 1 begin
		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where tipo = 0 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
		left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
		where tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type		
	end
	else begin
 		select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
 		calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where tipo = 1 
		union
		select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
		calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
		from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
		left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
		left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
		where tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
		for xml explicit, type
	end
end'

		EXEC(@Sql)

			Set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(20) = null,
@endDate varchar(20) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,
@agentId int = 0
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
	isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id) 
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

-- OUTBOUND x cal_id
if @action = 2 
 begin
	select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual
	from ccocallsout c with(nolock)
	left join ccusers b on (c.user_id = b.user_id) 
	left join cccamps a on (c.cam_id = a.cam_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

if @action = 3 --Session time
	begin
		declare @fecha_ini datetime
		declare @fecha_fin datetime	

		if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
			select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
			select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
		end
		else begin
			select @fecha_ini = convert(datetime,convert(varchar(11),@startDate))
			select @fecha_fin = convert(datetime,convert(varchar(11),@endDate))
		end

		select user_id, login, logout, datediff(ss,login,logout) as logintime 
		from(select a.user_id, a.fecha as ''login'',
				(select isnull(max(Fecha),getdate())
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
				and fecha >= @fecha_ini
				and fecha <= @fecha_fin) as sessiontime
		order by user_id, login
	end

	if @action = 4 -- Estados de los agentes
	begin	
		select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
	end

	if @action = 5 -- Sinlge Call id Inbound
	 begin
		select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing
		from cccallsin c with(nolock)
		left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
		left join ccusers b on (c.user_id = b.user_id) 
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalif e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end


	-- Single call_id Outbound
	if @action = 6
	 begin
		select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
		d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual
		from ccocallsout c with(nolock)
		left join ccusers b on (c.user_id = b.user_id) 
		left join cccamps a on (c.cam_id = a.cam_id)
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end

if @action = 7 begin --Status Agente
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) from cclogagentesdia with(nolock) where user_id = @agentId and fecha >= @startDate and fecha < @endDate order by fecha
end'

		EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
