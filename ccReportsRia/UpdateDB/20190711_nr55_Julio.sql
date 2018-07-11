/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
Date: 2018/05/15
Description:

Database: ccReportsRia
Required version: 54


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =55
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try
	
	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		begin
		DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		end'
	EXEC(@sql)

	set @process = 'CW-1974 -- Columna cal_tMsg en ccocallsout'
	set @Sql= 'if not exists (select * from sys.columns where name = N''cal_tMsg'' and Object_ID = Object_ID(N''ccocallsout''))
		begin
			alter table ccocallsout ADD cal_tMsg smallint null
		end'
	EXEC(@Sql)
	
	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
			ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)
	
	set @process = 'CW-1974 -- SP ccspRepOutAnswAndXferCalls'
	set @sql='ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		select @to = getdate()

		declare @IVA INT
		declare @country as tinyint


		select @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
		select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


		if @country is null set @country = 1


		if @action = 1
		begin
			--Borrar lo que esta para no repetir
			delete from RepOutAnswAndXferCalls with(rowlock) where date >= @from AND date < @to

			insert into RepOutAnswAndXferCalls
			select Call.cal_inicio as [date],
			Call.cal_id as [callid],
			camps.cam_id as [campaignId],
			ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
			Usr.user_id as [userId],
			ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') as [Agent],
			ISNULL(Call.totalCall_Time, 0)+isnull(cal_tMsg,0) as [dialog],
			Call.cal_telefono as [telephone],
			Call.cal_manual as [dialId],
			(select [description] from dialType where dialId = Call.cal_manual) as [dialType],
			ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
			dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, isnull(Call.totalCall_Time,0)+isnull(cal_tMsg,0)) as [ncost],
			@IVA as iva,
			convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, isnull(Call.totalCall_Time,0)+isnull(cal_tMsg,0)),0.00) * (1 + (@IVA / 100.00))) as total
			from ccoCallsOut Call
			LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
			INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
			LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)
			INNER JOIN ccoLogDials ccld on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
			where Call.cal_inicio >= @from
			and Call.cal_inicio < @to
			order by date

			insert into RepOutAnswAndXferCalls
			select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
			clt.cal_id as [callid],
			'''' as [campaignId],
			'''' as [campaign],
			(case tipo when 1 then ci.User_id else co.User_id end) as [userId],
			isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
			(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
			ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0) as [dialog],
			case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
			when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
			when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
			when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
			3 as [dialId],
			(select [description] from dialType where dialId = 3) as [dialType],
			ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
			ISNULL(dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(clt.destino), channel.proveedorId, clt.tAntesXfer+clt.tDespuesXfer), 0) as [ncost],
			@IVA as iva,
			convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(dbo.fnGetTipoLlamada(clt.destino), channel.proveedorId, clt.tAntesXfer+clt.tDespuesXfer),0.00) * (1 + (@IVA / 100.00))) as [total]
			from cclogtransfers clt
			LEFT JOIN cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
			LEFT JOIN ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
			LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
			LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id=dbo.fnGetTipoLlamada(clt.destino)
			LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = dbo.fnGetTipoLlamada(clt.destino) and tl.Country_id = @country)
			where clt.modo not in (1,2) 
			and (clt.tAntesXfer > 0 or clt.tDespuesXfer > 0)
			and dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) >= @from
			and dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) < @to
			order by date 

		end'
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