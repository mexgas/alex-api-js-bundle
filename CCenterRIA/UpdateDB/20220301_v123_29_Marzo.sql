/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 29
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-6223 Drop sp ccsp_GalateaAdminBlacklistCatalog '
    set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaAdminBlacklistCatalog'')
BEGIN
    DROP PROCEDURE dbo.ccsp_GalateaAdminBlacklistCatalog
END'
    EXEC(@sql)

	set @process = 'CW-6223 Create sp ccsp_GalateaAdminBlacklistCatalog '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminBlacklistCatalog]
@BLID smallint,
@name varchar(50),
@Type tinyint
AS
set nocount on
if @Type=1-- Read black lists
 begin
	Select idtipolista AS ID, tipolista AS TIPO , DateCreation as DateCreation 
	from cctiposlistanegra where idtipolista = case isnull(@BLID,0) when 0 then idtipolista else @BLID end
	and Status= 1 order by 2
	return(0)
 end

If @Type=2 --Create black list
 begin
 DECLARE @newBlackListId INT= -1 --Nombre en Uso
	if not exists(select tipolista from cctiposlistanegra where tipolista=@name)
		begin
			insert into cctiposlistanegra (tipolista,DateCreation) values(@name, SYSDATETIME())
			SELECT @newBlackListId = SCOPE_IDENTITY() 
		end
	else if exists(select tipolista from cctiposlistanegra where tipolista=@name and Status = 0)
		begin
			declare @idBL int = (select idtipolista from cctiposlistanegra where tipolista=@name and Status = 0)
			update cctiposlistanegra set Status = 1, DateCreation =  SYSDATETIME() where idtipolista = @idBL
			select @newBlackListId = @idBL
		end 
	SELECT @newBlackListId as ReturnValue
	return(0)
 end

if @Type=4-- update 
 begin
 if not exists(select tipolista from cctiposlistanegra where tipolista=@name)
		begin
			update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
			SELECT 200 as ReturnValue
		end
		else
			SELECT -1 as ReturnValue --Nombre en uso
 return(0)
 end

if @Type=5 --obtiene el id de lista llamada defaultList/General
	begin
		declare @dnclid as int
		set @dnclid = 0;

		select @dnclid = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
		select @dnclid
		return(0)
	end

