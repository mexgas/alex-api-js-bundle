CREATE PROCEDURE [dbo].[ReportsMasterSubProcess]
				--@from as DATETIME=NULL,
				--@to as DATETIME=NULL,
				--@dateStart DATETIME=NULL,
				--@scheduleTime int=NULL
			AS

			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

				DECLARE @from DATETIME = NULL
				DECLARE	@to DATETIME = NULL
				DECLARE @dateStart DATETIME = NULL
				DECLARE @scheduleTime int = 10


				-- Insert statements for procedure here
				PRINT '--------------------------- Creacion tablas cada domingo ---------------------------'

				DECLARE @isSunday TINYINT,  @hourSunday TINYINT,@minSunday TINYINT

				SELECT @isSunday = DATEPART(dw, GETDATE()),@hourSunday = DATEPART(hh, getdate()), @minSunday = DATEPART(mi, GETDATE())

				IF @isSunday=1 AND @hourSunday = 3 AND @minSunday>=30 
	
				BEGIN

					IF EXISTS (SELECT * FROM sys.tables WHERE name = 'logsReportsMaster') 
					BEGIN
						DROP TABLE logsReportsMaster
					END

					CREATE TABLE [logsReportsMaster](
						[id] INT IDENTITY not null PRIMARY KEY,
						[name] VARCHAR(100) not null,
						[status] TINYINT not null,
						[dateStart] DATETIME not null,
						[dateEnd] DATETIME not null,
						[error] VARCHAR(max) not null,
						[maxTime] INT not null)

					CREATE NONCLUSTERED INDEX [IX_logsReportsMaster1] ON [dbo].[logsReportsMaster]
					(
						[name] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

					CREATE NONCLUSTERED INDEX [IX_logsReportsMaster2] ON [dbo].[logsReportsMaster]
					(
					[status] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

					CREATE NONCLUSTERED INDEX [IX_logsReportsMaster3] ON [dbo].[logsReportsMaster]
					(
					[maxTime] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

				END

				PRINT '--------------------------- Termina Creacion tablas cada domingo ---------------------------'

				PRINT 'EXEC ReportsMasterProcessWIthOnlyGenerate @from='+CAST(@from as varchar)+',@to='+CAST(@to as varchar)+',@scheduleTime='+CAST(@scheduleTime as varchar)+',@dateStart='+CAST(@dateStart as varchar)

				EXEC ReportsMasterProcessWIthOnlyGenerate @from=@from,@to=@to,@scheduleTime=@scheduleTime,@dateStart=@dateStart	

			END