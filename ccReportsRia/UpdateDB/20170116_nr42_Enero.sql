/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2017/01/06
Description:
**********************************************************************************************
	Se agrega tarea CW-561_GASJ_Reportes_Errescuer_Fase_2
Database: ccReportsRia
Required version: 40



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =42
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1 or @actualVersion = @version begin
	begin tran
	begin try

	set @process = 'Drop SP -- ccspRepDialingResultsDetail 4180'
	set @Sql= 'if exists (select * from sys.procedures where name = ''ccspRepDialingResultsDetail'') DROP PROCEDURE [dbo].[ccspRepDialingResultsDetail]'
	EXEC(@sql)


	set @process = ''
	set @Sql= ''
	EXEC(@sql)

	set @process = 'Create Table -- RepDialingResultsDetail 4180'
	set @Sql= 'if not exists(select * from sys.tables where name=''RepDialingResultsDetail'')
create table RepDialingResultsDetail(
	[date] [datetime] NOT NULL,
	[telephone] [varchar](30) NOT NULL,
	[dialResultId] int NOT NULL,
	[dialResult] varchar(30) NOT NULL,
	[userId] [int] NOT NULL,
	[login] [varchar](20) NOT NULL,
	[campaignId] int NOT NULL,
	[campaign] [varchar](40) NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@sql)

	set @process = ''
	set @Sql= ''
	EXEC(@sql)

	set @process = 'Create SP -- ccspRepDialingResultsDetail 4180'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccspRepDialingResultsDetail]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

if @from is null
select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
select @to = getdate()

if @action = 1
begin


delete from  RepDialingResultsDetail where [date] between @from and @to

insert into RepDialingResultsDetail(date,telephone,dialResultId,dialResult,userId,login,campaignId,campaign,year,month,day,hour,minutes)
select dial.fecha as [date],dial.Telefono as [telephone],dial.tipoResDial_id as dialResultId,isnull(tr.descripcion,dial.disconnectCause) as dialResult,
isnull(co.User_id,0) as userId,isnull(u.Login,''systemTranslated_NoUserName'') as [Login],
dial.cam_id as campaignId,camp.cam_descripcion as campaign
,datepart(yyyy,dial.fecha) as [year]
,datepart(mm,dial.fecha) as [month]
,datepart(dd,dial.fecha) as [day]
,datepart(hh,dial.fecha) as [hour]
,datepart(mi,dial.fecha) as [minute]
FROM ccoLogDials dial
left join ccocallsout co on  dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono
left join cctipoResultadoDial tr ON dial.tiporesdial_id=tr.tiporesdial_id
left join ccUsers u on u.user_id =co.User_id
left join ccCamps camp on camp.cam_id=dial.cam_id
where dial.fecha>=@from and dial.fecha<@to


end'
	EXEC(@sql)

	set @process = 'Create Index -- RepDialingResultsDetail.IX_RepDialingResultsDetail 4180'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_RepDialingResultsDetail'' and object_id = OBJECT_ID(N''RepDialingResultsDetail''))
    begin
        CREATE NONCLUSTERED INDEX [IX_RepDialingResultsDetail] ON [dbo].[RepDialingResultsDetail]
(
	[date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    end'
	EXEC(@sql)

	set @process = 'Create ReportsFiltersMenus -- 4180'
	set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport=4180) begin
	insert into ReportsFiltersMenus(idReport,filterMenuName) values(4180,N''date'')
	insert into ReportsFiltersMenus(idReport,filterMenuName) values(4180,N''filterby'')
end'
	EXEC(@sql)

	set @process = 'Create ReportsFilters -- 4180'
	set @Sql= 'if not exists(select * from ReportsFilters where id=4180) begin
	insert into ReportsFilters(reportName,filterName,id) values(''Report detail Calling Dialing Errescuer'',''campaigns'',4180)
	insert into ReportsFilters(reportName,filterName,id) values(''Report detail Calling Dialing Errescuer'',''users'',4180)
end'
	EXEC(@sql)

	set @process = 'Create ReportsCharts -- 4180'
	set @Sql= 'if not exists(select * from ReportsCharts where id=4180) begin
	insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
	values(4180,''Report detail Calling Dialing Errescuer'',1,''campaign'','''','''','''',''sum([dialResultId])'',''Answered calls detail per Campaign'',0)
	insert into ReportsCharts(id,reportName,chartType,x1,subX1,x2,subX2,countColumn,chartDescription,isTime)
	values(4180,''Report detail Calling Dialing Errescuer'',2,''campaign'',''dialResult'','''','''','''',''Dial Results per Campaign'',0)
end'
	EXEC(@sql)

	set @process = 'Create TranslatedReports -- 4180'
	set @Sql= 'if not exists(select * from TranslatedReports where id=4180) insert into TranslatedReports (id,columns) values(4180,''login'')'
	EXEC(@sql)

	set @process = 'Create ReportsTotals -- 4180'
	set @Sql= 'if not exists(select * from ReportsTotals where id=4180) insert into ReportsTotals(id,totalColumns) values(4180,'''')'
	EXEC(@sql)


	set @process = ''
	set @Sql= ''
	EXEC(@sql)

	set @process = ''
	set @Sql= ''
	EXEC(@sql)

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