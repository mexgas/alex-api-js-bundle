/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: Fix muñoz

Database: CCReportsRIA
Required version: 144

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON --

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
SET @version = 145 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
--------------------------------------------------------BEGIN 127.20250325.0.0 Jesus Gallardo----------------------------------------------------------------------
    
    SET @process = 'Alter RepOutAnswAndXferCalls migración de dialTimeSec de SMALLINT a INT'
    SET @sql = 'IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = ''RepOutAnswAndXferCalls'' 
      AND COLUMN_NAME = ''dialTimeSec'' 
      AND DATA_TYPE = ''smallint''
)
BEGIN
    PRINT ''🔁 Iniciando migración de dialTimeSec de SMALLINT a INT (sin bloquear)...'';

    -- Paso 1: Agrega columna temporal solo si no existe
    IF COL_LENGTH(''RepOutAnswAndXferCalls'', ''dialTimeSec_int'') IS NULL
    BEGIN
        ALTER TABLE RepOutAnswAndXferCalls ADD dialTimeSec_int INT NULL;
    END

    -- Paso 2: Copia los datos en bloques para evitar bloqueos masivos
    DECLARE @BatchSize INT = 10000;

    WHILE 1=1
    BEGIN
        UPDATE TOP (@BatchSize) RepOutAnswAndXferCalls
        SET dialTimeSec_int = CAST(dialTimeSec AS INT)
        WHERE dialTimeSec_int IS NULL;

        IF @@ROWCOUNT = 0 BREAK;
    END

    -- Paso 3: Elimina columna original
    ALTER TABLE RepOutAnswAndXferCalls DROP COLUMN dialTimeSec;

    -- Paso 4: Renombra nueva columna
    EXEC sp_rename 
        ''RepOutAnswAndXferCalls.dialTimeSec_int'', 
        ''dialTimeSec'', 
        ''COLUMN'';

    PRINT ''✅ Migración finalizada con éxito.'';
END
ELSE
BEGIN
    PRINT ''✅ La columna ya es INT. No se requiere migración.'';
END

'
    EXEC(@sql)

     SET @process = 'ALTER PROCEDURE [dbo].[ccspGenSession] @from y @to Datetime'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspGenSession]
@from AS DATETIME,
@to AS DATETIME
AS
SET NOCOUNT ON

DECLARE @date DATETIME

CREATE TABLE #tempccGenSession ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, [login] [datetime] NOT NULL, [logout] [datetime] NULL, [extension] [varchar](7) NOT NULL, PRIMARY KEY (fila, user_id))
CREATE TABLE #temUserIdLogoutNull ([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, PRIMARY KEY (fila, user_id))


;with dataLoginLogout as(
select ROW_NUMBER() OVER (
PARTITION BY user_id ORDER BY FECHA, tipoMov
) Fila
,User_id,Extension,TipoMov,
case when TipoMov =1 then
dateadd(ms, - DATEPART(ms, fecha), fecha) 
else fecha  end 
fecha 
from ccLogLogin with(nolock) where fecha between @from and @to 
)



INSERT INTO #tempccGenSession
select A.Fila, A.User_id
,dateadd(ms, - DATEPART(ms, A.fecha), A.fecha) LOGIN,  S.fecha logout
, A.Extension
from dataLoginLogout A
left join dataLoginLogout S on A.Fila =S.Fila-1 and A.TipoMov=1 and S.TipoMov=0 AND A.User_id = S.User_id
where A.TipoMov=1



UPDATE x
SET x.fila = x.row
FROM (
    SELECT fila, ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY LOGIN
            ) row
    FROM #tempccGenSession
    ) x



INSERT INTO #temUserIdLogoutNull
    SELECT user_id
    FROM #tempccGenSession
    WHERE logout IS NULL
    GROUP BY user_id

INSERT INTO #temIdMaxLogoutNull
    SELECT A.fila, A.user_id
    FROM #tempccGenSession A
    INNER JOIN (
        SELECT max(fila) fila, user_id
        FROM #tempccGenSession
        WHERE user_id IN (
                SELECT user_id
                FROM #temUserIdLogoutNull
                )
        GROUP BY user_id
        ) B
        ON A.fila = B.fila
            AND A.user_id = B.user_id
    WHERE A.logout IS NULL




SET @date = GETDATE()

UPDATE A
    SET A.logout = CASE WHEN @to < @date THEN @to ELSE @date END
    FROM #tempccGenSession A
    INNER JOIN #temIdMaxLogoutNull B
        ON A.user_id = B.user_id
            AND A.fila = B.fila

    ;with logoutAgentDia as(
    select A.fila,A.user_id,A.login, A.extension,
    (
    select max( fecha) from ccLogAgentesDia where fecha between A.login and B.login
    and User_id=A.user_id 
    ) logout2
    FROM #tempccGenSession A
    LEFT JOIN #tempccGenSession B
        ON A.fila = B.fila - 1
            AND A.user_id = B.user_id
    WHERE A.logout IS NULL
    )

    update A set A.logout=B.logout2
    --select A.fila,A.user_id,A.login,B.logout2 as logout, A.extension 
    from #tempccGenSession A
    inner join logoutAgentDia B on A.fila=B.fila and A.user_id=B.user_id 
    where A.logout is null

DELETE
FROM #tempccGenSession
WHERE LOGIN = logout




DELETE A
FROM #tempccGenSession A
INNER JOIN (
    SELECT user_id, [login], logout
    FROM #tempccGenSession
    GROUP BY user_id, [login], logout
    HAVING count(*) > 1
    ) B
    ON A.user_id = B.user_id
        AND A.LOGIN = B.LOGIN
        AND A.logout = B.logout

UPDATE a
WITH (ROWLOCK)

SET a.logout = b.logout
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a
    ON a.user_id = b.user_id
        AND a.LOGIN = b.LOGIN
        AND a.logout <> b.logout;

    ;WITH tmpccGenSession
    AS (
        SELECT user_id, [login], [logout], extension
        , dbo.GetTimeGroup([login], 0) AS timeGroup, dbo.GetTimeGroup([logout], 1) AS timeGroupNext
        FROM #tempccGenSession
        )
    SELECT A.*, datediff(ss, [login], [logout]) AS tlog
    FROM tmpccGenSession A

DROP TABLE #tempccGenSession
DROP TABLE #temUserIdLogoutNull
DROP TABLE #temIdMaxLogoutNull

SET NOCOUNT OFF'
    EXEC(@sql)


    SET @process = 'Alter FN TimeInterval correcion visita muñoz'
    SET @sql = 'ALTER FUNCTION [dbo].[TimeInterval] (
    @start DATETIME,
    @stop DATETIME,
    @state1 DATETIME,
    @state2 DATETIME
)  
RETURNS INT
AS  
BEGIN 
    DECLARE @overlapStart DATETIME
    DECLARE @overlapEnd DATETIME
    DECLARE @time INT

    -- Calcular el máximo entre @start y @state1
    IF @start > @state1
        SET @overlapStart = @start
    ELSE
        SET @overlapStart = @state1

    -- Calcular el mínimo entre @stop y @state2
    IF @stop < @state2
        SET @overlapEnd = @stop
    ELSE
        SET @overlapEnd = @state2

    -- Calcular el tiempo
    IF @overlapEnd > @overlapStart
        SET @time = DATEDIFF(SECOND, @overlapStart, @overlapEnd)
    ELSE
        SET @time = 0

    RETURN @time
END'
    EXEC(@sql)

    SET @process = 'Alter Sp ReportsMasterProcessWIthOnlyGenerate Correcion para indices y filtro para tomar 02:59:30'
    SET @sql = 'ALTER procedure [dbo].[ReportsMasterProcessWIthOnlyGenerate] 
@from as datetime = null,@to as datetime=null,@scheduleTime int=10,@dateStart datetime =null
as

SET ANSI_WARNINGS off
SET NOCOUNT ON

declare @i int,@count int
declare @SQL varchar(max)
declare @name sysname
declare @descError nvarchar(max)
declare @dateSP datetime

set @dateSP = getdate()

-- Asumimos que @from y @to pueden venir con valores, o nulos

SET @from = ISNULL(@from, GETDATE());
SET @to = ISNULL(@to, GETDATE());

if @dateStart is null 
    set @dateStart=getdate()


-- Si @from es antes de las 03:00:00 → ajustarlo a 02:59:00 del día anterior
IF CAST(@from AS TIME) < ''03:59:30''
BEGIN
    SET @from = CAST( DATEADD(DAY, -1, CAST(@from AS DATE)) AS DATETIME);   -- 02:59:30 del día anterior
END
else begin
    SET @from = CAST(@from AS DATE);    -- 02:59:30 del día actual
end

set @from=dateadd(ss,(179*60)+30, @from)  -- 02:59:30

IF CAST(@to AS TIME) = ''00:00:00''
BEGIN
    set @to=dateadd(ss,(179*60)+30, @to) -- 02:59:00 del día siguiente
END


