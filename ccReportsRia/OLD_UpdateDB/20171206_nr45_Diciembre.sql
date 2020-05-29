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
Required version: 44



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =45
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try


	set @process = 'CW-1078 -- ADD Setting Country default 1'
	set @Sql= 'if not exists(select * from ccSettings where setting_id =104)
insert into ccSettings(setting_id,valor,descripcion,Status,Tipo) values(104,''1'',''País'',1,''X'')'
	EXEC(@sql)
	
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

	set @process = 'CW-1078 -- ALTER SP ccspRepOutCallsDetail'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
declare @country as tinyint


SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


if @country is null set @country = 1

if @action = 1
	begin
		--Borrar lo que esta para no repetir
		delete from RepOutCallsDetail with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepOutCallsDetail
		SELECT Call.cal_inicio as [date],
		Call.cal_key as [callKey],
		Call.cal_telefono AS [telephone],
		Call.cal_txfer + call.cal_tring AS [transfer],
		Call.cal_tdialog AS [dialog],
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup],
		ISNULL( Tipo.[description], '''') AS [CallDisposition],
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login],
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username],
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration],
		ISNULL(Call.costo,0.00) as [ncost],
		@IVA as iva,
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else ''systemTranslated_NoCarrier'' end as [ByCarrier],
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes],
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType],
		case when cal_whoHung = 0 then ''systemTranslated_Client''
		when cal_whoHung = 1 then ''systemTranslated_Agent''
		else ''systemTranslated_AgentSurvey'' end [whoHangUp],
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		,Call.cal_puerto
		, ISNULL(cs.Dato1,'''') as [data1]
		, ISNULL(cs.Dato2,'''') as [data2]
		, ISNULL(cs.Dato3,'''') as [data3]
		, ISNULL(cs.Dato4,'''') as [data4]
		, ISNULL(cs.Dato5,'''') as [data5]
		FROM ccoCallsOut Call
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN ccoCallsOutSource cs ON Call.callout_id = cs.callout_id
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual in (0, 2)
		order by date
	end'
	EXEC(@sql)

	set @process = 'CW-1078 -- ALTER SP ccspRepOutCallsOnChatDetail'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutCallsOnChatDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
declare @country as tinyint


select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @country is null set @country = 1


if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsOnChatDetail with(rowlock)
		where date >= @from AND date < @to

		INSERT INTO RepOutCallsOnChatDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		case when prov.descrip is not null then prov.descrip when cstoProvedor.descrip is not null then cstoProvedor.descrip else ''systemTranslated_NoCarrier'' end as [ByCarrier],		
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''systemTranslated_Client'' else ''systemTranslated_Agent'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		,Call.cal_puerto
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = @country)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		LEFT JOIN ccoDialers di on di.dialer_id = Call.cal_puerto
		LEFT JOIN cstoProvedor on di.provedor_id = cstoProvedor.provedor_id
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual = 3
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