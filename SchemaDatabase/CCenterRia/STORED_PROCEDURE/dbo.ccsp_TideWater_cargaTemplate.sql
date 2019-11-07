CREATE procedure [dbo].[ccsp_TideWater_cargaTemplate]
-- @Type = 1:Catalogo de Templates | 2:Detalle de Template | 3:Tipo de datos de Template
@Type tinyint, 
@User_Id smallint = null, 
@Temp_id smallint = null 
AS
set nocount on
if @Type not in (1,2,3,4) or (isnull(@User_Id,0)=0 and isnull(@Temp_id,0)=0)
	raiserror('ERROR. No se ingreso parametro de entrada', 18, 1)

Declare @idioma tinyint
select @idioma=valor from ccsettings where setting_id=27

if @Type=1 -- Catalogo de Templates
 begin
 	if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@User_id)
	 begin
		raiserror('ERROR. invalid user id', 18, 1)
		return(0)
	 end

	Select T.Temp_ID, T.Temp_Desc, C.Cam_Descripcion, 
	Nombres + ISNULL(' '+ApellidoPaterno, '') + ISNULL(' '+ApellidoMaterno, '') Admin_Name
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
		raiserror('ERROR. invalid template ID', 18, 1)
		return(0)
	 end

	Select T.Temp_id, T.Temp_Desc, T.ConnString, T.PathFile, T.cam_id, T.TableName, T.Tipo_Filtro,
	 case @idioma when 0 then left(F.Desc_Filtro, charindex('|', F.Desc_Filtro)-1) else 
	 substring(F.Desc_Filtro, charindex('|', F.Desc_Filtro)+1, len(F.Desc_Filtro)) end Desc_Filtro,
	 T.AceptaCel, T.Where_Array, T.idtipolista_array, T.tipo_Con, isnull(T.hasHeader,0) as hasHeader, isnull(T.nameList,'') as nameList
	From ccTideWater_Templates T join ccTipoFiltro F on T.Tipo_Filtro=F.Tipo_Filtro
	Where T.TempStatus=1 and T.Temp_id=@Temp_id
	return(0)
 end

if @Type=3 -- Tipo de datos de Template
 begin
	if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@Temp_id)
	 begin
		raiserror('ERROR. invalid template ID', 18, 1)
		return(0)
	 end

	declare @Tied_Datos table (Campo_ID int identity, Nombre varchar(35), ColumnAssigned varchar(35))

	insert @Tied_Datos Select 'cal_Key', cal_Key_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select 'cal_telefono', cal_telefono_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select 'cal_telefono2', cal_telefono2_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select 'cal_telefono3', cal_telefono3_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select 'cal_telefono4', cal_telefono4_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	insert @Tied_Datos Select 'cal_telefono5', cal_telefono5_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id

	insert @Tied_Datos select D.Nombre, C.ColumnAssigned From ccoDatos D left join ccTideWater_Templates_Cols C
	 on D.id = C.id and C.Temp_id in(select Temp_id From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id) Where D.visible=1 

	insert @Tied_Datos Select 'cal_callback', cal_callback_col From ccTideWater_Templates Where TempStatus=1 and Temp_id=@Temp_id
	select Nombre, ColumnAssigned from @Tied_Datos where (select count(ColumnAssigned) from @Tied_Datos)>0
	
	return(0)
 end

set nocount off