insert into logsReportsMaster(name,status,dateStart,dateEnd,error,maxTime)
values (''ReportsMasterProcessWIthOnlyGenerate'',2,@from,@to,'''',@scheduleTime)


exec ccspTmpTimesInterval @from= @from,@to=@to,@interval=15


declare @tableSpTmp table (id int identity primary key, nameSp varchar(300),status int)

insert into @tableSpTmp (nameSp,status) values (''ccspTmpSessionGeneral'',0)
insert into @tableSpTmp (nameSp,status) values (''ccspTmpSessionTimeGroup'',0)

insert into @tableSpTmp (nameSp,status) values (''ccspTimesccLogAgentesDia'',0) --Tabla tmpccLogAgentesDia tener los movimientos de los agentes
insert into @tableSpTmp (nameSp,status) values (''ccspTimesOutboundData'',0)        --Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
insert into @tableSpTmp (nameSp,status) values (''ccspTimesInboundData'',0)     --Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada


insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select nameSp,0,''19000101'',''19000101'','''',@scheduleTime from @tableSpTmp

select @i=1,@count =count(*) from @tableSpTmp


while @i<=@count
begin
    select @name = nameSp from @tableSpTmp where id=@i  

    set @sql =''EXEC ''+ @name +'' @from=''''''+convert(varchar(max),@from,121)+'''''', @to=''''''+convert(varchar(max),@to,121)+''''''''
    set @dateSP = getdate()
    
    
    begin try       
        --print (@sql)
        exec (@sql)     
        update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
    end try
    begin catch
        
        select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
        select @descError,@name
        update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''     
        
    end catch

    set @i = @i+1
end

create table #tmpProcedureReports( id int, name sysname)

insert into #tmpProcedureReports
select ROW_NUMBER() OVER(ORDER BY [name] ) AS id,[name] from  sys.procedures where [name] like ''ccspRep%'' and [name] not in(''ccspRepCatalogos'',''ccsprepLogAgentriaseparate'')

insert into [logsReportsMaster] (name,status,dateStart,dateEnd,error,maxTime)
select name,0,''19000101'',''19000101'','''',@scheduleTime from #tmpProcedureReports

select @i=1,@count =count(*) from #tmpProcedureReports

while @i<=@count
begin
    select @name = name from #tmpProcedureReports where id=@i   

    set @sql =''EXEC ''+ @name +'' @action=1,@from=''''''+convert(varchar(max),@from,121)+'''''', @to=''''''+convert(varchar(max),@to,121)+''''''''
    set @dateSP = getdate()
    
    
    begin try
        --print (@sql)
        exec (@sql)     
        update [logsReportsMaster] set status=1,dateStart=@dateSP,dateEnd=getdate() where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''
    end try
    begin catch
        
        select @descError = ''Line: '' + cast(error_line() as nvarchar) + '' Number: '' + cast(@@error as nvarchar) + '' Message: '' + error_message()
        select @descError,@name
        update [logsReportsMaster] set status=3,dateStart=@dateSP,dateEnd=getdate(),error=@descError where name =@name and status=0 and dateStart=''19000101'' and dateEnd=''19000101''     
        
    end catch

    set @i = @i+1
end

drop table #tmpProcedureReports'
    EXEC(@sql)


    SET @process = 'Alter SP ccSpCreateIndexReport se deja los inidices de los casos para reportes'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccSpCreateIndexReport]  
AS
BEGIN
    SET NOCOUNT ON;

declare @tIndexMerge table(id int identity,tableName varchar(255),status bit)
declare @sql nvarchar(max),@tableName varchar(255),@id int
declare @column varchar(255),@indexName varchar(255)



/****************************INDICES PARA REPORTES *******************************/
if not exists (select * from sys.indexes where name = N''IX_ccoCallsOut13'' and object_id = OBJECT_ID(N''ccoCallsOut''))
begin
   CREATE NONCLUSTERED INDEX IX_ccoCallsOut13
ON [dbo].[ccoCallsOut] ([cal_Inicio])
INCLUDE ([cal_id],[cal_telefono],[cal_puerto],[cam_id],[User_id],[statusCall_id],[calif_id],[cal_tDialog],[cal_tNotas],[cal_tXfer],[cal_tRing],[cal_manual],[cal_tMoh],[cal_whoHung],[cal_twait])
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_11'' and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_11
ON [dbo].[RIA_GRABACION] ([tipo_llamada],[cal_id])
INCLUDE ([grab_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogTransfers_3'' and object_id = OBJECT_ID(N''ccLogtransfers''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogTransfers_3
ON [dbo].[ccLogtransfers] ([fechaFin])
INCLUDE ([cal_id],[tipo],[modo],[destino],[tAntesXfer],[tDespuesXfer])
end


if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesDia_6'' and object_id = OBJECT_ID(N''ccLogAgentesDia''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesDia_6
ON [dbo].[ccLogAgentesDia] ([fecha])
INCLUDE ([User_id],[TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_ccLogAgentesNotReady_5'' and object_id = OBJECT_ID(N''cclogagentesnotready''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogAgentesNotReady_5
ON [dbo].[cclogagentesnotready] ([fecha])
INCLUDE ([User_id],[TipoNotReady_id],[tStatus])
end

    
if not exists (select * from sys.indexes where name = N''IX_ccLogLogin_6'' and object_id = OBJECT_ID(N''ccloglogin''))
begin
   CREATE NONCLUSTERED INDEX IX_ccLogLogin_6
ON [dbo].[ccloglogin] ([fecha])
INCLUDE ([User_id],[Extension],[TipoMov])
end

if not exists (select * from sys.indexes where name = N''IX_ccoLogDials_8'' and object_id = OBJECT_ID(N''ccoLogDials''))
begin
CREATE NONCLUSTERED INDEX IX_ccoLogDials_8
ON [dbo].[ccoLogDials] ([fecha],[cal_id])
INCLUDE ([tipoResDial_id])
end



if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_8'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_8
ON [dbo].[ccCallsIn] ([IVR_id])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_ccCallsIn_9'' and object_id = OBJECT_ID(N''ccCallsIn''))
begin
CREATE NONCLUSTERED INDEX IX_ccCallsIn_9
ON [dbo].[ccCallsIn] ([cal_Inicio])
INCLUDE ([cal_id])
end

if not exists (select * from sys.indexes where name = N''IX_tmpSessionTimeGroup_1'' and object_id = OBJECT_ID(N''tmpSessionTimeGroup''))
begin
CREATE NONCLUSTERED INDEX IX_tmpSessionTimeGroup_1
ON [dbo].[tmpSessionTimeGroup] ([user_id])
INCLUDE ([timegroup],[tlog])
end

   
if not exists (select * from sys.indexes where name = N''IX_tmpccLogAgentesDia_2'' and object_id = OBJECT_ID(N''tmpccLogAgentesDia''))
begin
CREATE NONCLUSTERED INDEX IX_tmpccLogAgentesDia_2
ON [dbo].[tmpccLogAgentesDia] ([userId],[timeGroup])
INCLUDE ([TipoStatusAge_id],[tStatus])
end

if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_1'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_1
ON [dbo].[tmpTimesInboundData] ([statusCall_id])
INCLUDE ([timegroup],[Inbound_id],[nabnd],[tque],[txfer],[tring])
end

    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesInboundData_2'' and object_id = OBJECT_ID(N''tmpTimesInboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesInboundData_2
ON [dbo].[tmpTimesInboundData] ([cal_id])
INCLUDE ([Inbound_id],[User_id])
end


if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_1'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_1
ON [dbo].[tmpTimesOutboundData] ([timegroup],[cal_id])
INCLUDE ([User_id])
end
    
if not exists (select * from sys.indexes where name = N''IX_tmpTimesOutboundData_2'' and object_id = OBJECT_ID(N''tmpTimesOutboundData''))
begin
CREATE NONCLUSTERED INDEX IX_tmpTimesOutboundData_2
ON [dbo].[tmpTimesOutboundData] ([cal_manual])
INCLUDE ([timegroup],[User_id],[nabnd_xfer],[nabnd_ring],[tdialog],[tnotes],[cal_id])
end



/**************************** INDICES Reportes *******************************/



set @column=''date''
delete from @tIndexMerge

insert into @tIndexMerge(tableName,status)
SELECT     
    t.TABLE_NAME,0
FROM 
    INFORMATION_SCHEMA.COLUMNS c
INNER JOIN 
    INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
WHERE 
    t.TABLE_NAME LIKE ''Rep%''   -- Las tablas que comienzan con ''Rep''
    AND c.COLUMN_NAME = ''date'' -- Que contienen una columna llamada ''date''
    AND t.TABLE_TYPE = ''BASE TABLE'' -- Solo tablas (no vistas)
ORDER BY 
    t.TABLE_SCHEMA, t.TABLE_NAME;


while exists(select 1 from @tIndexMerge where status=0) begin
    select top 1 @tableName=tableName,@id=id from @tIndexMerge where status=0 
    set @indexName=N''IX_''+ @tableName+''_date'' 
    set @sql=''if not exists(SELECT 1 FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_hypothetical = 0 -- Excluir índices hipotéticos
    and i.name = @tableName
    and c.name=@column
)
and not exists (select * from sys.indexes where name = @indexName and object_id = OBJECT_ID(@tableName)) 
and exists (select * from sys.columns where name = @column and Object_ID = Object_ID(@tableName))
begin
CREATE NONCLUSTERED INDEX ''+@indexName+''
ON [dbo].[''+@tableName+''] ([date])
end
    ''
    EXEC sp_executesql @sql, 
    N''@tableName varchar(255),@column varchar(255),@indexName varchar(255)'', 
    @tableName = @tableName, 
    @indexName = @indexName,
    @column = @column;
    --print (@sql)
    update @tIndexMerge set status=1 where @id=id
end
    
if not exists (select * from sys.indexes where name = N''IX_RepAgentNotReadyDet_2'' and object_id = OBJECT_ID(N''RepAgentNotReadyDet''))
begin
CREATE NONCLUSTERED INDEX IX_RepAgentNotReadyDet_2
ON [dbo].[RepAgentNotReadyDet] ([tiponotreadyId],[startDate])
INCLUDE ([userId],[status],[statusTime])
end

 

end'
    EXEC(@sql)
    set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
    set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)
 
  SET @process = 'CREATE TABLE [dbo].[ccInbound_consulta]'
    SET @sql = 'if not exists (select * from sys.tables where name = N''ccInbound_consulta'')
begin
        CREATE TABLE [dbo].[ccInbound_consulta](
    [cli_id] [smallint] NULL,
    [Inbound_id] [smallint] NOT NULL,
    [descripcion] [varchar](50) NOT NULL,
    [Status] [smallint] NOT NULL,
    [dnis] [varchar](4) NOT NULL,
    [standby] [smallint] NOT NULL,
    [tNotas] [int] NOT NULL,
    [tMaxWaitCall] [smallint] NOT NULL,
    [nMaxQue] [smallint] NOT NULL,
    [Msg_id] [int] NULL,
    [tel_maxwait] [varchar](15) NOT NULL,
    [tel_maxqueue] [varchar](15) NOT NULL,
    [tel_outservice] [varchar](15) NOT NULL,
    [tel_noct] [varchar](15) NOT NULL,
    [bnocturno] [tinyint] NOT NULL,
    [ShowCalifWnd] [bit] NOT NULL,
    [StartTimerOnHangUp] [bit] NOT NULL,
    [voicePath] [varchar](30) NULL,
    [IDArea] [smallint] NULL,
    [editableCallKey] [bit] NOT NULL,
    [cam_id] [smallint] NULL
)
end'
    EXEC(@sql)        
 
set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
EXEC(@sql)

  


 SET @process = 'DROP VIEW [dbo].[ccInboundView] '
   SET @sql = 'IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N''ccInboundView''))
BEGIN
    DROP VIEW [dbo].[ccInboundView];
END;'
   EXEC(@sql)

   SET @process = 'CREATE VIEW [dbo].[ccCampsView]'
   SET @sql = 'CREATE VIEW [dbo].[ccInboundView] AS
SELECT 
    Inbound_id, descripcion, IDArea
FROM ccInbound
UNION
SELECT 
    Inbound_id, descripcion, IDArea
FROM ccInbound_consulta;'
   EXEC(@sql)


    SET @process = 'Alter Sp ccspRepAgentKPI se pone el from date'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS


SET NOCOUNT ON

if @from is null
    select @from =convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)


if @action = 1
begin
   delete RepAgentKPI with(rowlock) where date >= @from AND date < @to
    
    ;with callTemp as(  
    select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 0  as callType
    from ccoCallsOut with(nolock)
    where cal_inicio between @from and @to and cal_manual < 3
    union all
    select  User_id, statusCall_id, cal_tDialog, convert(date, cal_Inicio, 121) as cal_Inicio, cal_whoHung, 1 as callType
    from ccCallsIn with(nolock)
    where cal_inicio between @from and @to 
    ) 
    , Conteos as(
    select user_id, cal_Inicio, 1 Total, case callType when 1 then 1 else 0 end Cin, case callType when 0 then 1 else 0 end Cout,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
    case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
    cal_whoHung from callTemp
    ), logAgentDialogDistinct as(
    
    select distinct User_id,fecha_Calc_ms/1000.0 as fecha_Calc_ms,fecha_Dispo,fecha_Dialog
    from ccLogAgentesDia_Dialog 
    where fecha_Dialog between @from and @to     
    )
    , Trd as(   
    select  User_id, cast(AVG(fecha_Calc_ms) as decimal(10,0)) avg_fCalc
    , CONVERT(date,fecha_Dialog,121) as fecha_Dispo
    ,sum(fecha_Calc_ms) sum_fCalc
    from logAgentDialogDistinct with(nolock)
    where fecha_Dialog between @from and @to 
    group by User_id,CONVERT(date,fecha_Dialog,121)
    )
    , Snd as(
    select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout,
    sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
    from Conteos group by user_id, cal_Inicio
    ), timeAgtDontDialog as(
    select A.User_id,convert(date,fecha) date
    ,sum(case when A.TipoStatusAge_id not in(0,4,5,6,9,37) then tStatus else 0 end) tDontDialog 
    ,sum(case when A.TipoStatusAge_id in(3,31) then tStatus else 0 end) tready
    from ccLogAgentesDia A with(nolock)
    where fecha between @from and @to
    group by A.User_id,convert(date,fecha)
    
    )


    insert into RepAgentKPI
    select Snd.cal_Inicio,Fst.Login as login , Fst.user_id as [userId]
    ,Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') as [user]
    ,Total as totalCalls, Cin as callsIn
    ,Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung
    ,isnull(avg_fCalc, 0) as callsAvgTime
    ,datepart(yyyy,Snd.cal_Inicio) [year]
    ,datepart(mm,Snd.cal_Inicio) [mounth]
    ,datepart(dd,Snd.cal_Inicio) [day]
    ,0 as [hour]
    ,0 as [minute]
    ,convert(decimal(10,0),agtTime.tDontDialog/Total) as [callsAvgTimeCustom]   
    from Snd
    inner join ccUserView Fst on Fst.User_id = Snd.User_id
    left join Trd on Trd.User_id=Snd.User_id and Trd.fecha_Dispo=Snd.cal_Inicio
    left join timeAgtDontDialog agtTime on agtTime.User_id=Snd.User_id and agtTime.date=Snd.cal_Inicio
    order by cal_Inicio

    

end'
    EXEC(@sql)


    SET @process = 'Alter SP ccspRepAgentSummary set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSummary] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()))

IF @to IS NULL
    SELECT @to = GETDATE()

set @from=convert(date,@from)

IF @action = 1
BEGIN

    IF OBJECT_ID(''tempdb..#AuxiliarReadyDetail'') IS NOT NULL
    DROP TABLE #AuxiliarReadyDetail

    CREATE TABLE #AuxiliarReadyDetail
    (
        timegroup DATE,
        userId INT,
        [user] VARCHAR(50),
        [sessionTime] INT,
        TipoReadyAuxiliarId INT,
        descripcion VARCHAR(50),
        descripcion_time VARCHAR(50),
        [time] DECIMAL(18, 3),
        timeSeconds DECIMAL(18, 3)
    )

    INSERT INTO #AuxiliarReadyDetail
    EXEC ccspGetAuxiliarReadyDetail @from = @from, @to = @to
        
    DELETE RepAgentSummary WHERE DATE BETWEEN @from AND @to;
    DELETE RepAgentSummary_VersionAmatech WHERE DATE BETWEEN @from  AND @to;
    ;
    WITH AgentSession
    AS (
        SELECT dbo.getdaygroup(loginTime) AS [date], userId, min([login]) AS [login], [user] AS [user], MIN(loginTime) AS dateLogin, MAX(logoutTime) AS logout, SUM(sessionTimeSeconds) AS sessionTime
        FROM RepAgentSession
        WHERE dbo.getdaygroup(loginTime) BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(logintime), userId, [user]
        ),
        -------------OUT -------------------
    dataCallsOut
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY cal_id, statusCall_id
        ), dataCallsOutByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogOut, SUM(tnotes) tNotesOut, sum(nabnd_xfer) nabnd_xfer
        , sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferOut, SUM(tring)  tringOut
        FROM tmpTimesOutboundData
        where cal_manual in (0,2,3)
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallout
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifOut
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallOut
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallOut
        , sum(tDialogOut) AS tDialogOut, sum(tNotesOut) AS tNotesOut, sum(nabnd_xfer) abnd_xfer, sum(nabnd_ring) abnd_ring
        , sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferOut)  txferOut, SUM(tringOut)  tringOut
        FROM dataCallsOutByDay A
        INNER JOIN dataCallsOut B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ),
        ------------- IN -------------------
    dataCallsIn
    AS (
        SELECT DISTINCT cal_id, max(calif_id) calif_id, statusCall_id
        FROM tmpTimesInboundData
        GROUP BY cal_id, statusCall_id
        ), dataCallsInByDay
    AS (
        SELECT dbo.getdaygroup(timegroup) AS [date], User_id, cal_id, SUM(tdialog) tDialogIn, SUM(tnotes) tNotesIn
        , sum(nabnd_xfer) nabnd_xfer, sum(nabnd_ring) nabnd_ring, sum(nabnd_dialog) nabnd_dialog
        , SUM(txfer)  txferIn, SUM(tring)  tringIn
        FROM tmpTimesInboundData
        GROUP BY dbo.getdaygroup(timegroup), User_id, cal_id
        ), tmpCallIn
    AS (
        SELECT A.User_id AS userId, sum(CASE WHEN B.calif_id = 0 THEN 1 ELSE NULL END) NoCalifIn
        , isnull(sum(CASE WHEN B.statusCall_id = 11 THEN 1 ELSE NULL END), 0) NotAttendedCallIn
        , isnull(sum(CASE WHEN B.statusCall_id = 13 THEN 1 ELSE NULL END), 0) AttendedCallIn
        , sum(tDialogIn) AS tDialogIn, sum(tNotesIn) AS tNotesIn, sum(nabnd_xfer) abnd_xfer
        , sum(nabnd_ring) abnd_ring, sum(nabnd_dialog) abnd_dialog, [date]
        , SUM(txferIn)  txferIn, SUM(tringIn)  tringIn
        FROM dataCallsInByDay A
        INNER JOIN dataCallsIn B
            ON A.cal_id = B.cal_id
        GROUP BY [date], User_id
        ), RepDetail
    AS (
        SELECT r.userId, SUM(r.timeSeconds) AS notReady, dbo.getdaygroup(r.DATE) AS daygroup
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId
        )
    ,notReadyDay as(
    SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(r.DATE) AS daygroup
        ,descripcion_time,descripcion,tiponotreadyId
        FROM RepAgentNotReady r with(nolock)
        WHERE r.DATE BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup(r.DATE), r.userId,descripcion,descripcion_time,tiponotreadyId
    ),auxiliarReadyDay as(
        SELECT r.userId, SUM(r.timeSeconds) AS timeSeconds, dbo.getdaygroup(timegroup) AS daygroup
        ,descripcion_time,descripcion,TipoReadyAuxiliarId
        FROM #AuxiliarReadyDetail r with(nolock)
        GROUP BY dbo.getdaygroup(timegroup), r.userId,descripcion,descripcion_time,TipoReadyAuxiliarId
    ), RepAgentGIGroup as(
        SELECT dbo.getdaygroup([date]) AS [date], userId, SUM(tav) AS tav
        , SUM(tunknown) AS tunknown
        , SUM(tother) AS tother
        , SUM(tprob) AS tprob
        , SUM(tChatting) AS tChatting       
        , SUM(tundefined) AS tundefined
        , SUM([tManual]) AS [tManual]
        FROM RepAgentGI
        WHERE [date] BETWEEN @from AND @to
        GROUP BY dbo.getdaygroup([date]), userId
    )
    --select * from AgentSession
    
    INSERT INTO RepAgentSummary (date,login,[user],sessionTime,loginMktTime,logoutMktTime,callTengaged,ndTime,NCallsOut,NCallsIn,NCallsCorta,NAtend,NNoCalif
    ,Available,avgCallTengaged,twrapup,userId,TypeNotReady,descripcion,descripcion_time,time,transferStatus,ringingTime,unknownStatus,otherStatus,failureStatus
    ,chatTengaged,undefinedTime,dialingStatus,TipoReadyAuxiliarId,auxiliarRedy_descripcion,descripcion_auxiliarRedyTime_time,auxiliarRedyTime)
    SELECT A.[date], A.[login], A.[user], A.sessionTime, A.dateLogin AS loginMktTime
    , A.logout AS logoutMktTime
    , isnull(co.tDialogOut, 0) + isnull(ci.tDialogIn, 0) callTengaged
    , ISNULL(r.notready, 0) AS ndTime, isnull(co.AttendedCallOut, 0) AS NCallsOut, isnull(ci.AttendedCallIn, 0) AS NCallsIn
    , ISNULL(co.abnd_xfer, 0) + isnull(co.abnd_ring, 0) + isnull(co.abnd_ring, 0) + isnull(ci.abnd_xfer, 0) + isnull(ci.abnd_ring, 0) + isnull(ci.abnd_ring, 0) AS NCallsCorta
    , ISNULL(co.NotAttendedCallOut, 0) + ISNULL(ci.NotAttendedCallIn, 0) AS NAtend
    , ISNULL(ci.NoCalifIn, 0) + ISNULL(co.NoCalifOut, 0) AS NNoCalif    
    , ISNULL(AgtGI.tav, 0) AS Available
        ,ISNULL(    
        (   ISNULL(co.tDialogOut, 0) + ISNULL(co.tNotesOut, 0) + ISNULL(ci.tDialogIn, 0) + ISNULL(ci.tNotesIn, 0) )
            /
         nullif(isnull(co.AttendedCallOut,0) + isnull(ci.AttendedCallIn,0),0)
        , 0) AS avgCallTengaged
        
        ,ISNULL(co.tNotesOut, 0) + ISNULL(ci.tNotesIn, 0) AS twrapup, A.userId AS userId
        , notReady.TipoNotReadyId
        , notReady.descripcion
        , notReady.descripcion_time
        , notReady.timeSeconds
        , ISNULL(co.txferOut, 0) + ISNULL(ci.txferIn, 0) AS transferStatus
        , ISNULL(co.tringOut, 0) + ISNULL(ci.tringIn, 0) AS ringingTime
        , ISNULL(AgtGI.tunknown, 0) unknownStatus
        , ISNULL(AgtGI.tother, 0) otherStatus
        , ISNULL(AgtGI.tprob, 0) failureStatus
        , ISNULL(AgtGI.tChatting, 0) chatTengaged
        , ISNULL(AgtGI.tundefined, 0) undefinedTime
        , ISNULL(AgtGI.tManual, 0) dialingStatus
        , auxiliarReady.TipoReadyAuxiliarId
        , auxiliarReady.descripcion as auxiliarRedy_descripcion
        , auxiliarReady.descripcion_time as descripcion_auxiliarRedyTime_time
        , convert(int,auxiliarReady.timeSeconds) as auxiliarRedyTime
    FROM AgentSession A
    LEFT JOIN tmpCallout co ON A.DATE = co.DATE AND A.userId = co.userId
    LEFT JOIN tmpCallIn ci  ON A.DATE = ci.DATE AND A.userId = ci.userId
    LEFT JOIN RepDetail r   ON r.daygroup = A.DATE AND A.userId = r.userId
    inner join notReadyDay notReady on notReady.userId=A.userId and notReady.daygroup=A.date
    LEFT join #AuxiliarReadyDetail auxiliarReady on auxiliarReady.userId=A.userId and auxiliarReady.timegroup=A.date
    left join RepAgentGIGroup AgtGI on AgtGI.date=A.date and AgtGI.userId=A.userId
    order by A.[date],A.userId

END'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepCallXfer]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepCallXfer with(rowlock)    where [date] between @from and @to
    insert RepCallXfer 
    select convert(varchar(10),fechafin,121) [date], 
    clt.cal_id callid, 
    case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
    isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno 
            from ccUserView nolock 
            where user_id = (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent, 
    case when modo = 0 then ''systemTranslated_blindXfer'' 
        when modo = 1 then ''systemTranslated_Agent'' 
        when modo = 2 then 
            case when cast(dbo.Limpia(clt.destino) as int) >= 0 then ''systemTranslated_acd'' 
                else ''systemTranslated_Survey'' end 
        when modo = 3 then ''systemTranslated_conference'' 
        when modo = 4 then ''systemTranslated_supXfer'' 
        when modo in(5,6) then ''systemTranslated_overflow'' 
        when modo in(7) then ''systemTranslated_press8'' 
        else ''systemTranslated_Default'' 
    end as xfertype, 
    ISNULL((case when modo = 0 then isnull((select top 1 nombre 
                                    from telefonosTransferencia 
                                    where tel = clt.destino),clt.destino) 
        when modo = 1 then isnull((select Computer 
                                    from ccposicion 
                                    where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
        when modo = 2 then 
            case when cast(dbo.Limpia(clt.destino) as bigint) >= 0 then
                    isnull((select descripcion from ccinbound 
                            where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
                else
                    isnull((select top 1 description 
                            from survey 
                            where active=1 
                            and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
            end 
        when modo = 3 then isnull((select nombre 
                                    from telefonosConferencia 
                                    where tel = clt.destino),clt.destino) 
        when modo = 4 then isnull((select top 1 nombre 
                                    from telefonosTransferencia 
                                    where tel = clt.destino),clt.destino) 
        when modo in(5,6) then isnull((select Computer 
                                        from ccposicion 
                                        where pos_id = abs(clt.destino)),clt.destino) 
    end), ''systemTranslated_Indefinite'') destination, 
    tantesxfer timebeforexfer, 
    tdespuesxfer timeafterxfer, 
    dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate, 
    fechafin as endDate, 
    case when camp.cam_descripcion is not null then camp.cam_descripcion 
        when inbound.descripcion is not null then inbound.descripcion 
        else ''systemTranslated_Indefinite'' 
    end as Origin, 
    tantesxfer+tdespuesxfer as TotalTimeDuration, 
    isnull((select case clt.tipoLlamada_id 
                when 1 then ''systemTranslated_fijo'' 
                when 3 then ''systemTranslated_cellPhone'' 
                else ''systemTranslated_interno'' 
            end),''systemTranslated_Indefinite'') as TipoTel, 
    (case tipo when 1 then ci.User_id else co.User_id end) User_ID, 
    isnull(callerAni, '''')  as callerni
    from cclogtransfers clt 
    left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
    left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1 
    left join cccamps camp on camp.cam_id =co.cam_id 
    left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id 
    WHERE fechafin >= @from and fechafin < @to
end
    '
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepIVRGeneral] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)

