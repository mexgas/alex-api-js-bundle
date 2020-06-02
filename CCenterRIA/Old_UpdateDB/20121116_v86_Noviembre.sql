/*
Autor: Raymundo Gonzalez
Fecha: 2012/11/16
Descripcion: 	
	Se insertan los setting 122 para laURL para los errores del AgentWS y 123 para activar o desactivar alerta de cambios en los grupos de trabajo 
	Se modifica el setting de validación de listas negras de '0' a '1' por default en la tabla ccsetting
	Se modifica el SP ccsp_RIACATMenu para correcion a referencia de indice en ccsettings inexistente
	Se modifica el SP ccsp_RIAManageAreas para quuitar relación Workgroup-Agente sin el Area
	Se modifica el SP ccsp_InsertDNCList donde se agrega validacion para depuracion de telefonos en lista negra
	Se modifica el SP ccsp_Limpia donde se elimina validacion de idioma para el pais USA
	Se modifica el SP ccsp_AgentLogINOUT que devuelve el tiempo de login real del agente

Version requerida: 85
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '86'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @Sql='insert into ccsettings values (122,'''',''URL para los errores del AgentWS'',1,''X'',''URL para disparar los errores recibidos por el webservice del agente remoto'',''URL for the errors triggered by the remote agent web service'',0)

insert into ccsettings values (123,''1'',''Activar o desactivar alerta de cambios en los grupos de trabajo'', 1, ''ADM'', ''Activa o desactiva el mensaje de alerta de algún cambio'', ''Enable or Disable the warning message of changes in the WG'',1)

update ccSettings set valor = ''1'' where setting_id = 114'
	
	EXEC(@Sql)

		set @Sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

if @Type=1
 begin
 if @ReportRol <> 1
  begin
  Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
  where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
  return(0)
  end

 Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
 and ((menu_id not in (41,42,53)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1))
 order by ordengral asc
 return(0)
end

if @Type=2
 begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu
  return(0)
 end

if @Type=3
 begin
  insert into ccMenuUser values (@id_User, @id_Menu,1)
  return(0)
 end
 
if @Type=4
 begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
  
  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
 end

set nocount off'

	EXEC(@Sql)

		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
@option tinyint,
@IDArea smallint = 0,
@InsertUserId smallint =null,
@DeleteUserId varchar(255)=null,
@InsertCamId smallint=null,
@DeleteCamId smallint=null,
@InsertACDGroupId smallint=null,
@DeleteACDGroupId smallint=null
as
set nocount on

if @option = 1 -- Insert User Area
 begin
	if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
	 begin
		Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
		return(0)
	 end	
	 
	select 1
	return(0)
 end

if @option = 3 -- Insert camp area
 begin
	if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
	 begin
		Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
		where cam_id = @InsertCamId
		return(0)
	 end

	select 1
	return(0)
 end

if @option = 4 -- Delete camp area
 begin
	delete from ccCampsAgente where cam_id = @DeleteCamId
	delete from ccoDialerCamp where cam_id = @DeleteCamId
	delete from ccoWorkingTable where cam_id = @DeleteCamId
	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
	delete from ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
	 begin
		select -4
		return(0)	 
	 end

	Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
	return(0)
 end

if @option = 5 -- Insert ACDGroup area
 begin
	if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
	 begin
		Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
		return(0)
	 end

	select 1
	return(0)
 end

if @option = 6 -- Delete ACDGroup area
 begin
	delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
	delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
	delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
	delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
	delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

	Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
	select 1
	return(0)
 end

if @option in (2, 9, 10, 11)
 begin
 	declare @Type tinyint
	select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
	
	if @option in (2, 10, 11) -- Delete User area
	 begin
		if @Type = 1 -- Agente
		 begin
			delete from ccCampsAgente where user_id = @DeleteUserId
			delete from ccInboundAgentes where user_id = @DeleteUserId
		 end

		else if @Type in (2, 6) -- Supervisor
		begin
			delete from ccSupervisorCam where user_id = @DeleteUserId
		end

		delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
		
		if @option=2
		 begin
			update ccPosicion set user_id = 0 where user_id = @DeleteUserId
			update ccUsers set IDArea = null where user_id = @DeleteUserId	
		 end
		return(0)
	end

	declare @UserWG varchar(100)
	-- @option = 9 -- Delete User area and get his workgroups

	select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

	if @Type = 1 -- Agente
	 begin
		delete from ccCampsAgente where user_id = @DeleteUserId
		delete from ccInboundAgentes where user_id = @DeleteUserId
	 end

	if @Type in (2, 6) -- Supervisor
	 begin
		delete from ccSupervisorCam where user_id = @DeleteUserId
		delete from ccMenuUser where id_User = @DeleteUserId
	 end

	delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
	update ccPosicion set user_id = 0 where user_id = @DeleteUserId
	
	if @option <> 11
		update ccUsers set IDArea = null where user_id = @DeleteUserId
	
	select @UserWG, @Type
	return(0)
 end

declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

if @option = 7 -- Delete camp area
 begin
 	if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
	 begin
		select -3, @DeleteCamId camp
		return(0)	 
	 end

	select @AllWG = coalesce(@AllWG + '','', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1
	
	delete from ccCampsAgente where cam_id = @DeleteCamId
	delete from ccoWorkingTable where cam_id = @DeleteCamId or callout_id 
	 in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)
	delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
	delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	

	select @CurrentWG = coalesce(@CurrentWG + '','', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

	select @AreaDescripcion = area.AreaName
	from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
	 with(nolock) on camp.IDArea = area.IDArea
	where camp.cam_id = @DeleteCamId
	Update ccCamps set IDArea = null where cam_id = @DeleteCamId

	If @CurrentWG is null
		set @CurrentWG = 0

	If @AllWG is null
		set @AllWG = 0

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
	return(0)
 end

if @option = 8 --Delete ACDGroup area
 begin
	select @AllWG = coalesce(@AllWG + '','', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

	delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
	delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId
	delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
	delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
	delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

	select @CurrentWG = coalesce(@CurrentWG + '','', '''') + CAST(IDWG as varchar(400)) 
	from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

	select @AreaDescripcion = area.AreaName
	from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
	 with(nolock) on ACD.IDArea = area.IDArea
	where ACD.Inbound_id = @DeleteACDGroupId
	Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

	If @CurrentWG is null
		set @CurrentWG = 0

	If @AllWG is null
		set @AllWG = 0

	select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
	return(0)
 end

return(0)
set nocount off'

	EXEC(@Sql)

		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer
AS

declare @ld varchar(4), @tel as varchar(30)

insert into cclistanegra values(@telephone, @ln_id)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL )

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#mytemp](
	[callout_id] [int] NULL, 
    [telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
    [idtipolista] [int] NULL)

CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @ld = valor from ccSettings where setting_id = 17
select @tel = dbo.completa(@telephone)

-----------------------------------------------------------------------------  telefono1
insert #mytemp
select callout_id,cal_telefono,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono = @tel 
and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono= wt.cal_telefono 
	and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
						 + cs.cal_telefono3 + ''         ''
						 + cs.cal_telefono4 + ''         ''
						 + cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
										+ cs.cal_telefono3 + ''         ''
										+ cs.cal_telefono4 + ''         ''
										+ cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set cal_telefono = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp
end

----------------------------------------------------------------------------------- -telefono 2

insert #mytemp
select callout_id,cal_telefono2,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono2 = @tel 
and cal_fechadial >  getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono2= wt.cal_telefono 
	and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
						 + cs.cal_telefono4 + ''         ''
						 + cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
										+ cs.cal_telefono4 + ''         ''
										+ cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono2= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono2 de CS
	update ccoCallsOutSource 
	set cal_telefono2 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp
end

----------------------------------------------------------------------------------- -telefono 3

insert #mytemp
select callout_id,cal_telefono3,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono3 = @tel 
and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono3= wt.cal_telefono  
	and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
						  + cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
										+ cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono3= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono3 de CS
	update ccoCallsOutSource 
	set cal_telefono3 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp

	----------------------------------------------------------------------------------- -telefono 4

	insert #mytemp
	select callout_id,cal_telefono4,cam_id,''3'',@ln_id as idtipolista 
	from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
	where cs.cal_telefono4 = @tel 
	and cal_fechadial > getdate()-30

	-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono4= wt.cal_telefono 
	and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

	-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
	update ccoWOrkingTable 
	set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
	from ccoCallsOutSource cs 
	inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono4= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono4 de CS
	update ccoCallsOutSource 
	set cal_telefono4 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30

	truncate table #mytemp
end

----------------------------------------------------------------------------------- -telefono 5

insert #mytemp
select callout_id,cal_telefono5,cam_id,''3'',@ln_id as idtipolista 
from ccoCallsOutSource cs INNER JOIN #mycamps ca ON (cs.cam_id=ca.campsid)
where cs.cal_telefono5 = @tel 
and cal_fechadial > getdate()-30

if (select count(*) from #mytemp) > 0
begin
	-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
	delete ccoWOrkingTable 
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytemp t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30 
	and cs.cal_telefono5= wt.cal_telefono

	---insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytemp

	-- Eliminamos el telefono5 de CS
	update ccoCallsOutSource 
	set cal_telefono5 = ''''
	from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > getdate()-30
end

drop table #mytemp
drop table [dbo].[#mycamps]'

	EXEC(@Sql)

		set @Sql = 'ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(30),
@Camp int = 0
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint 
select @tel = dbo.limpia(@tel)
select @lon = len(@tel)
select @ld = valor from ccsettings where setting_id = 17
select @pais = valor from ccsettings where setting_id = 104
select @extLen = valor from ccsettings where setting_id = 108
declare @telTemp as varchar(15)

if @extLen=@lon and @lon>1
 begin
	select 0 as res, @tel as tel -- Extension
	return(0)
 end	
	
if @pais = 1 
 begin
	if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
	 begin
		select 1 as res, @tel as tel --Longitud invalida
		return(0)
	 end

	if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
	 begin
		select 2 as res, @tel as tel--Digitos incorrectos
		return(0)
	 end

	if left(@tel, 3) = ''001'' 
	 begin
		select 0 as res, @tel as tel
		return(0)
	 end

	declare @mod varchar(5)
	select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
	select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

	if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
	on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	 begin
		select 4 as res, @tel as tel
		return(0)
	 end 

	if @mod = ''CPP'' 
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
		return(0)
	 end

	if @mod in (''FIJO'', ''MPP'') 
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
		return(0)
	 end

	--if @mod is null 
	select 3 as res, @tel as tel--No encontrado					
	return(0)
 end

if @pais = 2 
 begin	
	select @telTemp = @tel
	set @tel = dbo.completa(@tel)
	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return
	end

	select @tel = dbo.fnClearPhoneArg(@tel)

	if len(@tel) = 10 and left(@tel,1) <> ''E'' begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	   begin				
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end else begin
			select 4 as res, @tel
			return(0)
		end
	end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos 
 end

if @pais = 3 
 begin
	select @telTemp = @tel
	if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	end
	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 4
 begin
	exec ccsp_LimpiaUsa @tel, @Camp
	return(0)
 end

if @pais = 5 
 begin	
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if len(@tel) in(8,9) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 6
 begin
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)


	if len(@tel) = 10 and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end

if @pais = 7
 begin	
	select @telTemp = @tel
	if left(@tel,1)=''E'' 
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E'' 
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin		 		
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end 
		else 
		 begin
			select 4 as res, @tel
			return(0)
		 end		
	 end 
	else 
	 begin 
		select 2 as res, @telTemp as tel 
	 end --Digitos incorrectos 
 end


if @pais = 8
 begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)

	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return (0)
	end

	if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
	begin
		if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		begin
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end
		else 
		begin
			select 4 as res, @tel
			return(0)
		end
	end
 end

set nocount off'

	EXEC(@Sql)

		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentLogINOUT]
@UserID smallint,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@TipoMov tinyint	-- 0= LogOut,  1=LogIN,	3=Consulta 
AS
set nocount on

declare @hourlogin   varchar(8)
declare @sessionsecs int
declare @sessiontime varchar(8)
declare @fecha_ini datetime

IF  @TipoMov=1
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov ) Values( @UserID, @Extension, 1)
	Update ccPosicion Set User_id=@UserID Where Computer =@Computer
	update ccPOsicion set user_id = 0 where Computer <> @Computer and user_id = @UserId
	update ccUsers set TipoStatusAge_id=3 where User_id=@UserID

	if exists(select valor from ccSettings where tipo=''AGT'' and Status=''1'' and setting_id=''53'' and valor=2)
	 begin
	 	if not exists (select axLic_Desc from axLicG729_Data where axLic_Status=1 and pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid))
		 begin
	 		raiserror(''Error. Without License'', 18, 1)
			return(0)
		 end

		update axLicG729_Data set axLic_Status=2 where axLic_Status=1 and pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid)
		select ''0'' CPLic
		return(0)
	 end

	return(0)
 END

IF @TipoMov=0
 BEGIN
	Insert ccLogLogIn ( User_id, Extension, TipoMov ) Values( @UserID, @Extension, 0 )
	Update ccPosicion Set User_id= 0 Where Computer =@Computer or user_id = @Userid
	update ccUsers set TipoStatusAge_id=0 where User_id=@UserID
	
	if exists(select valor from ccSettings where tipo=''AGT'' and Status=''1'' and setting_id=''53'' and valor=2)
	 begin
		update axLicG729_Data set axLic_Status=0, pos_id=null, fecha_log=null where pos_id in (select pos_id from ccPosicion Where Computer =@Computer or user_id = @Userid)
	 end

	return(0)
 END

IF @TipoMov=3
 BEGIN
    select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

	select @hourlogin = convert(varchar(8), isnull(min(fecha), getdate()), 114) 
	       from ccLogLogin where TipoMov=1 and user_id=@UserID and fecha >= @fecha_ini

    SELECT @sessionsecs = isnull (case 
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0 
			THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))  
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) + 
			         convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END, 0)
		FROM ccLogLogin where user_id=@UserID and fecha > dateadd(hh, -10, getdate())

    SELECT @sessiontime = RIGHT(''0'' + CONVERT(varchar(6),  @sessionsecs / 3600),       2) + '':'' +
                          RIGHT(''0'' + CONVERT(varchar(2), (@sessionsecs % 3600) / 60), 2) + '':'' +
                          RIGHT(''0'' + CONVERT(varchar(2),  @sessionsecs % 60),         2)

    select ''HourLogin'' = @hourlogin, ''SessionTime'' = @sessiontime, ''SessionSecs'' = @sessionsecs
	return(0)
 END
set nocount off'

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
