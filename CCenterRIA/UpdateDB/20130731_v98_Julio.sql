/*
Autor: Raymundo Gonzalez
Fecha: 2013/07/31
Descripcion:
	Se crea la tabla ccRateByCarrier para configuracion de tarifas por zona
	Se insertan registros en la tabla cstoTipoLlamada para configuracion de tarifas por zona
	Se inserta registro en la tabla ccsettings para nombre del servidor de replicas de AVRS
	Se actualiza la tabla ccMenus para descripcion de Formatos de Calificacion
	Se actualiza la tabla ccsettings 119 y 131 para agente remoto y local
	Se modifica la tabla ccTideWater_Templates para guardar valores de template
	Se crea el SP ccsp_RIACatRatesCarriers para configuracion de tarifas por zona
	Se modifica el SP ccsp_RIANotReadyEsp para configuracion de not ready por campañas y especialidades
	Se modifica el SP ccsp_TideWater_ABCTemplate para guardar valores de template
	Se modifica el SP ccsp_TideWater_cargaTemplate para guardar valores de template
	se modifica el SP ccsp_ExtAppsGetDialInfo para Web Service
	Se modifica el SP ccsp_ExtAppsCallHistory para Web Service
	Se modifica el SP ccsp_SaveStatusAgent para cambio en tipo de dato del parametro tStatus
	Se modifica el SP ccsp_RIACATMenu para cambio en lectura de menus de usuario
	
Version requerida: 97
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '98'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------
	
		set @process = 'ccRateByCarrier - Create Table'
		set @Sql='create table ccRateByCarrier(
	tipoLlamada_id [smallint] NOT NULL,
	estado [varchar](255) NOT NULL,
	lada [varchar](255) NOT NULL
	PRIMARY KEY (tipoLlamada_id,estado,lada)
)'
			
	EXEC(@Sql)

		set @process = 'cstoTipoLlamada - Insert'
		set @Sql='insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values(1,8,''On Net'',10,''%'')
insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values(1,9,''Off Net'',10,''%'')
insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values(1,10,''On Ring'',10,''%'')
insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values(1,11,''Triangle'',10,''%'')'
			
	EXEC(@Sql)
	
		set @process = 'ccSettings - Insert'
		set @Sql='INSERT INTO ccSettings (setting_id ,valor ,descripcion ,Status ,Tipo ,detalle ,description ,bLoadSettings) 
VALUES (138 ,'''' ,''Ip AVRS para Replicacion'' ,1 ,''X'' ,''Alias del servidor de suscripcion de replicas'' ,''Subscription Server Name Alias for replication'' ,1)'

	EXEC(@Sql)


		set @process = 'ccMenus - Update'
		set @Sql='UPDATE ccMenus
SET menu_descrip = ''Formatos de calificacion| Scoring Templates''
WHERE menu_id = 74'
			
	EXEC(@Sql)

		set @process = 'ccSettings - Update'
		set @Sql='update ccsettings set bloadsettings = 1 where setting_id = 66
update ccsettings set valor = 5061, bLoadSettings = 1 where setting_id = 119
update ccsettings set valor = ''2|2|1|0'' where setting_id = 131'
		
	EXEC(@Sql)
	
		set @process = 'ccTideWater_Templates - Alter Table'
		set @Sql='alter table ccTideWater_Templates add hasHeader bit default(0)
alter table ccTideWater_Templates add nameList varchar(255) '
			
	EXEC(@Sql)
	
		set @process = 'ccsp_RIACatRatesCarriers - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIACatRatesCarriers]
@type tinyint,
@tipoLlamada_id smallint = 0,
@estado varchar(max) = '''',
@lada varchar(max) = ''''
AS

set nocount on

--- Obtiene Tarifas 
if @type = 1 begin	
	select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = 1 and tipoLlamada_id in(8,9,10,11)
end
-- Obtine la lista de ladas y los estados
if @type = 2 begin
	select distinct(series.estado) as estado, series.cld as lada 
	from series 
	left join ccRateByCarrier rate on series.cld=rate.lada
	where rate.lada is null

end
--Regresa la relacion de tipos de llamadas y las ladas
if @type = 3 begin
	select estado,lada from ccRateByCarrier where tipoLlamada_id = @tipoLlamada_id
end
--Inserta la relacion tarifas y ladas y estados
if @type = 4 begin
	delete ccRateByCarrier where [tipoLlamada_id] = @tipoLlamada_id

	insert into ccRateByCarrier
			select @tipoLlamada_id,estado.value,lada.value
				from fn_RIASplitDelimited (@estado, ''|'')  as estado
				inner join fn_RIASplitDelimited (@lada, ''|'')  as lada
				on estado.id = lada.id
end
-- Borra la relacion estados y lada con el tipo de llamada
if @type = 5 begin	
	delete ccRateByCarrier
		from ccRateByCarrier as rate
		inner join fn_RIASplitDelimited (@estado, ''|'')  as tEstado on tEstado.value =  rate.estado
		inner join fn_RIASplitDelimited (@lada, ''|'')  as tLada on tLada.value =  rate.lada
		where [tipoLlamada_id] = @tipoLlamada_id
	 
end'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_RIANotReadyEsp - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIANotReadyEsp]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InOut_Id smallint,
@InsertNotReady_id varchar(1000),
@DeleteNotReady_id varchar(1000)
AS
set nocount on


If @Type=1 --get camps
 begin
	SELECT a1.cam_id, a1.cam_descripcion, a3.frame,CASE a1.CallsBySurvey WHEN 0 THEN 0 ELSE 1 END as ''CallsBySurvey''  FROM ccCamps a1
	inner join ccRIACampsGraph a2 on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(IDArea, -1) = case 
	when @IDArea = 0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

If @Type=2 --get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=3 --query
 begin
	If(@Type2=0) --ACDGroup
	 begin
		select c.Inbound_id, c.Descripcion as c_Descripcion, nr.TipoNotReady_id, nr.Descripcion as nr_Descripcion, nr.Time_Acum, nr.Time_xEv
	 	from ccInbound c
		inner join ccTipoNotReadyInbound nri on c.Inbound_id = nri.Inbound_id
	 	inner join ccTipoNotReady nr on nr.TipoNotReady_id = nri.TipoNotReady_id
	 	where c.inbound_id=@CamEspID
		and status=1
		ORDER BY 4
	 end

	If(@Type2=1) --Camp
	 begin
	  	select c.Cam_id, c.Cam_descripcion as c_Descripcion, nr.TipoNotReady_id, nr.Descripcion as nr_Descripcion, nr.Time_Acum, nr.Time_xEv
	 	from ccCamps c
		inner join ccTipoNotReadyCamps nrc on c.Cam_id = nrc.Cam_id
	 	inner join ccTipoNotReady nr on nr.TipoNotReady_id = nrc.TipoNotReady_id
	 	where c.cam_id=@CamEspID
		ORDER BY 4
	 end
 end

If @Type=4
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql as nvarchar(1000), @nIDArea as varchar(10)

if @Type=5 --Insert NotReadys
 begin
	If @Type2=3
	 begin
		If exists(select inbound_id from ccTipoNotReadyInbound where inbound_id=@CamEspID and TipoNotReady_id=@InsertNotReady_id)
			select 2
		else
			insert ccTipoNotReadyInbound(inbound_id, TipoNotReady_id) select @CamEspID, @InsertNotReady_id
		return(0)
	 end

	If @Type2=2
	 begin
		If exists(select cam_id from ccTipoNotReadyCamps where cam_id=@CamEspID and TipoNotReady_id=@InsertNotReady_id)
			select 2
		else
			insert ccTipoNotReadyCamps(cam_id, TipoNotReady_id) select top 1 @CamEspID, @InsertNotReady_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0 --ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccTipoNotReadyInbound
			select distinct a.inbound_id, b.TipoNotReady_id from ccInbound a, ccTipoNotReady b where
			b.TipoNotReady_id in(''+@InsertNotReady_id+'')
			and not exists(select c.inbound_id, e.TipoNotReady_id from ccTipoNotReadyInbound c
			join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea is null
			where c.inbound_id=a.inbound_id and b.TipoNotReady_id=e.TipoNotReady_id)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccTipoNotReadyInbound select distinct a.inbound_id, b.TipoNotReady_id 
		from ccInbound a, ccTipoNotReady b where b.TipoNotReady_id in(''+@InsertNotReady_id+'')
		and not exists(select c.inbound_id, e.TipoNotReady_id from ccTipoNotReadyInbound c
		join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
		join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
		'' where c.inbound_id=a.inbound_id and b.TipoNotReady_id=e.TipoNotReady_id)
		and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1 --Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccTipoNotReadyCamps
			select distinct a.cam_id, b.TipoNotReady_id from ccCamps a, ccTipoNotReady b where
			b.TipoNotReady_id in(''+@InsertNotReady_id+'')
			and not exists(select c.cam_id, e.TipoNotReady_id from ccTipoNotReadyCamps c
			join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
			join ccCamps d on d.cam_id=c.cam_id and IDArea is null
			where c.cam_id=a.cam_id and b.TipoNotReady_id=e.TipoNotReady_id)
			and a.cam_id in(select x.cam_id from ccCamps x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccTipoNotReadyCamps select distinct a.cam_id, b.TipoNotReady_id
		from ccCamps a, ccTipoNotReady b where b.TipoNotReady_id in(''+@InsertNotReady_id+'')
		and not exists(select c.cam_id, e.TipoNotReady_id from ccTipoNotReadyCamps c
		join ccTipoNotReady e on e.TipoNotReady_id=c.TipoNotReady_id
		join ccCamps d on d.cam_id=c.cam_id and IDArea=''+@nIDArea+
		'' where c.cam_id=a.cam_id and b.TipoNotReady_id=e.TipoNotReady_id)
		and a.cam_id in(select x.cam_id from ccCamps x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

If @Type=6 --Delete NotReadys
 begin
	If @Type2=3
	 begin
		delete ccTipoNotReadyInbound where inbound_id=@CamEspID	and TipoNotReady_id=@DeleteNotReady_id
		return(0)
	 end

	If @Type2=2
	 begin
		delete ccTipoNotReadyCamps where cam_id=@CamEspID and TipoNotReady_id=@DeleteNotReady_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0 --ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccTipoNotReadyInbound where inbound_id in(select inbound_id from 
			ccInbound where IDArea is null) and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccTipoNotReadyInbound where inbound_id in(select inbound_id from 
		ccInbound where IDArea=''+@nIDArea+'') and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1 --Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccTipoNotReadyCamps
			where cam_id in(select cam_id from ccCamps where IDArea is null)
			and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccTipoNotReadyCamps
		where cam_id in(select cam_id from ccCamps where IDArea=''+@nIDArea+'')
		and TipoNotReady_id in(''+@DeleteNotReady_id+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end
if @type = 7
begin
	select TipoNotReady_id, Descripcion from ccTipoNotReady where statustiponotready = 1
end
return(0)
set nocount off'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_TideWater_ABCTemplate - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_TideWater_ABCTemplate]
@Type tinyint, -- 1:add | 2:delete | 3:update
@Temp_id smallint = NULL,
@Temp_Desc varchar(80) = NULL,
@ConnString varchar(100) = NULL,
@PathFile varchar(100) = NULL,
@User_id smallint = NULL,
@cam_id smallint = NULL,
@TableName varchar(50) = NULL,
@Tipo_Filtro tinyint = NULL,	-- Verificar en: select * from ccTipoFiltro
@AceptaCel bit = 0,
@tipo_Con tinyint = 0,
@Where_Array varchar(8000) = NULL,
@idtipolista_array varchar(4000) = NULL,
@cal_Key_col varchar(35) = NULL,
@cal_telefonos varchar(255) = NULL,
@ColumnAssigned varchar(2000) = NULL,
@cal_callback_col varchar(35) = NULL,
@hasHeader bit = NULL,
@nameList varchar(255) = NULL

as
set nocount on
if @Type=1 -- add
 begin
	if isnull(@Temp_Desc,'''')='''' or isnull(@TableName,'''')='''' or isnull(@cal_Key_col,'''')=''''
	 begin
		raiserror(''ERROR. invalid input data'', 18, 2)
		return(0)
	 end

	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror(''ERROR. invalid user id'', 18, 1)
		return(0)
	 end

	if not exists(select cam_id from ccCamps where cam_activo=1 and cam_id=@cam_id and 
	 IDArea in (select IDArea from ccUsers where User_id=@User_id))
	 begin
		raiserror(''ERROR. invalid campaign'', 18, 1)
		return(0)
	 end

	if (select COUNT(id) from dbo.fn_RIASplitDelimited(@cal_telefonos, '',''))<>5
	 begin
		raiserror(''ERROR. invalid telephone array'', 18, 1)
		return(0)
	 end

	if (select COUNT(id) from dbo.fn_RIASplitDelimited(@ColumnAssigned, '',''))<>
	 (select COUNT(id) from ccodatos) and isnull(@ColumnAssigned,''&'')<>''&''
	 begin
		raiserror(''ERROR. invalid aditional data array'', 18, 1) 
		return(0)
	 end

	if not exists(select Tipo_Filtro from ccTipoFiltro where Status_Filtro=1 and Tipo_Filtro=@Tipo_Filtro)
	 begin
		raiserror(''ERROR. invalid filter'', 18, 1)
		return(0)
	 end
		
	insert ccTideWater_Templates (Temp_Desc, ConnString, PathFile, User_id, cam_id, TableName, Tipo_Filtro, 
	 AceptaCel, tipo_Con, Where_Array, idtipolista_array, cal_Key_col, cal_telefono_col, cal_telefono2_col, 
	 cal_telefono3_col, cal_telefono4_col, cal_telefono5_col, cal_callback_col, hasHeader, nameList)
	select @Temp_Desc, @ConnString, @PathFile, @User_id, @cam_id, @TableName, @Tipo_Filtro, 
	 @AceptaCel, @tipo_Con, @Where_Array, @idtipolista_array, @cal_Key_col, 
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5),	 
	 @cal_callback_col,@hasHeader,@nameList

	select @Temp_id=SCOPE_IDENTITY()
	if isnull(@Temp_id,0)=0
	 begin
		raiserror(''ERROR. insert can not be reached'', 18, 2)
		return(0)
	 end

	if isnull(@ColumnAssigned,''&'')<>''&''
	 begin
		insert ccTideWater_Templates_Cols (Temp_id, id, ColumnAssigned)
		 select @Temp_id, D.id, S.value from ccodatos D join dbo.fn_RIASplitDelimited(@ColumnAssigned, '','') S 
		 on D.id=S.id order by D.id

		if @@ROWCOUNT<1
		 begin
			delete ccTideWater_Templates where Temp_id=@Temp_id
			raiserror(''ERROR. insert 2 can not be reached'', 18, 1)
			return(0)
		 end
	 end

	select @Temp_id
	return(0)
 end

if @Type=2 -- delete
 begin
	if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
	 begin
		raiserror(''ERROR. invalid template ID'', 18, 1)
		return(0)
	 end

	update ccTideWater_Templates set TempStatus=0 where Temp_id=@Temp_id
	return(0)
 end

if @Type=3 -- update
 begin
	if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
	 begin
		raiserror(''ERROR. invalid template ID'', 18, 1) 
		return(0)
	 end 

	begin tran upd
	update ccTideWater_Templates set 
	 Temp_Desc=isnull(@Temp_Desc,Temp_Desc),
	 ConnString=isnull(@ConnString,ConnString),
	 PathFile=isnull(@PathFile,PathFile),
	 User_id=isnull(@User_id,User_id),
	 cam_id=isnull(@cam_id,cam_id),
	 TableName=isnull(@TableName,TableName),
	 Tipo_Filtro=isnull(@Tipo_Filtro,Tipo_Filtro),
	 AceptaCel=isnull(@AceptaCel,AceptaCel),
	 tipo_Con=isnull(@tipo_Con,tipo_Con),
	 Where_Array=isnull(@Where_Array,Where_Array),
	 idtipolista_array=isnull(@idtipolista_array,idtipolista_array),
	 cal_Key_col=isnull(@cal_Key_col,cal_Key_col),

--	 cal_telefono_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1) = ''''
--	  then cal_telefono_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1) end,
--
--	 cal_telefono2_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2) = ''''
--	  then cal_telefono2_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2) end,
--
--	 cal_telefono3_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3) = ''''
--	  then cal_telefono3_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3) end,
--
--	 cal_telefono4_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4) = ''''
--	  then cal_telefono4_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4) end,
--
--	 cal_telefono5_col= case when (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5) = ''''
--	  then cal_telefono5_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5) end,

	 cal_telefono_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=1),
	 cal_telefono2_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=2),
	 cal_telefono3_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=3),
	 cal_telefono4_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=4),
	 cal_telefono5_col= (select isnull(value,'''') from dbo.fn_RIASplitDelimited(@cal_telefonos, '','') where id=5),

	 cal_callback_col=isnull(@cal_callback_col,cal_callback_col),

	hasHeader = isnull(@hasHeader,hasHeader),
	nameList = isnull(@nameList,nameList)
	where Temp_id=@Temp_id
	 
	if @@Rowcount<0	 
	 begin
		raiserror(''ERROR. update can not be reached'', 18, 2) 
		return(0)
	 end 

	if isnull(@ColumnAssigned,''&'')<>''&''
	 begin
		update ccTideWater_Templates_Cols set ccTideWater_Templates_Cols.ColumnAssigned=S.value 
		from ccodatos D join dbo.fn_RIASplitDelimited(@ColumnAssigned, '','') S on D.id=S.id 
		where /*isnull(S.value,'''')<>'''' and*/ ccTideWater_Templates_Cols.Temp_id=@Temp_id and S.id=ccTideWater_Templates_Cols.id

		if @@ROWCOUNT=0
		 begin
			raiserror(''ERROR. update 2 can not be reached'', 18, 1) 
			rollback tran upd
			return(0)
		 end
	 end

	commit tran upd
	return(0)
 end

