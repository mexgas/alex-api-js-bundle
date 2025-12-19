/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/12/17
Description:

Database: CCenterRia
Required version: 121.11

Se agrega la tarea
	CW-2467

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 121--**********actualizar a 119 sin fix
set @versionfix = 22
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 11
	begin
		begin tran
		begin try


---------------------------BEGIN Octavio Ortiz Nova monti 8 fixes--------------------------------------------------
    /* =========================================================================================
   1) ccsp_AgentUpdateCallCALIF 
   ========================================================================================= */

SET @process = 'Drop Procedure [dbo].[ccsp_AgentUpdateCallCALIF]';
SET @sql = N'
IF OBJECT_ID(N''dbo.ccsp_AgentUpdateCallCALIF'', ''P'') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF];
END';
EXEC(@sql);

SET @process = 'Create Procedure [dbo].[ccsp_AgentUpdateCallCALIF]';
SET @sql = N'
CREATE PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] -- FIX #4852
    @IDCall INT, 
    @calif_id SMALLINT, 
    @TipoCall SMALLINT,
    @Origin INT = 0, 
    @cal_key VARCHAR(40) = NULL, 
    @callOutId INT = 0, 
    @subId SMALLINT = 0
AS
SET NOCOUNT ON;

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, 
@tel VARCHAR(30), @camp INT, @iddncList AS INT,@completatel VARCHAR(30),@camId int,@dni_id int
,@useCalkeyBlackList bit
,@userid INT
,@statusCallId int
,@hashTel INT;

SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60;

SELECT @RecicleSIC = ISNULL(@RecicleSIC, 0);

DECLARE @killListID INT = (
        SELECT idtipolista
        FROM ccTiposListaNegra
        WHERE Tipolista = ''default/KillList''
        );

DECLARE @killListSetting INT = (
        SELECT STATUS
        FROM ccSettings
        WHERE setting_id = 215
        );

