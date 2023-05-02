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
SET @versionfix = 17
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

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		
	SET @process = 'Insert into ccMenus menu_id 13000'
	SET @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 13000)
			begin
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (13000,''SMS|SMS'',13000,''A'',12,3,'''',''d108a7f110b9d54d296cb729b6e11f92'')
			end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenus menu_id 13010'
	SET @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 13010)
			begin
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (13010,''Detalle de mensajes recibidos|Received Messages Detail'',13000,''B'',12,3,'''',''c52ae15116ddecd653ac7b2f660e4c46032ff614b634f1915e0f7f212a52943a83df5bf0619d99a3a303031a13230ee885b38c3701c2d075cf6f9099d22a0af8'')
			end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenus menu_id 13020'
	SET @sql = '
	if not exists(select menu_id from ccMenus where menu_id = 13020)
			begin
			insert into ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF,release) values (13020,''Detalle de mensajes enviados|Sent Messages Detail'',13000,''B'',12,3,'''',''c52ae15116ddecd653ac7b2f660e4c4687844bcbc5259b1f9ad3fde279181a449ed8f11ad1596ecc4311c4471dff08146fcd2fb13f94e5c06032e70312406c2c'')
			end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenuUser 13000'
	SET @sql = '
	if not exists(select * from ccMenuUser where id_Menu= 13000 and id_User=1)
	begin 
		insert into ccMenuUser values(1,13000,3)
	end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenuUser 13010'
	SET @sql = '
	if not exists(select * from ccMenuUser where id_Menu= 13010 and id_User=1)
	begin 
		insert into ccMenuUser values(1,13010,3)
	end'
	EXEC(@sql)

	SET @process = 'Insert into ccMenuUser 13020'
	SET @sql = '
	if not exists(select * from ccMenuUser where id_Menu= 13020 and id_User=1)
	begin 
		insert into ccMenuUser values(1,13020,3)
	end'
	EXEC(@sql)

	
		
		----------------------------------------------------------------------------------------------------------------------------
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


