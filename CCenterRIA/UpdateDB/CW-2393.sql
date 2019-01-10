/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Trejo
Date: 2018/03/15
Description:



Database: CCenterRia
Required version: 119.119.124

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

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 1
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  (@actualVersion = @version-1 and  @actualVersionFix >= 122) or( @actualVersion=120 and  @actualVersionFix=1)
	begin
		begin tran
		begin try


		set @process = 'CW-2393 ETIQUETAS EN PORTUGUES Permitir el valor 2 que es portugués en base de datos ccsp_RIAccSettingsConfig -- Version BD 119.122 -- '
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null
AS
set nocount on
declare @idioma tinyint
declare @activeChat tinyint
select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145
if @command=0
	begin
	SELECT case @idioma when 0 then descripcion 
						when 1 then [description]
						else DescripcionPT end descripcion
	FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
	order by descripcion
	return(0)
	end

if @command=1
	begin
	Select setting_id, case @idioma  
						when 0 then descripcion 
						when 1 then [description]
						else DescripcionPT end descripcion,valor, tipo,validate
	from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'',''SV'')
	and (setting_id not in (139,140,141)
	or   setting_id     in (139,140,141) and @activeChat > 0)
	order by tipo, descripcion
	return(0)
	end

if @command=2
	begin
	if @setting_id = 27 and @value not in(''0'',''1'',''2'') begin
		set @value = 0
	end
	else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'',''14'',''15'',''16'') begin
		set @value = 1
	end
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
	end
set nocount off'
    	EXEC(@Sql)
								

		set @process = 'CW-2393 ETIQUETAS EN PORTUGUES Validate y Detalle ccSettings -- Version BD 119.122 -- '
    	set @Sql= 'update ccSettings set detalle = ''Idioma en que apareceran tanto agente como admin RIA.  (0 español - 1 inglés - 2 portugués)'' where setting_id=27
update ccSettings set validate = ''^[0-2]$'' where setting_id=27
'
    	EXEC(@Sql)
	
		/* End script release */

		/* Upgrade database version (use your own script to do it) */		
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