if @action = 1
    begin
        delete RepIVRGeneral with(rowlock)
        where date >= @from and date < @to

        insert into RepIVRGeneral
        select convert(date,[date],121) as [date], 
        sum(case when calId = 0 then 1 else 0 end) as [noTransferred], 
        sum(case when calId > 0 then 1 else 0 end) as [transferred], 
        count(*) as [total]
        , datepart(yyyy,date)
        , datepart(mm,date)
        , datepart(dd,date)
        , 0
        , 0
        from (
        select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId ,convert(date,A.[date],121) as [date] 
                from IVRCallsIn as a with(nolock)
                left join ccCallsIn as b with(nolock) on  A.IVR_id = B.IVR_id 
                where date >= @from and date < @to
            ) as c
        where date >= @from and date < @to
        group by [date]
        
    end'
    EXEC(@sql)



    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON
if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin

select 
    convert(datetime,convert(date,login)) fecha,
    SUM(DATEDIFF(ss, login, logout)) t_ses,
    count(distinct user_id) user_id
into #infoSession
from TmpSessionGeneral
GROUP BY convert(datetime,convert(date,login))

SELECT 
        i.cal_Inicio as [date],
        i.user_id as acduser,
        i.Inbound_id as inboundId,
        case when i.statuscall_id=13 then i.cal_tmoh else 0 end thold,
        case when i.statusCall_id=13 then i.cal_tring else 0 end tring,
        case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end tacd,
        case when i.statusCall_id=13 then i.cal_tnotas else 0 end tacw,
        case when i.statusCall_id=13 then 1 else null end nacd,
        case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end nacw,
        case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else null end nhold,
        case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring   
    into #inboundData2          
    FROM    cccallsin i (NOLOCK)    
    WHERE   i.cal_inicio between @from and @to

