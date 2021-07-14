/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 21
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= 19
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-5390 se quita el sp ccsp_GalateaAdminGetPermissions si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetPermissions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
            end'
    EXEC(@sql)

	set @process = 'CW-5390 Alter procedure ccsp_GalateaAdminGetPermissions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
                    @user_id varchar(255),
                    @Type int
                AS
                set nocount on

                Select distinct A.User_id as AgentId, Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' +
                isNull(ApellidoMaterno, '''') as FullName, cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording
                from ccUsers A
                join ccRIAWorkGroupUsers B on A.user_id = B.user_id
                where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
                return(0)

                set nocount off'
	exec (@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaGetAdminRelations si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetAdminRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaGetAdminRelations;
            end'
    EXEC(@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaGetAdminRelations si ya existe'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetAdminRelations]
                @Option smallint,
                @areaId AS INT = 0,
                @AdminId AS INT = 0
                as
                declare @agentes varchar(max)
                declare @wgs varchar(max)
                declare @count int
                declare @id int
                declare @wg int

                if @option =1 --Obtiene las relaciones de los Administradores con los WG
                begin
                    SELECT 
                    ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
                    IDWG,@agentes as agents
                    into #Relations
                    FROM ccRIAAreaWorkGroup 

                    if not exists(select * from ccRIACat_Areas) or (select count(idWG) from #Relations) = 0
                    begin
                        select Null as IDWG ,@agentes as agents, @wgs as idsWg
                        return (0)
                    end

                    select @count = count(idWG) from #Relations
                    set @id =1
                    while @id<=@count
                    begin
                        select @wg =idwg from #Relations where Row =@id
                        select @agentes=null
                        select @agentes = coalesce(@agentes + '','', '''') +  convert(varchar(12),wgu.user_id)
                        from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
                        where TipoUser_id = 1 and wgu.IDWG =@wg
                        order by u.user_id

                        Update #Relations set agents= @agentes where IDWG= @wg
                        set @id=@id+1
                    end
                    if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
                        BEGIN
                            select  Cast(Re.IDWG as varchar(10)) as idwg,agents
                            from #Relations Re
                            right JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = Re.IDWG
                            where wg.StatusWorkGroup = 1
                        END

                        ELSE
                        BEGIN
                            SELECT @AdminId = ISNULL(@AdminId, 0)			
                        
                            select  Cast(Re.IDWG as varchar(10)) as idwg,agents
                            from #Relations Re
                            Left JOIN  ccRIAWorkGroupUsers wg ON wg.IDWG = Re.IDWG
                            WHERE wg.User_id = @AdminId
                        END		

                end'
	exec (@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaAdminSetPermissions si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSetPermissions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
            end'
    EXEC(@sql)

    set @process = 'CW-5390 Alter procedure ccsp_GalateaAdminSetPermissions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
                    @user_id varchar(MAX),
                    @permissionName VARCHAR(255),
                    @permissionValue INT
                AS
                SET NOCOUNT ON

                DECLARE @changeBit INT

                SET @changeBit =
                CASE
                    WHEN @permissionName = ''AllowCellPhoneCalls'' or @permissionName = ''startStopRecording'' or @permissionName = ''XferManual'' or @permissionName = ''AllowTransferCalls''
                    THEN 1
                    WHEN @permissionName = ''AllowLongDistanceCalls'' or @permissionName = ''XferExt''
                    THEN 2
                    WHEN @permissionName = ''AllowLocalCalls'' or @permissionName = ''XferCamps''
                    THEN 4
                    WHEN @permissionName = ''XferAgents''
                    THEN 8
                    ELSE 0
                END

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
						END
                    WHERE User_id IN (select value from dbo.fn_RIASplitDelimited(@user_id,'',''))
                END

                SET NOCOUNT OFF'
	exec (@sql)


	set @process = 'CW-55543 No se muestran los datos de llamadas de entrada en reportes'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateDataCallIn'')
            begin
          DROP PROCEDURE ccsp_RIAUpdateDataCallIn;
            end'
    EXEC(@sql)

	set @process = 'CW-55543 No se muestran los datos de llamadas de entrada en reportes'
    set @sql = 'CREATE procedure [dbo].[ccsp_RIAUpdateDataCallIn]
@calloutid int,
@callid int,
@typecall smallint,
@data1 varchar(100),
@data2 varchar(100),
@data3 varchar(100),
@data4 varchar(100),
@data5 varchar(100)

AS

if @typecall = 1 --Inbound 
begin
	IF EXISTS (SELECT * FROM DataCallIn WHERE CallId=@callid )
		DELETE FROM DataCallIn WHERE CallId=@callid

	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data1, ''Dato 1'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data2, ''Dato 2'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data3, ''Dato 3'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data4, ''Dato 4'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data5, ''Dato 5'' )
end
	
if @typecall = 2 --Outbound 
begin
	update ccocallsoutsource set Dato1 = @data1,
			Dato2 = @data2,
			Dato3 = @data3,
			Dato4 = @data4,
			Dato5 = @data5 where callout_id = @calloutid
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