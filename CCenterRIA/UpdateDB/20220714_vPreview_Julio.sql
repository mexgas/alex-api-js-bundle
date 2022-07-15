/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/05/23
Description: Archivo mayo 2022, cambios preview

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
SET @versionfix = 31
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

	set @process = 'CW-PREVIEW se agrega campo para permiso eliminar en campañas preview'
    set @sql = 'IF not exists(SELECT top 1 1
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE COLUMN_NAME = ''AllowDeleteRecord'' AND TABLE_NAME = ''ccUsers'')
		BEGIN
			ALTER TABLE ccUsers ADD AllowDeleteRecord bit not null DEFAULT(0)
		END'
	EXEC(@sql)

    set @process = 'CW-PREVIEW eliminar sp ccsp_GalateaAdminSetPermissions'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSetPermissions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
    end'
    EXEC(@sql)

    set @process = 'CW-PREVIEW se agrega SP ccsp_GalateaAdminSetPermissions'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
                    @user_id varchar(MAX),
                    @permissionName VARCHAR(255),
                    @permissionValue INT
                AS
                SET NOCOUNT ON

                DECLARE @changeBit INT

                SET @changeBit =
                CASE
                    WHEN @permissionName = ''AllowCellPhoneCalls'' or @permissionName = ''startStopRecording'' or @permissionName = ''XferManual'' or @permissionName = ''AllowTransferCalls'' or @permissionName = ''AgentPermissionDailing''or @permissionName = ''DailingMode'' or @permissionName=''AgentPermissionDailing'' or @permissionName=''AgentPermissionDelete''
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
                        END,
                        AllowDeleteRecord = 
                        CASE
                        WHEN @permissionName = ''AgentPermissionDelete'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN 1
                            WHEN @permissionValue = 0
                            THEN 0
                            END
                        ELSE AllowDeleteRecord
                        END
                    WHERE User_id IN (select value from dbo.fn_RIASplitDelimited(@user_id,'',''))
                END

                SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'CW-PREVIEW eliminar sp ccsp_GalateaAdminGetPermissions'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetPermissions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
    end'
    EXEC(@sql)

    set @process = 'CW-PREVIEW agregar sp ccsp_GalateaAdminGetPermissions'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
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
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
                cast(AllowDeleteRecord as int) as AgentPermissionDelete
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
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
                cast(AllowDeleteRecord as int) as AgentPermissionDelete
            from 
                ccUsers A
            join ccRIAWorkGroupUsers B on 
                A.user_id = B.user_id
            where 
                tipoUser_id = 1 and 
                IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
            return(0)
            END
            set nocount off'
    EXEC(@sql)

    set @process = 'CW-PREVIEW eliminar sp ccsp_GalateaGetPreviewData'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetPreviewData'')
    begin
        DROP PROCEDURE ccsp_GalateaGetPreviewData;
    end'
    EXEC(@sql)

    set @process = 'CW-PREVIEW agregar sp ccsp_GalateaGetPreviewData'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @callout_id int,
        @user_id smallint

        AS
        set nocount on

        select''previewData''=
         case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
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
         ISNULL(P.Dato15,'''')+''~''+
         ISNULL(O.cal_telefono2,'''')+''~''+
         ISNULL(O.cal_telefono3,'''')+''~''+
         ISNULL(O.cal_telefono4,'''')+''~''+
         ISNULL(O.cal_telefono5,'''')+''~''+
         ISNULL(O.cal_telefono5,'''')+''~''
               from ccUsers U,ccoCallsOutSource O (nolock)
        INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
        Where callout_id=@callout_id and U.User_id=@user_id
        --union
        --select AllowDeleteRecord+''~'' from ccUsers where User_id=@user_id

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


