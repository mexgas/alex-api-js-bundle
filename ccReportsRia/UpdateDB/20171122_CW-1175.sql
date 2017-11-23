/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Mike Trejo
Date: 2017/11/22
Description:
**********************************************************************************************
CW-1175 Nuevas Columnas en Reportes
-Modificar el SP ccspRepInCallsDetail para obtener la columna cal_tnotas de la tabla cccallsin e 
insertarla en la tabla RepInCallsDetail. Adicionalmente insertar la información a la nueva columna "Average Handle Time" 
-Agregar la columna wrapup y "Average Handle Time" a la tabla RepInCallsDetail
**********************************************************************************************
Database: ccReportsRia
Required version: 43



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =44
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try
	set @process = 'ADD COLUMN TO RepInCallsDetail  CW-1175'	
	set @Sql='if not exists (select * from sys.columns where name = N''twrapup'' and Object_ID = Object_ID(N''RepInCallsDetail''))
    begin
        ALTER TABLE RepInCallsDetail ADD twrapup smallint default (0);
    end'
	EXEC(@Sql)

	set @process = 'ADD COLUMN TO RepInCallsDetail  CW-1175'
	set @Sql='if not exists (select * from sys.columns where name = N''AverageHandleTime'' and Object_ID = Object_ID(N''RepInCallsDetail''))
    begin
        ALTER TABLE RepInCallsDetail ADD AverageHandleTime smallint default (0);
    end'
	EXEC(@Sql)

	set @process = 'ALTER SP ccspRepInCallsDetail  CW-1175'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]
	@action as tinyint,
	@from as datetime = null,
	@to as datetime = null
	AS

	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	select @to = getdate()

	if @action = 1
	begin

		--Borrar lo que esta para no repetir
		delete from RepInCallsDetail with(rowlock) where date >= @from AND date < @to

		insert into RepInCallsDetail
		select cal_inicio, Inbound_id, '''' as Inbound, statusCall_id, '''' as statusCall, calif_id, '''' as calif, isnull(califSub_id,0), '''' as califSub,
		dni_id, '''' as dni, user_id, '''' as agentName,
		isnull(cal_key,''''), cal_ANI, cal_tWait, cal_tXfer, cal_tRing, cal_tDialog, cal_extension, '''',
		case when a.cal_whoHung = 0 then ''systemTranslated_Client''
		when a.cal_whoHung = 1 then ''systemTranslated_Agent''
		else ''systemTranslated_AgentSurvey'' end [whoHangUp]
		, cal_tMoh, datepart(yyyy,cal_inicio), datepart(mm,cal_inicio), datepart(dd,cal_inicio)
		, datepart(hh,cal_inicio), datepart(mi,cal_inicio)
		,di.provedor_id,prov.descrip [Proveedor],a.cal_puerto
		,case when a.file_moved = 1 then ''systemTranslated_Remoto'' else ''Local'' end as file_Moved
		,cal_tNotas,AverageHandleTime= cal_tNotas+cal_tDialog
		from cccallsin a
		left join ccoDialers di on di.dialer_id = a.cal_puerto
		left join cstoProvedor prov on di.provedor_id = prov.provedor_id
		where cal_inicio >= @from AND cal_inicio < @to
		
		update a set acdGroup = isnull(descripcion,'''')
		from RepInCallsDetail a
		left join ccInbound b
		on a.inboundId = b.Inbound_id
		where [date] >= @from AND [date] < @to

		update a set callStatus = isnull(descripcion,'''')
		from RepInCallsDetail a
		left join ccstatusllamada b
		on a.callStatusId = b.statusCall_id
		where [date] >= @from AND [date] < @to

		update a set disposition = isnull(description,'''')
		from RepInCallsDetail a
		left join cctipocalif b
		on a.dispositionId = b.calif_id
		where [date] >= @from AND [date] < @to

		update a set subDisposition = isnull(califSubDesc,'''')
		from RepInCallsDetail a
		left join cctipocalifsub b
		on a.subDispositionId = b.califSub_id
		where [date] >= @from AND [date] < @to

		update a set username = isnull(login,'''')
		from RepInCallsDetail a
		left join ccusers b
		on a.userId = b.user_id
		where [date] >= @from AND [date] < @to

		update a set dnis = isnull(dni_numero,'''')
		from RepInCallsDetail a
		left join ccdnis b
		on a.dnisId = b.dni_id
		where [date] >= @from AND [date] < @to

		update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
		from RepInCallsDetail a
		left join ccusers b
		on a.userId = b.user_id
		where [date] >= @from AND [date] < @to
	end'
	EXEC(@sql)

	set @process = ''
	set @Sql= ''
	EXEC(@sql)


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