/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.31

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
SET @versionfix = 33
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
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

	---------------------------------------BEGIN Marco Garcia & Marco Chagolla K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema)---------------------------------------------------------
	SET @process = 'K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema) delete store procedure ccsp_RIA_AddressBook'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIA_AddressBook'')
		BEGIN
			DROP PROCEDURE ccsp_RIA_AddressBook
		END'
EXEC(@sql)

SET @process = 'K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema) create store procedure [ccsp_RIA_AddressBook]'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIA_AddressBook]
			@action smallint,
			@Email varchar(100) = '''',
			@Name varchar(100) = '''',
			@Organization varchar(100) = '''',
			@Department varchar(100) = '''',
			@Title varchar(100) = '''',
			@IDArea smallint = NULL,
			@IDAddr smallint = NULL,
			@IsKolob BIT = 0
			AS

			set nocount ON
            
			DECLARE @newAdressBookId SMALLINT; 

			if @action = 0 begin --Selected Address
				select addr_id,name,email,organization,department,job_title from ccRIACat_AddressBook nolock where area_id=@IDArea order by Name
				return(0)
			end
			else if @action=2 begin --Insert Address
				IF(@IsKolob = 1)
				BEGIN
					BEGIN TRY
						BEGIN TRANSACTION insertDirectory
							if exists(select addr_Id from ccRIACat_AddressBook where name = @Name)
							BEGIN
								SET @newAdressBookId = -1 -- Name in use
							END
							ELSE IF exists(select addr_Id from ccRIACat_AddressBook where email = @Email)
							BEGIN
								SET @newAdressBookId = -2 -- Email in use
							END
							ELSE
							BEGIN
								Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
								SET @newAdressBookId = SCOPE_IDENTITY(); 
							END
						COMMIT TRANSACTION insertDirectory
					END TRY
					BEGIN CATCH
						IF @@trancount > 0 ROLLBACK TRANSACTION insertDirectory
						SET @newAdressBookId = -500 --Internal Server  
					END CATCH

					SELECT @newAdressBookId
				END
				ELSE
				BEGIN
					Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
					SELECT 1, scope_identity()--, Address Inserted
				END
				return(0)
			end
			else if @action=3 begin--Update Address

				IF(@IsKolob = 1)
				BEGIN
					BEGIN TRY
						BEGIN TRANSACTION updateDirectory
							if exists(select addr_Id from ccRIACat_AddressBook where name = @Name AND addr_Id <> @IDAddr)
							BEGIN
								SET @newAdressBookId = -1 -- Name in use
							END
							ELSE IF exists(select addr_Id from ccRIACat_AddressBook where email = @Email AND addr_Id <> @IDAddr)
							BEGIN
								SET @newAdressBookId = -2 -- Email in use
							END
							ELSE
							BEGIN
								update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
								SET @newAdressBookId = 1 --Address Book Updated successfully
							END
						COMMIT TRANSACTION updateDirectory
					END TRY
					BEGIN CATCH
						IF @@trancount > 0 ROLLBACK TRANSACTION updateDirectory
						SET @newAdressBookId = -500 --Internal Server  
					END CATCH

					SELECT @newAdressBookId
				END
				ELSE
				BEGIN
					update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
				END
				return(0)
			end
			else if @action=4 begin --Delete Address
			IF(@IsKolob = 1)
				BEGIN
					delete ccRIACat_AddressBook where addr_id = @IDAddr
					SELECT @@ROWCOUNT AS result
				END
				ELSE BEGIN
					delete ccRIACat_AddressBook where addr_id = @IDAddr
				END
				return(0)
			end'
			EXEC(@sql)


		

	---------------------------------------END Marco Garcia & & Marco Chagolla K039000 Destinatario de grabaciones (envío de grabaciones en finder a correos dados de alta en el sistema)-----------------------------------------------------------

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