CREATE procedure [dbo].[ccsp_TideWater_ABCTemplate]
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
	if isnull(@Temp_Desc,'')='' or isnull(@TableName,'')='' or isnull(@cal_Key_col,'')=''
	 begin
		raiserror('ERROR. invalid input data', 18, 2)
		return(0)
	 end

	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror('ERROR. invalid user id', 18, 1)
		return(0)
	 end

	if not exists(select cam_id from ccCamps where cam_activo=1 and cam_id=@cam_id and 
	 IDArea in (select IDArea from ccUsers where User_id=@User_id))
	 begin
		raiserror('ERROR. invalid campaign', 18, 1)
		return(0)
	 end

	if (select COUNT(id) from dbo.fn_RIASplitDelimited(@cal_telefonos, ','))<>5
	 begin
		raiserror('ERROR. invalid telephone array', 18, 1)
		return(0)
	 end

	if (select COUNT(id) from dbo.fn_RIASplitDelimited(@ColumnAssigned, ','))<>
	 (select COUNT(id) from ccodatos) and isnull(@ColumnAssigned,'&')<>'&'
	 begin
		raiserror('ERROR. invalid aditional data array', 18, 1) 
		return(0)
	 end

	if not exists(select Tipo_Filtro from ccTipoFiltro where Status_Filtro=1 and Tipo_Filtro=@Tipo_Filtro)
	 begin
		raiserror('ERROR. invalid filter', 18, 1)
		return(0)
	 end
		
	insert ccTideWater_Templates (Temp_Desc, ConnString, PathFile, User_id, cam_id, TableName, Tipo_Filtro, 
	 AceptaCel, tipo_Con, Where_Array, idtipolista_array, cal_Key_col, cal_telefono_col, cal_telefono2_col, 
	 cal_telefono3_col, cal_telefono4_col, cal_telefono5_col, cal_callback_col, hasHeader, nameList)
	select @Temp_Desc, @ConnString, @PathFile, @User_id, @cam_id, @TableName, @Tipo_Filtro, 
	 @AceptaCel, @tipo_Con, @Where_Array, @idtipolista_array, @cal_Key_col, 
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=1),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=2),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=3),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=4),
	(select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=5),	 
	 @cal_callback_col,@hasHeader,@nameList

	select @Temp_id=SCOPE_IDENTITY()
	if isnull(@Temp_id,0)=0
	 begin
		raiserror('ERROR. insert can not be reached', 18, 2)
		return(0)
	 end

	if isnull(@ColumnAssigned,'&')<>'&'
	 begin
		insert ccTideWater_Templates_Cols (Temp_id, id, ColumnAssigned)
		 select @Temp_id, D.id, S.value from ccodatos D join dbo.fn_RIASplitDelimited(@ColumnAssigned, ',') S 
		 on D.id=S.id order by D.id

		if @@ROWCOUNT<1
		 begin
			delete ccTideWater_Templates where Temp_id=@Temp_id
			raiserror('ERROR. insert 2 can not be reached', 18, 1)
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
		raiserror('ERROR. invalid template ID', 18, 1)
		return(0)
	 end

	update ccTideWater_Templates set TempStatus=0 where Temp_id=@Temp_id
	return(0)
 end

if @Type=3 -- update
 begin
	if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
	 begin
		raiserror('ERROR. invalid template ID', 18, 1) 
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

--	 cal_telefono_col= case when (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=1) = ''
--	  then cal_telefono_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=1) end,
--
--	 cal_telefono2_col= case when (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=2) = ''
--	  then cal_telefono2_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=2) end,
--
--	 cal_telefono3_col= case when (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=3) = ''
--	  then cal_telefono3_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=3) end,
--
--	 cal_telefono4_col= case when (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=4) = ''
--	  then cal_telefono4_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=4) end,
--
--	 cal_telefono5_col= case when (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=5) = ''
--	  then cal_telefono5_col else (select value from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=5) end,

	 cal_telefono_col= (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=1),
	 cal_telefono2_col= (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=2),
	 cal_telefono3_col= (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=3),
	 cal_telefono4_col= (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=4),
	 cal_telefono5_col= (select isnull(value,'') from dbo.fn_RIASplitDelimited(@cal_telefonos, ',') where id=5),

	 cal_callback_col=isnull(@cal_callback_col,cal_callback_col),

	hasHeader = isnull(@hasHeader,hasHeader),
	nameList = isnull(@nameList,nameList)
	where Temp_id=@Temp_id
	 
	if @@Rowcount<0	 
	 begin
		raiserror('ERROR. update can not be reached', 18, 2) 
		return(0)
	 end 

	if isnull(@ColumnAssigned,'&')<>'&'
	 begin
		update ccTideWater_Templates_Cols set ccTideWater_Templates_Cols.ColumnAssigned=S.value 
		from ccodatos D join dbo.fn_RIASplitDelimited(@ColumnAssigned, ',') S on D.id=S.id 
		where /*isnull(S.value,'')<>'' and*/ ccTideWater_Templates_Cols.Temp_id=@Temp_id and S.id=ccTideWater_Templates_Cols.id

		if @@ROWCOUNT=0
		 begin
			raiserror('ERROR. update 2 can not be reached', 18, 1) 
			rollback tran upd
			return(0)
		 end
	 end

	commit tran upd
	return(0)
 end

set nocount off