/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo 
Date: 2017/22/07
Description:



Database: CCenterRia
Required version: 119.09-4

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 103
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and ( @actualVersionFix = 102 or  @actualVersionFix= @versionfix)
	begin
		begin tran
		begin try
		
		set @process = 'CW-1078 -- Correcion de cstoTipoLlamada'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CheckTarifas]
@tel varchar(255)
AS
set nocount on

--declare @tel varchar(255)
declare @countryId tinyint
declare @len varchar(10)
declare @porcentaje tinyint
declare @typeLlamada tinyint

if (select valor from ccsettings where setting_id=164)= 1 begin

	--set @tel=dbo.limpia(''044 55 64234886'')
	set @tel = dbo.limpia(@tel)
	set @len = convert(varchar(10),len(@tel))
	
	select @countryId=valor from ccsettings where setting_id=104

	select @typeLlamada=tipoLlamada_id
	from cstoTipoLlamada where country_id=@countryId and prefijo = substring(@tel,0,CHARINDEX(''%'',prefijo))+''%'' and longitud like ''%''+@len+''%'' 


	if exists (select * from cstoTarifa where tipoLlamada_Id= @typeLlamada)  select 0,''existe tarifa''
	else select 11,''No existe tarifa''

end
else begin 
	select 0
end

set nocount off'
    	EXEC(@Sql)

    	set @process = 'CW-1078 '
    	set @Sql= ''
    	EXEC(@Sql)

    	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end