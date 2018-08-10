/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
Date: 2018/07/11
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
		
		set @process = 'CW-1974 -- editar Columna ncost en RepOutAnswAndXferCalls_ARO'
		set @Sql= 'if exists (select * from sys.columns where name = N''ncost'' and Object_ID = Object_ID(N''RepOutAnswAndXferCalls''))
			begin
				alter table RepOutAnswAndXferCalls
					alter column ncost decimal(10,2)
			end'
		EXEC(@Sql)

		set @process = 'CW-1974 -- editar Columna total en RepOutAnswAndXferCalls_ARO'
		set @Sql= 'if exists (select * from sys.columns where name = N''total'' and Object_ID = Object_ID(N''RepOutAnswAndXferCalls''))
			begin
				alter table RepOutAnswAndXferCalls
					alter column total decimal(10,2)
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
	select COALESCE([Call].cal_inicio,ccld.fecha) as [date],
	isnull(ccld.cal_id,0) as [callid],
	isnull(ccld.cam_id,0) as [campaignId],
	ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
	isnull([Call].user_id,0) as [userId],
	ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') as [Agent],
	case when (COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) end as [dialog],
	ccld.telefono as [telephone],
	isnull(Call.cal_manual,0) as [dialId],
	isnull((select [description] from dialType where dialId = Call.cal_manual),''systemTranslated_Auto'') as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), case when Call.provedor_id is not null then Call.provedor_id else 1 end , case when (COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) end) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), case when Call.provedor_id is not null then Call.provedor_id else 1 end , case when (COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + cal_tMsg, ccld.tdialing) end),0.00) * (1 + (@IVA / 100.00))) as total
	from (select *, dbo.fnGetTipoLlamada(telefono) as CallType from ccologdials where fecha >= @from and fecha < @to and answerbit = 1) ccld
	LEFT JOIN ccoCallsOut Call on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
	LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
	LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
	order by date

	insert into RepOutAnswAndXferCalls
	select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
	clt.cal_id as [callid],
	'''' as [campaignId],
	'''' as [campaign],
	isnull((case tipo when 1 then ci.User_id else co.User_id end),0) as [userId],
	isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
	(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
	case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end as [dialog],
	case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
	when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
	when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
	when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
	3 as [dialId],
	(select [description] from dialType where dialId = 3) as [dialType],
	ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
	ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end), 0) as [ncost],
	@IVA as iva,
	convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else  60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end),0.00) * (1 + (@IVA / 100.00))) as [total]
	from (select *,dbo.fnGetTipoLlamada(ccenterria.dbo.Verifica(destino)) as  CallType from cclogtransfers where modo not in (1,2) and (tAntesXfer > 0 or tDespuesXfer > 0) and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
	LEFT JOIN cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
	LEFT JOIN ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
	LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
	LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id=dbo.fnGetTipoLlamada(clt.destino)
	LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType and tl.Country_id = @country)
	order by date 

			end'
		EXEC(@sql)

		set @process = 'CW-2019 drop and create table RepInCallsDetail'
		set @Sql= 'drop table [RepInCallsDetail]
			create TABLE [dbo].[RepInCallsDetail](
				[date] [datetime] NOT NULL,
				[callid] [int] NOT NULL,
				[inboundId] [smallint] NOT NULL,
				[ACDGroup] [varchar](255) NOT NULL,
				[callStatusId] [tinyint] NOT NULL,
				[callStatus] [varchar](255) NOT NULL,
				[dispositionId] [smallint] NOT NULL,
				[disposition] [varchar](255) NOT NULL,
				[subDispositionId] [smallint] NOT NULL,
				[subDisposition] [varchar](255) NOT NULL,
				[dnisId] [smallint] NOT NULL,
				[dnis] [varchar](255) NOT NULL,
				[userId] [smallint] NOT NULL,
				[username] [varchar](100) NOT NULL,
				[callKey] [varchar](255) NOT NULL,
				[ANI] [varchar](255) NOT NULL,
				[queueTime] [smallint] NOT NULL,
				[xferTime] [smallint] NOT NULL,
				[ringingTime] [smallint] NOT NULL,
				[dialogTime] [smallint] NOT NULL,
				[extension] [varchar](10) NOT NULL,
				[agentName] [varchar](500) NOT NULL,
				[whoHangUp] [varchar](255) NULL,
				[mohTime] [smallint] NOT NULL,
				[year] [int] NOT NULL,
				[month] [int] NOT NULL,
				[day] [int] NOT NULL,
				[hour] [int] NOT NULL,
				[minutes] [int] NOT NULL,
				[provedorId] [smallint] NULL,
				[provider] [varchar](30) NULL,
				[trunk] [smallint] NULL,
				[fileMoved] [nvarchar](100) NULL,
				[twrapup] [smallint] NULL,
				[AverageHandleTime] [smallint] NULL,
				[Dato1] [varchar](100) NULL,
				[Dato2] [varchar](100) NULL,
				[Dato3] [varchar](100) NULL,
				[Dato4] [varchar](100) NULL,
				[Dato5] [varchar](100) NULL
			) ON [PRIMARY]

			ALTER TABLE [dbo].[RepInCallsDetail] ADD  DEFAULT ((0)) FOR [twrapup]
			ALTER TABLE [dbo].[RepInCallsDetail] ADD  DEFAULT ((0)) FOR [AverageHandleTime]'
		EXEC(@Sql)
		
		set @process = 'CW-1290 -- Columna userName en RepInCallsDetail'
		set @Sql= 'EXEC sp_RENAME ''RepInCallsDetail.username'', ''userName'', ''COLUMN'''
		EXEC(@Sql)
		
		set @process = 'CW-1290 -- SP ccspRepInCallsDetail'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail]
			@action as tinyint,
			@from as datetime = null,
			@to as datetime = null
			AS

			DECLARE @callId as int

			if @from is null
				select @from = convert(datetime,convert(varchar(11),getdate()))
			select @to = getdate()

			if @action = 1
			begin
				
				declare @tab table(callId int primary key, [Dato1] varchar(255),[Dato2] varchar(255),[Dato3] varchar(255),[Dato4] varchar(255),[Dato5] varchar(255))

				insert into @tab
				select callId,[Dato 1],[Dato 2],[Dato 3],[Dato 4],[Dato 5]
				from
				(select A.CallId,[Data],[Description] from DataCallIn A
				inner join ccCallsIn B on A.CallId=B.cal_id
				where b.cal_Inicio >= @from AND b.cal_Inicio < @to
				) as SourceTable
				pivot
				(
				max([Data])
				for [Description] in ([Dato 1],[Dato 2],[Dato 3],[Dato 4],[Dato 5])
				)as pvt


				--Borrar lo que esta para no repetir
				delete from RepInCallsDetail with(rowlock) where date >= @from AND date < @to

				insert into RepInCallsDetail
				select cal_inicio, cal_id, Inbound_id, '''' as Inbound, statusCall_id, '''' as statusCall, calif_id, '''' as calif, isnull(califSub_id,0), '''' as califSub,
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
				,ISNULL(tab.Dato1,'''') as Dato1
				,ISNULL(tab.Dato2,'''') as Dato2
				,ISNULL(tab.Dato3,'''') as Dato3
				,ISNULL(tab.Dato4,'''') as Dato4
				,ISNULL(tab.Dato5,'''') as Dato5
				from cccallsin a
				left join ccoDialers di on di.dialer_id = a.cal_puerto
				left join cstoProvedor prov on di.provedor_id = prov.provedor_id
				left join @tab tab on tab.callId=a.cal_id
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

				update a set dnis = isnull(dni_numero,'''')
				from RepInCallsDetail a
				left join ccdnis b
				on a.dnisId = b.dni_id
				where [date] >= @from AND [date] < @to

				update a set userName = isnull(login,''''),
				agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
				from RepInCallsDetail a
				left join ccusers b
				on a.userId = b.user_id
				where [date] >= @from AND [date] < @to

			end'
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