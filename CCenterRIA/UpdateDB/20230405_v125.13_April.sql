/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 13
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	-------------------------------------------- BEGIN Marco Garcia --------------------------------------------------------------

	SET @process = 'K042008-Carga BD SMS-Generar plantilla delete table smsOutSource';
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''smsOutSource'' and xtype=''U'')
		BEGIN
			DROP TABLE [dbo].smsOutSource;
		END';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla create table smsOutSource';
SET @sql = 'CREATE TABLE smsOutSource(
	smsout_id INT IDENTITY PRIMARY KEY , 
	callkey VARCHAR(40),
	cam_id SMALLINT,
	sms_phoneNumber VARCHAR(30),
	sms_phoneNumber2 VARCHAR(30),
	sms_phoneNumber3 VARCHAR(30),
	sms_phoneNumber4 VARCHAR(30),
	sms_phoneNumber5 VARCHAR(30),
	sms_status TINYINT,
	sms_attemps TINYINT DEFAULT ((0)),
	user_id  SMALLINT DEFAULT ((0)),
	sms_dateDial DATETIME,
	data1 VARCHAR(255),
	data2 varchar(255),
	data3 VARCHAR(255),
	data4 VARCHAR(255),
	data5 VARCHAR(255),
	dial_tels CHAR(8) DEFAULT(''12345NNN''),
	iTimeZone INT,
	iTimeZone_summer INT,
	iTimeZone2 INT,
	iTimeZone_summer2 INT,
	iTimeZone3 INT,
	iTimeZone_summer3 INT,
	iTimeZone4 INT,
	iTimeZone_summer4 INT,
	iTimeZone5 INT,
	iTimeZone_summer5 INT,
	list_id INT,
	Region VARCHAR(20),
	Localidad VARCHAR(20))';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete table smsoutSourceMessage';
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''smsoutSourceMessage'' and xtype=''U'')
		BEGIN
			DROP TABLE [dbo].smsoutSourceMessage;
		END';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla create table smsoutSourceMessage';
SET @sql = 'CREATE TABLE smsoutSourceMessage(
	smsoutSourceMessage_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	smsout_id INT NULL,
	message VARCHAR(160) NULL) ';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla delete table smsWorkingTable';
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''smsWorkingTable'' and xtype=''U'')
		BEGIN
			DROP TABLE [dbo].smsWorkingTable;
		END';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla create table smsWorkingTable';
SET @sql = 'CREATE TABLE smsWorkingTable(
	smsout_id  INT PRIMARY KEY,
	sms_phoneNumber VARCHAR(19),
	cal_keyw VARCHAR(40),
	attemps TINYINT,
	cam_id INT,
	sms_dateDial DATETIME,
	sms_status TINYINT,
	priority_cb TINYINT DEFAULT(0),
	user_id INT,
	iTimeZone INT,
	iTimeZone_summer INT,
	iTimeZone2 INT,
	iTimeZone_summer2 INT,
	iTimeZone3 INT,
	iTimeZone_summer3 INT,
	iTimeZone4 INT,
	iTimeZone_summer4 INT,
	iTimeZone5 INT,
	iTimeZone_summer5 INT,
	list_id  INT,
	id_RAniList INT,
	ani_idx  VARCHAR(500)) ';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla drop trigger trigZonaHorariaSMS';
SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE [name] = N''trigZonaHorariaSMS'' AND [type] = ''TR'')
			BEGIN
				  DROP TRIGGER [dbo].[trigZonaHorariaSMS];
			END;';
EXEC(@sql);

SET @process = 'K042008-Carga BD SMS-Generar plantilla create trigger trigZonaHorariaSMS';
SET @sql = 'CREATE TRIGGER dbo.trigZonaHorariaSMS ON dbo.smsOutSource
FOR INSERT, UPDATE 
AS
SET NOCOUNT ON
BEGIN
if update(sms_phoneNumber) begin
	update smsOutSource 
	set iTimeZone = dbo.fnGetTimeZone(cs.sms_phoneNumber,0),
	iTimeZone_summer = dbo.fnGetTimeZone(cs.sms_phoneNumber,1)
	from smsOutSource cs 
	inner join inserted i
	on cs.smsout_id = i.smsout_id
END

if update(sms_phoneNumber2) begin
	update smsOutSource 
	set iTimeZone2 = dbo.fnGetTimeZone(cs.sms_phoneNumber2,0),
	iTimeZone_summer2 = dbo.fnGetTimeZone(cs.sms_phoneNumber2,1)
	from smsOutSource cs 
	inner join inserted i
	on cs.smsout_id = i.smsout_id
END
if update(sms_phoneNumber3) begin
	update smsOutSource 
	set iTimeZone3 = dbo.fnGetTimeZone(cs.sms_phoneNumber3,0),
	iTimeZone_summer3 = dbo.fnGetTimeZone(cs.sms_phoneNumber3,1)
	from smsOutSource cs 
	inner join inserted i
	on cs.smsout_id = i.smsout_id
END
if update(sms_phoneNumber4) begin
	update smsOutSource 
	set iTimeZone4 = dbo.fnGetTimeZone(cs.sms_phoneNumber4,0),
	iTimeZone_summer4 = dbo.fnGetTimeZone(cs.sms_phoneNumber4,1)
	from smsOutSource cs 
	inner join inserted i
	on cs.smsout_id = i.smsout_id
END
if update(sms_phoneNumber5) begin
	update smsOutSource 
	set iTimeZone5 = dbo.fnGetTimeZone(cs.sms_phoneNumber5,0),
	iTimeZone_summer5 = dbo.fnGetTimeZone(cs.sms_phoneNumber5,1)
	from smsOutSource cs 
	inner join inserted i
	on cs.smsout_id = i.smsout_id
end
END';
EXEC(@sql);

SET @process = 'K042010-Registros nuevos SMS Dashboard';
SET @sql = '
if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRecordsInfoBySMSCamp'')
    begin
		drop proc ccsp_GalateaGetRecordsInfoBySMSCamp
    end';
EXEC(@sql);

SET @process = 'K042010-Registros nuevos SMS Dashboard';
SET @sql = '
if not exists (select * from sys.procedures where name = N''ccsp_GalateaGetRecordsInfoBySMSCamp'')
    begin
        Create proc ccsp_GalateaGetRecordsInfoBySMSCamp
		@cam_id integer = 0, @user_id int = 0
		as
		SELECT cam_id as id,
		count(case sms_status when 0 then 1 else null end) as New
		FROM smsWorkingTable SMS where SMS.cam_id=@cam_id group by cam_id
    end';
EXEC(@sql);
	--------------------------------------------------- END Marco Garcia --------------------------------------------------------------------
	
	
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
