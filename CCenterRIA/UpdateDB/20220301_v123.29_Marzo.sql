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


