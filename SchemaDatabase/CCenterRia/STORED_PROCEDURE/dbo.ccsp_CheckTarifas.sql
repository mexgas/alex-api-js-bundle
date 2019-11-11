CREATE PROCEDURE [dbo].[ccsp_CheckTarifas]
@tel varchar(255)
AS
set nocount on

--declare @tel varchar(255)
declare @countryId tinyint
declare @len varchar(10)
declare @porcentaje tinyint
declare @typeLlamada tinyint

if (select valor from ccsettings where setting_id=164)= 1 begin

	set @tel = dbo.limpia(@tel)
	set @len = convert(varchar(10),len(@tel))
	
	select @countryId=valor from ccsettings where setting_id=104

	select @typeLlamada=tipoLlamada_id
	from cstoTipoLlamada where country_id=@countryId and prefijo = substring(@tel,0,CHARINDEX('%',prefijo))+'%' and longitud like '%'+@len+'%' 


	if exists (select * from cstoTarifa where tipoLlamada_Id= @typeLlamada)  select 0 Response ,'Existe tarifa' Note
	else select 11 Response ,'No existe tarifa' Note

end
else begin 
	select 0 Response
end

set nocount off