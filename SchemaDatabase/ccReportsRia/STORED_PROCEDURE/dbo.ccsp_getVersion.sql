CREATE procedure [dbo].[ccsp_getVersion]
@Module varchar(3) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma bit
select @Idioma = cast(valor as bit) from ccSettings where setting_id = 23

if upper(isnull(@Module, '')) not in ('BD', 'REP', 'ALL')
 begin
	select '-2' ID, case @Idioma when 0 then 'ERROR. Modulo no valido'
	else 'ERROR. Invalid Module' end [Description]
	return(0)
 end

if @Module = 'ALL'
 begin
	select valor Ver_BD_REP from ccSettings where setting_id = 24
	return(0)
 end

declare @nVersion varchar(30)
select @nVersion = cast(valor as varchar(15)) from ccSettings where setting_id = 24

BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9)
	set @version_1 = substring(@nVersion, 1, charindex('.', @nVersion)-1)
	set @nVersion = substring(@nVersion, charindex('.', @nVersion) + 1, len(@nVersion))
	set @version_2 = @nVersion
END TRY

BEGIN CATCH
	select '-1' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH

if isnull(@Version, 0) = 0
 begin
	select @version = cast(case upper(@Module) when 'BD' then @version_1
	else @version_2 end as int)
	select @version Version
	return(@version)
 end

if upper(@Module) = 'BD' and (@Version <= cast(@version_1 as int) or (@Version - cast(@version_1 as int))>1)
 begin
	select '-3' ID, case @Idioma when 0
	then 'ERROR. Version no Valida para BD. Version Actual: ' + @version_1 
	else 'ERROR. Invalid Version for BD. Current Version: ' + @version_1
	end [Description]
	return(0)
 end

if @Version <= cast(case upper(@Module) when 'BD' then @version_1
else @version_2 end as int)
 begin
	select '-3' ID, case @Idioma when 0
	then 'ERROR. Version no Valida para ' + @Module + '. Version Actual: ' +
	 case upper(@Module) when 'BD' then @version_1 else @version_2 end
	else 'ERROR. Invalid Version for ' + @Module + '. Current Version: ' +
	 case upper(@Module) when 'BD' then @version_1 else @version_2 end
	end [Description]
	return(0)
 end

if upper(@Module) = 'BD' set @version_1 = @Version
else set @version_2 = @Version

set @nVersion = @version_1 + '.' + @version_2 
update ccSettings set valor = @nVersion where setting_id = 24
if @@rowcount = 1
	select '0' ID, 'Actualizado a version: ' + @nVersion [Description]

else
	select '-4' ID, case @Idioma when 0 
	then 'ERROR generado al actualizar a version ' + @nVersion
	else 'ERROR introduced when upgrading to version ' + @nVersion
	end [Description]

return (0)
set nocount off