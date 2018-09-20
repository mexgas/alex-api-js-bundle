/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Daniel Vega
	
Date: 
Description:

Database: CCenterRia
Required version: 

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

set @version =59
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if  @actualVersion in(@version-1,@version)
begin
	begin tran
	begin try		

	set @process = 'CW-1823 agrega Origin a RepCallXfer'
    set @Sql= '
	 if not exists (select * from sys.columns where name = N''Origin'' and Object_ID = Object_ID(N''RepCallXfer''))
    begin
       alter table ccReportsRia..RepCallXfer add Origin varchar(max) null
    end
	'
    EXEC(@Sql)     

	
	set @process = 'CW-1823 agrega TotalTimeDuration a RepCallXfer'
    set @Sql= '
		if not exists (select * from sys.columns where name = N''TotalTimeDuration'' and Object_ID = Object_ID(N''RepCallXfer''))
    begin
      alter table ccReportsRia..RepCallXfer add TotalTimeDuration int null
    end
	'
    EXEC(@Sql)        


	set @process = 'CW-1823 agrega TipoTel a RepCallXfer'
    set @Sql= '
    if not exists (select * from sys.columns where name = N''TipoTel'' and Object_ID = Object_ID(N''RepCallXfer''))
    begin
       alter table ccReportsRia..RepCallXfer add TipoTel varchar(max) null
    end
	'
    EXEC(@Sql)        

	   

	set @process = 'CW-1823 se agregan las columnas para traducciones'
    set @Sql= '    
    if exists (select * from TranslatedReports where id = 4120)
    begin
	update TranslatedReports set columns = ''CallTypes|Agent|xfertype|destination|TipoTel'' where id = 4120
	end


	'
    EXEC(@Sql)        

	set @process = 'CW-1823 Se modifica el SP del reporte ccspRepCallXfer'
    set @Sql= '
	ALTER PROCEDURE [dbo].[ccspRepCallXfer]
			@action as tinyint,
			@from AS datetime = null,
			@to AS datetime = null
			AS

			if @action = 1
			begin
				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
				if @to is null	
					select @to = getdate()

				delete RepCallXfer with(rowlock)
				where [date] between @from and @to
				
				insert RepCallXfer 
				select convert(varchar(10),fechafin,121) [date],
				clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
				isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
				(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,
				case when modo = 0 then ''systemTranslated_blindXfer'' 
				when modo = 1 then ''systemTranslated_Agent'' 
				when modo = 2 then 
					case when cast(clt.destino as int) >= 0 then ''systemTranslated_acd'' else ''systemTranslated_Survey'' end
				when modo = 3 then ''systemTranslated_conference'' 
				when modo = 4 then ''systemTranslated_supXfer'' 
				when modo = 5 then ''systemTranslated_overflow'' end as xfertype,
				case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
				when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
				when modo = 2 then 
					case when cast(clt.destino as int) >= 0 then
						isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
					else
						isnull((select description from survey where scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
					end
				when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
				when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
				when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
				tantesxfer timebeforexfer,
				tdespuesxfer timeafterxfer,
				dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
				fechafin as endDate,
				case tipo when 1 then isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'')
				else
				isnull((select cam_descripcion from cccamps where cam_id = clt.destino),''systemTranslated_Indefinite'')
				end as Origin,
				tantesxfer+tdespuesxfer as TotalTimeDuration,				
				case tipo when 1 then isnull((select case dbo.fnGettipollamada(cal_ANI) when 1 then ''systemTranslated_fijo''
					 when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end from ccCallsIn where cal_id= clt.cal_id
					 ),''systemTranslated_Indefinite'')
				else
				isnull((
					select case dbo.fnGettipollamada(cal_telefono) when 1 then ''systemTranslated_fijo''
					 when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end from ccoCallsOut where cal_id = clt.cal_id					
				),''systemTranslated_Indefinite'')
				end as TipoTel
				from cclogtransfers clt 
				left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
				left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
				WHERE fechafin >= @from and fechafin < @to
			end
			

	'
    EXEC(@Sql)        

	
	/* End script release */

	/* Upgrade database version (use your own script to do it) */
	--exec ccsp_getVersion 'BD', @version
	

	commit tran
	end try

	begin catch

		/* Error generated based on sintax */
		select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
		RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
