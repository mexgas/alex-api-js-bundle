/*******************************/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
USE CCenterRIA;

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
    SET @versionfix = 7
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

    SET @process = 'DROP ccsp_GetNotReadyTimesxTipo'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetNotReadyTimesxTipo'')
    begin
            DROP PROCEDURE ccsp_GetNotReadyTimesxTipo;
    end'
    exec (@sql)


    SET @process = 'DROP ccsp_GetNotReadyTimes'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetNotReadyTimes'')
    begin
            DROP PROCEDURE ccsp_GetNotReadyTimes;
    end'
    exec (@sql)

    
    SET @process = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimes]'
    SET @sql = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimes]
@user_id int = 0
AS
-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer
declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin   
    set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
    set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fStart = dateadd( d,-1, @fEnd )
end

;WITH Tiempos AS
(
    SELECT 
        t.Descripcion,
        CAST(SUM(l.tStatus) AS BIGINT) AS TotalSegundos
    FROM ccLogAgentesNotReady l
    INNER JOIN ccTipoNotReady t
        ON l.tiponotready_id = t.tiponotready_id    
    WHERE l.fecha BETWEEN @fStart AND @fEnd
      AND (l.user_id = @user_id OR @user_id = 0)
    GROUP BY t.Descripcion
)
SELECT
    Descripcion,
    CAST(TotalSegundos / 3600 AS varchar(10)) + '':'' +
    RIGHT(''0'' + CAST((TotalSegundos % 3600) / 60 AS varchar(2)), 2) + '':'' +
    RIGHT(''0'' + CAST(TotalSegundos % 60 AS varchar(2)), 2) AS Tiempo,
    TotalSegundos AS total
FROM Tiempos;'
    exec (@sql)

    
    SET @process = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimesxTipo]'
    SET @sql = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimesxTipo]
@user_id int = 0,
@idTipo int
AS
-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer

declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin   
    set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
    set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fStart = dateadd( d,-1, @fEnd )
end

;WITH Tiempos AS
(
    SELECT 
        t.Descripcion,
        l.tiponotready_id,
        CAST(SUM(l.tStatus) AS BIGINT) AS TotalSegundos
    FROM ccLogAgentesNotReady l
    INNER JOIN ccTipoNotReady t
        ON l.tiponotready_id = t.tiponotready_id
    WHERE l.tiponotready_id = @idTipo
      AND l.fecha BETWEEN @fStart AND @fEnd
      AND (l.user_id = @user_id OR @user_id = 0)
    GROUP BY 
        t.Descripcion, 
        l.tiponotready_id
)
SELECT
    Descripcion,
    CAST(TotalSegundos / 3600 AS varchar(10)) + '':'' +
    RIGHT(''0'' + CAST((TotalSegundos % 3600) / 60 AS varchar(2)), 2) + '':'' +
    RIGHT(''0'' + CAST(TotalSegundos % 60 AS varchar(2)), 2) AS Tiempo,
    TotalSegundos AS total,
    tiponotready_id
