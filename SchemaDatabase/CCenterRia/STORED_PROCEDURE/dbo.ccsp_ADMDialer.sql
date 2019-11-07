CREATE PROCEDURE [dbo].[ccsp_ADMDialer]
@Descripcion varchar(15),
@dialer_id smallint,
@Port int = 0, -- se cambia tipo de dato
@Status smallint,
@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 3=Eliminar
@provedor_id int=0--by odc
AS
set nocount on
declare @idioma as bit
Select @idioma=isnull(valor,0) from ccSettings where setting_id=27

if @Tipo=1
 begin
	if @provedor_id=0
		select top 1 @provedor_id=provedor_id from cstoProvedor

	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion or Puerto=@Port)
	 begin
		select 0, case @idioma when 1 then 'Name in Use' else 'Nombre en Uso' end
		return(0)
	 end
	
	Insert ccoDialers (Descripcion, Puerto, Status, provedor_id) Select @Descripcion, @Port, @Status, @provedor_id
	select -1, case @idioma when 1 then 'Dialer: ' + upper(@Descripcion) + ' Added Succesfuly'
	else 'Dialer: ' + upper(@Descripcion) + ' Dado de alta' end
	return(0)
 end

if @Tipo=2
 begin
	if exists(select Descripcion from ccoDialers where Descripcion=@Descripcion and dialer_id<>@Dialer_id) or 
	exists(select Puerto from ccoDialers where Puerto=@Port and dialer_id<>@Dialer_id)
	 begin
		select 0, case @idioma when 1 then 'Name or port in Use' else 'Nombre o puerto en Uso' end
		return(0)
	 end

	Update ccoDialers set Descripcion= @Descripcion, Puerto=@Port, Status=@Status, provedor_id=@provedor_id Where Dialer_id=@dialer_id
	select -1, case @idioma when 1 then 'Dialer: ' + upper(@Descripcion) + ' Modified'
	else 'Dialer: ' + upper(@Descripcion) + ' Modificado' end
	return(0)
 end

if @Tipo=3
 begin
	if exists(select Dialer_id from ccoDialerCamp where Dialer_id=@dialer_id)
	select 0, case @idioma when 1 then 'There is some campaign that is using this dialer'
	else 'Existe alguna campaña que esta utilizando este dialer' end
	return(0)

	delete ccoDialers Where Dialer_id=@dialer_id		
	select -1, case @idioma when 1 then 'Dialer: ' + upper(@Descripcion) + ' Eliminado'
	else 'Dialer: ' + upper(@Descripcion) + ' Removed' end
	return(0)
 end
set nocount off