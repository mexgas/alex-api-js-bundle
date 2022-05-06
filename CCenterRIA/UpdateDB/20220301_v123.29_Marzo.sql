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

	SET @process = 'CW-6518 Registro menu 7210'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 7210)
		INSERT INTO ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
		VALUES (7210, ''KPIs Especiales Salida|Special Outbound KPIs'', 7000, ''B'', 10, 3, '''', ''efa4d1a49710f091ef14fbe832fa64deea30ab5e5d898ad75f065e83546205909bb8196a7e85810bdcd22d0ee7e07293'')
	'
	EXEC(@sql)

	SET @process = 'CW-6519 Registro menu 7220'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 7220)
		INSERT INTO ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
		VALUES (7220, ''KPIs Especiales Agentes|Special Agent KPIs'', 7000, ''B'', 10, 3, '''', ''a51282c9f3778d5f7b8f48a3b7290382b057c1652fa3ce9ac6a0683abb45d2a62ab46ec96807514900822f4d16a634ef'')
	'
	EXEC(@sql)

	SET @process = 'CW-6451 Registro menu 7200'
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 7200)
		INSERT INTO ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
		VALUES (7200, ''KPIs Especiales Entrada|Special Inbound KPIs'', 7000, ''B'', 10, 3, '''', ''a51282c9f3778d5f7b8f48a3b7290382cb7373be67144e901962bae0c6147dbcf390fbdb914fffe3d313764e5b14fce9'')
	'
	EXEC(@sql)

	SET @process = 'Insert new column allNumbersBL'
	SET @sql = ' if not exists (select * from sys.columns where name = N''allNumbersToBlacklist'' and Object_ID = Object_ID(N''ccTipoCalifOut''))
    begin
        alter table ccTipoCalifOut add allNumbersToBlacklist bit default 0 not null
    end'
	EXEC (@sql)
	SET @process = 'Delete ccsp_GalateaAdminDispositions'
	SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminDispositions;
    end'
	EXEC (@sql)
	SET @process = 'Create sp ccsp_GalateaAdminDispositions'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@calif_id smallint = null,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0,
@allNumbersToBlacklist bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]	-- Disposition already exists
      return(0)
    end

  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
	select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
	output inserted.calif_id into @inserted
    where calif_id=@calif_id
	select ID [result] from @inserted 
    return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]	-- Disposition already exists
  return(0)
  end

 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
	select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
	update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
	Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
	finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
	output inserted.calif_id into @inserted
	where calif_id=@calif_id
	select ID [result] from @inserted 
	return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0) from ccTipoCalifOut
 select ID [result] from @inserted 
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	if @canReprogram=1
	begin
		if exists(select i.Inbound_id from ccCalifCamp cc inner join ccTipoCalif t on cc.calif_id=t.calif_id and tipo=0
		inner join ccInbound i on cc.cam_id=i.Inbound_id where cc.calif_id=@calif_id and i.cam_id is null)
		begin
			select cast(-2 as smallint) [result]	-- Cant reprogram, there is not assigned campaign
			return(0)
		end
	end

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
	EndConversation=isnull(@endConversation,EndConversation)
	output inserted.calif_id into @inserted
    where calif_id=@calif_id

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
	autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
	finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist)
	output inserted.calif_id into @inserted
	where calif_id=@calif_id

	if @keepDial is not null
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end

	select ID [result] from @inserted
	return(0) 
	end

set nocount off

	'
	EXEC (@sql)
	SET @process = 'Delete ccsp_AgentUpdateCallCALIF'
	SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_AgentUpdateCallCALIF'')
    begin
        DROP PROCEDURE ccsp_AgentUpdateCallCALIF;
    end'
	EXEC (@sql)
	SET @process = 'Create sp ccsp_AgentUpdateCallCALIF'
	SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(20) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
DECLARE @userid INT

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

DECLARE @hashTel INT
DECLARE @killListID INT = (
		SELECT idtipolista
		FROM ccTiposListaNegra
		WHERE Tipolista = ''default/KillList''
		)
DECLARE @killListSetting INT = (
		SELECT STATUS
		FROM ccSettings
		WHERE setting_id = 215
		)

IF @TipoCall = 1
BEGIN
	UPDATE ccCallsIN
	SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key), califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 0 AND calif_id = @calif_id
			)
	BEGIN
		SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
		FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
		JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
		WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			--insert ccListaNegra
			INSERT INTO cclistanegra (telefono, idtipolista)
			VALUES (@tel, @iddncList)

			--insert cc_killlist
			IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
			BEGIN
				select @hashTel = dbo.hashPhone(@tel)

				IF NOT EXISTS (
						SELECT hashtel
						FROM cc_KillList
						WHERE hashTel = @hashTel
						)
				BEGIN
					INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
					VALUES (@hashTel, @iddncList, GETDATE())
				END
			END

			INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
			FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
			JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
			WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
		END
	END

	RETURN (0)
END

IF @TipoCall = 2
BEGIN
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @autoCB = autocallback
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @autoCB IS NULL
	BEGIN
		SELECT @autoCB = autocallback
		FROM cctipocalifout
		WHERE calif_id = @calif_id
	END

	IF @autoCB = 1
	BEGIN
		SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
		FROM ccocallsout
		WHERE Cal_id = @IDCall

		SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
		FROM cccamps cam
		WHERE cam.cam_id = @camp

		EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	END

	UPDATE ccoCallsOUT
	SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 1 AND calif_id = @calif_id
			) AND NOT EXISTS (
			SELECT co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
			WHERE co.cal_id = @idCall AND bl.idtipolista IN (
					SELECT idTipoLista
					FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
					WHERE tipo = 1 AND calif_id = @calif_id
					)
			)
	BEGIN --IF

		CREATE TABLE #NUMANDBL (id int identity,  iddncList int)
		CREATE TABLE #NUMBERS (id int identity, number varchar(30))
		DECLARE @allnumbersToBl BIT
		DECLARE @number varchar(30)

		SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id

		IF(@allnumbersToBl = 1)
		BEGIN
			DECLARE @camid SMALLINT
			SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall
			DECLARE @i SMALLINT = 0
			WHILE (@i < 5 )
			BEGIN
				SELECT @number = CASE @i 
									WHEN 0 THEN cal_telefono 
									WHEN 1 THEN cal_telefono2
									WHEN 2 THEN cal_telefono3
									WHEN 3 THEN cal_telefono4
									WHEN 4 THEN cal_telefono5
									END FROM ccoCallsOutSource WHERE callout_id = @callOutId AND cam_id = @camid
				SET @number = dbo.Completa_ListaNegra(@number)
				IF(LEFT(@number, 1) <> ''E'') 
				BEGIN
					INSERT INTO #NUMBERS (number) VALUES (@number)
				END
				SET @i = @i + 1
			END
		END
		ELSE
		BEGIN
			SELECT @number = co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			WHERE co.cal_id = @idCall 
			SET @number = dbo.Completa_ListaNegra(@number)
			IF(LEFT(@number, 1) <> ''E'') 
			BEGIN
				INSERT INTO #NUMBERS (number) VALUES (@number)
			END
		END

		IF((SELECT COUNT(*) FROM #NUMBERS) > 0) begin
			INSERT INTO #NUMANDBL (iddncList) 
			select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
		END

		DECLARE @Count int		
		WHILE (SELECT count(id) from #NUMANDBL) > 0
		BEGIN  --WHILE
			select @Count = count(id) from #NUMANDBL
			SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
			DECLARE @countNumbers INT, @indexNumbers INT = 1
			SELECT @countNumbers = COUNT(*) FROM #NUMBERS
			WHILE( @indexNumbers <= @countNumbers) --WHILE NUMBERS
			BEGIN 
				SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers
				IF @tel IS NOT NULL AND @iddncList IS NOT NULL
				BEGIN--Tel adn iddnclist
					EXEC ccsp_InsertDNCList @tel, @iddncList

					IF (@killListSetting = 1 AND @iddncList = @killListID)
					BEGIN
						select @hashTel = dbo.hashPhone(@tel)

						IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
						BEGIN
							INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
							VALUES (@hashTel, @iddncList, GETDATE())
						END
					END

					INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
					SELECT @tel, @iddncList, co.cam_id, getdate(), co.callout_id, 6
					FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
					--JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
					WHERE co.cal_id = @idCall 
				END --Tel adn iddnclist
				SET @indexNumbers = @indexNumbers + 1
			END --WHILE NUMBERS
			delete from #NUMANDBL where id = @Count
		END --WHILE
		DROP TABLE #NUMANDBL
		DROP TABLE #NUMBERS
	END --IF
	IF @RecicleSIC = 1
	BEGIN
		-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		SELECT @Reprogram = CanReprogram
		FROM ccTipoCalifSubout
		WHERE califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		IF @Reprogram IS NULL
		BEGIN
			SELECT @Reprogram = CanReprogram
			FROM ccTipoCalifOUT
			WHERE calif_id = @calif_id
		END

		IF @callOutId = 0
			SELECT @callOutId = callout_id
			FROM ccocallsout
			WHERE Cal_id = @IDCall

		UPDATE ccoWorkingTable
		SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
		WHERE callout_id = @callOutId
	END

	DECLARE @keepDial BIT
	DECLARE @finishPreview SMALLINT

	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	SELECT @keepDial = keepDial
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @keepDial IS NULL
	BEGIN
		SELECT @keepDial = keepDial
		FROM ccTipoCalifout
		WHERE calif_id = @calif_id
	END

	SELECT @finishPreview = isnull(finishPreview, 0)
	FROM ccTipoCalifout
	WHERE calif_id = @calif_id

	IF @keepDial = 1
	BEGIN
		UPDATE ccologdials
		SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		WHERE logDial_id IN (
				SELECT TOP 1 L.logDial_id
				FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
				JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
				WHERE O.cal_id = @IDCall
				ORDER BY L.logDial_id DESC
				)
	END

	SELECT @keepDial, @finishPreview

	RETURN (0)
END

SET NOCOUNT OFF

	'
	EXEC (@sql)

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

		set @process = 'SPEC-9 - Limpiar tabla'
		set @sql = 'truncate table ccsipcodemap'
		EXEC(@sql)

		set @process = 'SPEC-9 - Valores default'
		set @sql = 'IF NOT EXISTS (select top 1 1 from ccsipcodemap)
			BEGIN
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''RADIOMOVIL DIPSA S.A. DE C.V.'',504,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''RADIOMOVIL DIPSA S.A. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''PEGASO PCS S.A. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''GRUPO AT&T CELULLAR S. DE R.L. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''AT&T COMERCIALIZACION MOVIL S. DE R.L. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''TELEFONOS DE MEXICO S.A.B. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''RADIOMOVIL DIPSA S.A. DE C.V.'',404,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''AT&T COMUNICACIONES DIGITALES S. DE R.L. DE C.V.'',480,2)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''TELEFONOS DE MEXICO S.A.B. DE C.V.'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''PEGASO PCS S.A. DE C.V.'',410,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''GRUPO AT&T CELULLAR S. DE R.L. DE C.V.'',410,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''AXTEL S.A.B. DE C.V.'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''MAXCOM TELECOMUNICACIONES S.A.B. DE C.V.'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''AT&T COMERCIALIZACION MOVIL S. DE R.L. DE C.V.'',410,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''TOTAL PLAY TELECOMUNICACIONES S.A. DE C.V.'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''MEGA CABLE S.A. DE C.V.'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''RADIOMOVIL DIPSA S.A. DE C.V.'',404,10)
			insert ccsipcodemap (country,carrier,resultcode,mappedcode) values (1,''TELEFONOS DE MEXICO S.A.B. DE C.V.'',484,10)
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

		set @process = 'SPEC-9 - Eliminar GetCarrierByTel'
		set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE Name = ''GetCarrierByTel'' 
						 AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
			BEGIN
				DROP FUNCTION  GetCarrierByTel
			END'
		EXEC(@sql)

		set @process = 'SPEC-9 - Crear GetCarrierByTel'
		set @sql = 'CREATE FUNCTION [dbo].[GetCarrierByTel] (@tel VARCHAR(32))
			RETURNS VARCHAR(255)
			AS
			BEGIN
				DECLARE @ld VARCHAR(7), @cldLocal VARCHAR(7)
				DECLARE @lon TINYINT
				DECLARE @mod VARCHAR(10)
				DECLARE @serie VARCHAR(10)
				DECLARE @carrier VARCHAR(255)

				SELECT @lon = len(@tel), @mod = '''', @carrier = ''''

				IF @lon < 10
				BEGIN
					RETURN ''''
				END

				SELECT @cldLocal = valor
				FROM ccSettings WITH (NOLOCK)
				WHERE setting_id = 17

				SELECT @tel = right(@tel, 10)

				SELECT @lon = len(@tel)

				IF @lon = 10
				BEGIN
					IF EXISTS (
								SELECT TOP 1 cld
								FROM series NOLOCK
								WHERE cld = left(@tel, 3)
								and serie=SUBSTRING(@tel,4,3)
								)
							SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
						ELSE IF EXISTS (
								SELECT TOP 1 cld
								FROM series NOLOCK
								WHERE cld = left(@tel, 2)
								and serie=SUBSTRING(@tel,3,4)
								)
							SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)
						ELSE
						BEGIN
							RETURN ''''
						END

					SELECT TOP 1 @mod = modalidad, @carrier= [RAZON SOCIAL]
					FROM series NOLOCK
					WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

				END

				RETURN @carrier
			END'
		EXEC(@sql)

	
	set @process = 'CW-6448 Eliminar sp ccsp_OUTGetCallsInfo_AllCamps si existe'
    set @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_OUTGetCallsInfo_AllCamps'')
    begin
        DROP PROCEDURE ccsp_OUTGetCallsInfo_AllCamps;
    end
    '
    EXEC(@sql)
	
	
	set @process = 'CW-6448 Crear sp ccsp_OUTGetCallsInfo_AllCamps'
    set @sql = '
    CREATE PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
	@Tipo as tinyint= 1,
	@cam_id as smallint = 0,
	@sup_id as smallint= 0
	AS

	declare @mToday as smalldatetime
			
	select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
	if @Tipo = 0
	begin
		SELECT cam_id, cam_descripcion, 0 AS pContesta, 0 AS pOcupado, 0 AS pNoContesta, 0 AS pFaxModem, 0
	AS pNoService, 0 AS Marcaciones, 0 AS Contestan, 0 AS Ocupado, 0 AS NoContesta, 0 AS FaxModem, 0 AS NoService
	FROM ccCamps
		   ORDER BY cam_id;
	end

	else if @Tipo = 1
	begin
		select L.cam_id, L.Campana,
		((L.Contestan*100)/ L.Marcaciones) as pContesta,
		((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		((L.NoService*100)/ L.Marcaciones) as pNoService,
		L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
		,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended,isnull(Abandon,0) As Abandoned
		from (
		select cam_id, '''' as Campana,
		count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Marcaciones
		,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
		,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
		,count(case tipoResDial_id when 11 then 1 else null end) as buzon
		,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
		,count(case tipoResDial_id when 12 then 1 else null end) as congestion

		from ccoLogDials with(nolock)
		Where fecha >  @mToday
		group by cam_id
		) L 
		left join (select 
		cam_id
		,count(case statuscall_id when 6 then 1 else null end) as Abandon
		,count(*) as Contesta
		,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
		,count(case statuscall_id when 13 then 1 else null end) as [Attended]
		from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		where cal_Inicio > @mToday
		group by cam_id) callsOut on L.cam_id = callsOut.cam_id
			  
		order by Campana

	end

	else if @Tipo = 2
	begin
		select cam_id, L.Campana,
		((L.Contestan*100)/ L.Marcaciones) as pContesta,
		((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		((L.NoService*100)/ L.Marcaciones) as pNoService,
		L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		from (
		select C.cam_id as cam_id, cam_descripcion as Campana,
		count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Marcaciones
		from ccoLogDials L with(nolock)
		inner join ccCamps C on L.cam_id=C.cam_id
		Where fecha >  @mToday
		group by C.cam_id, cam_descripcion
		) L order by Campana
	end

	else if @Tipo = 3 --Busqueda por campa?a
	begin
		select L.cam_id,
		L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		from (
		select cam_id,
		count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Calls
		,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		,count(case tipoResDial_id when 12 then 1 else null end) as Congestion

		from ccoLogDials with(nolock)
		Where cam_id = @cam_id
		and fecha >  @mToday
		group by cam_id
		) L 
		left join (select 
		cam_id,
		count(case statuscall_id when 6 then 1 else null end) as Abandon,
		count(*) as Contesta    
		from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		where cal_Inicio > @mToday
		group by cam_id) callsOut on L.cam_id = callsOut.cam_id

	end

	else if @Tipo = 4-- Busqueda por campa?as asociadas a admin
	begin
		select L.cam_id,
		L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended
		from (
		select logDials.cam_id,
		count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		count(case tipoResDial_id when 4 then 1 else null end) as Fax, 
		count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		count(*) as Calls
		,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		,count(case tipoResDial_id when 12 then 1 else null end) as Congestion
		from ccoLogDials logDials with(nolock)
		right join (select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id) B ON logDials.cam_id = B.cam_id
		Where fecha >  @mToday
		group by logDials.cam_id
		) L 
		left join (select 
		cam_id
		,count(case statuscall_id when 6 then 1 else null end) as Abandon
		,count(*) as Contesta
		,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
		,count(case statuscall_id when 13 then 1 else null end) as [Attended]
		from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		where cal_Inicio > @mToday
		group by cam_id) callsOut on L.cam_id = callsOut.cam_id
		order by L.cam_id
	end
	else if @Tipo = 5-- lista campaÃ±as
	begin
	;with callResult as(
	select logDials.cam_id,
		count(*) as Calls,
		count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer		    
		,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		,count(case tipoResDial_id when 11 then 1 else null end) as Machine		    
		from ccoLogDials logDials with(nolock)		  
		Where fecha >  @mToday
		group by logDials.cam_id
	),callData as(
	select 
		cam_id		    		    
		,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
		,count(case statuscall_id when 13 then 1 else null end) as [Attended]
		from ccoCallsOut with(nolock)
		where cal_Inicio > @mToday
		group by cam_id
	)

	select  cast(L.cam_id as int) as Id,
		C.cam_descripcion as CampName,
		L.Calls, L.Answer,L.NoAnswer,isnull(Attended,0) As Attended , 
		L.Canceled
		,isnull(Assigned,0) As Assigned
		,c.aggressionFactor as AggressionFactor
		,L.Busy
		,L.Machine
		,isnull(Other,0) as Other
		,area.AreaName as Area
		from callResult as L 
		inner join ccCamps C on L.cam_id=C.cam_id
		inner join ccRIACat_Areas area on area.IDArea=c.IDArea
		left join callData callsOut on L.cam_id = callsOut.cam_id
		
		order by L.cam_id

	end
    '
    EXEC(@sql)




	set @process = 'CW-6799 update configuraIdiomaCatalogosEspañol -------- '
	set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol] AS
				SET NOCOUNT ON

				Print ''Iniciando proceso de configuracion en Español''

				Print ''Estableciendo Horarios''
				Delete [dbo].[ccHorarios]
				DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
				INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
				INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
				INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
				INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

				Print ''Estableciendo Not Ready y graficas''
				Delete [ccRIANotReadyGraph]
				Delete [dbo].[ccTipoNotReady]
				Delete [ccRIAGraphics]

				DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

				DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
				INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
				INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

				Print ''Estableciendo Status de llamadas''
				delete from [dbo].[ccStatusLLamada]

				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
				update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

				Print ''Estableciendo los tipos de dias''
				truncate table [dbo].[ccTipoDias]
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

				Print ''Estableciendo resultados de marcacion''
				delete from [dbo].[ccTipoResultadoDial]

				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

				Print ''Estableciendo los tipos de estado de los agentes''
				Delete [dbo].[ccTipoStatusAgente]

				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, convert(text, N''Preview'' collate SQL_Latin1_General_CP1_CI_AS))

				Print ''Estableciendo los tipos de usuario''
				Delete [dbo].[ccTipoUsers]
				INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

				Print ''Estableciendo los dias''
				Delete [dbo].[ccDias]
				DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
				SET IDENTITY_INSERT [ccDias] ON
				INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
				SET IDENTITY_INSERT [ccDias] OFF

				Print ''Estableciendo los tipos de llamada''
				delete from [dbo].cstoTarifa
				delete cstoTipoLlamada

				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
				INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

				Print ''Estableciendo los movimientos de lista negra''
				Delete [dbo].[ccTipoMovsListaNegra]
				SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, convert(text, N''Agregado por calificación por campaña'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, convert(text, N''Carga Registro Cliente Lista Negra''collate SQL_Latin1_General_CP1_CI_AS))
				INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, convert(text, N''Agregado por calificación por ACD'' collate SQL_Latin1_General_CP1_CI_AS))
				SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

				Print ''Estableciendo los tipos de calificacion''
				Delete [dbo].[ccTipoCalif]
				INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
				INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
				INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

				Print ''Estableciendo los tipos de calificacion de salida''
				Delete [dbo].[ccTipoCalifOUT]
				INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
				INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
				INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

				Print ''Estableciendo proveedores''
				Delete [dbo].[cstoProvedor]
				DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
				INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

				Print ''Mensajes voz defualt''
				DELETE [dbo].[ccMsgFiles]
				DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
				INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


				Print ''Mensajes default chat''
				DELETE [dbo].[ccRIAChatInboundMsgs]
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
				INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')
				'
	EXEC(@sql)

		set @process = 'KR007004 update ccTipoMovsListaNegra 6-------- '
		set @sql='DECLARE @valorLang INT; 
					select @valorLang = valor from ccSettings where setting_id = 27; 
					if @valorLang = 0 begin update ccTipoMovsListaNegra set movimiento=''Agregado por calificación por campaña'' where idtipomov = 6  end'
		EXEC(@sql)

		set @process = 'KR007004 update ccTipoMovsListaNegra 9 -------- '
		set @sql='DECLARE @valorLang INT; 
					select @valorLang = valor from ccSettings where setting_id = 27; 
					if @valorLang = 0 begin update ccTipoMovsListaNegra set movimiento=''Agregado por calificación por ACD'' where idtipomov = 9  end'
		EXEC(@sql)

		set @process = 'CW-6799 insert ccTipoMovsListaNegra -------- '
		set @sql='DECLARE @valorLang INT; 
					select @valorLang = valor from ccSettings where setting_id = 27; 
					if @valorLang = 0 begin if not exists (select * from ccTipoMovsListaNegra where idtipomov = 1) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Carga Registro Lista Negra''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 2) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Lista Negra en Carga de Registros''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 3) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Eliminado por Aplicar Lista Negra''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 4) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Eliminado de Lista Negra por Remplazo ''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 5) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Borrado de Lista Negra''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 6) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Agregado por calificación por campaña''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 7) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Carga Lista Negra''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 8) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Carga Registro Cliente Lista Negra''); 
					if not exists (select * from ccTipoMovsListaNegra where idtipomov = 9) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, ''Agregado por calificación por ACD''); end'
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