FROM Tiempos;'
    exec (@sql)
    
    SET @process = 'DROP ccsp_GetPreviewHistory'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetPreviewHistory'')
    begin
            DROP PROCEDURE ccsp_GetPreviewHistory;
    end'
    exec (@sql)


    SET @process = 'CREATE ccsp_GetPreviewHistory'
    SET @sql = '	CREATE Proc [dbo].[ccsp_GetPreviewHistory]( @callOut_Id int ,@initialRow smallint,@finalRow smallint)
		AS
		declare @initialDate datetime, @finalDate datetime
		set @finalDate= GETDATE()
		set @initialDate = (select DATEDIFF(day,30,@finalDate))

		declare @temTable table (callOut_id int, dialResult varchar(50),disposition varchar(100),date datetime)
		insert into @temTable 
					select co.callout_id as callOut_id, 
					trd.descTranslate dialResult,
					ISNULL( tco.Description,'''') as calificacion,
					ld.fecha as fecha
					from ccoCallsOut co 
					left join ccoLogDials ld on co.callout_id = ld.callout_id
					left join cctipoResultadoDial trd ON ld.tipoResDial_id = trd.tiporesdial_id
					LEFT JOIN cctipocalifout tco ON tco.calif_id = co.calif_id
					where co.callout_id = @callOut_Id and co.cal_id = ld.cal_id  and ld.fecha >= @initialDate and ld.fecha <=@finalDate and ld.tipoResDial_id != 13

					union 
					select rppr.callout_id,
					tpp.descripcion,
					'''',
					rppr.reg_date
					from RegProcessPreviewRecord rppr
					join ccTypeProcessPreview tpp on rppr.process= tpp.typeProcess_id
					where rppr.process NOT IN (1,5,7,14,15) and rppr.callout_id = @callOut_Id and rppr.reg_date >= @initialDate and rppr.reg_date <=@finalDate
			

		SELECT  * FROM    
				( SELECT    ROW_NUMBER() OVER ( ORDER BY date ) AS RowNum, *
				  FROM      @temTable 
				) AS RowConstrainedResult
		WHERE   RowNum >= @initialRow
			AND RowNum <= @finalRow 
		ORDER BY RowNum	'
    exec (@sql)
    
    SET @process = 'Se realiza la modificación para que las grabaciones se detengan al transferir'
    SET @sql = '
        ALTER procedure [dbo].[ccsp_DLRgetXferInfo]
        @camEspecId smallint=0,
        @iPortNumber smallint = 0,
        @type smallint,
        @typeTransfer smallint = 0,
        @phone varchar(50) = '''',
        @trunkId int=0
        as
        -- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
        declare @prefix as varchar(15), @trunk varchar(200)
        declare @timeout int
        declare @ani as varchar(32)
        declare @stop int
        declare @ivr_script smallint, @surveycamid int

        set @prefix =''''
        set @timeout = 20
        set @ani = ''''
        set @stop = 0

        -- Prefijo por puerto
        select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
            select provedor_id from ccodialers nolock where puerto = @iPortNumber )
        -- Prefijo por campaña o especialidad
        if @prefix =''''
            if @type = 2
                select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
            else
                select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
        -- Prefijo general
        if @prefix ='''' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
            select @prefix = valor from ccsettings where setting_id =101
        if @prefix ='''' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
            select @prefix = valor from ccsettings where setting_id =101

        -- Tiempo de marcado
        select @timeout = cast(valor as int) from ccSettings where setting_id = 109

        -- Ani y stopRecord
        if @type = 2
            select @ani = callerIdDesc, @stop = isnull(stopRecording, 0) from ccCamps nolock where cam_id = @camEspecId
        else
        begin
            select @ani = callerIdDesc, @stop = stopRecording, @surveycamid = isnull(extend.SurveyCamId,0)
            from ccInbound i (nolock)
            left join ccInboundExtend extend on extend.Inbound_id = i.Inbound_id
            where i.inbound_id= @camEspecId

            if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
        end

        if (@typeTransfer in (0,4) and @type = 2 and @phone is not null and @phone <> '''')
        begin
            if @stop = 0
                begin
                    select @stop = case when @typeTransfer = 0 then isnull(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone
                end
        end

        select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording, @ivr_script as ivrScript,
        dbo.GetRoute(@phone,'''',@trunkId) destination, @trunk trunk
    '
    exec (@sql)


    SET @process = 'Se especifican columnas de RiaLogPhones para carga de listas negras'
    SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as nvarchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL,
@cleanType int=0, --0 limpia,2 verifica
@skipWorkingCleanup bit = 0 -- 0 = hace toda la limpieza WT/CS, 1 = SOLO inserta en ccListaNegra
AS
BEGIN
SET NOCOUNT ON;

declare @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null
,@fnPhone nvarchar(100) =null
,@motivo nvarchar(100)
,@keyTranslate nvarchar(100)
,@params nvarchar(max)

declare @phoneEmpty nvarchar(1)
set @phoneEmpty =''''


set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](@telephone)'' else  ''[dbo].[Verifica](@telephone)'' end

set @motivo=case when @cleanType=0 then ''Length exceeded'' else  ''Error en COFETEL'' end
set @keyTranslate=case when @cleanType=0 then ''description-length'' else  ''description-cofetel'' end


SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

declare @hashList bigint =dbo.hashList(@calKey)

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificacion
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = @hashList) begin
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

    EXEC sp_executesql @sqlcmd, N''@telephone nvarchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;

END
else if @cleanType<>0 begin
    set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](phoneNumber)'' else  ''[dbo].[Verifica](phoneNumber)'' end

    set @sqlcmd=''update '' + @tmpTableName + '' set phoneNumber=''+@fnPhone

    EXEC (@sqlcmd);

    set @sqlcmd=''
   Insert into ccRIALogPhones (load_id, cal_key, telefono, tipoMov, motivo, keyTranslate, internationalRecords)
select @ln_id,@phoneEmpty,phoneNumber,0,@motivo,@keyTranslate,0
from ''+ @tmpTableName+''
where left(phoneNumber,1)= ''''E''''
delete from ''+ @tmpTableName+'' where left(phoneNumber,1)= ''''E''''
''

    set @params=''@ln_id int, @phoneEmpty nvarchar(1),@motivo nvarchar(100),@keyTranslate nvarchar(100)''
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id
    ,@phoneEmpty=@phoneEmpty,@motivo =@motivo ,@keyTranslate =@keyTranslate

end

set @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.idtipolista = @ln_id AND B.telefono is not null''

set @params=''@ln_id int''
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey
FROM '' + @tmpTableName + '' A

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista
FROM '' + @tmpTableName + '' A '';

EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;


IF (@skipWorkingCleanup = 0)
BEGIN

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

    EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

    INSERT INTO #myprincipaltempCall
    SELECT * FROM #helpTempCall
    GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)

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
    else @phoneEmpty end
    ,wt.iZonaHoraria=null, wt.iZonaHoraria_verano=null''

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

    UPDATE_CALL_WT_QUERY

    --insertar el historial
    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    -- Eliminamos el telefono1 de CS
    update ccoCallsOutSource
    set COLUMN_CHECK = @phoneEmpty
    ,COLUMN_ZONE_CHECK=0
    ,COLUMN_ZONE_CHECK_VERANO=0
    from ccoCallsOutSource cs
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech

    truncate table #mytempCall
end''


    /******************/
    /*** Telefono 1 ***/
    /******************/

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria'')

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

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano2'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria2'')

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

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano3'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria3'')

    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech

    /******************/
    /*** Telefono 4 ***/
    /******************/

    set @column=''cal_telefono4''

    set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''

    set @sqlCaseWorking='' case when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5
        else @phoneEmpty end ''

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'',@sqlUpdateWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano4'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria4'')

    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech

    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''cal_telefono5''
    set @sqlDeleteWorking=''''
    set @sqlCaseWorking=''''

    set @sqlWithReplace=  REPLACE(@sql,''UPDATE_CALL_WT_QUERY'','''')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_CHECK'',@column)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''AND_DELETE_WT'',@sqlDeleteWorking)
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''CASE_UPDATE_WT'',@sqlCaseWorking )
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK_VERANO'',''iZonaHoraria_verano5'')
    set @sqlWithReplace=  REPLACE(@sqlWithReplace,''COLUMN_ZONE_CHECK'',''iZonaHoraria5'')

    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall'') IS NOT NULL drop table #helpTempCall


END -- IF @skipWorkingCleanup = 0
    ----------------------------------------------------------------

IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);
END
'
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    


     
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    
    --- END  ----

	
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