SELECT user_id AS agtuser_id,
    login AS agtlogin,
    ISNULL(apellidopaterno,'''')+'' ''+ISNULL(apellidomaterno,'''')+'' ''+ISNULL(nombres,'''') agt_name
    into #users
    FROM ccUserView (NOLOCK)

    delete from [RepMKTDiarioTiemposTotales] with(rowlock)  where date >= @from AND date <= @to 

    insert RepMKTDiarioTiemposTotales 
    select c.[date] --
        ,isnull(l.agtlogin,''N/A'') as [OpaId]
        ,isnull(l.agt_name,'''') [NombreDeOperadora]
        ,[InboundID]--
        ,[TiempoPromACD]--
        ,[TiempoPromACW]--
        ,[TiempoPromReten]
        ,[TiempoPromRing]
        ,[AHT]
        ,[LlamadasAtendidas]
        ,DATEPART(YYYY, c.[date]) as [year] 
        ,DATEPART(mm, c.[date]) as [month]
        ,DATEPART(dd, c.[date]) as [day]
        ,DATEPART(hh, c.[date]) as [hour]
        ,DATEPART(mi, c.[date]) as [minutes]
     from (
        select convert(datetime,convert(date,[date])) as [date],
            acduser as [user],
            inboundId as [InboundId]
            ,case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end as [TiempoPromACD]
            ,case when sum(c.nacw)>0 then sum(c.tacw)/sum(c.nacw) else 0 end as [TiempoPromACW]
            ,case when sum(c.nhold)>0 then sum(c.thold)/sum(c.nhold) else 0 end as [TiempoPromReten]
            ,case when sum(c.nring)>0 then sum(c.tring)/sum(c.nring) else 0 end as [TiempoPromRing]
            ,sum(((case when c.nacd>0 then c.tacd/c.nacd else 0 end)+(case when c.nacw>0 then c.tacw/c.nacw else 0 end)+(case when c.nring>0 then c.tring/c.nring else 0 end)+(case when c.nhold>0 then c.thold/c.nhold else 0 end))) [AHT]
            ,isnull(sum(c.nacd),0) as [LlamadasAtendidas]
        from #inboundData2 as c 
        group by convert(datetime,convert(date,[date])),inboundId,acduser
    ) c
    LEFT JOIN #infoSession G on G.fecha = c.date
    left join #users l on [user]=l.agtuser_id   
    WHERE @from <= C.[date] AND @to >= c.[date] and [LlamadasAtendidas]>0
    order by [date]

drop table #inboundData2
drop table #infoSession 
drop table #users

end
'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
    if @from is null
        select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)
                            
    delete RepOutAnswCalls with(rowlock)
    where [date] between @from and @to

    ;with   
    co as(
    select
    convert(date,cal_inicio,121) [date],
    co.cam_id campaignId, count(*) total, 
    COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
    COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
    COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
    COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
    COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
    from ccocallsout co with(nolock,index(IX_ccoCallsOut13))    
    where cal_inicio between @from and @to 
    group by convert(date,cal_inicio,121),co.cam_id
    ) 
    ,wgCalId as(
    
        select campaignId,isnull(min(wg.IDWG),1) IDWG
        from co o 
        left join ccRIACampEspWG wg on o.campaignId =wg.IdCampEsp and wg.Tipo=1
        group by campaignId
    )
    

    insert RepOutAnswCalls
    select 
    [date], abnd.campaignId, ca.cam_descripcion campaign, 
    wg.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
    cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
    cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
    cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
    cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
    cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
    from co abnd    
    left join cccamps ca on ca.cam_id=abnd.campaignId 
    left join wgCalId wg on abnd.campaignId=wg.campaignId
    left join ccRIACat_WorkGroup as e on e.idwg = wg.idwg
    left join ccRIAAreaWorkGroup as f on f.idwg = e.idwg
    left join ccRIACat_Areas as g on g.idarea = f.idarea
                            
end'
    EXEC(@sql)



    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsByTelephone] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsByTelephone]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

set @from=convert(date,@from)


if @action = 1
    begin
        delete RepOutCallsByTelephone with(rowlock)
        where date >= @from and date < @to

        insert into RepOutCallsByTelephone
        select timegroup as [date], cal_telefono as [telephone], cal_key as [callKey], cam_id as [campaignId], cam_descripcion as [campaign], 
        count(cal_telefono) as quantity
        , datepart(yyyy,timegroup) as [year]
        , datepart(mm,timegroup) as [month]
        , datepart(dd,timegroup) as [day]
        , datepart(hh,timegroup) as [hour]
        , datepart(mi,timegroup) as [minutes]
        from(select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, a.cam_id, b.cam_descripcion
             from ccocallsout a
             left join cccamps b on (a.cam_id = b.cam_id) 
             where cal_inicio >= @from 
             and cal_inicio < @to) c
        group by cal_telefono, timegroup, cal_key, cam_id, cam_descripcion
        order by cal_telefono, count(cal_telefono)
    end'
    EXEC(@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd] se cambia ccCampsView y ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbnd]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    delete RepSpececialAbnd with(rowlock)
    where [date] between @from and @to
    
    insert RepSpececialAbnd select [date], campaignId, inboundId, [Espec/Camp], total, abandonedCalls, 
    cast(((abandonedCalls*100.0)/total) as decimal(5,2)) abandonedCallsPctg from (
        select convert(varchar(10),cal_inicio,121) [date], 0 campaignId, ci.inbound_id inboundId, 
        ''ACD - '' + descripcion [Espec/Camp], count(*) total, 
        COUNT(
        CASE WHEN @setting = 0 and (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00''))  THEN 1
             WHEN @setting = 1 and (statuscall_id IN (6) AND (cal_que > 0) AND (isnull(cal_xfer,''1900-01-01 00:00:00'') = ''1900-01-01 00:00:00'')) THEN 1
         ELSE NULL END) abandonedCalls
        from cccallsin ci with(nolock) 
        left join ccInboundView ib on ib.inbound_id=ci.inbound_id 
        where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, ''ACD - '' + descripcion
        union all
        select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, 0 inboundId, 
        ''Camp - '' + cam_descripcion [Espec/Camp], count(*) total, 
        COUNT(
            CASE WHEN @setting = 0 and (statuscall_id in(11,15,16))THEN cal_id 
                 WHEN @setting = 1 and (statuscall_id in(6))THEN cal_id ELSE NULL END) abandonedCalls
        from ccocallsout co with(nolock) 
        left join ccCampsView ca on ca.cam_id=co.cam_id 
        where cal_inicio between @from and @to and cal_manual in (0,2) group by convert(varchar(10),cal_inicio,121), co.cam_id, ''Camp - '' + cam_descripcion
    ) abnd
end'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndPercentage] se agrega ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndPercentage]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
set @setting=1
select @setting= valor from ccSettings where setting_id=43 

begin
    if @from is null
    select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepSpececialAbndPercentage with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndPercentage select [date], inboundId, [inbound]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [5]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [10]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [15]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [20]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [25]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [30]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [40]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [50]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [60]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.cal_id)),0)))) AS [>60]
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) 
                left join ccInboundView ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)
    

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndProfiles] set @from=convert(date,@from) y ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndProfiles]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS
declare @setting smallint
select @setting= valor from ccSettings where setting_id=43
if @action = 1
begin
    if @from is null
        select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepSpececialAbndProfiles with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndProfiles select [date], inboundId, [inbound]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))) AS [5]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))) AS [10]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))) AS [15]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))) AS [20]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))) AS [25]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))) AS [30]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))) AS [40]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))) AS [50]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))) AS [60]
        , (CONVERT(DECIMAL(18),ISNULL(COUNT(CASE WHEN xCalls.nAbnd>0 THEN 1 ELSE NULL END),0))) AS [>60]
        , COUNT(*) total
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) 
                left join ccInboundView ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)


    
    SET @process = ' ALTER PROCEDURE [dbo].[ccspRepSpececialAbndTimes] set @from=convert(date,@from) y ccInboundView'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAbndTimes]
@action as tinyint,
@from AS smalldatetime = null,
@to AS smalldatetime = null
AS

declare @setting smallint
select @setting= valor from ccSettings where setting_id=43

if @action = 1
begin
    if @from is null
        select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    delete RepSpececialAbndTimes with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAbndTimes select [date], inboundId, [inbound]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 5 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [5]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 10 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [10]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 15 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [15]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 20 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [20]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 25 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [25]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 30 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [30]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 40 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [40]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 50 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [50]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 and xCalls.tAbnd <= 60 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [60]
        , CONVERT(INTEGER,100*(CONVERT(DECIMAL(18,3),ISNULL(COUNT(CASE WHEN xCalls.nAbnd > 0 THEN 1 ELSE NULL END),0))/CONVERT(DECIMAL(18,3),ISNULL((COUNT(xCalls.nAbnd)),0)))) AS [>60]
            from (
                select convert(varchar(10),cal_inicio,121) [date], ci.inbound_id inboundId, descripcion [inbound]
                ,cal_id
                ,SUM(CASE WHEN  @setting = 0 and (statuscall_id <> 13) THEN (cal_twait + cal_txfer + cal_tring) 
                          WHEN  @setting = 1 and (statuscall_id = 6) THEN (cal_twait + cal_txfer + cal_tring) ELSE 0 END) AS tAbnd
                ,COUNT(
                    CASE WHEN @setting = 0 and (statuscall_id <> 13) THEN 1 
                         WHEN @setting = 1 and (statuscall_id = 6) THEN 1 ELSE NULL END) AS nAbnd
                from cccallsin ci with(nolock) 
                left join ccInboundView ib on ib.inbound_id=ci.inbound_id
                where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121), ci.inbound_id, descripcion, cal_id
            ) xCalls
        GROUP BY [date], inboundId, [inbound]
end
'
    EXEC(@sql)


    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialAgtPerformance]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
        select @from = convert(datetime,convert(varchar(11),getdate()))
    if @to is null  
        select @to = getdate()

    set @from=convert(date,@from)
                            
    DECLARE @data varchar(10), @promesa INT, @promesainb INT, @tresDialog AS smallint
    EXEC @tresDialog=ccspConfigTresDialog
    select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
    SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
    SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2
                        
    delete RepSpececialAgtPerformance with(rowlock)
    where [date] between @from and @to

    insert RepSpececialAgtPerformance select [date],rcalls.USER_ID [userId]
    ,us.apellidopaterno + '' '' + us.apellidomaterno + '' '' + nombres [user],login [Agent]
    ,answer Answered, promises, promisesPctg, dialog avgCallTime, wrapup avgWrapupTime
    from (
    select [date], user_id, SUM(answer) answer, SUM(promises) promises
    ,isnull(cast(SUM(promises)*100.0/nullif(SUM(answer),0) as decimal(5,2)),0) promisesPctg
    ,isnull(sum(dialog)/nullif(SUM(answer),0),0) dialog, isnull(sum(wrapup)/nullif(SUM(answer),0),0) wrapup
    from (
    select 
    CONVERT(varchar(10),cal_inicio,121) [date], user_id
    ,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
    ,isnull(count(case calif_id when @promesa then 1 else null end),0) promises
    ,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END),0) answer
    from ccoCallsOut with(nolock) where cal_inicio between @from and @to and cal_manual in(0,2) and USER_ID>0
    group by CONVERT(varchar(10),cal_inicio,121),user_id
    union all
    select
    CONVERT(varchar(10),cal_inicio,121) [date], user_id
    ,isnull(sum(cal_tdialog),0) dialog, isnull(sum(cal_tnotas),0) wrapup
    ,isnull(count(case calif_id when @promesainb then 1 else null end),0) promises
    ,isnull(COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),0) answer
    from ccCallsIn with(nolock) where cal_inicio between @from and @to  and USER_ID>0
    group by CONVERT(varchar(10),cal_inicio,121),user_id) calls group by [date],user_id) rcalls 
    left join ccUserView us on us.user_id=rcalls.user_id
end'
    EXEC(@sql)



    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepSpececialPromises] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepSpececialPromises]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
    if @from is null
    select @from = convert(date,getdate())

    if @to is null
        select @to = getdate()

    set @from=convert(date,@from)

    DECLARE @data varchar(10), @promesa INT, @promesainb INT
    select @data = isnull(valor,''1|1'') from ccSettings where setting_id = 30
    SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 1
    SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,''|'') where id = 2

    delete RepSpececialPromises with(rowlock)
    where [date] between @from and @to
    
    insert RepSpececialPromises SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_outbound'' [type],
    cout.campaignId campaignId, 0 inboundId,
    camp.cam_descripcion [campACDDescription],
    ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0) AS promises,
    ISNULL(SUM(cout.count),0) AS total,
    CASE ISNULL(SUM(cout.count),0) WHEN 0 THEN 0 ELSE  
    CONVERT(decimal,ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0))/ 
    CONVERT(decimal,ISNULL(SUM(cout.count),0)) END AS percentage 
    FROM RepOutDispositions as cout JOIN ccCamps as camp ON camp.cam_id = cout.campaignId 
    WHERE cout.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cout.campaignId, camp.cam_descripcion
    union all
    SELECT convert(varchar(10),[date],121) [date], ''systemTranslated_inbound'' [type],
    0 campaignId, cin.inboundId inboundId,
    espe.descripcion [campACDDescription],
    ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0) AS promises,
    ISNULL(SUM(cin.count),0) AS TOTAL,
    CASE ISNULL(SUM(cin.count),0) WHEN 0 THEN 0 ELSE
    CONVERT(decimal,ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0))/ 
    CONVERT(decimal,ISNULL(SUM(cin.count),0)) END AS percentage
    FROM RepInDispositions as cin JOIN ccInbound as espe ON espe.inbound_id = cin.inboundId
    WHERE cin.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cin.inboundId, espe.descripcion
end'
    EXEC(@sql)


    SET @process = 'ALTER   PROCEDURE [dbo].[ccspRepMKTTiemposTotales] se cambia  ccInboundView'
    SET @sql = 'ALTER   PROCEDURE [dbo].[ccspRepMKTTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
    select @to = getdate()

