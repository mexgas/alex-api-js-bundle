/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 29
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

	------------------------------------------- BEGIN Jesus ----------------------------------------
	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  
@command TINYINT, 
@telephone VARCHAR(20) = 0, 
@idtipolista INT, 
@calKey AS VARCHAR(40) = NULL, 
@isKolob bit=0
AS
DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

SELECT @hashPhone = dbo.hashPhone(@telephone)

IF @calKey IS NOT NULL
BEGIN
    SELECT @hashCalKey = dbo.hashList(@calKey)
END
        
IF @hashCalKey IS NULL
BEGIN
    IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
        SELECT idtipolista
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista
        )
    BEGIN
    SELECT 1

    RETURN (0)
    END
END
ELSE
        
BEGIN
    IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
        SELECT idtipolista
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
        )
    BEGIN
    SELECT 1

    RETURN (0)
    END
END
        
IF @command = 1 --Insert Number
BEGIN
    
	EXEC ccsp_InsertDNCList @telephone = @telephone, @ln_id = @idtipolista, @hashCalKey = @hashCalKey, @calKey = @calKey,@cleanType=0
	EXEC ccsp_InsertDNCListSms @telephone = @telephone, @ln_id = @idtipolista, @hashCalKey = @hashCalKey, @calKey = @calKey
	EXEC [ccsp_InsertDNCListWhatsApp] @telephone = @telephone, @ln_id = @idtipolista, @hashCalKey = @hashCalKey, @calKey = @calKey
    --print  @telephone
    --INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    --VALUES (@telephone, 1, @idtipolista)

    SELECT 200
END

IF @command = 2 --Delete Number
BEGIN
    --Check if phone number exists
    IF EXISTS(SELECT cln.Hashtel FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista)
    BEGIN
            IF @hashCalKey IS NULL OR @hashCalKey = 0
            BEGIN
            --Check if request is from kolob or xion
            IF(@isKolob = 1)
            BEGIN
                --Check if phone number has calKey assigned
                SELECT @hashCalKey = cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista
                IF (@hashCalKey > 0)
                BEGIN
                    SELECT CAST(-1 AS INT) --Phone number need a calkey to delete it
                END
                ELSE
                BEGIN
                    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                    VALUES (@telephone, 5, @idtipolista)

                    DELETE
                    FROM cclistanegra
                    WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista;
                    SELECT CAST(1 AS INT)
                END
            END
            ELSE
            BEGIN
                INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                VALUES (@telephone, 5, @idtipolista)

                DELETE
                FROM cclistanegra
                WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista
            END
            END
            ELSE
            BEGIN
            --Check if phone with calKey exist
            IF NOT EXISTS (SELECT cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.HashKey = @hashCalKey AND cln.idtipolista = @idtipolista)
            BEGIN
                SELECT CAST(-4 AS INT) --Phone Number with calKey not exist
            END
            ELSE
            BEGIN
                INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                VALUES (@telephone, 5, @idtipolista)

                DELETE
                FROM cclistanegra
                WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
                IF(@isKolob = 1)
                BEGIN
                    SELECT CAST(1 AS INT)
                END
            END
            END
    END
    ELSE
    BEGIN
        SELECT CAST(-3 AS INT) --Phone Number not exist
    END
    RETURN (0)
END

IF @command = 3 --Reemplaza
BEGIN
    INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
    SELECT telefono, 4, @idtipolista
    FROM cclistanegra
    WHERE idtipolista = @idtipolista

    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idtipolista

    RETURN (0)
END

IF @command = 5 --Delete by idtipolista
BEGIN
    UPDATE ccTiposListaNegra
    SET STATUS = 0
    WHERE idtipolista = @idtipolista

    DELETE ccAgendaListaNegra
    WHERE idagenda IN (
        SELECT idagenda
        FROM ccAgenda_TipolistaNegra
        WHERE idtipolista = @idtipolista
        )

    DELETE ccAgenda_TipolistaNegra
    WHERE idtipolista = @idtipolista

    DELETE cccalifblacklist
    WHERE idtipolista = @idtipolista

    DELETE Camplistanegra
    WHERE idtipolista = @idtipolista    

    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    
    SELECT  telefono,5,@idtipolista
    FROM ccListaNegra
    WHERE idtipolista = @idtipolista

    
    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idtipolista


    RETURN (0)
END

SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS

Set nocount on

