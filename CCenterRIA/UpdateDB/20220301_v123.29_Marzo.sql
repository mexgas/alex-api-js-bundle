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
			reg_date datetime2,
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
        DECLARE @result_callout_id INT
        if(exists(select * from ccoWorkingTable where callout_id = @callout_id)) begin
            set @result_callout_id =1
        end
        IF (@result_callout_id > 0)
        BEGIN
            INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date) VALUES (@agent_id,@process,@callout_id,@camId,SYSDATETIME())
        END
        IF (@process = 1 AND @result_callout_id > 0)
        BEGIN
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
		@callout_id int 

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
	set @process = 'Cambios_preview Eliminar ccsp_GalateaAdminSetPermissions'
    set @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSetPermissions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
    end
    '
    EXEC(@sql)
    set @process = 'Cambios_preview Actualizar el dato AllowChangeDialingMode en ccsp_GalateaAdminSetPermissions'
    set @sql='
    Create PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
                    @user_id varchar(MAX),
                    @permissionName VARCHAR(255),
                    @permissionValue INT
                AS
                SET NOCOUNT ON

                DECLARE @changeBit INT

                SET @changeBit =
                CASE
                    WHEN @permissionName = ''AllowCellPhoneCalls'' or @permissionName = ''startStopRecording'' or @permissionName = ''XferManual'' or @permissionName = ''AllowTransferCalls'' or @permissionName = ''AgentPermissionDailing''or @permissionName = ''DailingMode'' or @permissionName=''AgentPermissionDailing''
                    THEN 1
                    WHEN @permissionName = ''AllowLongDistanceCalls'' or @permissionName = ''XferExt'' 
                    THEN 2
                    WHEN @permissionName = ''AllowLocalCalls'' or @permissionName = ''XferCamps''
                    THEN 4
                    WHEN @permissionName = ''XferAgents''
                    THEN 8
                    ELSE 0
                END
                print(@changeBit)
                IF @user_id IS NOT NULL
                BEGIN
                    
                    UPDATE
                        ccUsers
                    SET DialMask =
                        CASE
                        WHEN @permissionName = ''AllowCellPhoneCalls''
                        OR @permissionName = ''AllowLongDistanceCalls''
                        OR @permissionName = ''AllowLocalCalls''
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (DialMask & @changeBit) <> @changeBit
                                THEN DialMask ^ @changeBit
                                ELSE DialMask
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (DialMask & @changeBit) = @changeBit
                                THEN DialMask ^ @changeBit
                                ELSE DialMask
                                END
                            END 
                        ELSE DialMask
                        END,
                        
                        XferMask =
                        CASE
                        WHEN @permissionName = ''AllowTransferCalls''
                        THEN
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (XferMask & @changeBit) <> @changeBit
                                THEN XferMask ^ @changeBit
                                ELSE XferMask
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (XferMask & @changeBit) = @changeBit
                                THEN XferMask ^ @changeBit
                                ELSE XferMask
                                END
                            END
                        ELSE XferMask
                        END,

                        XferAgents =
                        CASE
                        WHEN @permissionName = ''XferAgents''
                        OR @permissionName = ''XferCamps'' 
                        OR @permissionName = ''XferExt'' 
                        OR @permissionName = ''XferManual'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (XferAgents & @changeBit) <> @changeBit
                                THEN XferAgents ^ @changeBit
                                ELSE XferAgents
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (XferAgents & @changeBit) = @changeBit
                                THEN XferAgents ^ @changeBit
                                ELSE XferAgents
                                END
                            END
                        ELSE XferAgents
                        END,

                        startStopRecording =
                        CASE
                        WHEN @permissionName = ''startStopRecording'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN 1
                            WHEN @permissionValue = 0
                            THEN 0
                            END
                        ELSE startStopRecording
                        END,

                        DialingMode = 
                        CASE
                        WHEN @permissionName = ''DailingMode'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (DialingMode & @changeBit) <> @changeBit
                                THEN DialingMode ^ @changeBit
                                ELSE DialingMode
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (DialingMode & @changeBit) = @changeBit
                                THEN DialingMode ^ @changeBit
                                ELSE DialingMode
                                END
                            END 
                        ELSE DialingMode
                        END,
                        AllowChangeDialingMode = 
                        CASE
                        WHEN @permissionName = ''AgentPermissionDailing'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN 1
                            WHEN @permissionValue = 0
                            THEN 0
                            END
                        ELSE AllowChangeDialingMode
                        END
                    WHERE User_id IN (select value from dbo.fn_RIASplitDelimited(@user_id,'',''))
                END

                SET NOCOUNT OFF'
                EXEC(@sql)
                    set @process = 'Cambios_preview Eliminar ccsp_GalateaAdminGetPermissions'
    set @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetPermissions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
    end
    '
    EXEC(@sql)
        set @process = 'Cambios_preview Modificar la linea AllowChangeDialingMode ccsp_GalateaAdminGetPermissions'
    set @sql = '
    
        CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
            @user_id varchar(255),
            @Type int
            AS
            set nocount on

            declare @isRoot int;

            if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
            print @isRoot

            IF @isRoot = 1
            BEGIN
            
            
                Select 
                User_id as AgentId, 
                Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, 
                cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
                
                cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode
            from 
                ccUsers
            where 
                tipoUser_id = 1
            return(0)
            END
            ELSE
            BEGIN
                Select distinct 
                A.User_id as AgentId, 
                Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, 
                cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
                cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode
            from 
                ccUsers A
            join ccRIAWorkGroupUsers B on 
                A.user_id = B.user_id
            where 
                tipoUser_id = 1 and 
                IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
            return(0)
            END
            set nocount off
        
    '
    EXEC(@sql)



		set @process = 'SPEC-9 - Crear tabla'
		set @sql = 'IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = ''dbo'' 
                 AND  TABLE_NAME = ''ccSIPCodeMap''))
			BEGIN
			CREATE TABLE [dbo].[ccSIPCodeMap](
				[id] [int] IDENTITY(1,1) NOT NULL,
				[country] [int] NOT NULL,
				[carrier] [varchar](255) NOT NULL,
				[resultCode] [smallint] NOT NULL,
				[mappedCode] [smallint] NOT NULL,
				[hash] [varchar](34) NULL
			) ON [PRIMARY]
			END
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Eliminar trigger para hash'
		set @sql = 'IF EXISTS (SELECT 1 FROM sys.triggers 
           WHERE Name = ''trigMapHash'')
			BEGIN
				DROP TRIGGER trigMapHash;
			END
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Crear trigger para hash'
		set @sql = 'CREATE TRIGGER [dbo].[trigMapHash] ON [dbo].[ccSIPCodeMap]
			FOR INSERT,UPDATE
			AS
			SET NOCOUNT ON
			BEGIN

				update ccSIPCodeMap set 
				hash=UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(HashBytes(''MD5'', rtrim(ltrim(map.carrier))+''|''+cast(map.resultCode as varchar(5)))), 3, 32))
				from ccSIPCodeMap map 
				inner join inserted i on map.id=i.id

			END
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Valores default'
		set @sql = 'IF NOT EXISTS (select top 1 1 from ccsipcodemap)
			BEGIN
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''RADIOMOVIL DIPSA S.A. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''RADIOMOVIL DIPSA S.A. DE C.V.'',504,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''OPERBES S.A. DE C.V. (ANTES BESTPHONE S.A. DE C.V.)'',403,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''OPERBES S.A. DE C.V. (ANTES BESTPHONE S.A. DE C.V.)'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''CABLEMAS TELECOMUNICACIONES S.A. DE C.V.'',403,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''CABLEMAS TELECOMUNICACIONES S.A. DE C.V.'',404,10)
			END
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Eliminar SP ccsp_DLRGetSIPCodeMap'
		set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures 
          WHERE Name = ''ccsp_DLRGetSIPCodeMap'')
			BEGIN
				DROP PROCEDURE ccsp_DLRGetSIPCodeMap
			END
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Crear SP ccsp_DLRGetSIPCodeMap'
		set @sql = 'CREATE procedure [dbo].[ccsp_DLRGetSIPCodeMap]
			AS
			set nocount on

			declare @country int
			select @country = valor from ccsettings where setting_id=104
			select hash,mappedCode from ccSIPCodeMap nolock where country=@country
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Obtener carrier sp ccsp_DLRgetDialPrefix'
		set @sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
			@cam_id smallint=0,
			@iPortNumber smallint = 0,
			@phone varchar(30) = '''',
			@callout_id int = 0
			as
			declare @prefix as varchar(15), @sipheader varchar(500)
			declare @ani as varchar(32)
			declare @call_record_cam as tinyint
			declare @pais as tinyint 
			declare @aniglobal varchar(32), @sipHdrFormat varchar(255)
			declare @ivr_script smallint, @surveycamid int
			declare @call_record bit, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint
			declare @PrefixRec varchar(40)
			declare @carrier varchar(255)

			select @pais = valor from ccsettings with(nolock) where setting_id = 104
			select @call_record_cam = call_record from ccCamps where cam_id = @cam_id
			select @aniglobal = valor from ccsettings with(nolock) where setting_id = 177

			set @prefix =''''
			-- Prefijo por puerto
			select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

			-- Prefijo por campaña,
			if @prefix =''''
				select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

			-- Prefijo general
			if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
				select @prefix = valor from ccsettings with(nolock) where setting_id =101

			-- Ani
			set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

			--AnswerMachine Message Files
			DECLARE @MsgFiles VARCHAR(8000) 
			SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
			FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

			--Custom MOH Files
			DECLARE @MohFiles VARCHAR(8000) 
			SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
			FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

			select @surveycamid = 0, @ivr_script = 0

			select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
			,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
			,@call_record = dbo.EnableCallRecord(@call_record_cam,@pais,@phone), @surveycamid = isnull(surveycamid,0)
			from ccCamps where cam_id = @cam_id

			SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)

			if @surveycamid > 0
				select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
    

			if @ani = '''' begin 
			set @ani = @aniglobal 
			end 

			 select @PrefixRec=ISNULL(prefijo,'''') from ccCamps where cam_id = @cam_id

			 set @carrier = ''''
			 select @carrier = dbo.GetCarrierByTel(@phone)

			select @prefix as sDialPrefix, @tNoContesta as tNoContesta,@ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
			@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript, @sipheader data
			,@PrefixRec PrefijoRec, @carrier Carrier
		'
		EXEC(@sql)

		set @process = 'SPEC-9 - Obtener carrier ccsp_DLRGetDialInfo'
		set @sql = 'ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
			@callout_id int,
			@cam_id smallint=0,
			@iPortNumber smallint = 0
			AS
			set nocount on
			declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
			declare @prefix as varchar(15)
			declare @prefixCalKey as varchar(30)
			declare @tNoContesta as tinyint
			declare @ani as varchar(32)
			declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint
			declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
			declare @ivr_script smallint, @surveycamid int
			declare @call_record_cam as tinyint
			declare @pais as tinyint 
			declare @sipHdrFormat varchar(255)
			declare @PrefixRec varchar(40)

			set @prefix =''''
			set @tNoContesta = 25
			set @ani=''''
			set @iTipoDial = 0
			set @detectAnswerMachine = 0
			set @detectVoiceMail =1
			set @cam_tnotas = 30
			set @keepDial = 0

			select @pais = valor from ccsettings where setting_id = 104
			select @PrefixRec=ISNULL(prefijo,'''') from ccCamps where cam_id = @cam_id

			-- Mensajes
			select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
			from dbo.fn_ccCamps_SelMessage(@cam_id)

			-- Prefijo por puerto
			select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
			-- Prefijo por campaña
			if @prefix =''''
				select @prefix = dialPrefix from ccCamps where cam_id = @cam_id
			-- Prefijo general, si es que esta habilitado
			if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)
				select @prefix = valor from ccsettings where setting_id =101

			select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

			-- Propiedades de campaña
			select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
			@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
			@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0)
			from ccCamps C (nolock) where C.cam_id=@cam_id

			if @surveycamid > 0
				select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

			--Custom MOH Files
			DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
			SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
			FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

			--Agrega prefijo Marcacion con directo    
			set @prefixCalKey=''''
			if (select valor from ccSettings where setting_id=202)=''1'' begin
				select @prefixCalKey=isnull(dialPrefix,'''') from ccoCallsOutSource with(nolock) where callout_id=@callout_id 
			end

			if @iPortNumber >= 0 
			begin
				SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
	
				SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)+''~''+rtrim(dato5)
				, ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
				, C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
				, @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
				, case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani
				, case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2
				, case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3
				, case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4
				, case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5
				, @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
				, @cam_tnotas cam_tnotas, @keepDial keepDial
				, isnull(@messageDNCL_name, '''') as messageDNCL_name
				,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
				,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
				,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
				,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
				,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
				, isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
				, isnull(@MohFiles,'''') as mohFiles
				,@ivr_script ivrScript
				,@sipheader data
				,@PrefixRec as Prefijo,
				dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
				dbo.GetCarrierByTel(cal_telefono2) carrier2, 
				dbo.GetCarrierByTel(cal_telefono3) carrier3, 
				dbo.GetCarrierByTel(cal_telefono4) carrier4, 
				dbo.GetCarrierByTel(cal_telefono5) carrier5
				FROM ccoCallsOutSource C with(nolock)
				left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
				left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
				WHERE C.callout_id = @callout_id
				return
			end 

			set nocount off
		'
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


