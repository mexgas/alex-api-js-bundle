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
		select cam_id, '' as Campana,
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
	else if @Tipo = 5-- lista campañas
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


