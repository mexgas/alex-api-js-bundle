/*
Autor: Raymundo Gonzalez
Fecha: 2013/09/30
Descripcion:
	Se agrega la columna dnis a la tabla IVRCallsIn para reporte
	Se insertan registros en la tabla ccSettings 147 y 148 para marcacion predictiva y activación de Xion
	Se actualiza el campo descripcion de la tabla ccsettings para el id 145 de activacion de chat
	Se actualiza el campo menu_descrip de la tabla ccMenus para version Xion
	Se modifica el SP ccsp_RIACATNotReadyTypes para fix en cargas de Not Ready
	Se modifica el SP ccsp_ExtAppsCallHistory para agregar id de lista de carga
	Se modifica el SP ccsp_RIA_ABCAreas para devolver el scope_identity de la insercion
	Se modifica el SP ccsp_RIA_ABCWorkGroups para devolver workgroups con base en area
	Se modifica el SP ccsp_RIALoadCamps para devolver DNCScrub en la lista de campañas
	Se modifica el SP ccsp_IVRInCalls para guardar dnis
	Se modifica el SP ccsp_IVRADM para devolver lista de dnis
	Se modifica el SP ccsp_RIAADMAddCalif para inserciones en tablas con columna de replicas
	Se modifica el SP ccsp_RIA_ABCACDGroups para inserciones en tablas con columna de replicas
	Se modifica el SP ccsp_getCampDialInfo para inserciones en tablas con columna de replicas
	Se modifica el SP ccsp_ADMAddCalifCamp para inserciones en tablas con columna de replicas
	Se modifica el SP ccsp_ADMAddCalif para inserciones en tablas con columna de replicas
	Se modifica el SP ccsp_RIAccSettingsConfig para mostrar u ocultar settings de chat
	Se modifica el SP ccsp_RIAMenuRoles para mostrar u ocultar menus de chat
	
Version requerida: 99
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '100'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'IVRCallsIn - Alter Table'
		set @Sql='ALTER TABLE dbo.IVRCallsIn 
ADD dnis varchar(50) DEFAULT '''' NOT NULL'
	
	EXEC(@Sql)

		set @process = 'ccSettings - Insert'
		set @Sql='INSERT INTO ccSettings(setting_id, valor, descripcion, Status, Tipo, Detalle, description, bLoadSettings)
VALUES(147, ''0'', ''Modo de marcacion'', 1, ''GRL'', ''Modo de marcacion Clasico:0 o predictivo:1'', ''Dialing mode'', 0)
		
insert into ccsettings(setting_id, valor, descripcion, Status, Tipo, Detalle, description, bLoadSettings)
values (148, ''0'', ''Tipo de licenciamiento de la versión Xion'', 1, ''X'', ''Si el valor es 0 no hay licencia de Xion, si el valor es 1 el sistema se reconoce como Xion'', ''Xion license type'', 1)'
			
	EXEC(@Sql)

		set @process = 'ccsettings - Update'
		set @Sql = 'update ccsettings
set detalle = ''0 inactivo, 1 activo y 3 con cola de espera''
where setting_id = 145'
		
	EXEC(@Sql)
	
		set @process = 'ccMenus - Update'
		set @Sql = 'update ccmenus 
set menu_descrip = ''Centerware|Centerware'' 
where menu_id = 40'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIACATNotReadyTypes - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIACATNotReadyTypes]
@TipoNotReady_id varchar(5)='''',
@Descripcion varchar(30)='''',
@Time_Acum varchar(10)='''',
@Time_xEv varchar(5)='''',
@Pas_Sup varchar(2)='''',
@NextStatus varchar(5)='''',
@graphic_id varchar(5)='''',
@Type varchar(1)='''',
@IsSup int = null,
@super_id as int = null
AS
set nocount on
DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

if @Type=0
 begin
	SELECT TipoNotReady_id, Descripcion FROM ccTipoNotReady WITH(NOLOCK) WHERE StatusTipoNotReady=1
	return(0)
 end

if @Type=6 -- LOAD by setting
 begin
	select @Type = valor from ccSettings where setting_id = 87

    if @Type = 4 begin
		SELECT a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		inner join ccsupervisor_notready snd on (a1.tiponotready_id = snd.tiponotready_id and snd.user_id = @super_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
		when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
	end
	else begin
		SELECT a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = case @Type when 1 then (select valor from ccSettings where setting_id = 28)
		when 2 then a1.IsSup when 4 then a1.issup else 1 end and a1.StatusTipoNotReady=1
	end
	return(0)
 end

if @Type=1 -- LOAD
 begin
	declare @NotReadybyCampACD int
	select @NotReadybyCampACD = valor from ccsettings where setting_id = 135
	
	if (@NotReadybyCampACD = 0)
	begin
		SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
	end
	else if (@NotReadybyCampACD = 1)
		begin
			SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
			and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
			AND a4.type = 0
			union
			SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
			and a4.idCampACD in (select distinct(cam_id) from ccSupervisorCam where user_id = @super_id)
			AND a4.type = 1
		end
	return(0)
 end

If @Type=2 -- INSERT
 begin
	if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
	 begin		
		select 1
		return(0)
	 end
	if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Descripcion)
		begin		
			select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Descripcion
			update ccTipoNotReady set 
			Time_acum=@Time_Acum,
			Time_xEv=@Time_xEv,
			Pas_Sup=@Pas_Sup,
			NextStatus=@NextStatus,
			IsSup=@IsSup,
			StatusTipoNotReady=1
			where Descripcion=@Descripcion
			If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
				Begin
					insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
				End
			
			insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
			return(0)		
		end
	If not exists(select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
	 Begin
		insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
	 End

	insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup,StatusTipoNotReady) 
	select @Descripcion, @Time_Acum, @Time_xEv, @Pas_Sup, @NextStatus, @IsSup,1
	select @id=SCOPE_IDENTITY()
	insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
	return(0)
 end

If @Type=3 -- DELETE
 begin
	exec ccsp_AdminNotready 3,0,@TipoNotReady_id,0
	delete ccRIANotReadyGraph where tipoNotReady_id = @TipoNotReady_id
	update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id = @TipoNotReady_id
 end

if(@Type=4) --UPDATE
 begin

	if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Descripcion)
	 begin		
		select @Descripcion=''''
	 end

	update ccTipoNotReady set 
	 Descripcion=case @Descripcion when '''' then Descripcion else @Descripcion end,
	 Time_Acum=case @Time_Acum when '''' then Time_Acum else @Time_Acum end,
	 Time_xEv=case @Time_xEv when '''' then Time_xEv else @Time_xEv end,
	 Pas_Sup=case @Pas_Sup when '''' then Pas_Sup else @Pas_Sup end,
	 NextStatus=case @NextStatus when '''' then NextStatus else @NextStatus end,
	 IsSup=ISNULL(@IsSup,IsSup)
	where TipoNotReady_id=@TipoNotReady_id

	IF ISNULL(@graphic_id,'''') not in('''')
	 BEGIN
		If not exists (select frame from ccRIAGraphics where frame = @graphic_id and type_id = 4)
		 begin
			insert into ccRIAGraphics (frame, type_id) select @graphic_id,4
		 end

		select @graph = graphic_id from ccRIAGraphics where frame = @graphic_id and type_id = 4
		update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@TipoNotReady_id as tinyint)
	 END
	return(0)
 end

if @Type = 7 -- LOAD
	begin
		SELECT distinct a1.TipoNotReady_id, a1.Descripcion, a1.Time_Acum, a1.Time_xEv, a1.Pas_Sup, a1.NextStatus, frame, a1.IsSup
		FROM ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
		where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id > 0
		return(0)
	end
set nocount off'

	EXEC(@Sql)

		set @process = 'ccsp_ExtAppsCallHistory - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(30) = null,
@endDate varchar(30) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,
@agentId int = 0
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
	isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing,  cal_key as callKey
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
	select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,c.cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual,  c.cal_key as callKey,
	list_id
	from ccocallsout c with(nolock)
	left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
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
			select @fecha_ini = convert(datetime,convert(varchar(30),getdate()))
			select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
		end
		else begin
			select @fecha_ini = convert(datetime,convert(varchar(30),@startDate))
			select @fecha_fin = convert(datetime,convert(varchar(30),@endDate))
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
		isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_key as callKey
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
		select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,c.cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
		d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual, c.cal_key as callKey,
		cs.list_id
		from ccocallsout c with(nolock)
		left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
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
	
		set @process = 'ccsp_RIA_ABCAreas - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40)
AS
set nocount on
if @option=1 --Selected Area
begin
declare @maxchats as smallint

Select a.IDArea, AreaName, maxChats as maxChats  from ccRIACat_Areas a 
left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b
on a.IDArea = b.IDArea
where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0) 
when 0 then isnull(a.IDArea,0) else @IDArea end
order by AreaName
return(0)
end

if @option=2 --Insert Area
begin
if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
 begin
	select -1--, Nombre en Uso
	return(0)
 end

Insert into ccRIACat_Areas (AreaName) values (@Descripcion)			
select 1, scope_identity()--, Area Insertada
return(0)
end

if @option=3 --Update Area
begin
if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
	Update ccRIACat_Areas set AreaName=@Descripcion where IDArea=@IDArea

return(0)
end

if @option=4 --Delete Area
begin	
if (exists(select IDArea from ccUsers where IDArea=@IDArea) 
 or exists(select IDArea from ccCamps where IDArea = @IDArea)
 or exists(select IDArea from ccInbound where IDArea=@IDArea)) 
 and (select valor from ccSettings where setting_id=95)<>1
 begin
	select -1
	return(0)
 end

declare @DWorkGroups as varchar(500)
Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

select @DWorkGroups = coalesce(@DWorkGroups + '','', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

if (select valor from ccSettings where setting_id=95)=1
 begin
	Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea	
	Update ccCamps set IDArea=NULL where IDArea=@IDArea
	Update ccUsers set IDArea=NULL where IDArea=@IDArea
 end

Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea
select @DWorkGroups
return(0)
end
return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIA_ABCWorkGroups - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCWorkGroups]
@option smallint,
@IDWG smallint,
@user_Id smallint = 0,
@Descripcion varchar(45) = null,
@IDArea smallint = null,
@IDCampEsp varchar(2000),
@Type smallint
as
set nocount on
if @option = 0 -- All WokGroup
 begin
	if(@IDArea = 0 or @IDArea is null)
		select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1
	else
		select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1 and IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea=@IDArea)
	
	return(0)
 end

if @option = 1 -- Selected WokGroup
 begin
	if @type = 0
	begin
		select IDWG, WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and IDWG=@IDWG
	end
	else if @type = 1
	begin
		select w.IDWG, w.WGName, a.IDArea
		from ccRIACat_WorkGroup w
		join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
		join ccRIACat_Areas a on a.IDArea = aw.IDArea
		where w.StatusWorkGroup=1
	end
	else if @type = 2
	begin
		select w.WGName, a.IDArea, a.AreaName
		from ccRIACat_WorkGroup w
		join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
		join ccRIACat_Areas a on a.IDArea = aw.IDArea
		where w.StatusWorkGroup=1 and w.IDWG=@IDWG
	end
	else if @type = 3
	begin
		select count(*)
		from ccRIAWorkGroupUsers
		where idwg=@IDWG
		and user_id=@user_Id
	end

	return(0)
 end

if @option = 2 -- insert WorkGroup
 begin
	if exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
	 begin
		select -1 --, Nombre en Uso
		return(0)
	 end
	
	insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	if @@rowcount = 1
		select @IDWG = scope_identity()

	else 
	 begin
		select -2 --, No se inserto correctamente
		return(0)
	 end

	insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
	select 1 --, WG insertado
	return(0)
 end

if @option = 3 -- UpdateWokGroup
 begin
	Update ccRIACat_WorkGroup set WGName=@Descripcion where StatusWorkGroup=1 and IDWG=@IDWG
	return(0)
 end

if @option in (4,8) -- Delete WorkGroup (4:all / 8:only from acd/camps)
 begin
	Delete from ccCampsAgente where IDWG = @IDWG
	Delete from ccInboundAgentes where IDWG = @IDWG
	Delete from ccSupervisorCam where IDWG = @IDWG
	Delete from ccRIACampEspWG where IDWG = @IDWG
	
	if @option=4
	 begin
		Delete from ccRIAAreaWorkGroup where IDWG = @IDWG 
		Delete from ccRIAWorkGroupUsers where IDWG = @IDWG
		Update ccRIACat_WorkGroup set StatusWorkGroup=0 where IDWG=@IDWG
	 end
	return(0)
 end

if @option = 5 -- Insert WorkGroup in Camp or ACDGroup	
 begin
	if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) >= (select valor from ccSettings where setting_id=64) -- limit
	 begin
		select 2
		return(0)
	 end
	
	if exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- Ya existe el grupo en el ACD o Especialidad
	 begin
		select 1
		return(0)
	 end

	insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
	exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
	if @Type not in (0, 1) -- ACDGroup
		return(0)
		
	if @Type=0 --ACDGroup
	begin

		if @IDWG is null or @IDWG = 0
		 begin
			select 48
			return(0)
		 end
		 
		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		 join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
		and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

		insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
		select b.user_id, @IDCampEsp, 0, @IDWG
		from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
		 join ccusers s on b.user_id = s.user_id
		where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
		 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
	 
		return(0)
	end
	
	if @IDWG is null or @IDWG = 0
	 begin
		select 18
		return(0)
	 end

	-- if @Type = 1 -- Camp
	insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
	SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
	FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
	join ccusers s on u.user_id = s.user_id
	WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
	 and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
	
	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select b.user_id, @IDCampEsp, 1, @IDWG
	from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
	 join ccusers s on b.user_id = s.user_id
	where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
	 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)

	return(0)
 end

if @option = 6 -- Verifica si existe el grupo
 begin
  	select @IDWG = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
	 then 1 else 0 end
 
 	if isnull(@IDArea,0)=0
	 begin
		select @IDWG
		return(0)
	 end

 	if @IDWG=1
	 begin
		select ''-1''
		return(0)
	 end

	insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	if @@rowcount = 1
		select @IDWG = scope_identity()

	insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

if @option = 7 -- Delete WokGroup from ACD or Camp
 begin
	if @Type = 1
		Delete from ccCampsAgente where IDWG=@IDWG and cam_id=@IDCampEsp

	else if @Type = 0 
		Delete from ccInboundAgentes where IDWG=@IDWG and inbound_id=@IDCampEsp

	Delete from ccRIACampEspWG where IDWG=@IDWG and IdCampEsp=@IDCampEsp and Tipo=@Type

	return(0)
 end
 
return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIALoadCamps - Alter Procedure'
		set @Sql='ALTER PROCedure [dbo].[ccsp_RIALoadCamps]
@option smallint,
@AreaId smallint = null,
@Sup smallint = null
as
set nocount on
if @option = 1 -- Todas las campañas
begin
      select a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0), isnull(DNCscrub,0)
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 1))
      order by 5,2
      return(0)
end
 
if @option = 2 -- Campañas de un Area
begin
      select distinct a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0)
      IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
      order by cam_descripcion
      return(0)
end
 
if @option = 3 -- Campañas por Supervisor
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea,0) IDArea
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
      where a3.type_id = 1 and a4.tipo = 1 and a4.user_id = @Sup
      order by 5, 2
      return(0)
end
 
if @option = 4 -- Rels Camps-Agents
begin
      select Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
      from (select A.Login, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea,0) IDArea, CA.rel_id
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
            join ccRIACampsGraph a2 on C.cam_id = a2.cam_id
            join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
            join ccUsers A on A.User_id = CA.User_id and A.TipoUser_id = 1 and A.Status = 1
            where C.cam_id in(select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0)
             when 0 then user_id else @Sup end and tipo=1)) Relations
      group by Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
      order by User_id, cam_descripcion, cam_id, Prioridad
      return(0)
end
 
if @option = 5 -- Campañas por Supervisor
      begin
            select distinct Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea,0)IDArea,
            IsNull(CN.New, 0) as New, IsNull(CN.CB, 0) as CB, IsNull(CN.Pro, 0) as Pro,
            IsNull(CN.pen, 0) as Pen, cast(Camps.cam_procesando as int) as St, Camps.cam_TipoJobs as Job,
            isnull(CN.Fin, 0)Fin, isnull(CP.prioridad,''12345NNN'') prioridad, cast(camps.dialorder as tinyint) dialorder,
            cast(camps.progDial as tinyint) progDial, U.monitored
            from ccCamps Camps left join ccCampsPrioridadTel CP on CP.cam_id = Camps.cam_id
            left join ccCampsNvosCB CN on CN.id = Camps.cam_id
            join ccRIACampsGraph a2 on (Camps.cam_id = a2.cam_id)
            join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
            join ccSupervisorCam U on Camps.cam_id = U.cam_id
            where U.user_id = @sup
            and tipo = 1
            and a3.type_id = 1
            and Camps.cam_id in (select cam_id from ccSupervisorCam where tipo = 1 and user_id = @sup)
            order by 5, cam_procesando desc, cam_descripcion
            return(0)
      end
 
if @option = 7 -- Una sola
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea,0) IDArea,
      isnull(DNCscrub,0) DNCScrub
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id=1 and isnull(a1.cam_id,0)=isnull(@AreaId,0)
      order by 5,2
      return(0)
end
 
if @option = 8 -- Campañas de un Agente
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccCampsAgente a4 on a1.cam_id = a4.cam_id
      where a3.type_id=1 and a4.user_id = @Sup
      order by 2
      return(0)
end
 
return(0)
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_IVRInCalls - Alter Procedure'
		set @Sql='ALTER Procedure [dbo].[ccsp_IVRInCalls]
@action tinyint = 0 ,
@ani varchar(30) = null ,
@idIvr int = 0 , 
@option varchar(5)= null ,
@saveType tinyInt = null,
@dnis varchar(50) = null
-- saveType 1 es menu 2 es dato
-- accion 1 siempre @ani  -> @idIvr
-- accion 2 siempre @idIvr @opcionDigitada -> nada
AS

IF @action = 1 
	BEGIN
		IF @ani IS NOT NULL 
			BEGIN
				INSERT  INTO IVRCallsIn(cal_ani,date,dnis) values(@ani,getDate(),isnull(@dnis,''''));
				Select ''ID''=scope_identity()
			END
	END
ELSE IF @action = 2 
	BEGIN
		IF @option IS NOT NULL AND @idIvr IS NOT NULL
			BEGIN
				INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType) values (@idIvr,@option,getDate(),@saveType)
				select 0
			END
	END'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_IVRADM - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_IVRADM]
@option smallint, 
@idScript smallint = NULL, 
@name varchar(40) = NULL,  
@dnis varchar(400) = NULL, 
@blockId smallint = NULL,  
@blockType tinyint = NULL,  
@blockLabel varchar(40) = NULL, 
@variablesStruct varchar (MAX) = NULL, 
@retCodeStruct varchar (MAX) = NULL,
@storeProcedureName varchar (MAX) = NULL,
@storeProcedureParams varchar (MAX) = NULL,
@audioFile varchar(40) = NULL, 
@audioDescription varchar(40) = NULL

AS
-- INTERNAL VARS
DECLARE @newIdTemplate smallint
SET @newIdTemplate = 0
DECLARE @newAudioIdTemplate smallint
SET @newAudioIdTemplate = 0


----------------------
---- CASE OPTIONS


-- DO NOTHING
IF @option = 1
	BEGIN	
		SELECT 1
	END


-- INSERT A NEW TEMPLATE
IF @option = 2 
BEGIN
	IF EXISTS (SELECT * FROM IVRTemplate WHERE name = @name  ) 	
		BEGIN
			SELECT -1 --''The IVR template name is already in use.''
		END
	ELSE
		BEGIN
			INSERT INTO IVRTemplate(name, dnis) VALUES (@name, @dnis)			
			SELECT @newIdTemplate = scope_identity()						
			SELECT @newIdTemplate
		END
END


-- UPDATE AN IVRTEMPLATE
IF @option = 3 
BEGIN
	IF NOT EXISTS (SELECT * FROM IVRTemplate WHERE idScript = @idScript  ) 	
		BEGIN
			SELECT -1 --''The ivr  does not exists''
		END
	ELSE
		BEGIN
			UPDATE IVRTemplate SET name = @name, dnis = @dnis WHERE idScript=@idScript
		END
	SELECT @idScript
END


IF @option = 4 
BEGIN 
    BEGIN TRAN
    BEGIN TRY
           DELETE FROM IVRTemplate WHERE idScript=@idScript 
           DELETE FROM IVRTemplateStruct WHERE idScript = @idScript
           SELECT @idScript
           COMMIT TRAN
    END TRY
    BEGIN CATCH
           select -1  
           ROLLBACK TRAN
    END CATCH
END



-- SELECT ALL IVR TEMPLATES
IF @option = 5
BEGIN
	SELECT idScript, name, dnis FROM IVRTemplate 
END


-- INSERT A NEW BLOCK
IF @option = 6 
BEGIN
	INSERT INTO IVRTemplateStruct (idScript, idBlock, TypeBlock, LabelBlock, VariablesBlock, RetCodeBlock)
	VALUES (@idScript, @blockId, @blockType, ISNULL(@blockLabel, ''''), @variablesStruct, @retCodeStruct)
END

-- SELECT ALL BLOCKS
IF @option = 7
BEGIN
	SELECT idBlock, TypeBlock, LabelBlock, VariablesBlock, RetCodeBlock
	FROM IVRTemplateStruct
	WHERE idScript = @idScript
END


-- DELETE ALL BLOCKS (IVR STRUCT) OF IVR ID PROVIDED
IF @option = 8
BEGIN
	DELETE IVRTemplateStruct WHERE idScript = @idScript
END


--------------------------------
--------------------------------
--- STORE PROCEDURE VERIFICATION

-- CHECK IF EXISTS STORE PROCEDURE
IF @option = 9
BEGIN
	IF OBJECT_ID (@storeProcedureName) is NULL
		BEGIN
			SELECT 0 -- ''There is not even a single object with the provided id''
		END
	ELSE
		BEGIN
			IF OBJECTPROPERTY(OBJECT_ID (@storeProcedureName), ''isProcedure'') = 1
				BEGIN
					SELECT 1 -- ''The supposed store, actually is.''
				END
			ELSE IF OBJECTPROPERTY(OBJECT_ID (@storeProcedureName), ''isExtenerProc'') = 2
				BEGIN
					SELECT 2 -- ''The supposed store is an Extended Procedure''
				END
			ELSE 
				BEGIN
					SELECT 3 -- ''The supposed store, is not a store and is a non-null object; it ''s something else.
				END
		END
END


-- CHECK CURRENT PARAMETERS OF THE STORE PROCEDURE
IF @option = 10
BEGIN
	SELECT SCHEMA_NAME(SCHEMA_ID) AS [Schema], 
			SO.name AS [ObjectName],
			SO.Type_Desc AS [ObjectType (UDF/SP)],
			P.parameter_id AS [ParameterID],
			P.name AS [ParameterName],
			TYPE_NAME(P.user_type_id) AS [ParameterDataType],
			P.max_length AS [ParameterMaxBytes],
			P.is_output AS [IsOutPutParameter],
			P.has_default_value AS [IsRequired],
			P.default_value AS [DefValue]
	FROM sys.objects AS SO
	INNER JOIN sys.parameters AS P 
	ON SO.OBJECT_ID = P.OBJECT_ID
	WHERE SO.OBJECT_ID  = object_id(@storeProcedureName)
	ORDER BY [Schema], SO.name, P.parameter_id
END


-- TRIES THE STORE PROCEDURE WITH ITS PARAMETERS
IF @option = 11
BEGIN
	BEGIN TRAN
	BEGIN TRY
		   EXEC @storeProcedureName @storeProcedureParams
		   SELECT 1 
		   COMMIT TRAN
	END TRY
	BEGIN CATCH
		   SELECT -1 
		   ROLLBACK TRAN
	END CATCH
END


-- SELECT ALL AUDIOS FOR IVR TEMPLATES
IF @option = 12
BEGIN
	SELECT ivrAudioId,audioFile,description FROM IVRTemplateAudio
END

-- DELETE AUDIO FOR IVR TEMPLATES
IF @option = 13
BEGIN
    BEGIN TRAN
    BEGIN TRY
           DELETE FROM IVRTemplateAudio WHERE ivrAudioId = @idScript 
           SELECT @idScript
           COMMIT TRAN
    END TRY
    BEGIN CATCH
           select -1  
           ROLLBACK TRAN
    END CATCH
END



-- INSERT AUDIO FOR IVR TEMPLATES
IF @option = 14
BEGIN
	insert into IVRTemplateAudio values (@audioFile,@audioDescription)
	SELECT @newAudioIdTemplate = scope_identity()							
	SELECT @newAudioIdTemplate
END

IF @option = 15
BEGIN
	IF ( select count(*) from ccDnis) = 0
			begin	
				select -1 --''No hay 
			end
	 ELSE
			begin
				select dni_id, dni_numero, dni_descripcion, cast(dni_isBlock as tinyint) dni_isBlock 
				from ccDnis where dni_Status=1  order by 2
				--and dni_id not in(select dni_id from ccInboundDnis)
		--return(0)
			end
END'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAADMAddCalif - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIAADMAddCalif]
@calif_id varchar(8000) = null, --Id Calificacion
@Type tinyint = null, --0=In, 1=Out
@cam_id smallint = null, --Inbound_id, or cam_id, si es 0 la Agrega a Todos
@command tinyint,
@AreaId as smallint = null
AS
set nocount on
declare @sql as nvarchar(2000)

If @command=1 -- Agrega Una calificacion a una campa?a o especialidad
 begin
	if @Type=0 and exists (select calif_id from ccTipoCalif where CanReprogram=1 and calif_id=@calif_id)
	 and exists (select inbound_id from ccInbound where cam_id is null and Inbound_id=@cam_id)
	 begin
		select -1 -- raiserror(''Campaign unassigned for Reprogramation'', 18, 1)
		return(0) 
	 end
	if not exists (select calif_id from ccCalifCamp where calif_id=@calif_id and cam_id=@cam_id and tipo=@Type)
		 insert into ccCalifCamp(calif_id,cam_id,tipo) select @calif_id, @cam_id, @Type 
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	select 1
 end

If @command=2 -- Agrega Una a calificacion a todas las campa?as o especialidades
 begin
	if @Type=0 -- InBound
	 begin	
		If @AreaId = 0
		 begin
			set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
			select f.calif_id, e.inbound_id, 0 from ccInbound e, cctipoCalif f where 
			f.Calif_Status=1 and f.calif_id in ('' + @calif_id + '')
			and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id and IDArea is null
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id)
			and IDArea is null'' 

			set @sql = ''delete ccCalifCamp where cast(calif_id as varchar(100))+''''&''''+CAST(cam_id as varchar(100)) in 
			(select cast(C.calif_id as varchar(100))+''''&''''+CAST(C.cam_id as varchar(100))
			from ccCalifCamp C join ccInbound I on C.cam_id = I.inbound_ID
			join ccTipoCalif T on C.calif_id = T.calif_id
			where T.CanReprogram=1 and C.tipo=0 and I.cam_id is null and C.calif_id in ('' + @calif_id + ''))''
			execute sp_executesql @sql
		 end
		else
		 begin
			set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
			select f.calif_id, e.inbound_id, 0 from ccInbound e, cctipoCalif f where 
			f.Calif_Status=1 and f.calif_id in ('' + @calif_id + '')
			and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id and IDArea = '' + cast(@AreaId as varchar(10)) +
			''where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id)
			and IDArea = '' + cast(@AreaId as varchar(10)) 
			execute sp_executesql @sql
		end
		return(0)
	 end

	If @AreaId = 0
	 begin
		set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in ('' + @calif_id + '')
		and not exists(
		select a.calif_id,c.cam_id,1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id and IDArea is null 
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id)
		and IDArea is null''
		execute sp_executesql @sql
	 end
	else
	 begin
		set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo)  
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in ('' + @calif_id + '')
		and not exists(select a.calif_id,c.cam_id,1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id and IDArea = '' + cast(@AreaId as varchar(10)) +
		''where f.calif_id = a.calif_id and e.cam_id = c.cam_id)
		and IDArea = '' + cast(@AreaId as varchar(10)) 
		execute sp_executesql @sql
	 end
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
 end

If @command=3 -- Verifica si de la opci?n uno se eliminaron todas sus calificaciones
 begin
	If exists(Select cam_id from ccCalifCamp where cam_id=@cam_id and tipo=@Type)
	 begin
		If @Type = 0
		 begin
			Update ccInbound set ShowCalifWnd = 1 where inbound_id = @cam_id
			return(0)
		 end

		Update ccCamps set cam_ShowCalifWnd = 1 where cam_id = @cam_id
	 end
	return(0)
 end

If @command=4 -- Verifica si de la opci?n dos se eliminaron todas sus calificaciones
 begin
	If @Type = 0
	 begin
		Update ccInbound set ShowCalifWnd = 0 where inbound_id not in (select A.inbound_id from ccInbound A
		left join ccCalifCamp B on A.inbound_id = B.cam_id and B.Tipo = 0
		group by A.inbound_id having count(B.cam_id)>0)
		and IDArea = @AreaId
		return(0)
	 end

	Update ccCamps set cam_ShowCalifWnd = 0 where cam_id not in (select A.cam_id from ccCamps A
	left join ccCalifCamp B on A.cam_id = B.cam_id and B.Tipo = 1
	group by A.cam_id having count(B.cam_id)>0)
	and IDArea = @AreaId
	return(0)
 end
set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIA_ABCACDGroups - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint
as
set nocount on
declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
	 select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
	isnull(areas.areaname,'''') as areaname
	 from ccinbound as acd with(nolock)
	 left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
	 return(0)
 end

if @option = 1 -- select acd
 begin
	 select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id
	 from ccinbound a1 
	  inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
	  inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
	 where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
	 order by descripcion
	 return(0)
 end

if @option = 2 -- insert
 begin
	if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
	 begin
			select -1--, ''nombre en uso''
			return(0)
	 end
	
	if @idarea = 0
	set @idarea = null
	
	insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd)
	select @descripcion, 1, @idarea, case when exists(select calif_id from cctipocalif) then 1 else 0 end
	
	if @@rowcount = 1
		select @new_inbound_id = inbound_id from ccinbound where descripcion = @descripcion and status = 1

	else
	 begin
		select -2 -- Error al insertar
		return(0)
	 end

	insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

	if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
	 begin
		insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
		select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
	 end

	if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
	 insert into ccriagraphics (frame,type_id) values (@frame,1)
	
	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 
	 insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
	 select @new_inbound_id
	 return(0) 
 end

if @option = 3 -- update
 begin
	 if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
		insert into ccriagraphics (frame, type_id) values (@frame, 1)

	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
	 update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
	 return(0)
 end

if @option = 4 -- delete
 begin
	 delete cccalifcamp where cam_id = @inbound_id and tipo = 0
	 delete ccinboundhorarios where inbound_id = @inbound_id
	 delete ccriainboundgraph where inbound_id = @inbound_id
	 delete ccinbound where inbound_id = @inbound_id
	 return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
	if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña o ACD invalido
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null

	update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
	if @@rowcount=0
		select -4 -- Error al actualizar
		
	else
	 begin
		delete cccalifcamp where tipo=0 and cam_id=@inbound_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	 end

	return(0)
 end
set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_getCampDialInfo - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_getCampDialInfo]
@cam_id as integer = 0
AS
declare @idioma as bit
declare @msg as varchar(40)

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

if @idioma = 1
select @msg = ''Last campaigns resume creation''
else
select @msg = ''Ultima generacion de resumen campañas''

if (select count(*) from ccSettings where setting_id = 24) = 0 begin
	insert ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) values (24, convert(varchar(25), dateadd(ss, -10, getdate()), 121), @msg, 1, ''GRL'',''Detalle'',''description'',0)	
end

if (select datediff(ss, (select valor from ccsettings where setting_id = 24), getdate())) > 60 begin
	update ccsettings set valor = convert(varchar(25), getdate(), 121) where setting_id = 24
	delete ccCampsDialInfo
	insert ccCampsDialInfo
	select c.cam_id, isnull(t.nCalls, 0), isnull(t.nAnswer, 0), isnull(t.nBusy, 0), isnull(t.nNoAnswer, 0),
			 isnull(t.nMachine, 0), isnull(t.nFax, 0), isnull(t.nNoTone, 0), isnull(t.nCongestion, 0), isnull(t.nOthers, 0)
	from ccCamps c left join 
	(
		select cam_id, count(*) as nCalls, 
		count(case tiporesdial_id when 1 then 1 else null end) as nAnswer, 
		count(case tiporesdial_id when 2 then 1 else null end) as nBusy, 
		count(case tiporesdial_id when 3 then 1 else null end) as nNoAnswer, 
		count(case tiporesdial_id when 11 then 1 else null end) as nMachine, 
		count(case tiporesdial_id when 4 then 1 else null end) as nFax, 
		count(case tiporesdial_id when 5 then 1 else null end) as nNoTone,
		count(case tiporesdial_id when 12 then 1 else null end) as nCongestion, 
		count(case when tiporesdial_id not in (1, 2, 3, 4, 5, 11, 12) then 1 else null end) as nOthers 
		from ccoLogDials where fecha > convert(varchar(11), getdate(), 101) 
		group by cam_id
	) t on c.cam_id = t.cam_id
end

select * from ccCampsDialInfo where (cam_id = @cam_id or @cam_id = 0)'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_ADMAddCalifCamp - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ADMAddCalifCamp]
@calif_id smallint, --Id Calificacion
@Tipo tinyint, --0=In, 1=Out
@cam_id smallint=0, --Inbound_id, or cam_id, si es 0 la Agrega a Todos
@user_id smallint=1
AS

if ( @calif_id >0 and ( @Tipo=1or @Tipo=0 ) )
begin
	if ( @cam_id>0 ) -- Agrega Una a una Campañas  por Tipo
		if (select count(*) from ccCalifCamp where calif_id = @calif_id and cam_id = @cam_id and tipo = @tipo) = 0
		      insert into ccCalifCamp (calif_id,cam_id,tipo) values ( @calif_id, @cam_id, @Tipo)
	
	if (@cam_id=0 )   -- Agrega Una a Todas las Campañas por Tipo
	begin
		delete ccCalifCamp where calif_id=@calif_id and tipo=@Tipo and (cam_id in (select cam_id from ccSupervisorCam where tipo = @tipo and user_id = @user_id)  or @user_id = 1)
	
		if (@Tipo=0) -- InBound
		begin			
			insert into ccCalifCamp(calif_id,cam_id,tipo)
			select @calif_id as calif_id, Inbound_id, 0 as tipo from ccInbound
			where inbound_id in (select cam_id from ccSupervisorCam where tipo = 0 and user_id = @user_id) or @user_id = 1
		end
	
		if (@Tipo=1) -- OutBound
		begin	
			insert into ccCalifCamp(calif_id,cam_id,tipo)
			select @calif_id as calif_id, cam_id, 1 as tipo from ccCamps
			where cam_id in (select cam_id from ccSupervisorCam where tipo = 0 and user_id = @user_id) or @user_id = 1
		end
	end
end'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_ADMAddCalif - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ADMAddCalif]
@calif_id smallint, --Id Calificacion
@Tipo tinyint, --0=In, 1=Out
@cam_id smallint=0, --Inbound_id, or cam_id, si es 0 la Agrega a Todos
@orden smallint=0 --Orden en la Lista  Si son todas, se va en 0
AS

if ( @calif_id >0 and ( @Tipo=1or @Tipo=0 ) )
begin
	if ( @cam_id>0 ) -- Agrega Una a una Campañas  por Tipo
		insert into ccCalifCamp (calif_id,cam_id,tipo) values ( @calif_id, @cam_id, @Tipo )
	
	if (@cam_id=0 )   -- Agrega Una a Todas las Campañas por Tipo
	begin
		delete ccCalifCamp where calif_id=@calif_id and tipo=@Tipo
	
		if (@Tipo=0) -- InBound
		begin			
			insert into ccCalifCamp(calif_id,cam_id,tipo)
			select @calif_id as calif_id, Inbound_id, 0 as tipo from ccInbound
		end
	
		if (@Tipo=1) -- OutBound
		begin	
			insert into ccCalifCamp(calif_id,cam_id,tipo)
			select @calif_id as calif_id, cam_id, 1 as tipo from ccCamps
		end
	end
end'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIAccSettingsConfig - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null 
AS
set nocount on

declare @idioma tinyint
declare @activeChat tinyint

select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145

if @command=0
 begin
	SELECT case @idioma when 0 then descripcion else [description] end descripcion 
	FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
	order by descripcion
	return(0)
 end

if @command=1
 begin
	Select setting_id, case @idioma when 0 then descripcion else [description] end descripcion, valor, tipo
	from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'') 
	and (setting_id not in (139,140,141)
	or   setting_id     in (139,140,141) and @activeChat > 0)
	order by tipo, descripcion
	return(0)
 end

if @command=2
 begin
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
 end

set nocount off'
		
	EXEC(@Sql)

		set @process = 'ccsp_RIAMenuRoles - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on
select @reportRol = case @reportRol when 0 then 1 else @reportRol end, 
 @role_id = case @role_id when 0 then 1 else @role_id end

select @AE = valor from ccsettings where setting_id = 71

Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint

select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145


If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id 
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin
	if @Role_id in (1, 10) and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	 begin
		Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
		if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)
					Insert into ccMenuUser values(@User_id,40,1)
		else If not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999))
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, 2 from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
		
	 end

	else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
	 begin
		if @InsertMenu_id <> 40
			  delete ccMenuUser where id_User = @User_id and type = @reportRol

		Insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
		If @reportRol = 1
			  Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,1)
	 end

	If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

	--    inserta parent en caso de no haberlo hecho en rol personalizado        
	Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
	(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
	where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
	where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

	return(0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
  Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

      else
            insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
      select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))  
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))  
	  order by ordengral asc
      return(0)
 end

If @Type = 7 -- Get language
 begin
      select valor from ccSettings where setting_id = 27
      return(0)
 end

If @Type = 8 -- Insert the personalized menus of a supervisor
 begin
      insert into ccMenuUser (id_User, id_Menu, type)
      select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
       begin
            Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
            return(0)
       end

      insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 9 -- Delete all supervisor menus 
 begin
      delete ccMenuUser where id_User = @User_id and type = @reportRol
      return(0)
 end

If @Type = 10 -- Delete all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, 2 from               
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id
      where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol 
      group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

      return(0)
 end

If @Type = 12
 begin
      declare @lan as tinyint
      select @lan = valor from ccSettings where setting_id = 27
      select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
      return(0)
 end

return(0)
set nocount off'
		
	EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
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