if @action = 1
begin

    IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;           
        
    IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
    
    IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
    IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog    

    IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData        
    

    CREATE TABLE #sessionTimeGroup( [user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[timegroup] [datetime]  NOT NULL,
    [timegroup_next] [datetime]  NOT NULL, [tlog seg] [INT] NULL, [inb_id] [int] NOT NULL)
            
    
    ;with 
     relationCallIdCamId as(
        select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
    ),
    transferData as(
        select B.userId,B.InboundId
        ,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
        ,CASE WHEN t.modo in (0,3,4)  then (t.tAntesXfer + t.tDespuesXfer) else 0 end as tprosalext         
        ,timegroup      
        from TmpTimesccLogtransfers T
        inner join relationCallIdCamId B on t.callId=B.callId   
        where tipo=1
    ), transferDataGroup as(

    select userId, timegroup, InboundId 
    ,sum(SalExt) SalExt,sum(tprosalext) tprosalext
    from transferData
    group by timegroup, InboundId,userId
    )
    

    select * into #transferData from transferDataGroup

    ;with relationWg as(
        select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
        Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
        where wg.Tipo = 0
    )

    INSERT INTO #sessionTimeGroup
    select st.[user_id],[login],logout,timegroup,timegroup_next timeGroupNext,tlog, wgu.IdCampEsp from TmpSessionTimeGroup st
        Inner Join relationWg wgu ON st.User_id = wgu.User_id

    
    select userId as user_id,camId as IdCampEsp,TipoStatusAge_id,
    sum(tstatus) as tstatus,
    sum(CASE WHEN timeGroup > dateIni AND timeGroupNext > dateEnd THEN 1 ELSE 0 END) AS nstatusfra,
    timeGroup
    INTO #groupLog
    from tmpccLogAgentesDia
    where TipoStatusAge_id IN (3,37) 
    GROUP BY userId,camId,TipoStatusAge_id,timegroup
    order by userId,timegroup,camId
                
    
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ;with inCount as(
        select i.timegroup,Inbound_id as inboundId,User_id userId 
        ,sum(CASE WHEN i.timeGroup > dateStartDetail AND i.timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nacd          
                ,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  THEN 1 ELSE 0 END ) as nabnd
                ,sum(tdialog) as tacd
                ,sum(tnotes) as tacw
                ,sum(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tnotes>0 THEN 1 ELSE 0 END) as nacw            
                ,sum(SalExt) as SalExt
                ,sum(tprosalext) as tprosalext
                ,sum(ntotal) as ncalls  
                ,SUM(tring) as tring
                ,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13  and tring>0 THEN 1 ELSE 0 END) as nring
                ,SUM(CASE WHEN i.timeGroup > dateStartDetail AND timegroup_next > dateEndDetail and  statusCall_id = 13   THEN nMoh ELSE 0 END) as nhold
        from tmpTimesInboundData i
        left join #transferData  t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId
                    group by i.timegroup,Inbound_id,User_id 
    )

    select case when c.timegroup is not null then c.timegroup else G.timegroup end  as [date]
        ,isnull(c.inboundId,inb_id) as inboundId
        ,isnull(c.nacd,0) as nacd
        ,isnull(c.nabnd,0)  as nabnd    
        ,isnull(c.tacd,0)tacd, isnull(c.tacw,0) tacw,isnull(c.nacw,0) nacw      
        ,isnull(c.SalExt,0)  SalExt,isnull(c.tprosalext,0)  tprosalext
        ,G.userId 
        ,isnull(G.[tlog seg],0) as tlog
        ,isnull(c.ncalls, 0) AS ncalls      
        ,isnull(c.tring, 0) AS tring
        ,isnull(c.nring, 0) AS nring
        ,isnull(c.nhold, 0) AS nhold
     INTO #IntervalosInbound
     from (
            select * from  inCount where inboundId > 0      
        ) c     
    full join 
    (select [user_id] as userId, timegroup, inb_id,sum([tlog seg] ) as [tlog seg] from  #sessionTimeGroup group by [user_id] ,timegroup,inb_id ) G
    on G.timegroup=c.[timegroup] and c.inboundId = G.inb_id and G.userId=c.userId

    
    select i.*
    ,isnull(case when lo.TipoStatusAge_id=3 then isnull(lo.tStatus,0) end,0) tdispo
    ,isnull(case when lo.TipoStatusAge_id=3 then lo.nstatusfra end,0) ndispo
    ,isnull(case when lo.TipoStatusAge_id=37 then isnull(lo.tStatus,0) end,0) tauxiliar
    ,isnull(case when lo.TipoStatusAge_id=37 then 1 end,0) nauxiliar
    ,isnull(h.tiempohold, 0) AS thold
    INTO #HoldDisp
    from #IntervalosInbound i
    left JOIN #groupLog lo on i.date = lo.timegroup and i.inboundId = lo.IdCampEsp and i.userId = lo.user_id
    left JOIN tmpTimesHoldIn h on h.inbound_id = i.inboundId and i.date = h.timegroup and i.userId = h.userId   

    delete from [RepMKTTiemposTotales]  where date >= @from AND date <= @to

    INSERT INTO [RepMKTTiemposTotales]
    select 
        [date] as [date]
        ,inboundId
        ,inb.descripcion as Acds
        ,round(case when count(distinct userId)>1 then ((convert(float,(sum(tlog)*100))/convert(float,count(distinct userId)*1800))*count(distinct userId))/100 else 0 end,1) as [Llamadas por Posic.]
        ,sum(ncalls) [Recibidas]
        ,sum(nacd) [Atendidas]
        ,sum(nabnd) [Abandonadas]
        ,case when sum(nacd)>0 then sum(tacd)/sum(nacd) else 0 end as [tPromACD]
        ,case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end as [tPromACW]
        ,case when sum(nhold)>0 then sum(thold)/sum(nhold) else 0 end as [tPromRetention]
        ,sum(SalExt) as [callsOutExt]   
        ,isnull(case when sum(SalExt)>0 then sum(tprosalext)/sum(SalExt) else 0 end,0) as [TPromSalidaExt]
        ,case when sum(ndispo)>0 then sum(tdispo)/sum(ndispo) else 0 end as [TPromDispon]
        ,case when sum(nring)>0 then sum(tring)/sum(nring) else 0 end [TPromRing]
        ,sum(((case when nacd>0 then tacd/nacd else 0 end)+(case when nacw>0 then tacw/nacw else 0 end)+(case when nring>0 then tring/nring else 0 end)+(case when nhold>0 then thold/nhold else 0 end))) [AHT1]
        ,sum(tacd) as tacd
        ,sum(tacw) as tacw
        ,sum(nacw) as nacw              
        ,sum(tprosalext) as tprosalext
        ,sum(tlog) as tlog
        ,sum(nhold) as nhold
        ,sum(thold) as thold
        ,sum(tdispo) as tdispo
        ,sum(ndispo) as ndispo
        ,sum(tring) as tring
        ,sum(nring) as nring
        ,userId as accountUserId            
        ,DATEPART(YYYY, [date]) as [year] 
        ,DATEPART(mm, [date]) as [month]
        ,DATEPART(dd, [date]) as [day]
        ,DATEPART(hh, [date]) as [hour]
        ,DATEPART(mi, [date]) as [minutes]
        ,case when sum(nauxiliar)>0 then sum(tauxiliar)/sum(nauxiliar) else 0 end [TPromAuxiliar]
        ,sum(tauxiliar) as tauxiliarRdy
        ,sum(nauxiliar) as nauxiliar
        from #HoldDisp
        Left join ccInboundView inb ON inb.Inbound_id = inboundId
        group by[date],inboundId, userId, inb.descripcion
        order by date       

    IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup;                   
    IF OBJECT_ID(''tempdb..#IntervalosInbound'') IS NOT NULL DROP TABLE #IntervalosInbound
    
    IF OBJECT_ID(''tempdb..#HoldDisp'') IS NOT NULL drop table #HoldDisp
    IF OBJECT_ID(''tempdb..#groupLog'') IS NOT NULL drop table #groupLog    

    IF OBJECT_ID(''tempdb..#transferData'') IS NOT NULL drop table #transferData        

END'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos] set @from=convert(date,@from)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepMKTIntervalos]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
    
set nocount on
set ansi_nulls off
set ANSI_WARNINGS off


if @from is null
    select @from = convert(date,getdate())

if @to is null
    select @to = getdate()

if @action = 1
begin
    
    IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup
    CREATE TABLE #sessionTimeGroup( [user_id] [smallint] NOT NULL,[timegroup] [datetime]  NOT NULL, [tlog] [INT] NULL, [inb_id] [int] NOT NULL) 
    
    ;with relationWg as(
        select distinct wgu.User_id,wg.IdCampEsp from ccriaworkgroupusers wgu
        Inner Join ccRIACampEspWG wg ON wg.IDWG = WGU.IDWG
        where wg.Tipo = 0
    )

    INSERT INTO #sessionTimeGroup
    select st.[user_id],timegroup,tlog, wgu.IdCampEsp 
    from TmpSessionTimeGroup st
    Inner Join relationWg wgu ON st.User_id = wgu.User_id


    delete from [RepMKTIntervalos]  where date >= @from AND date <= @to
        
    
    
    ;with 
     relationCallIdCamId as(
        select distinct cal_id as callId,Inbound_id InboundId,User_id as userId from tmpTimesInboundData
    ),
    transferData as(
        select B.userId,B.InboundId
        ,CASE WHEN t.modo = 2 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fent
        ,CASE WHEN t.modo = 2 and t.tipo=1 then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as fsal
        ,CASE WHEN t.modo in (0,3,4) then dbo.AccountInterval(timegroup,timegroup_next,dateIni,dateEnd,1)  else 0 end as SalExt
        ,CASE WHEN t.modo in (0,3,4) then [dbo].TimeInterval( timegroup,timegroup_next,dateIni,dateEnd) else 0 end as tprosalext    
        ,dateIni as dateStart   
        ,dateEnd
        ,timegroup
        ,timegroup_next
        from TmpTimesccLogtransfers T
        inner join relationCallIdCamId B on t.callId=B.callId   
        where tipo=1
    ), transferDataGroup as(

    select userId, timegroup, InboundId 
    ,sum(fent) fent,sum(fsal) fsal, sum(salExt) salExt,sum(tprosalext) as tprosalext
    ,min(dateStart) as [dateTTransferStart]
    ,max(dateEnd) as [dateTTransferEnd]
    from transferData
    group by timegroup, InboundId,userId
    ), mktInterval as(

    select 
    i.timegroup
    ,i.inbound_Id as inboundId  
    ,i.User_id as userId
    ,sum(tresp) as tresp
    ,sum(case when statusCall_id =13 and ntotal>0 then 1 else 0 end) as nacd
    ,sum(case when statuscall_id <> 13 then tque+txfer+tring else 0 end) AS tAbnd
    ,sum(case when statusCall_id <>13 and ntotal>0 then 1 else 0 end) as nabnd  
    ,sum(case when statusCall_id=13 then tdialog else 0 end) as tacd
    ,sum(tnotes) as tacw
    ,sum(case when statusCall_id=13 and ntotal>0 and tnotes>0 then 1 else 0 end) as nacw 
    ,sum(case when statuscall_id = 13 then tque + txfer + tring else 0 end) as maxdem
    ,sum(case when statuscall_id in (7,8) AND nque > 0 AND txfer=0 then 1 else 0 end) as ncalque
    ,sum(case when statusCall_id in (7,8) AND nque > 0 AND txfer=0 then tque else 0 end) as tcalque
    ,isnull(sum(t.fent),0) as fent
    ,isnull(sum(t.fsal),0) as fsal
    ,isnull(sum(t.SalExt),0) as SalExt
    ,isnull(sum(t.tprosalext),0) as tprosalext  
    ,isnull(sum(ntotal),0) as ntotal
    ,1 as countUserDistinct
    ,count(distinct case when statusCall_id =13 and ntotal>0 then  userId end ) countUserDistinctNacd
    from tmpTimesInboundData i
    left join transferDataGroup t on i.timegroup=t.timegroup and i.Inbound_id=t.InboundId and i.User_id=t.userId    
    group by i.timegroup,i.inbound_Id,i.User_id 
    )

    INSERT INTO [RepMKTIntervalos]
    select 
    isnull(A.timegroup,g.timegroup) as [date]
    ,isnull(A.inboundId,g.[inb_id]) as inboundId
    ,inb.descripcion as Acds
    ,case when A.nacd>0 then A.tresp/isnull(nullif(A.nacd,0), 1) else 0 end as [avrAnswer]
    ,case when A.nabnd>0 then A.tabnd/A.nabnd else 0 end as [AvgAbandonTime]
    ,isnull(A.nacd,0) [acdCalls]
    ,case when A.nacd>0 then A.tacd/A.nacd else 0 end as [tPromACD]
    ,case when A.nacw>0 then A.tacw/A.nacw else 0 end as [tPromACW]
    ,isnull(A.nabnd,0) as [abondeonedCalls]
    ,isnull(A.maxdem,0) as [maxDelay]
    ,isnull(A.fent,0) as  [entryFlow]   
    ,isnull(A.fsal,0) as  [outFLow]
    ,isnull(A.SalExt,0) as [calloutExt] 
    ,isnull(case when A.SalExt>0 then A.tprosalext/A.SalExt else 0 end,0) as [TPromSalidaExt]
    ,isnull(A.ncalque,0) as [callDeleteQue] 
    ,case when A.ncalque>0 then A.tcalque/A.ncalque else 0 end as [TpromElimCola]       
    ,case when round(case when countUserDistinct>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1)>0 
        then (case when convert(decimal(15,2),(((nacd) * case when (nacd)>0 then (tacd)/isnull(nullif((nacd),0), 1) else 0 end) / convert(float,((round(case when (countUserDistinct)>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1))*1800)))*100)>100 then 100 
               else convert(decimal(15,2),(((nacd) * case when (nacd)>0 then (tacd)/isnull(nullif((nacd),0), 1) else 0 end) / convert(float,((round(case when countUserDistinct>0 then ((convert(float,((tlog)*100))/isnull(nullif(convert(float,countUserDistinct*1800),0), 1))*countUserDistinct)/100 else 0 end,1))*1800)))*100) end)
        else 0 end avrTimeACD       
    ,isnull(convert(decimal(10,2), case when nacd+nabnd>0 then convert(decimal(10,2), nacd*100.0/(nacd+nabnd)) else 0.00 end),0.00) avrCallsAnswer  
    ,isnull(convert(decimal(10,2), round( case when countUserDistinct is not null then (tlog*100.0/1800)/100 else 0 end,1)),0.00) as PromPosicionPersonal   
    ,case when (nacd) >0 then (case when (nacd)/isnull(nullif(countUserDistinctNacd,0), 1) >0 then convert(int, (nacd)/isnull(nullif(countUserDistinctNacd,0), 1)) else 1 end) else 0 end as [LlamadasporPosicion]
    ,isnull(A.tresp,0) as tresp
    ,isnull(A.tabnd,0) as tabnd
    ,isnull(A.tacd,0) as tacd
    ,isnull(A.tacw,0) as tacw
    ,isnull(A.nacw,0) as nacw       
    ,isnull(A.tcalque,0) as tcalque         
    ,isnull(A.tprosalext,0) as tprosalext
    ,isnull(g.tlog,0) as tlog
    ,isnull(A.userId,g.user_id) accountUserId   
    ,DATEPART(YYYY, isnull(A.timegroup,g.timegroup)) as [year] 
    ,DATEPART(mm, isnull(A.timegroup,g.timegroup)) as [month]
    ,DATEPART(dd, isnull(A.timegroup,g.timegroup)) as [day]
    ,DATEPART(hh, isnull(A.timegroup,g.timegroup)) as [hour]
    ,DATEPART(mi, isnull(A.timegroup,g.timegroup)) as [minutes]
    from mktInterval A
    full join #sessionTimeGroup g on A.timegroup=g.timegroup and A.inboundId=g.[inb_id] and A.userId=g.[user_id]
    Left join ccInboundView inb ON inb.Inbound_id = A.inboundId or inb.Inbound_id=g.inb_id
    where ntotal>0
    order by [date],inboundId,A.userId

    IF OBJECT_ID(''tempdb..#sessionTimeGroup'')  IS NOT NULL  drop table #sessionTimeGroup  
    
end
'
    EXEC(@sql)


 SET @process = 'ALTER PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS DATETIME, @to AS DATETIME'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS DATETIME, @to AS DATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL Begin
    DROP TABLE #tempccLogAgentesDia2
End

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''tmpccLogAgentesDia'')
BEGIN
    CREATE TABLE tmpccLogAgentesDia (
        id INT NOT NULL 
        ,userId INT NOT NULL
        ,TipoStatusAge_id TINYINT NOT NULL
        ,tStatus FLOAT NOT NULL
        ,dateIni DATETIME NOT NULL
        ,dateEnd DATETIME NOT NULL
        ,currentStatus INT NOT NULL
        ,timeGroup DATETIME NOT NULL
        ,timeGroupNext DATETIME NOT NULL
        ,camId SMALLINT
        ,camType SMALLINT
        ,callId INT,
        primary key (id,userId)
        );

        CREATE NONCLUSTERED INDEX [IX_tmpccLogAgentesDia_TipoStatusAge_id]
        ON [dbo].[tmpccLogAgentesDia] ([TipoStatusAge_id])
        INCLUDE ([tStatus],[timeGroupNext])
END
ELSE
BEGIN
    TRUNCATE TABLE tmpccLogAgentesDia       
END

CREATE TABLE #tempccLogAgentesDia2 (
    rowId INT NOT NULL
    ,userId INT NOT NULL
    ,TipoStatusAge_id TINYINT NOT NULL
    ,tStatus FLOAT NOT NULL
    ,dateIni DATETIME NOT NULL
    ,dateEnd DATETIME NOT NULL
    ,currentStatus INT
    ,timeGroup DATETIME NOT NULL
    ,timeGroupNext DATETIME NOT NULL
    ,camId SMALLINT
    ,camType SMALLINT
    ,callId INT
    );

WITH tmpLog
AS (
    SELECT User_id AS userId
        ,TipoStatusAge_id
        ,tStatus
        ,DATEADD(ms, - tStatus*1000, fecha) dateIni
        ,fecha dateEnd
        ,ISNULL(currentStatus, 0) AS currentStatus
        ,dbo.GetTimeGroup(DATEADD(ms, - tStatus*1000, fecha), 0) AS timegroup
        ,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
        ,IdCampEsp AS camId
        ,Tipo AS camType
        ,callId
    FROM ccLogAgentesDia
    WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to   
    )
, cteLogAgentesDia as (

SELECT ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
    ,userId
    ,TipoStatusAge_id
    ,tStatus
    ,dateIni
    ,dateEnd
    ,currentStatus
    ,timegroup
    ,timegroup_next
    ,camId
    ,camType
    ,callId
FROM tmpLog
)
insert into tmpccLogAgentesDia
select * from cteLogAgentesDia


/***** Elimina los repetidos ******/
; with regDeleteRepLogout as(
SELECT 
    case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId  
    FROM tmpccLogAgentesDia A
    LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
        AND A.userId = S.userId
    WHERE A.dateIni >= @from
        AND A.dateIni < @to
        AND A.tStatus >0 and S.tStatus >0
        AND A.TipoStatusAge_id = S.TipoStatusAge_id
        AND A.TipoStatusAge_id>0        
        AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 1             
),
rowReconnectLogout as(
select ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId,* 
from tmpccLogAgentesDia where currentStatus in(30,-2) and tStatus>0
)
,
regDeleteReconnect as( 
 select 
case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId
--,A.userId,S.userId,A.RowId,S.RowId,A.timeGroup,S.timeGroupNext,A.id,S.id,A.TipoStatusAge_id,S.TipoStatusAge_id,A.tStatus,S.tStatus
--,A.dateIni,A.dateEnd,S.dateIni,S.dateEnd
--,ABS(A.tStatus-S.tStatus)
from rowReconnectLogout A
inner join rowReconnectLogout S on A.userId=S.userId and A.RowId=S.RowId-1 
and A.TipoStatusAge_id=S.TipoStatusAge_id 
where ( A.dateIni between S.dateIni and S.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
 )
 , rowDelete as(
 select * from regDeleteRepLogout
 union 
 select * from regDeleteReconnect
 )

--SELECT A.*
Delete A
from tmpccLogAgentesDia A
inner join rowDelete X  ON A.id = x.rowId AND A.userId = x.userId;

    
/***** Revisa si es el dia actual para calcular el tiempo del estado ******/
declare @today date,@dateNow datetime
SET @today = convert(DATE, GETDATE(), 121)
SET @dateNow=GETDATE()


IF @today = CONVERT(DATE, @to, 121)
BEGIN
    ;   
    WITH tmpAgentLastStatus
    AS (
        SELECT userId ,MAX(dateEnd) AS dateStart
        FROM tmpccLogAgentesDia
        WHERE dateEnd BETWEEN @today AND @to
        GROUP BY userId
        )           

    INSERT INTO tmpccLogAgentesDia
    SELECT 0
        ,A.userId
        ,A.currentStatus
        ,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
        ,B.dateStart
        ,@dateNow
        ,A.currentStatus
        ,dbo.GetTimeGroup(B.dateStart, 0) AS timegroup
        ,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
        ,A.camId
        ,A.camType
        ,A.callId
    FROM tmpccLogAgentesDia A
    INNER JOIN tmpAgentLastStatus B ON A.dateEnd = B.dateStart AND A.userId = B.userId
    WHERE A.dateIni BETWEEN @today AND @to
        AND A.currentStatus NOT IN (- 2, - 1, 0);
END


/***** Separa los estados para tenerlos en intervalos 15 minutos para algunos reportes ******/
INSERT INTO #tempccLogAgentesDia2
SELECT * FROM tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15


DELETE tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;



INSERT INTO tmpccLogAgentesDia
SELECT-1* ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
    ,t.userId
    ,TipoStatusAge_id
    ,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
    ,dateIni
    ,dateEnd
    ,currentStatus
    ,th.start AS timegroup
    ,th.stop AS timegroup_next
    ,t.camId
    ,t.camType
    ,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
        t.timegroup > th.Start
        AND t.timegroup < th.stop
        )
    OR th.Start BETWEEN t.timegroup
        AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
    AND th.Start BETWEEN @from
        AND @to
order by dateIni,timegroup


IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
    DROP TABLE #tempccLogAgentesDia2'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspTimesInboundData] @from AS DATETIME, @to AS DATETIME'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspTimesInboundData]
@from AS DATETIME, @to AS DATETIME
AS

SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
    DROP TABLE #inboundData2

IF NOT EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesInboundData''
        )
BEGIN
    CREATE TABLE tmpTimesInboundData (
        [row] INT, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, time_endque 
        DATETIME, dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_in VARCHAR(40), 
        cal_id INT, dni_id INT, Inbound_id INT, [User_id] INT, ntotal INT, ninitial INT, nout_hour INT, nout_service INT, nabnd INT, 
        nno_agent INT, nque INT, ntimeout INT, noverflow INT, nxfer INT, nxfer_que INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, 
        nabnd_dialog INT, nanswer INT, nlost INT, nmsg INT, nabnd_tres INT, nansw_tres INT, tque_max INT, tque INT, txfer INT, tdialog INT, 
        tnotes INT, tring INT, tresp INT, nMoh INT, nWHag INT, nWHcl INT, statusCall_id INT, [dateTResp] DATETIME, [dateTACD] DATETIME, 
        calif_id INT, cal_tMoh INT, cal_puerto INT
        );
END
ELSE
BEGIN
    TRUNCATE TABLE tmpTimesInboundData  
END

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT MAX(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 0
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT

SELECT @HourExtend = 2

DECLARE @fromExtended AS SMALLDATETIME

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn


DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH inboundData
AS (
    SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
    , CASE WHEN cal_Xfer IS NULL OR cal_Xfer = ''1900-01-01 00:00:00'' THEN cal_inicio ELSE cal_Xfer END AS dateStartDetail 
    ,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas 
    ,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
    ,cal_tMoh, cal_whoHung, calif_id, cal_puerto
    FROM ccCallsIn
    WHERE cal_inicio between @fromExtended AND @to AND INBOUND_ID > 0   
    )
    ,callInStart as(
    select distinct userId,min(dateIni) dateIni,callId,camType
    from tmpccLogAgentesDia 
    where callId>0 and  camType=0 and TipoStatusAge_id in(5,9,4,6)
    group by userId,callId,camType
    ) 
    ,callDataStartXfer as(
    select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) dateIni from callInStart A
    inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni
    where B.tStatus>0
    group by A.userId,B.callId,B.camType,B.camId
    ),inboundDataWithXferAgent  as(
    select rowId
    ,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas 
    ,dateStartDetail    
    ,DATEADD(ss, cal_tWait, A.dateStartDetail) as time_endque
    ,ISNULL(B.dateIni,A.dateStartDetail) as dateXferAgtStart
    ,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.dateStartDetail)) as dateEndDetail
    ,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
    ,cal_tMoh, cal_whoHung, calif_id, cal_puerto
    from inboundData A
    left join callDataStartXfer B on A.cal_id= B.callId and A.Inbound_id=B.camId and A.User_id=B.userId
    )   
    

    

    INSERT INTO tmpTimesInboundData
    select rowId, dateStartDetail,dateEndDetail
    , dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
    , dbo.GetTimeGroup(dateEndDetail, 1 ) AS timegroup_next
    , time_endque, dateXferAgtStart
    , DATEADD(ss, cal_txfer, dateXferAgtStart) AS time_ring
    , DATEADD(ss, cal_txfer + cal_tring, dateXferAgtStart) AS time_dialog
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS time_notes  
    , dateEndDetail AS time_end_call
    , cal_Ani AS phone_in, cal_id, dni_id, Inbound_id, [User_id], 1 AS ntotal
    , CASE WHEN statuscall_id = 1 THEN 1 ELSE 0 END AS ninitial
    , CASE WHEN statuscall_id = 2 THEN 1 ELSE 0 END AS nout_hour
    , CASE WHEN statuscall_id = 3 THEN 1 ELSE 0 END AS nout_service
    , CASE WHEN statuscall_id IN (5, 6) AND cal_que > 0 AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd
    , CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
    , CASE WHEN cal_que > 0 THEN 1 ELSE 0 END AS  nque
    , CASE WHEN statuscall_id = 7 THEN 1 ELSE 0 END AS ntimeout
    , CASE WHEN statuscall_id = 8 THEN 1 ELSE 0 END AS noverflow
    , CASE WHEN statuscall_id IN (11, 15, 13, 16)OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'' ) THEN 1 ELSE 0 END AS nxfer
    , CASE WHEN cal_que > 0 AND ( statuscall_id IN (11, 15, 13, 16) OR ( statuscall_id = 6  AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE 0 END AS nxfer_que
    , CASE WHEN statuscall_id = 11 OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd_xfer
    , CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing    THEN 1 ELSE 0 END AS nabnd_ring
    , CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing  THEN 1 ELSE 0 END AS nno_answer
    , CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog  THEN 1 ELSE 0 END AS nabnd_dialog
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog   THEN 1 ELSE 0 END AS nanswer
    , CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
    , CASE WHEN statuscall_id IN (9, 10, 12, 14)  THEN 1 ELSE 0 END AS nmsg
    , CASE WHEN ( ( statuscall_id IN (5, 6) AND cal_que > 0 AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'')    )
                    AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE 0 END AS nabnd_tres
    , CASE WHEN ((statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn) ) THEN 1 ELSE 0 END AS nansw_tres    
    , cal_twait AS tque_max, cal_twait AS tque, cal_txfer AS txfer, cal_tdialog AS tdialog
    , cal_tnotas AS tnotes, cal_tring AS tring
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_twait + cal_txfer + cal_tring ELSE 0 END AS tresp
    , CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
    , CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
    , CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
    , statusCall_id
    , dateadd(ss, cal_txfer + cal_tring, dateXferAgtStart) AS [dateTResp]
    , dateadd(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS [dateTACD]
    , calif_id, cal_tMoh, cal_puerto
    from inboundDataWithXferAgent

/******************* Revisa si los datos son del dia ******************************/

declare @today date
set @today =convert(date,@dateNow,121)

IF @today = CONVERT(DATE, @to, 121)
BEGIN
        ;

    WITH lastAgentStatus
    AS (
        SELECT userId, max(dateIni) dateIn
        FROM tmpccLogAgentesDia
        WHERE dateIni BETWEEN @today AND @to
        GROUP BY userId
        ), timeAcumlate
    AS (
        SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
                    ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
            dateEnd, max(A.timeGroupNext) AS timeGroupNext
        FROM tmpccLogAgentesDia A
        INNER JOIN lastAgentStatus B ON A.userId = B.userId
            AND A.dateIni = B.dateIn
        WHERE A.dateIni BETWEEN @today AND @to
            AND currentStatus IN (4, 5, 6, 9)
            AND A.camType = 0
        GROUP BY A.userId, A.camId, A.callId
        )
    UPDATE A
    SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
                tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
                    dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END, A.
        User_id = CASE WHEN A.User_id > 0 THEN B.userId ELSE A.User_id END
    FROM tmpTimesInboundData A
    INNER JOIN timeAcumlate B ON A.Inbound_id = B.camId
        AND A.cal_id = B.callId
END

SELECT *
INTO #inboundData2
FROM tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

DELETE tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

INSERT INTO tmpTimesInboundData
SELECT [row], dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, time_endque
,dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_in, cal_id, dni_id, Inbound_id, [User_id] 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ninitial ELSE 0 END AS ninitial 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_hour ELSE 0 END AS nout_hour 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_service ELSE 0 END AS nout_service 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd ELSE 0 END AS nabnd 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nque ELSE 0 END AS nque 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntimeout ELSE 0 END AS ntimeout 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN noverflow ELSE 0 END AS noverflow 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer ELSE 0 END AS nxfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer_que ELSE 0 END AS nxfer_que 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nanswer ELSE 0 END AS nanswer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nlost ELSE 0 END AS nlost 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nmsg ELSE 0 END AS nmsg 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_tres ELSE 0 END AS nabnd_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nansw_tres ELSE 0 END AS nansw_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN tque_max ELSE 0 END AS tque_max
, dbo.TimeInterval(th.start, th.stop, dateStartDetail,  time_endque) AS tque
, dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
, dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
, dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
, dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
, dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nMoh ELSE 0 END AS nMoh 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHag ELSE 0 END AS nWHag 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl, statusCall_id, [dateTResp], [dateTACD] 
, CASE WHEN th.start >  dateStartDetail AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id, dbo.AccountInterval(th.start, th.stop, dateStartDetail
        , dateEndDetail, cal_tMoh) AS cal_tMoh, cal_puerto
FROM #inboundData2 t
INNER JOIN TmpTimesInterval th ON (
        t.timegroup > th.Start
        AND t.timegroup < th.stop
        )
    OR th.Start BETWEEN t.timegroup AND t.timegroup_next
WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
    AND th.Start BETWEEN @from AND @to
ORDER BY [row], th.start


IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
    DROP TABLE #inboundData2'
    EXEC(@sql)

    set @process = 'ALTER PROCEDURE [dbo].[ccspTimesOutboundData] @from AS DATETIME, @to AS DATETIME'
    set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesOutboundData] 
@from AS DATETIME, @to AS DATETIME
AS
SET NOCOUNT ON


IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
    DROP TABLE #outboundData2

IF NOT EXISTS (
        SELECT *
        FROM sys.tables
        WHERE name = ''tmpTimesOutboundData''
        )
BEGIN
    CREATE TABLE tmpTimesOutboundData (
        row INT identity, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, cam_id INT, 
        User_id INT, ntotal INT, nno_agent INT, nxfer INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, nabnd_dialog INT, nanswer INT, 
        nlost INT, tque INT, txfer INT, tring INT, tdialog INT, tnotes INT, tresp INT, nhangup INT, nMoh INT, nWHag INT, nWHcl INT, 
        time_endque DATETIME,dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_out 
        VARCHAR(30), cal_id INT, cal_puerto INT, idwg INT, statuscall_id INT, calif_id INT, cal_manual INT, cal_tMoh INT
        )
END
ELSE
BEGIN
    TRUNCATE TABLE tmpTimesOutboundData
END

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT max(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 1
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT
DECLARE @fromExtended AS SMALLDATETIME
DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

SELECT @HourExtend = 2

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH outboundData AS (
SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
, cal_inicio AS dateStartDetail 
,cal_id,cam_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas 
,cal_telefono, User_id, statuscall_id, cal_que
,cal_tMoh, cal_whoHung, calif_id, cal_puerto
FROM ccoCallsOut
WHERE cal_inicio between @fromExtended AND @to AND cam_id > 0   
)
,callOutStart as(
select userId,MIN(dateIni) dateIni,callId,camType,camId
from tmpccLogAgentesDia 
where callId>0 and camType=1 and TipoStatusAge_id in(5,9,4,6)
group by userId,callId,camType,camId
)
, callDataStartXfer as(
select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) as dateIni from callOutStart A
inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni 
where B.tStatus>0
group by A.userId,B.callId,B.camType,B.camId
)
,outData  as(
    select 
    
    cal_Inicio AS dateStartDetail   
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS dateEndDetail
    ,cam_id,[User_id], 1 AS ntotal
    ,CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
    ,CASE WHEN statuscall_id >= 10 THEN 1 ELSE 0 END AS nxfer
    ,CASE WHEN statuscall_id = 11 THEN 1 ELSE 0 END AS nabnd_xfer
    , CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing THEN 1 ELSE 0 END AS nabnd_ring
    , CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing THEN 1 ELSE 0 END AS nno_answer
    , CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog THEN 1 ELSE 0 END AS nabnd_dialog
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN 1 ELSE 0 END AS nanswer
    , CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
    , cal_twait AS tque, cal_txfer AS txfer, cal_tring AS tring, cal_tdialog AS tdialog, cal_tnotas AS tnotes
    , CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_txfer + cal_tring ELSE 0 END AS tresp
    , CASE WHEN statuscall_id = 6 THEN 1 ELSE 0 END AS nhangup
    , CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
    , CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
    , CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
    , DATEADD(ss, cal_twait, cal_inicio) AS time_endque
    , ISNULL(B.dateIni,A.cal_Inicio) as dateXferAgtStart
    , DATEADD(ss, cal_txfer, ISNULL(B.dateIni,A.cal_Inicio)) AS time_ring
    , DATEADD(ss, cal_txfer + cal_tring, ISNULL(B.dateIni,A.cal_Inicio)) AS time_dialog
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, ISNULL(B.dateIni,A.cal_Inicio)) AS time_notes
    , DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS time_end_call
    , cal_telefono AS phone_out, cal_id, cal_puerto, C.idwg AS idwg
    , A.statuscall_id, A.calif_id, A.cal_manual, A.cal_tMoh
    from ccoCallsOut A
    left join callDataStartXfer B on A.cal_id= B.callId and A.cam_id=B.camId
    LEFT JOIN @relastionCampWg C ON A.cam_id = C.camId
    WHERE A.cal_Inicio between @fromExtended AND @to
)

    

INSERT INTO tmpTimesOutboundData (
    dateStartDetail, dateEndDetail, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, nno_answer, nabnd_dialog, 
    nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque,dateXferAgtStart, time_ring, time_dialog, 
    time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id, cal_manual, cal_tMoh, timegroup, 
    timegroup_next
    )
SELECT A.*, dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup, dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
FROM outData A




declare @today date
set @today =convert(date,@dateNow,121)


/******************* Revisa si los datos son del dia ******************************/

IF @today = CONVERT(DATE, @to, 121)
BEGIN
        ;

    WITH lastAgentStatus
    AS (
        SELECT userId, max(dateIni) dateIn
        FROM tmpccLogAgentesDia
        WHERE dateIni BETWEEN @today AND @to
        GROUP BY userId
        ), timeAcumlate
    AS (
        SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
                    ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
            dateEnd, max(A.timeGroupNext) AS timeGroupNext
        FROM tmpccLogAgentesDia A
        INNER JOIN lastAgentStatus B ON A.userId = B.userId
            AND A.dateIni = B.dateIn
        WHERE A.dateIni BETWEEN @today   AND @to
            AND currentStatus IN (4, 5, 6, 9)
            AND A.camType = 1
        GROUP BY A.userId, A.camId, A.callId
        )
    UPDATE A
    SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
                tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
                    dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
    FROM tmpTimesOutboundData A
    INNER JOIN timeAcumlate B ON A.User_id = B.userId
        AND A.cam_id = B.camId
        AND A.cal_id = B.callId
END

SELECT *
INTO #outboundData2
FROM tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO tmpTimesOutboundData (
    dateStartDetail, dateEndDetail, timegroup, timegroup_next, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, 
    nno_answer, nabnd_dialog, nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque, 
    dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id,  
    cal_manual, cal_tMoh
    )
SELECT dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, cam_id, [User_id]
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_agent ELSE 0 END AS nno_agent
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nxfer ELSE 0 END AS nxfer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_xfer ELSE 0 END AS nabnd_xfer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_ring ELSE 0 END AS nabnd_ring
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_answer ELSE 0 END AS nno_answer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_dialog ELSE 0 END AS nabnd_dialog
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nanswer ELSE 0 END AS nanswer
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nlost ELSE 0 END AS nlost
    , dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
    , dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
    , dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
    , dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
    , dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
    , dbo.TimeInterval(th.start, th.stop, dateStartDetail
    , dateadd(ss, tresp, dateStartDetail)) AS tresp
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nhangup ELSE 0 END AS nhangup
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nMoh ELSE 0 END AS nMoh
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHag ELSE 0 END AS nWHag
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHcl ELSE 0 END AS nWHcl
    , time_endque, dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call 
    , phone_out, cal_id, cal_puerto, idwg, statuscall_id
    , CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  calif_id ELSE - 2 END AS calif_id
    , cal_manual
    , dbo.AccountInterval(th.start, th.stop, dateStartDetail, dateEndDetail, cal_tMoh) AS cal_tMoh
    FROM #outboundData2 t
    INNER JOIN TmpTimesInterval th ON  ( t.timegroup > th.Start AND t.timegroup < th.stop)  OR th.Start BETWEEN t.timegroup AND t.timegroup_next
    WHERE datediff(ss, th.start, timegroup_next) > 0
    

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
    DROP TABLE #outboundData2
'
    EXEC(@sql)
    


    SET @process = 'ALTER PROCEDURE [dbo].[ccspTmpSessionTimeGroup] @from as datetime, @to as datetime'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspTmpSessionTimeGroup]
