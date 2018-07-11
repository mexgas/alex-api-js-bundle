/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Angel Trejo
Date: 2018/11/11
Description:

Database: ccReportsRia
Required version: 52


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =54
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try
	
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

	set @process = 'CW-2019 ALTER PROCEDURE ccspRepInCallsDetail'
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
	select cal_inicio,cal_id, Inbound_id, '''' as Inbound, statusCall_id, '''' as statusCall, calif_id, '''' as calif, isnull(califSub_id,0), '''' as califSub,
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