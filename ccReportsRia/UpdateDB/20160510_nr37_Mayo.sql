/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/04/11
Description:

	Se agrega fix para ejeccuion por tiempo report master process
Database: ccReportsRiaPara
Required version: 36

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 37

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = 'INSERT -------- ReportsFiltersMenus'
		set @Sql= 'if not exists(select * from ReportsFiltersMenus where idReport = 6050) begin
insert into ReportsFiltersMenus values (6050, ''date'')
end'
		EXEC(@Sql)

		set @process = 'INSERT -------- ReportsTotals'
		set @Sql= 'if not exists(select * from ReportsTotals where id = 6050) begin
insert into ReportsTotals values (6050, '')
end'
		EXEC(@Sql)

		set @process = 'CREATE TABLE -------- RepIVRSurveys'
		set @Sql= 'if not exists (select * from sys.tables where name = N''RepIVRSurveys'')
begin
create table RepIVRSurveys
(
	[date] datetime not null,
	[userId] smallint not null,
	[login] varchar(20) not null,
	[scriptId] int not null,
	[surveyId] int not null,
	[survey] varchar(MAX) not null,
	[calId] int not null,
	[calKey] varchar(20) not null,
	[campaignId] [int] NOT NULL,
	[inboundId] [int] NOT NULL,
	[campACDDescription] varchar(40) not null,
	[questionId] int not null,
	[question] varchar(MAX) not null,
	[question_Count] varchar(MAX) not null,
	[Count] varchar(MAX) not null,
	[year] int not null,
	[month] int not null,
	[day] int not null,
	[hour] int not null,
	[minutes] int not null
)
end'
		EXEC(@Sql)

		set @process = 'ADD COLUMN -------- PivotReports'
		set @Sql= 'if not exists (select * from sys.columns where name = N''isGroupPivot'' and Object_ID = Object_ID(N''PivotReports''))
begin
	alter table PivotReports add isGroupPivot bit
end'
		EXEC(@Sql)

		set @process = 'UPDATE -------- PivotReports'
		set @Sql= 'update PivotReports set isGroupPivot = 1'
		EXEC(@Sql)

		set @process = 'INSERT -------- PivotReports'
		set @Sql= 'if not exists(select * from PivotReports where id = 6050)
begin
insert into PivotReports values (6050, ''question_Count'', ''date|userId|login|IVRId|surveyId|survey|calId|calKey|campaignId|inboundId|campACDDescription|questionId|question|year|month|day|hour|minutes'', ''max'', 0)
end'
		EXEC(@Sql)

		set @process = 'VALIDATE PROCEDURE -------- ccsp_IVRInCalls'
		set @Sql= 'if exists (select * from sys.procedures where name = N''GetPivotColumns'')
begin
    drop procedure GetPivotColumns
end'
		EXEC(@Sql)

		set @process = 'CREATE PROCEDURE -------- GetPivotColumns'
		set @Sql= 'CREATE PROCEDURE [dbo].[GetPivotColumns]	
@id int	
AS
BEGIN
SELECT [columns],complementColumns,pivotFunction,isGroupPivot 
FROM dbo.PivotReports 
WHERE id = @id
END'
		EXEC(@Sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
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