set nocount off'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_TideWater_cargaTemplate - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_TideWater_cargaTemplate]
-- @Type = 1:Catalogo de Templates | 2:Detalle de Template | 3:Tipo de datos de Template
@Type tinyint, 
@User_Id smallint = null, 
@Temp_id smallint = null 
AS
set nocount on
if @Type not in (1,2,3,4) or (isnull(@User_Id,0)=0 and isnull(@Temp_id,0)=0)
	raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

Declare @idioma tinyint
select @idioma=valor from ccsettings where setting_id=27

if @Type=1 -- Catalogo de Templates
 begin
 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror(''ERROR. invalid user id'', 18, 1)
		return(0)
	 end

	Select T.Temp_ID, T.Temp_Desc, C.Cam_Descripcion, 
	Nombres + ISNULL('' ''+ApellidoPaterno, '''') + ISNULL('' ''+ApellidoMaterno, '''') Admin_Name
	From ccTideWater_Templates T join ccUsers U on T.User_id=U.User_id
	 join ccCamps C on T.cam_id = C.cam_id
	Where U.TipoUser_id in (2,6) and T.TempStatus=1 and T.cam_id in
	 (Select cam_id From ccCamps Where IDArea in (Select IDArea From ccUsers Where User_id=@User_Id))
	return(0)
 end

if @Type=2 -- Detalle de Template
 begin
	if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
	 begin
		raiserror(''ERROR. invalid template ID'', 18, 1)
		return(0)
	 end

	Select T.Temp_id, T.Temp_Desc, T.ConnString, T.PathFile, T.cam_id, T.TableName, T.Tipo_Filtro,
	 case @idioma when 0 then left(F.Desc_Filtro, charindex(''|'', F.Desc_Filtro)-1) else 
	 substring(F.Desc_Filtro, charindex(''|'', F.Desc_Filtro)+1, len(F.Desc_Filtro)) end Desc_Filtro,
	 T.AceptaCel, T.Where_Array, T.idtipolista_array, T.tipo_Con, isnull(T.hasHeader,0) as hasHeader, isnull(T.nameList,'''') as nameList
	From ccTideWater_Templates T join ccTipoFiltro F on T.Tipo_Filtro=F.Tipo_Filtro
	Where T.TempStatus=1 and T.Temp_id=@Temp_id
	return(0)
 end

if @Type=3 -- Tipo de datos de Template
 begin
	if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
	 begin
		raiserror(''ERROR. invalid template ID'', 18, 1)
		return(0)
	 end

	declare @Tied_Datos table (Campo_ID int identity, Nombre varchar(35), ColumnAssigned varchar(35))

	insert @Tied_Datos Select ''cal_Key'', cal_Key_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select ''cal_telefono'', cal_telefono_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select ''cal_telefono2'', cal_telefono2_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select ''cal_telefono3'', cal_telefono3_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select ''cal_telefono4'', cal_telefono4_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select ''cal_telefono5'', cal_telefono5_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id

	insert @Tied_Datos select D.Nombre, C.ColumnAssigned From ccoDatos D left join ccTideWater_Templates_Cols C
	 on D.id = C.id and C.Temp_id in(select Temp_id From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id) Where D.visible=1 

	insert @Tied_Datos Select ''cal_callback'', cal_callback_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	select Nombre, ColumnAssigned from @Tied_Datos where (select count(ColumnAssigned) from @Tied_Datos)>0
	
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
	select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual,  cal_key as callKey
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
		select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
		d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual, cal_key as callKey
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
	
		set @process = 'ccsp_ExtAppsGetDialInfo - Drop Procedure'
		set @Sql='IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccsp_ExtAppsGetDialInfo]'') AND type in (N''P'', N''PC''))
DROP PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]'

	EXEC(@Sql)

		set @process = 'ccsp_ExtAppsGetDialInfo - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
@action tinyint = 0,
@logDial_id int = null
As
Begin

	If @action = 1 begin
		select count(*) from ccologdials with(nolock) where logDial_id >= @logDial_id
	end

	if @action = 2 begin
		select top 500 logDial_id, callout_id, isnull(c.cam_descripcion,a.cam_id) as camId, isnull(b.descripcion,''Unknown'') as DialResult, Telefono, fecha, tDialing, tBusy, isnull(cal_id,0) as cal_id 
		from ccologdials a with(nolock) 
		inner join ccTipoResultadoDial b 		
		on a.tiporesdial_id = b.tiporesdial_id		
		inner join ccCamps c
		on a.cam_id = c.cam_id		
		where logDial_id >= @logDial_id
	end

End'
			
	EXEC(@Sql)
	
		set @process = 'ccsp_SaveStatusAgent - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus int,
@TipoCall  tinyint,
@Camp smallint
AS
declare @Fecha4 datetime
set @Fecha4 = getdate()

if @TipoCall > 0
	set @TipoCall = @TipoCall - 1

if (@User_id > 0 )
begin
	if (@TipoStatusAge_id=4) -- 4 = Dialogo
	 begin
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id
	 end

	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall )

	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )			
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
			
			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
				
	EXEC(@Sql)
	
			set @process = 'ccsp_RIACATMenu - Alter Procedure'
			set @Sql='ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125

if @Type=1
begin
	if @ReportRol <> 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	and ((menu_id not in (41,42,53,71,72,73,74,75,76,77,78)) 
	or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	or (menu_id in (71,72) and @IVRScripting = 1)
	or (menu_id in (73,74,75,76) and @AVRS = 1)
	or (menu_id in (77,78) and @RelationCampInbNotReady = 1))
	order by ordengral asc
	return(0)


	--if @AVRS = 1
	--begin
	--	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	--	and ((menu_id not in (41,42,53,71,72,77,78)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	--	or (menu_id = 77 and @RelationCampInbNotReady = 1) or (menu_id = 78 and @RelationCampInbNotReady = 1)
	--	or (menu_id = 71 and @IVRScripting = 1) or (menu_id = 72 and @IVRScripting = 1))
	--	order by ordengral asc
	--	return(0)
	--end
	--else
	--begin
	--	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	--	and ((menu_id not in (41,42,53,71,72,73,74,75,76,77,78)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	--	or (menu_id = 77 and @RelationCampInbNotReady = 1) or (menu_id = 78 and @RelationCampInbNotReady = 1)
	--	or (menu_id = 71 and @IVRScripting = 1) or (menu_id = 72 and @IVRScripting = 1))
	--	order by ordengral asc
	--	return(0)
	--end
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