declare @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null
,@fnPhone nvarchar(100) =null
,@motivo nvarchar(100)
,@keyTranslate nvarchar(100)

declare @phoneEmpty varchar(1)
set @phoneEmpty =''''


set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](@telephone)'' else  ''[dbo].[Verifica](@telephone)'' end

set @motivo=case when @cleanType=0 then ''Length exceeded'' else  ''Error en COFETEL'' end
set @keyTranslate=case when @cleanType=0 then ''description-length'' else  ''description-cofetel'' end


SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+@fnPhone+'',@calKey );
    '';
    EXEC (@dropTmpPhone);   
    EXEC sp_executesql @sqlcmd, N''@telephone varchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
END
else if @cleanType<>0 begin
	
	set @sqlcmd=''update '' + @tmpTableName + '' set phoneNumber=''+@fnPhone
	EXEC (@sqlcmd);

	set @sqlcmd=''Insert into ccRIALogPhones 
select @ln_id,@phoneEmpty,phoneNumber,0,@motivo,@keyTranslate from ''+ @tmpTableName+''
where left(phoneNumber,1)= ''''E''''
delete from ''+ @tmpTableName+'' where left(phoneNumber,1)= ''''E''''
''
	EXEC sp_executesql @sqlcmd,''@phoneEmpty varchar(1)'',@phoneEmpty=@phoneEmpty
end

set @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.telefono is not null''
--print(@sqlcmd)
EXEC (@sqlcmd);   

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '' A 

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '' A '';

--print (@sqlcmd)
EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] ( [campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


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
    )

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

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
    )

CREATE TABLE [dbo].[#mytempCall](
    [callout_id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
    SET @sqlcmd = ''
    insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  cal_fechadial > getdate()-30
    ''

SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')   
EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

DECLARE @columnIndex INT = 2;
WHILE @columnIndex <= 5
BEGIN
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono''+CONVERT(varchar(10),@columnIndex))
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
	set @columnIndex=@columnIndex+1;
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
    GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
    ,@params nvarchar(max)    
    ,@sqlWithReplace nvarchar(max)
    
    set @column=''cal_telefono''
    set @params=''@phoneEmpty varchar(1),@fech datetime''
    set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
    and cs.cal_telefono3=@phoneEmpty
    and cs.cal_telefono4=@phoneEmpty
    and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
    when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
    when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
    when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
    else @phoneEmpty end ''

    set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set cal_telefono = CASE_UPDATE_WT
    from ccoCallsOutSource cs 
    inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

    set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin       
    -- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
    delete wt with(rowlock)
    from ccoWOrkingTable wt 
    inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
    inner join #mytempCall t on wt.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and
    cs.COLUMN_CHECK = wt.cal_telefono
    AND_DELETE_WT

    UPDATE_SMS_WT_QUERY

    --insertar el historial
    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    -- Eliminamos el telefono1 de CS
    update ccoCallsOutSource 
    set COLUMN_CHECK = @phoneEmpty
    from ccoCallsOutSource cs 
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech      

    truncate table #mytempCall
end''

    
    /******************/
    /*** Telefono 1 ***/
    /******************/
    
    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    print(@sqlWithReplace)  
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 2 ***/
    /******************/
    set @column=''cal_telefono2''
    
    set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
        and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
        when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 3 ***/
    /******************/
    set @column=''cal_telefono3''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 4 ***/
    /******************/    
    
    set @column=''cal_telefono4''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''cal_telefono5''   
    set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty'' 
    set @sqlCaseWorking=''''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCListSms]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS
SET NOCOUNT ON;  


declare @sqlcmd nvarchar(max), @tmpTableName nvarchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null


if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra with(nolock) where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values([dbo].[Limpia](@telephone),@calKey );
    '';
    EXEC (@dropTmpPhone);   
    EXEC sp_executesql @sqlcmd, N''@telephone varchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
END
else begin
	SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));
end



IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms
IF OBJECT_ID(N''tempdb..#helpTempSms]'') IS NOT NULL drop table #helpTempSms


CREATE TABLE [dbo].[#mycamps] ([campsid] [int] NULL )

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id And B.CampType=7



CREATE TABLE [dbo].[#myprincipaltempSms](
    [smsout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [sms_phoneNumber] [varchar] (30) NULL ,
    [sms_phoneNumber2] [varchar] (30) NULL ,
    [sms_phoneNumber3] [varchar] (30) NULL ,
    [sms_phoneNumber4] [varchar] (30) NULL ,
    [sms_phoneNumber5] [varchar] (30) NULL
    )

CREATE CLUSTERED INDEX [IX_myprincipaltempSms] ON [dbo].[#myprincipaltempSms]([smsout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms2] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms3] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms4] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms5] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms6] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber5])

CREATE TABLE [dbo].[#helpTempSms](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE TABLE [dbo].[#mytempSms](
    [smsout_id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempSms]([smsout_id]) 

declare @fech datetime = getdate()-30

    SET @sqlcmd = ''
    insert into [#helpTempSms]
    SELECT a.smsout_id as smsout_id, a.cam_id,3, @ln_id as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
    FROM [smsOutSource] as a  with(nolock)
    inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  sms_dateDial > @fech
    ''

    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;
    
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber2'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;
    
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber3'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;
    
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber4'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;
    
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber5'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;


    SET @sqlcmd = ''insert into [#helpTempSms]
    SELECT a.smsout_id as smsout_id, a.cam_id,3, @ln_id as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
    FROM [smsOutSource] as a with(nolock)
    inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on a.callKey=t.calKey
    where sms_dateDial > @fech;
    '';
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;

    INSERT INTO #myprincipaltempSms
    SELECT * FROM #helpTempSms
    GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5
    
if EXISTS (select * from #myprincipaltempSms)
    begin
    
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
    ,@params nvarchar(max)
    ,@phoneEmpty varchar(1)
    ,@sqlWithReplace nvarchar(max)

    set @phoneEmpty=''''
    set @column=''sms_phoneNumber''
    set @params=''@phoneEmpty varchar(1),@fech datetime''
    set @sqlDeleteWorking=''and cs.sms_phoneNumber2=@phoneEmpty
    and cs.sms_phoneNumber3=@phoneEmpty
    and cs.sms_phoneNumber4=@phoneEmpty
    and cs.sms_phoneNumber5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.sms_phoneNumber2<>@phoneEmpty then cs.sms_phoneNumber2 
    when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
    when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
    when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
    else @phoneEmpty end ''

    set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set sms_phoneNumber = CASE_UPDATE_WT
    from smsOutSource cs
    inner join smsWorkingTable wt WITH(NOLOCK) on cs.smsout_id = wt.smsout_id
    inner join #mytempSms t on cs.smsout_id = t.smsout_id
    where cs.sms_dateDial > @fech and cs.COLUMN_CHECK= wt.sms_phoneNumber''

    set @sql=''insert #mytempSms
select smsout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempSms] with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty

if EXISTS (select * from #mytempSms)
begin
    -- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
    delete wt with(rowlock)
    from smsWorkingTable wt 
    inner join smsOutSource cs  on wt.smsout_id = cs.smsout_id
    inner join #mytempSms t on wt.smsout_id = t.smsout_id
    where cs.sms_dateDial > @fech and
    cs.COLUMN_CHECK = wt.sms_phoneNumber
    AND_DELETE_WT

    UPDATE_SMS_WT_QUERY

    --insertar el historial
    insert ccHistoryBlacklistSms (smsout_id,Phone,cam_id,movTypeId,listTypeId)
    select * from #mytempSms

    -- Eliminamos el telefono1 de CS
    update smsOutSource 
    set COLUMN_CHECK = @phoneEmpty
    from smsOutSource cs 
    inner join #mytempSms t on cs.smsout_id = t.smsout_id
    where cs.sms_dateDial > @fech       

    truncate table #mytempSms
end''
    /******************/
    /*** Telefono 1 ***/
    /******************/
    
    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech   

    /******************/
    /*** Telefono 2 ***/
    /******************/
    set @column=''sms_phoneNumber2''
    
    set @sqlDeleteWorking='' and cs.sms_phoneNumber3=@phoneEmpty
        and cs.sms_phoneNumber4=@phoneEmpty
        and cs.sms_phoneNumber5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
        when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
        when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech

    /******************/
    /*** Telefono 3 ***/
    /******************/
    set @column=''sms_phoneNumber3''
    
    set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
        and cs.sms_phoneNumber5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
        when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech   

    /******************/
    /*** Telefono 4 ***/
    /******************/    
    
    set @column=''sms_phoneNumber4''
    
    set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
        and cs.sms_phoneNumber5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
        when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech
        

    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''sms_phoneNumber5''    
    set @sqlDeleteWorking='' and cs.sms_phoneNumber5=@phoneEmpty''  
    set @sqlCaseWorking=''''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech
    
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms
IF OBJECT_ID(N''tempdb..#helpTempSms]'') IS NOT NULL drop table #helpTempSms
'
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = ''
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCListWhatsApp]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS
SET NOCOUNT ON;  


declare @sqlcmd nvarchar(max), @tmpTableName nvarchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null


if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra with(nolock) where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values([dbo].[Limpia](@telephone),@calKey );
    '';
    EXEC (@dropTmpPhone);   
    EXEC sp_executesql @sqlcmd, N''@telephone varchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
END
else begin
	SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));
end



IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempWhatsApp'') IS NOT NULL drop table #myprincipaltempWhatsApp
IF OBJECT_ID(N''tempdb..#mytempWhatsApp'') IS NOT NULL drop table #mytempWhatsApp
IF OBJECT_ID(N''tempdb..#helpTempWhatsApp]'') IS NOT NULL drop table #helpTempWhatsApp


CREATE TABLE [dbo].[#mycamps] ([campsid] [int] NULL )

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id And B.CampType=5 --WhatsApp



CREATE TABLE [dbo].[#myprincipaltempWhatsApp](
    [WAOut_Id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [phoneNumber] [varchar] (30) NULL ,    
    )

CREATE CLUSTERED INDEX [IX_myprincipaltempWa] ON [dbo].[#myprincipaltempWhatsApp]([WAOut_Id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempWa2] ON [dbo].[#myprincipaltempWhatsApp]([PhoneNumber]) 


CREATE TABLE [dbo].[#helpTempWhatsApp](
    [WAOut_Id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    )

CREATE TABLE [dbo].[#mytempWhatsApp](
    [WAOut_Id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempWhatsApp]([WAOut_Id]) 

declare @fech datetime = getdate()-30

    SET @sqlcmd = ''
    insert into [#helpTempWhatsApp]
    SELECT a.WAOut_Id as WAOut_Id, a.camId,3, @ln_id as idtipolista, a.PhoneNumber
    FROM [ccWhatsAppOutSource] as a with(nolock)
    inner join #mycamps as b with(nolock) on a.camId = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN (a.[SPACE_TEL])  AND t.calKey IS NULL    
	where dateDial > @fech
    ''

    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''PhoneNumber'')    
	EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;
	
	SET @sqlcmd = ''
    insert into [#helpTempWhatsApp]
    SELECT a.WAOut_Id as callout_id, a.camId,3, @ln_id as idtipolista, a.PhoneNumber
    FROM [ccWhatsAppOutSource] as a with(nolock)
    inner join #mycamps as b with(nolock) on a.camId = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN (a.[SPACE_TEL])  AND t.calKey IS NULL    
	where dateDial > @fech''
    
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''PhoneNumber'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int,@fech datetime'', @ln_id,@fech;

    INSERT INTO #myprincipaltempWhatsApp
    SELECT * FROM #helpTempWhatsApp
    GROUP BY WAOut_Id, cam_id, tipomov, idtipolista, cal_telefono
    
if EXISTS (select * from #myprincipaltempWhatsApp)
    begin
    
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
    ,@params nvarchar(max)
    ,@phoneEmpty varchar(1)
    ,@sqlWithReplace nvarchar(max)

    set @phoneEmpty=''''
    set @column=''PhoneNumber''
    set @params=''@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking='' and cs.PhoneNumber=@phoneEmpty''
	set @sqlCaseWorking=''@phoneEmpty''

    set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set PhoneNumber = CASE_UPDATE_WT
    from ccWhatsAppOutSource cs
    inner join ccoWAWorkingTable wt WITH(NOLOCK) on cs.WAOut_Id = wt.WAOut_Id
    inner join #mytempWhatsApp t on cs.WAOut_id = t.WAOut_id
    where cs.dateDial > @fech and cs.COLUMN_CHECK= wt.PhoneNumber''

    set @sql=''insert #mytempWhatsApp
select WAOut_Id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempWhatsApp] with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty

if EXISTS (select * from #mytempWhatsApp)
begin
    -- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
    delete wt with(rowlock)
    from ccoWAWorkingTable wt 
    inner join ccWhatsAppOutSource cs  on wt.WAOut_Id = cs.WAOut_Id
    inner join #mytempWhatsApp t on wt.WAOut_Id = t.WAOut_Id
    where cs.dateDial > @fech and
    cs.COLUMN_CHECK = wt.PhoneNumber
    AND_DELETE_WT

    UPDATE_WT_QUERY

    --insertar el historial
    --insert ccHistoryBlacklistSms (WAOut_Id,Phone,cam_id,movTypeId,listTypeId)
    --select * from #mytempWhatsApp

    -- Eliminamos el telefono1 de CS
    update ccWhatsAppOutSource 
    set COLUMN_CHECK = @phoneEmpty
    from ccWhatsAppOutSource cs 
    inner join #mytempWhatsApp t on cs.WAOut_Id = t.WAOut_Id
    where cs.dateDial > @fech       

    truncate table #mytempWhatsApp
end''
    /******************/
    /*** Telefono 1 ***/
    /******************/
    
    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech   
    
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempWhatsApp'') IS NOT NULL drop table #myprincipaltempWhatsApp
IF OBJECT_ID(N''tempdb..#mytempWhatsApp'') IS NOT NULL drop table #mytempWhatsApp
IF OBJECT_ID(N''tempdb..#helpTempWhatsApp]'') IS NOT NULL drop table #helpTempWhatsApp
'
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] 
@phoneNumber AS VARCHAR(30) = NULL, 
@idDNCList AS INTEGER, 
@tipoMov AS TINYINT, 
@calKey AS VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null,@cleanType=@cleanType
	EXEC ccsp_InsertDNCListSms @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	EXEC [ccsp_InsertDNCListWhatsApp] @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, ''4'', @idDNCList
	FROM cclistanegra
	WHERE idtipolista = @idDNCList

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idDNCList
END '
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppLoader]
	-- Add the parameters for the stored procedure here
	@action TINYINT =NULL,
	@tableTemp VARCHAR(255) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF(@action = 1) -- Get phone loaded with phoneType
	BEGIN

		DECLARE @columnList NVARCHAR(MAX);
		DECLARE @sql NVARCHAR(MAX);

		-- Obtener la lista de columnas excluyendo ''column1''
		SET @columnList = (SELECT STUFF((SELECT '','' +name 
				FROM sys.columns 
				WHERE object_id = OBJECT_ID(@tableTemp) 
				AND name <> ''phoneType'' FOR XML PATH('''')), 1, 1, ''''))

		-- Construir la consulta SQL dinámica
		SET @sql = ''
		;WITH CTE AS (
		SELECT  dbo.Verifica2(cal_telephone,1,0,0,1) as phoneType, '' + @columnList + '',
		ROW_NUMBER() OVER (PARTITION BY cal_Key ORDER BY Record_id) AS rn FROM''+ QUOTENAME(@tableTemp) + ''
		)
		SELECT *
		FROM CTE
		WHERE rn = 1
		ORDER BY Record_id ASC
		'';

		-- Ejecutar la consulta dinámica
		EXEC sp_executesql @sql;
	END
END'
	EXEC(@sql)

	SET @process = 'Listas negras internacional ValidateBlackListPhoneByList se agrega valiar whatsApp'
	SET @sql = 'ALTER FUNCTION [dbo].[ValidateBlackListPhoneByList] (@tel VARCHAR(32), @calKey VARCHAR(40),@blackListId varchar(100))
RETURNS BIT
AS
BEGIN
DECLARE @isBlackPhone BIT
--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
DECLARE @hasTelefono BIGINT

if @tel is null or @tel =''''
	return 1 --No tiene valor

SELECT @hasTelefono = dbo.hashPhone(@tel)	

DECLARE @hasCalKey BIGINT

SELECT @hasCalKey = dbo.hashList(@calKey)

SET @isBlackPhone = 0

IF EXISTS (
		SELECT a1.idtipolista
		FROM cclistanegra a1 with(nolock,index(IX_ccListaNegra_II))
		INNER JOIN 
		dbo.fn_RIASplitDelimited(@blackListId,'','') b ON a1.idtipolista = b.Value						
		WHERE a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
		)
	SET @isBlackPhone = 1

RETURN @isBlackPhone
END
'
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = ''
	EXEC(@sql)

	SET @process = 'Listas negras internacional ccsp_GalateaAdminUploadBLst se agrega valiar whatsApp'
	SET @sql = ''
	EXEC(@sql)

	------------------------------------------- BEGIN End ----------------------------------------

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
