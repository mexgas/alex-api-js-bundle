/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Mike Trejo
Date: 2018/03/28
Description:
**********************************************************************************************
CW-1697 - Agrega reporte nuevo con vista en la tabla repAgentGI
**********************************************************************************************
Database: ccReportsRia
Required version: 47


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =51
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try


	set @process = 'Elimina funcion [FNTruncateToDecimal]-- CW-1697'
    	set @Sql= 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''[FNTruncateToDecimal]'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
begin
drop function [FNTruncateToDecimal]
end'
		EXEC(@Sql)

	set @process = 'Elimina Vista RepViewAgentGISpecial-- CW-1697'
    	set @Sql= 'if exists (select * FROM sys.views where name = N''RepViewAgentGISpecial'')
begin
drop view RepViewAgentGISpecial
end'
		EXEC(@Sql)

	set @process = 'Crear funcion [FNTruncateToDecimal]-- CW-1697'
    	set @Sql= 'Create FUNCTION [dbo].[FNTruncateToDecimal] (@Valor float)
RETURNS  float
AS
begin
Declare @NumConverted as float;
set @NumConverted=(cast((cast(@Valor*100 as int)/100.00)/3600.00 as decimal(18,2)))
	return @NumConverted
END'
		EXEC(@Sql)

	set @process = 'Crear vista de la tabla RepAgentGIl-- CW-1697'
    	set @Sql= 'CREATE VIEW RepViewAgentGISpecial AS
select * from RepAgentGI'
		EXEC(@Sql)

	set @process = 'Agregar nuevo menú a ccMenus-- CW-1697'
    	set @Sql= 'if not exists (select * from ccMenus where menu_id=2090)
begin
insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(2090,''Información General Especial|General Information Special'',2000,''B'',2,3,'''',''c706077b228a003efcba36c3d76f8ccd36593f3a4dd74e5c87b92746ea976e6fa69c0068d09919abe5b326a8e278fcaaf3a01cb1653f02e5933aa50fb8cf0147'');
end'
		EXEC(@Sql)

		set @process = 'inserta valores a ReportsFiltersmenus-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsFiltersmenus where idReport=2090)
		begin
insert ReportsFiltersmenus(idReport,filterMenuName) Values(2090,N''date'')
insert ReportsFiltersmenus(idReport,filterMenuName) Values(2090,N''filterby'')
insert ReportsFiltersmenus(idReport,filterMenuName) Values(2090,N''groupby'')
END'
		EXEC(@Sql)

		set @process = 'inserta valores a ReportsFilters-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsFilters where id=2090)
begin
insert into ReportsFilters values (''General Information Special'',''users'',2090)
END'
		EXEC(@Sql)

		set @process = 'Inserta valores a ReportsCharts-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsCharts where id=2090)
begin
insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
values (2090,''General Information Special'',1,''user'','''','''','''',''sum([tav])'',''Ready time per user'',1)
insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
values (2090,''General Information Special'',2,''year|month|day|hour'',''user'','''','''',''sum([tav])'',''Ready time per user by hour'',1)
END'
		EXEC(@Sql)

		set @process = 'Inserta valores a GroupByReports-- CW-1697'
    	set @Sql= 'if not exists (select * from GroupByReports where id=2090)
begin
insert into GroupByReports values(2090,''userId|max([user]):user|max([login]):login|[dbo].[FNnoRoundGroupByReports]((sum([tdialogout])+sum([tringout])+sum([txferout])+sum([tunknown])+sum([tother])+sum([tprob])+sum([tundefined]))):tTalkNum|[dbo].[FNnoRoundGroupByReports](sum([tnotesout])):tnotesoutNum|[dbo].[FNnoRoundGroupByReports](sum([tav])):tavNum|[dbo].[FNnoRoundGroupByReports](sum([tnotav])):tnotavNum|[dbo].[FNnoRoundGroupByReports]((sum([tdialogout])+sum([tringout])+sum([txferout])+sum([tunknown])+sum([tother])+sum([tprob])+sum([tundefined]))+(sum([tnotesout]))+(sum([tav]))+(sum([tnotav]))):TotalNum'',''userId'')
END'
		EXEC(@Sql)

		set @process = 'Inserta valores a ReportsTotals-- CW-1697'
    	set @Sql= 'if not exists (select * from ReportsTotals where id=2090)
begin
insert into ReportsTotals values (2090,''sum:nxferin|sum:nanswerin|sum:nabndxferin|sum:nabndringin|sum:nabnddlgin|sum:abndaxferin|sum:nnoanswerin|sum:nlostin|sum:tdialogin|sum:tnotesin|sum:tringin|sum:txferin|sum:nxferout|sum:nanswerout|sum:nabndxferout|sum:nabndringout|sum:nabnddlgout|sum:abndaxferout|sum:nnoanswerout|sum:nlostout|sum:tdialogout|sum:tnotesout|sum:tringout|sum:txferout|sum:nother|sum:tunknown|sum:tnotav|sum:tlog|sum:tav|sum:tother|sum:tprob|sum:nmohin|sum:nmohout|sum:nwhagin|sum:nwhagout|sum:nwhcliin|sum:nwhcliout|special:tnotavg:isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout]),0),0)'')
END'
		EXEC(@Sql)

		 if @actualVersion  = @version - 1
	 	exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off