set nocount off'
    EXEC(@sql)

	
	set @process = 'Cambios_preview agregar columna nDescartes a ccoWorkingTable'
    set @sql = '
	if not exists (select * from sys.columns where name = N''nDescartes '' and Object_ID = Object_ID(N''ccoWorkingTable ''))
    begin
        alter table ccoWorkingTable add nDescartes int default 0
    end
	'
    EXEC(@sql)

	set @process = 'Cambios_preview crear tabla RegProcessPreviewRecord'
    set @sql = '
	if  not exists (select * from sys.tables where name = N''RegProcessPreviewRecord'')
    begin
       create table RegProcessPreviewRecord
	   (	userId smallint not null,
			process smallint not null,
			callout_id int not null,
			camId int not null,
			reg_date datetime,
		)
    end
	'
    EXEC(@sql)

	set @process = 'Cambios_preview Borrar sp ccsp_RegProcessPreviewRecord'
    set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_RegProcessPreviewRecord'')
    begin
        DROP PROCEDURE ccsp_RegProcessPreviewRecord;
    end
	'
    EXEC(@sql)

	set @process = 'Cambios_preview Crear sp ccsp_RegProcessPreviewRecord'
    set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
		@process smallint,
		@callout_id int,
		@agent_id smallint,
		@camId int)
		AS
		IF ((@process =0 OR @process=2) AND exists(select * from ccoWorkingTable where callout_id = @callout_id))
		BEGIN
			INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date  ) VALUES (@agent_id,@process,@callout_id,@camId,SYSDATETIME())
		END
		IF (@process = 1 AND exists(select * from ccoWorkingTable where callout_id = @callout_id))
		BEGIN
			INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date ) VALUES (@agent_id,@process,@callout_id,@camId,SYSDATETIME())
			DELETE ccoWorkingTable WHERE callout_id = @callout_id
		END
	'

    EXEC(@sql)

    set @process = 'Cambios_preview Creacion de la tabla ccoCallsPreviewData '
    set @sql = 'if not exists (select * from sys.tables where name = N''ccoCallsPreviewData'')
            begin
                CREATE TABLE [dbo].[ccoCallsPreviewData](
                        [cal_Key] [varchar](40) NOT NULL,
                        [cam_id] [smallint] NOT NULL,
                        [Dato6] [varchar](255) NOT NULL,
                        [Dato7] [varchar](255) NOT NULL,
                        [Dato8] [varchar](255) NOT NULL,
                        [Dato9] [varchar](255) NOT NULL,
                        [Dato10] [varchar](255) NOT NULL,
                        [Dato11] [varchar](255) NOT NULL,
                        [Dato12] [varchar](255) NOT NULL,
                        [Dato13] [varchar](255) NOT NULL,
                        [Dato14] [varchar](255) NOT NULL,
                        [Dato15] [varchar](255) NOT NULL,
                        [Headers] [varchar](1000) NOT NULL,
                        [TotalData] [int] NOT NULL
                        ) ON [PRIMARY]
            end'
 
    exec (@sql)

    set @process = 'Cambios_preview Borrar sp ccsp_GalateaGetPreviewData'
    set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaGetPreviewData'')
    begin
        DROP PROCEDURE ccsp_GalateaGetPreviewData;
    end
	'
    EXEC(@sql)


    set @process = 'Cambios_preview Creacion de la tabla ccoCallsPreviewData '
    set @sql ='
        if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_cal_Key'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_cal_Key]  DEFAULT ('''') FOR [cal_Key]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato6'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato6]  DEFAULT ('''') FOR [Dato6]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato7'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato7]  DEFAULT ('''') FOR [Dato7]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato8'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato8]  DEFAULT ('''') FOR [Dato8]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato9'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato9]  DEFAULT ('''') FOR [Dato9]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato10'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato10]  DEFAULT ('''') FOR [Dato10]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato11'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato11]  DEFAULT ('''') FOR [Dato11]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato12'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato12]  DEFAULT ('''') FOR [Dato12]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato13'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato13]  DEFAULT ('''') FOR [Dato13]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato14'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato14]  DEFAULT ('''') FOR [Dato14]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_Dato15'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_Dato15]  DEFAULT ('''') FOR [Dato15]
    end
    if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccoCallsPreviewData_TotalData'')
    begin
        ALTER TABLE [dbo].[ccoCallsPreviewData] ADD  CONSTRAINT [DF_ccoCallsPreviewData_TotalData]  DEFAULT ('''') FOR [TotalData]
    end
    '
    exec (@sql)
    
    	set @process = 'Cambios_preview Create sp ccsp_GalateaGetPreviewData'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
		@callout_id int -- 1.- cambia permiso, 2.- obtiene lista de permisos

		AS
		set nocount on

		select''previewData''=
		 ISNULL(P.Headers,'''')+''~''+
		 ISNULL(O.Dato1,'''')+''~''+
		 ISNULL(O.Dato2,'''')+''~''+
		 ISNULL(O.Dato3,'''')+''~''+
		 ISNULL(O.Dato4,'''')+''~''+
		 ISNULL(O.Dato5,'''')+''~''+
		 ISNULL(P.Dato6,'''')+''~''+
		 ISNULL(P.Dato7,'''')+''~''+
		 ISNULL(P.Dato8,'''')+''~''+
		 ISNULL(P.Dato9,'''')+''~''+
		 ISNULL(P.Dato10,'''')+''~''+
		 ISNULL(P.Dato11,'''')+''~''+
		 ISNULL(P.Dato12,'''')+''~''+
		 ISNULL(P.Dato13,'''')+''~''+
		 ISNULL(P.Dato14,'''')+''~''+
		 ISNULL(P.Dato15,'''')
			   from ccoCallsOutSource O
		INNER JOIN ccoCallsPreviewData P on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
		Where callout_id=@callout_id;
		set nocount off'
    EXEC(@sql)
	
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