IF @TipoCall = 1
BEGIN
    UPDATE ccCallsIN
    SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = ISNULL(@cal_key, cal_key)
    , califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    ,@statusCallId=statusCall_id
    WHERE cal_id = @IDCall;

    EXEC ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=0,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=13;

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 0 AND calif_id = @calif_id
            )
    BEGIN
        SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
        ,@camId=Inbound_id,@dni_id=dni_id
        FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
        JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
        WHERE ci.cal_id = @idCall AND LEFT(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0;

        IF @tel IS NOT NULL AND @iddncList IS NOT NULL
        BEGIN
            SELECT @useCalkeyBlackList = valor
            FROM ccSettings2
            WHERE setting_id = 288;

            IF @useCalkeyBlackList IS NULL SET @useCalkeyBlackList=0;    
            IF @useCalkeyBlackList=0 SET @cal_key=NULL;

            INSERT INTO cclistanegra (telefono, idtipolista, calKey)
            VALUES (@tel, @iddncList, @cal_key);

            IF (@killListSetting = 1 AND @iddncList = @killListID)
            BEGIN
                SELECT @hashTel = dbo.hashPhone(@tel);

                IF NOT EXISTS (
                        SELECT hashtel
                        FROM cc_KillList
                        WHERE hashTel = @hashTel
                        )
                BEGIN
                    INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
                    VALUES (@hashTel, @iddncList, GETDATE());
                END
            END

            INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
            VALUES (@tel,@iddncList,@camId,GETDATE(),@dni_id,6);            
        END
    END

    RETURN (0);
END

IF @TipoCall = 2
BEGIN
    SELECT @autoCB = autocallback
    FROM ccTipoCalifSubout
    WHERE califSub_Id = @subId;

    IF @autoCB IS NULL
    BEGIN
        SELECT @autoCB = autocallback
        FROM cctipocalifout
        WHERE calif_id = @calif_id;
    END

    SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
    ,@statusCallId=statusCall_id
    ,@tel=cal_telefono
        FROM ccocallsout
        WHERE Cal_id = @IDCall;

    IF @autoCB = 1
    BEGIN
        SELECT @DateNewDial = DATEADD(mi, t_autoCB, GETDATE())
        FROM cccamps cam
        WHERE cam.cam_id = @camp;

        EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1;
    END

    UPDATE ccoCallsOUT
    SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    WHERE cal_id = @IDCall;

    EXEC ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=1,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=@statusCallId;

    SELECT @useCalkeyBlackList = valor
    FROM ccSettings2
    WHERE setting_id = 288;

    IF @useCalkeyBlackList IS NULL SET @useCalkeyBlackList=0;

    SET @completatel=dbo.Completa_ListaNegra(@tel);

    IF @useCalkeyBlackList=0 SET @cal_key=NULL;
    
    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 1 AND calif_id = @calif_id
            ) AND NOT EXISTS (
            SELECT 1 FROM ccListaNegra bl WITH(NOLOCK) 
            WHERE (telefono=@tel OR telefono=@completatel)
              AND calKey=@cal_key
              AND bl.idtipolista IN (
                    SELECT idTipoLista
                    FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
                    WHERE tipo = 1 AND calif_id = @calif_id
              )   
            )
    BEGIN
    
        CREATE TABLE #NUMANDBL (id int identity,  iddncList int);
        CREATE TABLE #NUMBERS (id int identity, number varchar(30));
        DECLARE @allnumbersToBl BIT;
        DECLARE @number varchar(30);

        SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id;

        IF(@allnumbersToBl = 1)
        BEGIN
            SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall;
            DECLARE @i SMALLINT = 0;
            WHILE (@i < 5 )
            BEGIN
                SELECT @number = CASE @i 
                                    WHEN 0 THEN cal_telefono 
                                    WHEN 1 THEN cal_telefono2
                                    WHEN 2 THEN cal_telefono3
                                    WHEN 3 THEN cal_telefono4
                                    WHEN 4 THEN cal_telefono5
                                    END
                FROM ccoCallsOutSource 
                WHERE callout_id = @callOutId AND cam_id = @camid;

                SET @number = dbo.Completa_ListaNegra(@number);

                IF(LEFT(@number, 1) <> ''E'') 
                BEGIN
                    INSERT INTO #NUMBERS (number) VALUES (@number);
                END
                SET @i = @i + 1;
            END
        END
        ELSE
        BEGIN
            SELECT @number = co.cal_telefono
            FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
            WHERE co.cal_id = @idCall;

            SET @number = dbo.Completa_ListaNegra(@number);

            IF(LEFT(@number, 1) <> ''E'') 
            BEGIN
                INSERT INTO #NUMBERS (number) VALUES (@number);
            END
        END

        IF EXISTS(SELECT 1 FROM #NUMBERS)
        BEGIN
            INSERT INTO #NUMANDBL (iddncList) 
            SELECT cbl.idTipoLista 
            FROM cccalifblacklist cbl  
            WHERE cbl.calif_id=@calif_id AND cbl.tipo = 1;
        END

        DECLARE @Count int;      
        WHILE (SELECT COUNT(id) FROM #NUMANDBL) > 0
        BEGIN
            SELECT @Count = COUNT(id) FROM #NUMANDBL;
            SELECT @iddncList = iddncList FROM #NUMANDBL WHERE id = @Count;

            DECLARE @countNumbers INT, @indexNumbers INT = 1;
            SELECT @countNumbers = COUNT(*) FROM #NUMBERS;

            WHILE( @indexNumbers <= @countNumbers)
            BEGIN 
                SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers;

                IF @tel IS NOT NULL AND @iddncList IS NOT NULL
                BEGIN
                    EXEC ccsp_InsertDNCList @telephone = @tel, @ln_id = @iddncList, @calKey= @cal_key;

                    IF (@killListSetting = 1 AND @iddncList = @killListID)
                    BEGIN
                        SELECT @hashTel = dbo.hashPhone(@tel);

                        IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
                        BEGIN
                            INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
                            VALUES (@hashTel, @iddncList, GETDATE());
                        END
                    END

                    INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
                    SELECT @tel, @iddncList, co.cam_id, GETDATE(), co.callout_id, 6
                    FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
                    WHERE co.cal_id = @idCall;
                END
                SET @indexNumbers = @indexNumbers + 1;
            END

            DELETE FROM #NUMANDBL WHERE id = @Count;
        END

        DROP TABLE #NUMANDBL;
        DROP TABLE #NUMBERS;
    END

    IF @RecicleSIC = 1
    BEGIN
        SELECT @Reprogram = CanReprogram
        FROM ccTipoCalifSubout
        WHERE califSub_Id = @subId;

        IF @Reprogram IS NULL
        BEGIN
            SELECT @Reprogram = CanReprogram
            FROM ccTipoCalifOUT
            WHERE calif_id = @calif_id;
        END

        IF @callOutId = 0
            SELECT @callOutId = callout_id
            FROM ccocallsout
            WHERE Cal_id = @IDCall;

        UPDATE ccoWorkingTable
        SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
        WHERE callout_id = @callOutId;
    END

    DECLARE @keepDial BIT;
    DECLARE @finishPreview SMALLINT;

    SELECT @keepDial = keepDial
    FROM ccTipoCalifSubout
    WHERE califSub_Id = @subId;

    IF @keepDial IS NULL
    BEGIN
        SELECT @keepDial = keepDial
        FROM ccTipoCalifout
        WHERE calif_id = @calif_id;
    END

    SELECT @finishPreview = ISNULL(finishPreview, 0)
    FROM ccTipoCalifout
    WHERE calif_id = @calif_id;

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
                );
    END

    SELECT @keepDial as keepDial, @finishPreview as finishPreview;

    RETURN (0);
END

SET NOCOUNT OFF;
';
EXEC(@sql);



/* =========================================================================================
   2) ccsp_InsertDNCList
   ========================================================================================= */

SET @process = 'Drop Procedure [dbo].[ccsp_InsertDNCList]';
SET @sql = N'
IF OBJECT_ID(N''dbo.ccsp_InsertDNCList'', ''P'') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[ccsp_InsertDNCList];
END';
EXEC(@sql);

SET @process = 'Create Procedure [dbo].[ccsp_InsertDNCList]';
SET @sql = N'
CREATE PROCEDURE [dbo].[ccsp_InsertDNCList] -- FIX #4852
    @telephone as nvarchar(30)=null,
    @ln_id as integer,
    @hashCalKey bigint=NULL,
    @calKey VARCHAR(40) = NULL,
    @cleanType int=0 --0 limpia,2 verifica
AS

SET NOCOUNT ON;

DECLARE @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null
,@fnPhone nvarchar(100) =null
,@motivo nvarchar(100)
,@keyTranslate nvarchar(100)
,@params nvarchar(max);

DECLARE @phoneEmpty nvarchar(1);
SET @phoneEmpty = '''';

SET @fnPhone=CASE WHEN @cleanType=0 THEN ''[dbo].[Limpia](@telephone)'' ELSE  ''[dbo].[Verifica](@telephone)'' END;

SET @motivo=CASE WHEN @cleanType=0 THEN ''Length exceeded'' ELSE  ''Error en COFETEL'' END;
SET @keyTranslate=CASE WHEN @cleanType=0 THEN ''description-length'' ELSE  ''description-cofetel'' END;

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

IF (@telephone IS NOT NULL)
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey))
    BEGIN
        RETURN 0;
    END

    SET @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+@fnPhone+'',@calKey );
    '';
    EXEC (@dropTmpPhone);   
    
    EXEC sp_executesql @sqlcmd, N''@telephone nvarchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
    
END
ELSE IF @cleanType<>0
BEGIN
    SET @fnPhone=CASE WHEN @cleanType=0 THEN ''[dbo].[Limpia](phoneNumber)'' ELSE  ''[dbo].[Verifica](phoneNumber)'' END;
    
    SET @sqlcmd=''update '' + @tmpTableName + '' set phoneNumber='' + @fnPhone;
    EXEC (@sqlcmd);

    SET @sqlcmd=''
    Insert into ccRIALogPhones 
select @ln_id,@phoneEmpty,phoneNumber,0,@motivo,@keyTranslate 
from ''+ @tmpTableName+''
where left(phoneNumber,1)= ''''E''''
delete from ''+ @tmpTableName+'' where left(phoneNumber,1)= ''''E''''
'';
    
    SET @params=''@ln_id int, @phoneEmpty nvarchar(1),@motivo nvarchar(100),@keyTranslate nvarchar(100)'';
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id
    ,@phoneEmpty=@phoneEmpty,@motivo =@motivo ,@keyTranslate =@keyTranslate;

END

SET @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.idtipolista = @ln_id AND B.telefono is not null'';

SET @params=''@ln_id int'';
EXEC sp_executesql @sqlcmd,@params, @ln_id=@ln_id;

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '' A 

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '' A '';

EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps;
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall;
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall;
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall;

CREATE TABLE [dbo].[#mycamps] ( [campsid] [int] NULL);
CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]);

INSERT #mycamps
SELECT A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5);

CREATE TABLE [dbo].[#myprincipaltempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    );

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]);
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]);
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]);
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]);
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]);
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]);

CREATE TABLE [dbo].[#helpTempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    );

CREATE TABLE [dbo].[#mytempCall](
    [callout_id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
);

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]);

DECLARE @fech datetime = getdate()-30;
SET @sqlcmd = ''
    insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  cal_fechadial > getdate()-30
    '';

SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'');
EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

DECLARE @columnIndex INT = 2;
WHILE @columnIndex <= 5
BEGIN
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono''+CONVERT(varchar(10),@columnIndex));
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
    SET @columnIndex=@columnIndex+1;
END

SET @sqlcmd = ''insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
    where cal_fechadial > getdate()-30;
    '';

EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

INSERT INTO #myprincipaltempCall
SELECT * FROM #helpTempCall
GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5;

IF EXISTS (SELECT * FROM #myprincipaltempCall)
BEGIN
    DECLARE @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
    ,@sqlWithReplace nvarchar(max);
    
    SET @column=''cal_telefono'';
    SET @params=''@phoneEmpty varchar(1),@fech datetime'';
    SET @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
    and cs.cal_telefono3=@phoneEmpty
    and cs.cal_telefono4=@phoneEmpty
    and cs.cal_telefono5=@phoneEmpty'';
    
    SET @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
    when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
    when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
    when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
    else @phoneEmpty end 
    ,wt.iZonaHoraria=null, wt.iZonaHoraria_verano=null'';  

    SET @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set cal_telefono = CASE_UPDATE_WT
    from ccoCallsOutSource cs 
    inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono'';

    SET @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty

if EXISTS (select * from #mytempCall)
begin       
    delete wt with(rowlock)
    from ccoWOrkingTable wt 
    inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
    inner join #mytempCall t on wt.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and
    cs.COLUMN_CHECK = wt.cal_telefono
    AND_DELETE_WT

    UPDATE_CALL_WT_QUERY

    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    update ccoCallsOutSource 
    set COLUMN_CHECK = @phoneEmpty
    ,COLUMN_ZONE_CHECK=0
    ,COLUMN_ZONE_CHECK_VERANO=0
    from ccoCallsOutSource cs 
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech      

    truncate table #mytempCall
end'';

    SET @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking );
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano'');
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria'');
    
    EXEC sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech;

    SET @column=''cal_telefono2'';
    
    SET @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
        and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty'';
    
    SET @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
        when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end '';

    SET @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking );
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano2'');
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria2'');

    EXEC sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech;

    SET @column=''cal_telefono3'';
    
    SET @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty'';
    
    SET @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end '';

    SET @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking );
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano3'');
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria3'');

    EXEC sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech;

    SET @column=''cal_telefono4'';
    
    SET @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty'';
    
    SET @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end '';

    SET @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking );
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano4'');
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria4'');
   
    EXEC sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech;

    SET @column=''cal_telefono5'';   
    SET @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty'';

    SET @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'', '' '');
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking);
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano4'');
    SET @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria4'');

    EXEC sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech;

END

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps;
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall;
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall;
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall;
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);
';
EXEC(@sql);


    ---------------------------------END Octavio Ortiz-----------------------------------------------------------------

		 set @process = 'CW-2467 --Alter SP ccsp_RIAGetCampsNvosCB'
        set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

  declare @id AS INTEGER

  CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
  CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)

  create table #temccocallsoutsource (cam_id int,Pend  int)

  create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

  if @cam_id = 0 begin
    if @user_id > 0 begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam with(nolock) left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where user_id = @user_id and tipo = 1
    end
    else begin
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
      from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
    end

  end
  else begin
    if @Tipo = 2
      insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
      select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
      from ccCamps cam with(nolock)
      left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
      where cam.cam_id = @cam_id
    else
      if @user_id > 0 begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam with(nolock) left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and tipo = 1
       end
      else begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
          select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
          from ccCamps where cam_activo=1
      end
  end



  insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
  select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0 from(
  select A.* from #Tcamps A
  left join ccCampsNvosCB B  on A.cam_id=B.id
  where datediff(ss,B.dateUpdate,getdate())>5 or B.dateUpdate is null)X

  group by cam_id


  --Se revisa que por lo menos una campaña se pueda actualizar para realizar el proceso en caso contrario se regresa el valro extablecido
  if (select count(*) from #Tcamps2)>0 begin

    insert into #temccocallsoutsource(cam_id,Pend)
    SELECT ccos.cam_id, count(ccos.cam_id) as Pend
    FROM ccocallsoutsource ccos with(nolock)
    left join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
    WHERE cal_status in(0, 7)
    GROUP BY ccos.cam_id

    insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
    SELECT A.cam_id,
    count(case cal_status when 0 then 1 else null end) as New,
    count(case cal_status when 1 then 1 else null end) as Cb,
    count(case cal_status when 2 then 1 else null end) as Pro,
    count(case cal_status when 3 then 1 else null end) as Fin
    FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
    inner join #Tcamps2 B on A.cam_id = B.cam_id
    GROUP BY A.cam_id

    --select * from #Tcamps2

    --Se va agregar al ccsp_OUTGetNewJobs cuando lo ejecute el SP Outbound para actualizar de manera seguida si solo es una campaña
    if @regval = 0 and @cam_id >0 and @Tipo =2 begin
      update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
    end
    else begin
      While (select count(*) from #Tcamps2 where status = 0) > 0 Begin
        set rowcount 1
        select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
        set rowcount 0
        EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
      end
    end

    begin Tran updateccCampsNvosCB

      delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
      where CampNvosCB.id = tcamp.cam_id

      INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial,dateUpdate)
      SELECT cams.cam_id, cams.cam_descripcion,
      isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
      isNull(cs.Pend,0) as pend,
      isNull(wt.Pro,0) as pro,
      isNull(cams.procesando,0) cam_procesando,
      isNull(cams.cam_tipojobs,0) cam_tipojobs,
      isNull(wt.Fin,0) Fin,
      isNull(tc.cantidad,0) cantidad,
      getdate()
      FROM #Tcamps cams with(nolock)
      LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
      LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
      left join #Tcamps2 tc on (tc.cam_id = cams.cam_id)

    COMMIT TRAN updateccCampsNvosCB
  end

  if @isExecOutbound = 0 begin

    if @Tipo = 2
      -- devuelve resultado de la taba, solo las camps del usuario
      SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor
      FROM #Tcamps tcam
      left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
	  inner join cccamps cc on res.id=cc.cam_id
    else
      SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,cc.aggressionFactor
      FROM ccCampsNvosCB res
      LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
	  inner join cccamps cc on res.id=cc.cam_id
      WHERE res.id = @cam_id
  end

  drop table #Tcamps
  drop table #Tcamps2
  drop table #temccocallsoutsource
  drop table #temWorkinTable

  return(0)

end

set nocount off'
        EXEC(@Sql)



set @process = 'CW-2466 contraseña segura alter de ccsp_RIAChecaLogin'
        set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_RIAChecaLogin]
@Login varchar(20),
@Password varchar(40),
@Computer varchar(20),
@PasswordLwC varchar(40) = null
AS
declare @LoginOK tinyint, @PswdOK tinyint, @CompuOK tinyint, @ExtenOK tinyint, @TeclaOK tinyint, @XferAgents tinyint
declare @Nombre varchar(60), @Extension varchar(15), @UserID smallint, @CCServer varchar(20)

--Para posiciones ip, by ODC
declare @ext_id int, @pos_id int, @isIP bit, @ipExtension varchar(15)

-- Para live connected
-- Tipo de conexion: 0 normal, 1 liveconnected
declare @tipoConexion smallint

SELECT @LoginOK=0, @PswdOK=0, @CompuOK=0, @ExtenOK=0, @TeclaOK=0, @XferAgents=0,
 @Extension='' '', @UserID='' '', @Nombre='' '', @tipoConexion = 0, @ipExtension='''', @isIP=0
SELECT @CCServer=valor FROM ccSettings WHERE setting_id=7

IF not exists(select Login from ccUsers Where Login=@Login and status>0 and tipoUser_id=1)
  GOTO Mostrar
else
  set @LoginOK=1

IF not exists(select Login from ccUsers Where Login = @Login
 AND (Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
 or Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC)
 and status > 0 and tipoUser_id = 1)
  GOTO Mostrar
else
  set @PswdOK=1

-- Se actualiza a Lower Case
update ccUsers with(rowlock) set Password=isnull(@PasswordLwC, Password) where Login=@Login and status>0 and tipoUser_id=1

if not exists (select Computer from ccPosicion Where Status=1 and Computer=@Computer)
  insert ccposicion (computer, ext_id) select @Computer, 0

set @CompuOK = 1

if not exists(select Computer from ccPosicion P join ccMonitorExt M on P.ext_id= M.ext_id
 Where p.Status=1 and M.Status=1 and Computer=@Computer)
  GOTO Mostrar
else
  set @ExtenOK=1

select @Extension=Extension, @ext_id=p.ext_id, @pos_id=p.pos_id, @tipoConexion=p.tipoConexion, @isIP=isIP
from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
Where Computer = @Computer

select @TeclaOK=count(*) from ccTeclaExtensionPuerto T join ccMonitorExt M on T.ext_id=M.ext_id where M.Extension=@Extension

select @UserID=user_id, @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,''''), @XferAgents=XferAgents
from ccUsers Where Login = @Login AND TipoUser_id=1 AND status = 1

Mostrar:
--Para posiciones ip, by ODC
-- No verifica ccTeclaExtensionPuerto, @TeclaOK =1
-- Regresa un etension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
IF @ext_id=0
 BEGIN
  select @TeclaOK =1, @Extension=cast(@pos_id * -1 as varchar(15))
 END

---Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
IF(@ext_id > 0  and @isIP=1)
 BEGIN
  select @TeclaOK =1, @ipExtension = @Extension, @Extension = cast( @pos_id * -1 as varchar(15))
 END
-----------

IF @tipoConexion = 1
  select @TeclaOK =1

--  CRMx
DECLARE @crmxActive TINYINT
SET @crmxActive = 0
IF (SELECT COUNT(setting_id) FROM ccsettings WHERE setting_id = 168) = 1
  BEGIN
    SELECT @crmxActive = valor FROM ccsettings WHERE setting_id = 168
  END


declare @passSecure int
select @passSecure= valor from ccSettings where setting_id=207


SELECT @LoginOK as [LoginOK], @PswdOK as [PswdOK], @CompuOK as [CompuOK], @ExtenOK as [ExtenOK], @Extension as [Extension],
@UserID as [UserID], @Nombre as [Nombre], @CCServer as [CCServer], @TeclaOK as TeclaOK, @tipoConexion as TipoConexion, @ipExtension as ipExtension,
@XferAgents as XferAgents, @crmxActive as [CRMx], @passSecure as [passSecure]
    
    
    '
        EXEC(@Sql)        
  




        set @process = 'CW-2467 --Add SP ccSettings Send Acitvity Port'
        set @Sql= 'if not exists(Select * From ccSettings Where setting_id=184) begin
	insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
	values (184,''0'',''Envío los cambios de estado de los puertos'',1,''X'',''Envia los cambios de los puertos del outbound al Admin'',''Send port status changes'',0,''^[0-1]$'')
end'
        EXEC(@Sql)

set @process = 'CW-1903 -- JOB DatabaseCentinella '
    set @Sql= 'USE [msdb]

/****** Object:  Job [DatabaseCentinella]    Script Date: 23/06/2018 11:24:41 a.m. ******/
if exists( select * from msdb.dbo.sysjobs where name=''DatabaseCentinella'')
EXEC msdb.dbo.sp_delete_job @job_name=N''DatabaseCentinella'', @delete_unused_schedule=1

/****** Object:  Job [DatabaseCentinella]    Script Date: 23/06/2018 11:24:41 a.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 23/06/2018 11:24:41 a.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DatabaseCentinella'', 
    @enabled=1, 
    @notify_level_eventlog=0, 
    @notify_level_email=0, 
    @notify_level_netsend=0, 
    @notify_level_page=0, 
    @delete_level=0, 
    @description=N''Autor: Raymundo Gonzalez
        Fecha: 2018/06/15
        Descripcion:
          Centinela para monitoreo de performance y mantenimiento de las BD de SQL
        '', 
    @category_name=N''[Uncategorized (Local)]'', 
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseCentinellaTasks]    Script Date: 23/06/2018 11:24:41 a.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''DatabaseCentinellaTasks'', 
    @step_id=1, 
    @cmdexec_success_code=0, 
    @on_success_action=1, 
    @on_success_step_id=0, 
    @on_fail_action=2, 
    @on_fail_step_id=0, 
    @retry_attempts=0, 
    @retry_interval=0, 
    @os_run_priority=0, @subsystem=N''TSQL'', 
    @command=N''use [master]

set nocount on

declare @idDb int
declare @dbName nvarchar(100)
declare @dbLog nvarchar(100)
declare @sql nvarchar(max)
declare @idIndex int
declare @tableName nvarchar(100)
declare @indexName nvarchar(100)
declare @process int
declare @firstSunday datetime
declare @idCmdSql int
declare @cmdSql nvarchar(max)
declare @maxTimeSeconds int
declare @maxTimeSecondsSunday int
declare @dateExecution datetime

set @idDb = 0
set @dbName = ''''''''
set @dbLog = ''''''''
set @sql = ''''''''
set @idIndex = 0
set @tableName = ''''''''
set @indexName = ''''''''
set @process = 1
set @firstSunday = DATEADD(WEEKDAY,(8-(DATEPART(WEEKDAY,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))))%7,DATEADD(mm,DATEDIFF(m,0,GETDATE()),0))
set @idCmdSql = 0
set @cmdSql = ''''''''
set @maxTimeSeconds = 7200
set @maxTimeSecondsSunday = 14400
set @dateExecution = getdate()

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
  begin
    if exists (select * from sys.tables where name = ''''userDatabases'''')
      drop table userDatabases

    if exists (select * from sys.tables where name = ''''indexMaintenance'''')
      drop table indexMaintenance

    if exists (select * from sys.tables where name = ''''logCentinella'''')
      drop table logCentinella
  end

if not exists (select * from sys.tables where name = ''''userDatabases'''')
  begin
    create table dbo.userDatabases(
      [idDb] int not null identity primary key,
      [dbName] nvarchar(100) not null,
      [dbLog] nvarchar(100) not null,
      [status] bit not null
    )

    CREATE NONCLUSTERED INDEX [IX_userDatabases1] ON [dbo].[userDatabases]
    (
      [dbName] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_userDatabases2] ON [dbo].[userDatabases]
    (
      [status] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
  end

if not exists (select * from sys.tables where name = ''''indexMaintenance'''')
  begin
    create table dbo.indexMaintenance(
      [idIndex] int not null identity primary key,
      [dbName] nvarchar(100) not null,
      [tableName] nvarchar(100) not null,
      [indexName] nvarchar(100) not null,
      [indexType] nvarchar(100) not null,
      [indexFragmentation] nvarchar(100) not null,
      [status] bit not null
    )

    CREATE NONCLUSTERED INDEX [IX_indexMaintenance1] ON [dbo].[indexMaintenance]
    (
      [dbName] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_indexMaintenance2] ON [dbo].[indexMaintenance]
    (
      [tableName] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_indexMaintenance3] ON [dbo].[indexMaintenance]
    (
      [status] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
  end

if not exists (select * from sys.tables where name = ''''logCentinella'''')
  begin
    create table dbo.logCentinella(
      [idCmdSql] int not null identity primary key,
      [date] datetime not null,
      [cmdSql] nvarchar(max) not null,
      [status] int not null,
      [dateStart] datetime not null,
      [dateEnd] datetime not null,
      [executionTimeSeconds] int not null
    )

    CREATE NONCLUSTERED INDEX [IX_logCentinella1] ON [dbo].[logCentinella]
    (
      [date] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

    CREATE NONCLUSTERED INDEX [IX_logCentinella2] ON [dbo].[logCentinella]
    (
      [status] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
  end

insert into userDatabases
select db_name(database_id), '''''''', 0
from sys.master_files
where state = 0
and has_dbaccess(db_name(database_id)) = 1
and db_name(database_id) NOT IN (''''master'''', ''''tempdb'''', ''''model'''', ''''msdb'''', ''''resource'''', ''''distribution'''', ''''reportservice'''', ''''reportservicetempdb'''')
and type = 0

update userDatabases
set [dbLog] = name
from sys.master_files
inner join userDatabases on (db_name(database_id) = [dbName] and type = 1)

while (select count(*) from userDatabases where status = 0) > 0
  begin
    set rowcount 1
      select @idDb = idDb, @dbName = dbName from userDatabases where status = 0 order by idDb
    set rowcount 0

    select @sql = ''''use ['''' + @dbName + '''']

insert into master.dbo.indexMaintenance
SELECT '''''''''''' + @dbName + '''''''''''', OBJECT_NAME(ind.OBJECT_ID), ind.name, indexstats.index_type_desc, indexstats.avg_fragmentation_in_percent, 0
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind ON (ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id and ind.type > 0)
inner join sysobjects obj on (obj.id = indexstats.object_id and xtype=''''''''U'''''''' and category = 0)
WHERE indexstats.avg_fragmentation_in_percent > 30
ORDER BY OBJECT_NAME(ind.OBJECT_ID), ind.name''''

    exec(@sql)

    update userDatabases
    set status = 1
    where idDb = @idDb
  end

while (select count(*) from indexMaintenance where status = 0) > 0
  begin
    set rowcount 1
      select @idIndex = idIndex, @dbName = dbName, @tableName = tableName, @indexName = indexName from indexMaintenance where status = 0 order by idIndex
    set rowcount 0

    select @sql = ''''use ['''' + @dbName + ''''] ''''

    if @process = 1
        select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REORGANIZE WITH ( LOB_COMPACTION = ON )''''
    else if @process = 2
        select @sql = @sql + ''''ALTER INDEX ['''' + @indexName + ''''] ON [dbo].['''' + @tableName + ''''] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )''''
    else if @process = 3
        select @sql = @sql + ''''UPDATE STATISTICS [dbo].['''' + @tableName + ''''] WITH FULLSCAN''''

    insert into logCentinella
    select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

    if @process < 3
      update indexMaintenance set status = 1 where idIndex = @idIndex
    else
      update indexMaintenance set status = 1 where dbName = @dbName and tableName = @tableName

    if @process < 3
      begin
        if (select count(*) from indexMaintenance where status = 0) = 0
          begin
            update indexMaintenance
            set status = 0

            set @process = @process + 1
          end
      end
  end

if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
--if 1=1
  begin
    update userDatabases
    set status = 0

    while (select count(*) from userDatabases where status = 0) > 0
      begin
        set rowcount 1
          select @idDb = idDb, @dbName = dbName, @dbLog = dbLog from userDatabases where status = 0 order by idDb
        set rowcount 0

        select @sql = ''''use ['''' + @dbName + ''''] DBCC CHECKDB WITH NO_INFOMSGS''''

        insert into logCentinella
        select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0 
        
        select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = '''''''''''' + @dbName + ''''_Backup_Centinella_'''''''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''''''.bak''''''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''''''\'''''''' + @date

drop table #RutaBak

BACKUP DATABASE ['''' + @dbName + ''''] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10''''

        insert into logCentinella
        select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0       


        if @dbName in(''''CCenterRia'''',''''CCRecorderRIA'''',''''ccReportsRia'''',''''CW_CRMx'''') begin

          select @sql = ''''use ['''' + @dbName + ''''] ALTER DATABASE ''''+@dbName+ '''' SET RECOVERY SIMPLE''''

          insert into logCentinella
          select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0             
        
        end       

        select @sql = ''''use ['''' + @dbName + ''''] DBCC SHRINKFILE('''''''''''' + @dbLog + '''''''''''',1)''''

        insert into logCentinella
        select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0               

        update userDatabases
        set status = 1
        where idDb = @idDb
      end

    select @sql = ''''use [master]

DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''''''HKEY_LOCAL_MACHINE'''''''', N''''''''Software\Microsoft\MSSQLServer\MSSQLServer'''''''',N''''''''BackupDirectory''''''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''''''bak'''''''',@date

drop table #RutaBak''''

    insert into logCentinella
    select getdate(), @sql, 0, ''''19000101'''', ''''19000101'''',0

  end

set @dateExecution = getdate()

while (select count(*) from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate()))) > 0
  begin
    set rowcount 1
      select @idCmdSql = idCmdSql, @cmdSql = cmdSql from logCentinella where status = 0 and convert(datetime,convert(varchar(11),[date])) = convert(datetime,convert(varchar(11),getdate())) order by idCmdSql
    set rowcount 0

    update logCentinella
    set dateStart = getdate()
    where idCmdSql = @idCmdSql

    exec(@cmdSql)

    WAITFOR DELAY ''''00:00:01''''

    while(SELECT count(*)
        FROM sys.dm_exec_requests a
        INNER JOIN sys.dm_exec_connections b
        ON a.session_id = b.session_id
        INNER JOIN sys.dm_exec_sessions c
        ON c.session_id = a.session_id
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
        WHERE a.session_id > 50
        AND a.session_id = @@SPID
        and d.text = @cmdSql) > 0
      begin
        WAITFOR DELAY ''''00:00:01''''
      end

    if @firstSunday = convert(datetime,convert(varchar(11), getdate()))
      begin
        if((datediff(ss,@dateExecution,getdate())) > @maxTimeSecondsSunday)
          BREAK
      end
    else
      begin
        if((datediff(ss,@dateExecution,getdate())) > @maxTimeSeconds)
          BREAK
      end

    update logCentinella
    set status = 1, dateEnd = getdate(), executionTimeSeconds = datediff(ss,dateStart,getdate())
    where idCmdSql = @idCmdSql
  end

delete userDatabases
delete indexMaintenance'', 
    @database_name=N''master'', 
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''DatabaseCentinellaSchedule'', 
    @enabled=1, 
    @freq_type=4, 
    @freq_interval=1, 
    @freq_subday_type=1, 
    @freq_subday_interval=0, 
    @freq_relative_interval=0, 
    @freq_recurrence_factor=0, 
    @active_start_date=20140724, 
    @active_end_date=99991231, 
    @active_start_time=30000, 
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@Sql)        

				/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix 

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
