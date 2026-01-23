/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Carlos Eduardo Muñoz Carbajal
Date: 2025/10/08
Description: Sprint 4 - Agente Luis
Database: CCenterRia
Required version: 127.2
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
    SET @version = 127 --**********actualizar a 124 sin fix
    SET @versionfix = 9
    /* Actual version (use your own script to do it)*/
    EXEC @actualVersion = ccsp_getVersion 'BD'
    EXEC @actualVersionFix = ccsp_getVersion 'BDF'
    SELECT @versionALL = valor
    FROM ccsettings
    WHERE setting_id = 77;
    SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
    FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
    WHERE id = 5;
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

    ------------------------------------ BEGIN UNION 127.20250905.0.6 -- 127.20251008.0.1 ------------------------------------
    
    --------------------------------- BEGIN HCR 20250905.0.6-----------------------------------
    SET @process = 'Z3500 Constraint a la tabla ccCampsExtend con valor default en 0  '
    SET @sql = 'if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''DF_ccCampsExtend_zipCodeSchedule'')
                begin
                    ALTER TABLE dbo.ccCampsExtend ADD CONSTRAINT 
                    DF_ccCampsExtend_zipCodeSchedule DEFAULT 0 FOR [zipCodeSchedule]
                end
                '
    EXEC(@sql)
    --------------------------------- END HCR 20250905.0.6 ------------------------------------------------

    --------------------------------- BEGIN Gallardo 20250905.0.6-----------------------------------
    SET @process = 'ALTER PROCEDURE [dbo].[ccspCCserverLoadCamp] se agerga ccVirtualAgent camtype=1 para solo campañas de salida'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspCCserverLoadCamp]
@Type as smallint
AS
BEGIN
    DECLARE @sql NVARCHAR(max)

    SET @sql = ''SELECT
                    c.cam_id
                   ,ISNULL(g.graphic_id, 1) graphic_id
                   ,c.cam_descripcion
                   ,c.cam_tnotas
                   ,c.cam_maxqueue
                   ,c.cam_procesando
                   ,c.CampType
                   ,ISNULL(v.idAgent, 0) AS IdAgentVirtual
                   ,ISNULL(v.nameAgent, '''''''') AS NameAgentVirtual
                   ,ISNULL(v.concurrentSessionsLimit, 0) AS AgtVirtual
                FROM ccCamps c (NOLOCK)
                LEFT JOIN ccRIACampsGraph g (NOLOCK) ON g.cam_id = c.cam_id
                LEFT JOIN ccVirtualAgent v (NOLOCK) ON v.idCampaign = c.cam_id and v.campType=1
                WHERE cam_activo = 1''

    IF @Type<>1 BEGIN
        SET @sql = @sql + '' AND cam_bNew=2''
    END
    EXEC (@sql)
END
                '
    EXEC(@sql)

      SET @process = '#3138 ALTER PROCEDURE [dbo].[ccsp_RIAACDCallParams] valor default'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAACDCallParams]
@option int,
@campId int = 0
AS
BEGIN
    SET NOCOUNT ON;
declare @RecordCalls tinyint
set @RecordCalls=0
if(@option = 1)
begin
    select @RecordCalls= RecordCalls from ccInboundExtend where Inbound_id = @campId                
end

else if(@option = 2)
begin
    select @RecordCalls= RecordCalls from ccCampsExtend where cam_id = @campId              
end
select isnull(@RecordCalls,1) RecordCalls

    SET NOCOUNT OFF;
END'
    EXEC(@sql)
    --------------------------------- END Gallardo 20250905.0.6 ------------------------------------------------

    
    
    ------------------------------------------ Daniel Hernandez ------------------------------------------------
    SET @process = '#3271-KM24001 Setting for record load marking restriction'
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM [dbo].[ccSettings2] WHERE [setting_id] = 291)
    BEGIN
        INSERT INTO [dbo].[ccSettings2]
               ([setting_id]
               ,[valor]
               ,[descripcion]
               ,[Status]
               ,[Tipo]
               ,[detalle]
               ,[description]
               ,[bLoadSettings]
               ,[validate])
         VALUES
               (291
               ,''0''
               ,''Restricción de carga de registros en campañas de voz estándar''
               ,1
               ,''ADM''
               ,''0:(Default)No se deberá poder cargar bases de datos a campañas al menos que la campaña se encuentre apagada. |1:Se deberá permitir la carga de bases de datos a las campañas iniciadas desde los botones o secciones ya disponibles en el sitio.''
               ,''0:(Default) Database uploads should not be allowed to campaigns unless the campaign is turned off |1: Database uploads should be allowed to campaigns started from buttons or sections already available on the site''
               ,1
               ,''.*'')
    END'
    EXEC(@sql)
    ------------------------------------------------------------------------------------------------------------
    

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

    SET @process = ''
    SET @sql = ''

    EXEC(@sql)

	------------------------------------ END UNION 127.20250905.0.6 -- 127.20251008.0.1 ------------------------------------

	
    /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
