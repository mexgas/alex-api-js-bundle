CREATE PROCEDURE [dbo].[ccspTmpSessionGeneral]
@from as smalldatetime,
@to as smalldatetime 
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+':00')
end

if not exists( select * from sys.tables where name='tmpSessionGeneral') begin
	CREATE TABLE tmpSessionGeneral(	
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	[timeGroup] [datetime] NOT NULL,
	[timeGroupNext] [datetime] NULL,
	[tlog] int null,
	)
end
else begin
	truncate table tmpSessionGeneral	
	--drop table tmpSessionGeneral
end

insert into tmpSessionGeneral
exec ccspGenSession @from,@to

set nocount off