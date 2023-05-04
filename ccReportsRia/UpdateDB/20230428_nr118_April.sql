SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 118

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'Create table RepOutSMSAnswDetailByCamp '
	set @sql = '
	if not exists (select * from sys.tables where name = N''RepOutSMSAnswDetailByCamp'')
	begin
		create table RepOutSMSAnswDetailByCamp
			(	date datetime,
				camId int,
				campaignName varchar(255),
				message varchar(255),
				senderNumber varchar(255)
			)
	end
	'
	EXEC(@sql)

	set @process = 'Create table RepOutSMSSentMessagesDetail'
	set @sql = '
	if not exists (select * from sys.tables where name = N''RepOutSMSSentMessagesDetail'')
	begin
	create table RepOutSMSSentMessagesDetail
			(	
				recordId varchar(255),
				campaign varchar(255),
				recipientNumber varchar(255),
				date datetime,
				messageResult varchar(255),
				ncost decimal,
				messageId varchar(255),
				
			)
	end
	'
	EXEC(@sql)

	set @process = 'Insert into TranslatedReports'
	set @sql = '
	if not exists(select id from TranslatedReports where id = 13020 and columns=''messageResult'')
	begin
			insert into TranslatedReports (id,columns) values (13020,''messageResult'')
	end
	'
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=13010 and filterMenuName=''filterby'')
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(13010,N''filterby'') 
	end
	'
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus 13010 date'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=13010 and filterMenuName=''date'')
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(13010,N''date'') 
	end
	'
	EXEC(@sql)

	set @process = 'Insert into ReportsFilters 13010 campaigns'
	set @sql = '
	if not exists (select * from ReportsFilters where id =13010 and filterName=''campaigns'')
	begin
		insert into ReportsFilters values(''Received Messages Detail'',''campaigns'',13010)
	end
	'
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus 13020 filterby'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=13020 and filterMenuName=''filterby'')
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(13020,N''filterby'') 
	end
	'
	EXEC(@sql)

	set @process = 'Insert into ReportsFiltersMenus 13020 date'
	set @sql = '
	if not exists (select * from ReportsFiltersMenus where idReport=13020 and filterMenuName=''date'')
	begin
		INSERT INTO ReportsFiltersMenus(idReport,filterMenuName) VALUES(13020,N''date'') 
	end
	'
	EXEC(@sql)


	set @process = 'Insert into ReportsFilter 13020 campaigns'
	set @sql = '
	if not exists (select * from ReportsFilters where id =13020 and filterName=''campaigns'')
	begin
		insert into ReportsFilters values(''Sent Messages Detail'',''campaigns'',13020)
	end
	'
	EXEC(@sql)

	set @process = 'create table ccSMSResult'
	set @sql = '
	if not exists (select * from sys.tables where name = N''ccSMSResult'')
    begin
        create table ccSMSResult (resultId tinyint primary key, description varchar(20), translatedDesc varchar(50))
    end
	'
	EXEC(@sql)

	set @process = 'Insert into ccSMSResult delivered'
	set @sql = '
	if not exists(select description from ccSMSResult where description=''delivered'')
	begin
		insert into ccSMSResult (resultId,description, translatedDesc) values (0,''delivered'',''system_translated_delivered'')
	end
	'
	EXEC(@sql)

	set @process = 'Insert into ccSMSResult notDelivered'
	set @sql = '
	if not exists(select description from ccSMSResult where description=''notDelivered'')
			begin
			insert into ccSMSResult (resultId,description, translatedDesc) values (1,''notDelivered'',''system_translated_notDelivered'')
			end
	'
	EXEC(@sql)

	set @process = 'Insert into ccSMSResult sent'
	set @sql = '
	if not exists(select description from ccSMSResult where description=''sent'')
			begin
			insert into ccSMSResult (resultId,description, translatedDesc) values (2,''sent'',''system_translated_sent'')
			end
	'
	EXEC(@sql)

	set @process = 'Insert into ccSMSResult rejectedByrecipient'
	set @sql = '
	if not exists(select description from ccSMSResult where description=''rejectedByrecipient'')
			begin
			insert into ccSMSResult (resultId, description, translatedDesc) values (3,''rejectedByrecipient'',''system_translated_rejectedR'')
			end
	'
	EXEC(@sql)

	set @process = 'Insert into ccSMSResult rejectedByCarrier'
	set @sql = '
	if not exists(select description from ccSMSResult where description=''rejectedByCarrier'')
			begin
			insert into ccSMSResult (resultId, description,translatedDesc) values (4,''rejectedByCarrier'',''system_translated_rejectedC'')
			end
	'
	EXEC(@sql)	
	


	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
