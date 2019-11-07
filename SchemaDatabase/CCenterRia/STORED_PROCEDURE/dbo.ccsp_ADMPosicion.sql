CREATE PROCEDURE ccsp_ADMPosicion
@Computer varchar(40),
@pos_id smallint,
@ext_id smallint,
@Tipo tinyint -- 1=ALTA, 2=Modificacion
AS
set nocount on
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

if @Tipo=1
 begin
	if exists(select Computer from ccPosicion where Status=1 and Computer=@Computer)
	 begin
		select 0, case @idioma when 1 then 'Name in Use' else 'Nombre en Uso' end
		return(0)
	 end

	Insert ccPosicion (Computer, ext_id) Select @Computer, @ext_id
	select -1, case @idioma when 1 then 'Position: ' + upper(@Computer) + ' Added Succesfully'
	else 'Posicion: ' + upper(@Computer) + ' Dada de Alta' end
	return(0)
 end

if @Tipo=2
 begin
	Update ccPosicion set Computer=@Computer, ext_id=@ext_id where Status=1 and pos_id=@pos_id
	select -1, case @idioma when 1 then 'Position: ' + upper(@Computer) + ' Modified'
	else 'Posicion: ' + upper(@Computer) + ' Modificada' end
	return(0)
 end

if @Tipo=3
 begin
	Update ccPosicion Set Status=0 Where pos_id=@pos_id
	select -1, case @idioma when 1 then 'Position: ' + upper(@Computer) + ' Removed'
	else 'Posicion: ' + upper(@Computer) + ' Eliminada' end
	return(0)
 end
set nocount off