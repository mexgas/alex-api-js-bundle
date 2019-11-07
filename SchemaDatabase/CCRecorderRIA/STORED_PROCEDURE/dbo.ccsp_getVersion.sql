-- =============================================
/*Catalogo de errores:
-1 / ERROR. ??? -- Este error no es controlado, es una excepcion del store, server, segun mande la alerta es lo que se mostrara
-2 / ERROR. Modulo no valido -- Cuando en el parametro de modulo no se ingresa BD|DB, AVRS, ALL
-3 / ERROR. Version no Valida para 'BD/AVRS'. Version Actual: '#Version' -- Cuando se quiere generar una versión que no es mayor a la actual
-4 / ERROR. generado al actualizar a version '#Version' -- Cuando se presento un problema al hacer el update de la version, por lo cual no se actualizo
*/
CREATE procedure [dbo].[ccsp_getVersion]
@Module varchar(4) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma int
select @Idioma = cast(par_valor as int) from trec_parametros where par_id = 26
if @Module='DB'
	set @Module='BD'
if upper(isnull(@Module, '')) not in ('BD', 'AVRS', 'ALL')
 begin
	select '-2' ID, case @Idioma when 1 then 'ERROR. Modulo no valido'
	 when 2 then 'ERRO. Módulo inválido'
	else 'ERROR. Invalid Module' end [Description]
	return(0)
 end
if @Module = 'ALL'
 begin
	select par_valor Ver_BD_AVRS from trec_parametros where par_id = 30
	return(0)
 end
declare @nVersion varchar(30)
select @nVersion = cast(par_valor as varchar(15)) from trec_parametros where par_id = 30
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
	select @version = cast(case upper(@Module) when 'BD' then @version_2
	else @version_1 end as int)
	select @version Version
	return(@version)
 end
if upper(@Module) = 'BD' and (@Version <= cast(@version_2 as int) or (@Version - cast(@version_2 as int))>1)
 begin
	select '-3' ID, case @Idioma when 1
	then 'ERROR. Version no Valida para BD. Version Actual: ' + @version_2
	when 2 then 'ERRO. Versão inválida para BD, versão atual: ' + @version_2
	else 'ERROR. Invalid Version for DB. Current Version: ' + @version_2
	end [Description]
	return(0)
 end
if @Version <= cast(case upper(@Module) when 'BD' then @version_2
else @version_1 end as int)
 begin
	select '-3' ID, case @Idioma when 1
	then 'ERROR. Version no Valida para ' + @Module + '. Version Actual: ' +
	 case upper(@Module) when 'BD' then @version_2 else @version_1 end
	 when 2
	then 'ERRO. Versão inválida para ' + @Module + '. Versão atual: ' +
	 case upper(@Module) when 'BD' then @version_2 else @version_1 end
	else 'ERROR. Invalid Version for ' + @Module + '. Current Version: ' +
	 case upper(@Module) when 'BD' then @version_2 else @version_1 end
	end [Description]
	return(0)
 end
if upper(@Module) = 'BD' set @version_2 = @Version
else set @version_1 = @Version
set @nVersion = @version_1 + '.' + @version_2
update trec_parametros set par_valor = @nVersion where par_id = 30
if @@rowcount = 1
	select '0' ID, 'Actualizado a version: ' + @nVersion [Description]
else
	select '-4' ID, case @Idioma when 1
	then 'ERROR generado al actualizar a version ' + @nVersion
	when 2 then 'ERRO encontrado ao atualizar a versão ' + @nVersion
	else 'ERROR introduced when upgrading to version ' + @nVersion
	end [Description]
return (0)
set nocount off