@from as datetime, @to as datetime 
AS
set nocount on

if @from is null begin
    select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
    select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+'':00'')
end

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

CREATE TABLE #sessionTimeGroup( [user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)


if not exists( select * from sys.tables where name=''tmpSessionTimeGroup'') begin
    CREATE TABLE tmpSessionTimeGroup([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
end
else begin
    truncate table tmpSessionTimeGroup  
    --drop table tmpSessionGeneral
end


INSERT INTO #sessionTimeGroup
select * from tmpSessionGeneral

INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
    select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
    dbo.TimeInterval(th.start,th.stop,login,logout) as [tlog seg]    

from #sessionTimeMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;

delete from #sessionTimeGroup where tlog=0 and DATEPART(MS,logout)<=700
    
update  #sessionTimeGroup set tlog=1 where tlog=0 and DATEPART(MS,logout)>700


insert into tmpSessionTimeGroup
select user_id,min([login]) as [login],max([logout]) as [logout],min(extension) as extension,timegroup,timegroup_next,sum(tlog) as tlog from #sessionTimeGroup  
group by user_id,timegroup,timegroup_next   
    

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

set nocount off'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[ccspTmpTimesInterval] set @from =dateadd(mi,-15,@from )'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspTmpTimesInterval]
@from as smalldatetime,
@to as smalldatetime,
@interval as int
AS
set nocount on

if @from is null begin
    select @from = convert(datetime,convert(varchar(11),getdate()))
end
else begin
    set @from =dateadd(mi,-15,@from )
end

if @to is null begin
    select @to = dateadd(mi,2, convert(varchar(15),getdate(),121)+'':00'')
end

if not exists( select * from sys.tables where name=''TmpTimesInterval'') begin
    CREATE TABLE TmpTimesInterval([ID] INT primary key,[Start] DATETIME,[Stop] DATETIME)

    create nonclustered index ix_times on TmpTimesInterval([Start] DESC,[Stop] DESC)
    create nonclustered index ix_times2 on TmpTimesInterval([Start] DESC)

end
else begin
    truncate table TmpTimesInterval
--  drop table TmpTimesInterval
end

insert into TmpTimesInterval
exec ccspTimesReports @from=@from,@to=@to,@interval=@interval

set nocount off'
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



    --------------------------------------------------------END 127.20250325.0.0 Jesus Gallardo----------------------------------------------------------------------

    -------------------------------------------  BEGIN Ricardo Nunez LRSV  ----------------------------------------
    set @process = 'DELETE FROM ccWhatsOringCountry'
        set @sql='IF EXISTS (
            SELECT 1
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = ''ccWhatsOringCountry''
            AND COLUMN_NAME = ''CountryAbbreviation''
        )
        AND EXISTS (
            SELECT 1 FROM CCReportsRIA.dbo.ccWhatsOringCountry
        )
        BEGIN
            DELETE FROM CCReportsRIA.dbo.ccWhatsOringCountry;
        END'
        EXEC(@sql)


    set @process = 'INSERT VALUES TO COUNTRYABBREVIATION'
        set @sql='IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccWhatsOringCountry'' AND COLUMN_NAME = ''CountryAbbreviation'')
        BEGIN
            INSERT INTO CCReportsRIA.dbo.ccWhatsOringCountry
            SELECT * FROM CCenterRIA.dbo.ccWhatsOringCountry;
        END'
        EXEC(@sql)



    set @process = 'Facturación - Validación sp ccsp_GalateaWhastappBilling'
    set @sql='
    if exists (select * from sys.procedures where name = N''ccsp_GalateaWhastappBilling'')
    begin
        DROP PROCEDURE ccsp_GalateaWhastappBilling
    end'
    EXEC(@sql)

    SET @process = 'Facturación - Creación sp ccsp_GalateaWhastappBilling'
    SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaWhastappBilling] 
    @action SMALLINT,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @CompanyName VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ip VARCHAR(16) = ''''
    DECLARE @ipSettings VARCHAR(50) = ''''

    SELECT @ipSettings = valor FROM ccSettings WHERE setting_id = 31
    SELECT @ip = value FROM dbo.fn_RIASplitDelimited(@ipSettings, ''|'') WHERE Id = 2

    IF @DateFrom IS NULL AND @DateTo IS NULL
    BEGIN
        SET @DateFrom = DATEADD(DAY, -1, CAST(GETDATE() AS DATETIME));
        SET @DateTo = DATEADD(SECOND, -1, DATEADD(DAY, 0, CAST(GETDATE() AS DATETIME)));
    END
    ELSE
    BEGIN
        SET @DateFrom = ISNULL(CONVERT(DATETIME, CONVERT(VARCHAR(10), @DateFrom, 120) + '' 00:00:00''), ''1900-01-01 00:00:00'');
        SET @DateTo = ISNULL(CONVERT(DATETIME, CONVERT(VARCHAR(10), @DateTo, 120) + '' 23:59:59''), ''9999-12-31 23:59:59'');
    END

    -- Crear tabla temporal completa
    IF OBJECT_ID(''tempdb..#Temp_Facturacion'') IS NOT NULL DROP TABLE #Temp_Facturacion;

    CREATE TABLE #Temp_Facturacion (
        Account VARCHAR(MAX),
        IPAddress VARCHAR(16),
        Service VARCHAR(50),
        Billed VARCHAR(10),
        Type VARCHAR(20),
        OriginCountry VARCHAR(10),
        OriginCountryCode VARCHAR(10),
        OriginNumber VARCHAR(50),
        TargetCountry VARCHAR(10),
        TargetCountryCode VARCHAR(10),
        TargetNumber VARCHAR(50),
        ConversationDate VARCHAR(30),
        ConversationTime VARCHAR(20),
        CReserved01 VARCHAR(100),
        CReserved02 VARCHAR(100),
        CReserved03 VARCHAR(100),
        CReserved04 VARCHAR(100),
        CReserved05 VARCHAR(100),
        CReserved06 VARCHAR(100),
        CReserved07 VARCHAR(100),
        BillingIDWhatsApp VARCHAR(100),
        TemplateCategory VARCHAR(100),
        TemplateName VARCHAR(200),
        PaymentCodeWA VARCHAR(50),
        WAReserved01 VARCHAR(100),
        WAReserved02 VARCHAR(100),
        WAReserved03 VARCHAR(100),
        WAReserved04 VARCHAR(100),
        WAReserved05 VARCHAR(100),
        WAReserved06 VARCHAR(100),
        ConversationIDSMS VARCHAR(100),
        NumberType VARCHAR(50),
        MessageCharacters VARCHAR(10),
        TargetCarrier VARCHAR(100),
        SMSReserved01 VARCHAR(100),
        SMSReserved02 VARCHAR(100),
        SMSReserved03 VARCHAR(100),
        SMSReserved04 VARCHAR(100),
        SMSReserved05 VARCHAR(100),
        SMSReserved06 VARCHAR(100),
        VirtualAgentID VARCHAR(100),
        ConversationID VARCHAR(100),
        Channel VARCHAR(50),
        ConversationDuration VARCHAR(20),
        Seconds VARCHAR(10),
        Minutes VARCHAR(10),
        VAReserved01 VARCHAR(100),
        VAReserved02 VARCHAR(100),
        VAReserved03 VARCHAR(100),
        VAReserved04 VARCHAR(100),
        CallID VARCHAR(100),
        Detection VARCHAR(100),
        DurationSeconds VARCHAR(10),
        DurationMinutes VARCHAR(10),
        VMReserved01 VARCHAR(100),
        VMReserved02 VARCHAR(100),
        VMReserved03 VARCHAR(100),
        VMReserved04 VARCHAR(100),
        VMReserved05 VARCHAR(100),
        VMReserved06 VARCHAR(100)
    );
    IF @action = 0
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            BillingIDWhatsApp, TemplateCategory, TemplateName, PaymentCodeWA,
            WAReserved01, WAReserved02, WAReserved03, WAReserved04, WAReserved05, WAReserved06,
            ConversationIDSMS, NumberType, MessageCharacters, TargetCarrier,
            SMSReserved01, SMSReserved02, SMSReserved03, SMSReserved04, SMSReserved05, SMSReserved06,
            VirtualAgentID, ConversationID, Channel, ConversationDuration, Seconds, Minutes,
            VAReserved01, VAReserved02, VAReserved03, VAReserved04,
            CallID, Detection, DurationSeconds, DurationMinutes,
            VMReserved01, VMReserved02, VMReserved03, VMReserved04, VMReserved05, VMReserved06
        )
        SELECT 
            @CompanyName, ISNULL(@ip, ''''), ''WhatsApp'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            ISNULL(GlobalId, NULL),
            ISNULL(wa.Category, ''''),
            ISNULL(mt.TemplateName, ''''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''Wa In'' ELSE ''Wa Out'' END,
            '''', '''', '''', '''', '''', '''',
            '''', '''', '''', '''',
            '''', '''', '''', '''', '''', '''',
            '''', '''', '''', '''', '''', '''',
            '''', '''', '''', '''',
            '''', '''', '''', '''', '''', '''',
            '''', '''', '''', ''''

        FROM ccWhatsAppGlobalIds wa
        LEFT JOIN ccoWhatsLogDials a ON a.ConversationId = wa.FirstMessageConversationIdFromAgent
        LEFT JOIN ccMetaWAOutboundTemplates mt ON mt.Id = a.TemplateId
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;

        SELECT * FROM #Temp_Facturacion ORDER BY ConversationDate;
    END

    -- Acción 1: WhatsApp
    IF @action = 1
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            BillingIDWhatsApp, TemplateCategory, TemplateName, PaymentCodeWA,
            WAReserved01, WAReserved02, WAReserved03, WAReserved04, WAReserved05, WAReserved06
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''WhatsApp'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            ISNULL(GlobalId, NULL),
            ISNULL(wa.Category, ''''),
            ISNULL(mt.TemplateName, ''''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''Wa In'' ELSE ''Wa Out'' END,
            '''', '''', '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        LEFT JOIN ccoWhatsLogDials a ON a.ConversationId = wa.FirstMessageConversationIdFromAgent
        LEFT JOIN ccMetaWAOutboundTemplates mt ON mt.Id = a.TemplateId
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    -- Acción 2: SMS
    IF @action = 2
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            ConversationIDSMS, NumberType, MessageCharacters, TargetCarrier
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''SMS'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    -- Acción 3: VA
    IF @action = 3
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            VirtualAgentID, ConversationID, Channel,
            ConversationDuration, Seconds, Minutes
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''Virtual Agent'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            '''', '''', '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    -- Acción 4: VM
    IF @action = 4
    BEGIN
        INSERT INTO #Temp_Facturacion (
            Account, IPAddress, Service, Billed, Type,
            OriginCountry, OriginCountryCode, OriginNumber,
            TargetCountry, TargetCountryCode, TargetNumber,
            ConversationDate, ConversationTime,
            CReserved01, CReserved02, CReserved03, CReserved04, CReserved05, CReserved06, CReserved07,
            CallID, Detection, DurationSeconds, DurationMinutes
        )
        SELECT 
            @CompanyName,
            ISNULL(@ip, ''''),
            ''VMR'',
            ISNULL(CAST(IsBilled AS VARCHAR), ''0''),
            CASE WHEN FirstMessageConversationTypeFromAgent = 0 THEN ''inbound'' ELSE ''outbound'' END,
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(AssociatedNumber, 0), ''''),
            ISNULL(AssociatedNumber, ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 1), ''''),
            ISNULL(dbo.GetCountryDetailWhatsApp(ClientNumber, 0), ''''),
            ISNULL(ClientNumber, ''''),
            CAST(CAST(FirstMessageDateFromAgent AS DATE) AS VARCHAR(MAX)),
            FORMAT(FirstMessageDateFromAgent, ''HH:mm:ss''),
            '''', '''', '''', '''', '''', '''', '''',
            '''', '''', '''', ''''
        FROM ccWhatsAppGlobalIds wa
        WHERE FirstMessageDateFromAgent BETWEEN @DateFrom AND @DateTo;
    END

    ---------------------------
    -- Mostrar columnas por acción
    ---------------------------
    IF @action = 1
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               BillingIDWhatsApp, TemplateCategory, TemplateName, PaymentCodeWA,
               WAReserved01, WAReserved02, WAReserved03, WAReserved04, WAReserved05, WAReserved06
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END
    ELSE IF @action = 2
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               ConversationIDSMS, NumberType, MessageCharacters, TargetCarrier,
               SMSReserved01, SMSReserved02, SMSReserved03, SMSReserved04, SMSReserved05, SMSReserved06
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END
    ELSE IF @action = 3
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               VirtualAgentID, ConversationID, Channel,
               ConversationDuration, Seconds, Minutes,
               VAReserved01, VAReserved02, VAReserved03, VAReserved04
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END
    ELSE IF @action = 4
    BEGIN
        SELECT Account, IPAddress, Service, Billed, Type,
               OriginCountry, OriginCountryCode, OriginNumber,
               TargetCountry, TargetCountryCode, TargetNumber,
               ConversationDate, ConversationTime,
               CReserved01, CReserved02, CReserved03, CReserved04,
               CReserved05, CReserved06, CReserved07,
               CallID, Detection, DurationSeconds, DurationMinutes,
               VMReserved01, VMReserved02, VMReserved03, VMReserved04, VMReserved05, VMReserved06
        FROM #Temp_Facturacion
        ORDER BY ConversationDate;
    END

    DROP TABLE #Temp_Facturacion;
END;
'
    EXEC(@sql)
    
    -------------------------------------------  END Ricardo Nunez LRSV  ----------------------------------------



    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
