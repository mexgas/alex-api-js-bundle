/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 
		
Date: 2019/01/08
Description:

Database: CCenterRia
Required version: 121.31

Se agrega la tarea
CW-2487

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 32

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 31
BEGIN
	BEGIN TRAN

	BEGIN TRY				

		SET @process = 'CW-2487 Nuevo Setting 210'
		SET @Sql = 'if not exists(select * from ccsettings where setting_id=210)
			insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
			values (210,0,''Destinatarios de grabaciones para envío de email'',1,''ADM'',''0:Desactivado,1:Habilitar'',''Recordings Recipients. 0:Disabled,1:Enabled'',1,''^[0-1]$'')
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 Nuevo Menu 87'
		SET @Sql = 'if not exists(select * from ccmenus where menu_id=87)
			insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release) values (87,''Destinatarios de grabaciones|Recordings Recipients'',32,''B'',44,1,'''',''44c2462182a6c38fecaa6b187b70a43c7d14558a702cb4dd4f72d6da823ad6b90358675515652ad58ef44666b5e92f027723a4daf0af5d53fd9ae5c44ab070dc'')
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 Tabla ccRIACat_AddressBook'
		SET @Sql = 'if not exists (SELECT * 
							 FROM INFORMATION_SCHEMA.TABLES 
							 WHERE TABLE_SCHEMA = ''dbo'' 
							 AND  TABLE_NAME = ''ccRIACat_AddressBook'')
			BEGIN

				CREATE TABLE [dbo].[ccRIACat_AddressBook](
					[addr_Id] [smallint] IDENTITY(1,1) NOT NULL,
					[email] [varchar](100) NOT NULL,
					[name] [varchar](100) NOT NULL,
					[organization] [varchar](100) NOT NULL,
					[department] [varchar](50) NOT NULL,
					[job_title] [varchar](50) NOT NULL,
					[area_Id] [smallint] NULL,
				 CONSTRAINT [PK_ccRIACat_AddressBook] PRIMARY KEY CLUSTERED 
				(
					[addr_Id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]

			END
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 DROP Procedure ccsp_RIA_AddressBook'
		SET @Sql = 'IF EXISTS ( SELECT * 
					FROM   sysobjects 
					WHERE  id = object_id(N''[dbo].[ccsp_RIA_AddressBook]'') 
						   and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
		BEGIN
			DROP PROCEDURE [dbo].[ccsp_RIA_AddressBook]
		END
		'
		EXEC (@Sql)
		
		SET @process = 'CW-2487 Procedure ccsp_RIA_AddressBook'
		SET @Sql = 'CREATE PROCEDURE [dbo].[ccsp_RIA_AddressBook]
			@action smallint,
			@Email varchar(100) = '''',
			@Name varchar(100) = '''',
			@Organization varchar(100) = '''',
			@Department varchar(100) = '''',
			@Title varchar(100) = '''',
			@IDArea smallint = NULL,
			@IDAddr smallint = NULL
			AS

			set nocount on

			if @action = 0 begin --Selected Address
				select addr_id,name,email,organization,department,job_title from ccRIACat_AddressBook nolock where area_id=@IDArea order by Name
				return(0)
			end
			else if @action=2 begin --Insert Address
				Insert into ccRIACat_AddressBook (email,name,organization,department,job_title,area_Id) values (@Email,@Name,@Organization,@Department,@Title,@IDArea)
				select 1, scope_identity()--, Address Insertada
				return(0)
			end
			else if @action=3 begin--Update Address
				update ccRIACat_AddressBook set email=@Email,name=@Name,organization=@Organization,department=@Department,job_title=@Title where addr_id = @IDAddr
				return(0)
			end
			else if @action=4 begin --Delete Address
				delete ccRIACat_AddressBook where addr_id = @IDAddr
				return(0)
			end
		'
		EXEC (@Sql)
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
