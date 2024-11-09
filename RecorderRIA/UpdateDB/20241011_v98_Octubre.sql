set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 97
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	------------------------------Begin Jesus Landus
	-------------------------------------------- Begin Jesus Gallardo hotfix/125.20231211.0.18 -------------------------------------------------------------------------------

    SET @process = 'feature/KR179003 CREATE TABLE [dbo].[RIA_GRABACION_TEMP]'
    SET @sql = 'if not exists(select * from sys.tables where name=''RIA_GRABACION_TEMP'') begin
    CREATE TABLE [dbo].[RIA_GRABACION_TEMP](
    [AvrTransferId] int,
    [tipo_llamada] [smallint] NULL,
    [cal_id] [int] NULL,
    [age_id] [int] NULL,
    [cam_id] [smallint] NULL,
    [calif_id] [smallint] NULL,
    [cal_extension] [int] NULL,
    [finicio] [datetime] NOT NULL,
    [ffin] [datetime] NOT NULL,
    [ani] [varchar](30) NOT NULL,
    [duracion] [int] NULL,
    [cal_key] [varchar](40) NOT NULL,
    [puerto_id] [int] NULL,
    [dni_id] [smallint] NULL,
    [id_repositorio] [tinyint] NULL,
    [razon_id] [tinyint] NULL,
    [tipo_grab_id] [tinyint] NULL,
    [fvalida] [datetime] NULL,
    [cal_whoHung] [smallint] NULL,
    [califSub_id] [smallint] NOT NULL,
    [cal_tMoh] [smallint] NOT NULL,
    [cal_manual] [tinyint] NULL,
    [id_nivel_grito] [int] NULL,
    [Prefijo] [varchar](512) NULL,
    [dni] [varchar](15) NULL,
    [IDWG] [varchar](800) NULL,
    [extra_info] [varchar](50) NULL,
    [extra_info2] [varchar](50) NULL    
    )

    
end
'
    EXEC(@sql)

    SET @process = 'feature/KR179003 CREATE INDEX IX_RIA_GRABACION_TEMP_I'
    SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = ''IX_RIA_GRABACION_TEMP_I'')
BEGIN
    -- Crea el índice utilizando las columnas tipo_llamada y cal_id
    CREATE INDEX IX_RIA_GRABACION_TEMP_I
    ON [dbo].[RIA_GRABACION_TEMP] ([tipo_llamada], [cal_id]);
END'
    EXEC(@sql)


    
    SET @process = 'feature/KR179003 Drop procedure ccsp_InsertOrUpdateRecordingRIA_Grabacion'
    SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_InsertOrUpdateRecordingRIA_Grabacion'')
                begin
                    DROP PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion;
                end'
    EXEC(@sql);


    SET @process = 'feature/KR179003 Create SP ccsp_InsertOrUpdateRecordingRIA_Grabacion'
    SET @sql = 'CREATE PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion
AS
BEGIN
    -- Declaramos una tabla temporal para almacenar grab_id, cal_id, tipo_llamada y AvrTransferId de los registros procesados
    DECLARE @ProcessedRecords TABLE (       
        grab_id BIGINT,
        cal_id INT,
        tipo_llamada INT,
        AvrTransferId int
    );

    -- Utilizamos MERGE para insertar o actualizar registros en la tabla ria_grabacion
    
    MERGE INTO ria_grabacion AS Target
    USING RIA_GRABACION_TEMP AS Source
    ON Target.cal_id = Source.cal_id AND Target.tipo_llamada = Source.tipo_llamada
    WHEN MATCHED THEN 
        UPDATE SET
            Target.calif_id = Source.calif_id,
            Target.califSub_id = Source.califSub_id,
            Target.cal_tMoh = Source.cal_tMoh,
            Target.duracion = Source.duracion,
            Target.cal_extension = Source.cal_extension,
            Target.IDWG = Source.IDWG,
            Target.extra_info = Source.extra_info,
            Target.extra_info2 = Source.extra_info2
        --OUTPUT ''UPDATE'' AS ActionType, inserted.grab_id, inserted.cal_id, inserted.tipo_llamada INTO @ProcessedRecords
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (tipo_llamada, cal_id, age_id, cam_id, calif_id, cal_extension, finicio, ffin, ani, duracion, cal_key, puerto_id, dni_id, id_repositorio, razon_id, tipo_grab_id,
                fvalida, cal_whohung, califSub_id, cal_tMoh, cal_manual, id_nivel_grito, prefijo, dni, IDWG, extra_info, extra_info2)
        VALUES (Source.tipo_llamada, Source.cal_id, Source.age_id, Source.cam_id, Source.calif_id, Source.cal_extension, Source.finicio, Source.ffin, Source.ani, Source.duracion, 
                Source.cal_key, Source.puerto_id, Source.dni_id, Source.id_repositorio, Source.razon_id, Source.tipo_grab_id, Source.fvalida, Source.cal_whohung, Source.califSub_id, 
                Source.cal_tMoh, Source.cal_manual, Source.id_nivel_grito, Source.prefijo, Source.dni, Source.IDWG, Source.extra_info, Source.extra_info2)
       
       OUTPUT inserted.grab_id, inserted.cal_id, inserted.tipo_llamada 
       INTO @ProcessedRecords(grab_id,cal_id,tipo_llamada)
        ;
    -- Ahora añadimos el AvrTransferId a @ProcessedRecords uniendo con RIA_GRABACION_TEMP
    UPDATE PR
    SET PR.AvrTransferId = S.AvrTransferId
    FROM @ProcessedRecords PR
    INNER JOIN RIA_GRABACION_TEMP S ON PR.cal_id = S.cal_id AND PR.tipo_llamada = S.tipo_llamada;

    -- Regresamos grab_id, cal_id, tipo_llamada y AvrTransferId para los registros insertados o actualizados
    SELECT grab_id, cal_id, tipo_llamada, AvrTransferId FROM @ProcessedRecords;

    -- Limpiar la tabla temporal
    TRUNCATE TABLE RIA_GRABACION_TEMP;
END;
'
    EXEC(@sql)

    SET @process = 'Drop procedure trsp_InsertRecNodeGrabIds'
    SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_InsertRecNodeGrabIds'')
    begin
        DROP PROCEDURE trsp_InsertRecNodeGrabIds;
    end'
    EXEC(@sql)


    SET @process = 'feature/KR179003 Alter SP trsp_InsertRecNode'
    SET @sql = 'CREATE PROCEDURE [dbo].[trsp_InsertRecNodeGrabIds]
@grabIds varchar(8000),
@rateEvaluationFormatKolob int = -1
AS
BEGIN
    declare @grabIdTmp table(grabId bigint primary key)
    declare @tEvaluationTmp table(grabId bigint primary key,total float)    
    DECLARE @XMLTable TABLE (grab_id INT, dateIn datetime, [node] xml, [status] bit);
    
    DECLARE @RecNodeTable TABLE (
    Date datetime,
    CDATE VARCHAR(23),  -----> Date Generic
    CID int,            -----> CamId
    CType int,          -----> Tipo de llamada
    C01 bigint,         -----> grab_id
    C02 VARCHAR(50),    -----> Type of Recording (Inbound/Outbound)
    C03 VARCHAR(250),   -----> Camp/ACD descripcion
    C04 INT,            -----> ShoutLevel
    C05 VARCHAR(250),   -----> Agent Login
    C06 VARCHAR(50),    -----> Formated date
    C07 VARCHAR(50),    -----> Position Computer
    C08 VARCHAR(50),    -----> Duration
    C09 VARCHAR(50),    -----> Ani
    C10 VARCHAR(50),    -----> Dnis
    C11 VARCHAR(100),   -----> Calkey
    C12 VARCHAR(50),    -----> Manual
    C13 INT,            -----> User ID
    C14 int,            -----> cal ID
    C15 INT,            -----> Cam /ACD ID
    C16 VARCHAR(12),    -----> Duration Reco@rding as 00:00:00
    C17 INT,            -----> Position Extension
    C18 VARCHAR(50),    -----> rating(Scoring Template)
    C19 INT,            -----> Reposiory ID
    C20 VARCHAR(250),   -----> Disposition
    C21 INT,            -----> Disposition ID
    C22 TINYINT,        -----> Has Video
    C23 VARCHAR(300),   -----> Agent Full Name
    C24 VARCHAR(300),   -----> Supervisor Name
    C25 VARCHAR(250),   -----> Score Template
    C26 INT,            -----> graphic_id
    C27 VARCHAR(250),   -----> Prefix recording
    C28 VARCHAR(250),   -----> subDisposition
    C29 BIT,            -----> LLamada Grabada --@extraInfo 1 Record, 0 Dont Record
    C30 BIT             ------> LLamada VoiceMail @extraInfo 2
);
insert into @grabIdTmp
select value from  dbo.fn_RIASplitDelimited(@grabIds,'','')


if @rateEvaluationFormatKolob = 0 begin
    ;with maxFechaCalif as(
    select max(fecha_calif) as fecha_calif,B.grabId from ria_formacalif A 
    inner join @grabIdTmp B on A.id_grabacion=B.grabId
    group by B.grabId
    ), ria_formacalifTop as(
    select A.grabId,B.total_forma from maxFechaCalif A
    inner join ria_formacalif B on A.grabId=B.id_grabacion and A.fecha_calif=B.fecha_calif
    )
    insert into @tEvaluationTmp
    select * from ria_formacalifTop
end
else if @rateEvaluationFormatKolob = 1 begin
    insert into @tEvaluationTmp
    SELECT A.grab_id,AVG(totalPoints) FROM RECORDERRIA_RECORDINGEVALUATION  A
    inner join @grabIdTmp T on A.grab_id=T.grabId
    WHERE deleted != 1 
    group by A.grab_id
end

;with GrabacionSource AS (
    SELECT rec.grab_id, rec.tipo_llamada, rec.Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, rec.video, 
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension
    FROM ria_grabacion rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId    
    UNION ALL
    SELECT rec.grab_id, rec.tipo_llamada, '''' AS Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, NULL AS video,
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension
    FROM RIA_GRABACIONCONSULTA rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId
)
INSERT INTO @RecNodeTable
SELECT 
rec.finicio,
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'',
rec.cam_id AS ''@CID'',
rec.tipo_llamada AS ''@CType'',
rec.grab_id AS ''@C01'',
CASE WHEN rec.tipo_llamada = 1 THEN ''Inbound'' ELSE ''Outbound'' END AS ''@C02'',
CASE WHEN rec.tipo_llamada = 1 THEN inb.descripcion ELSE outb.cam_descripcion END AS ''@C03'',
ISNULL(rec.id_nivel_grito, -1) AS ''@C04'',
ISNULL(usr.LOGIN, ''N/A'') AS ''@C05'',
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@C06'',
pos.Computer AS ''@C07'',
CONVERT(NVARCHAR(10), rec.duracion) AS ''@C08'',
rec.ani AS ''@C09'',
rec.dni AS ''@C10'',
rec.cal_key AS ''@C11'',
CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END AS ''@C12'',
ISNULL(usr.[User_id], 0) AS ''@C13'',
rec.cal_id AS ''@C14'',
rec.cam_id AS ''@C15'',
CONVERT(CHAR(8), DATEADD(SECOND, rec.duracion, 0), 108) AS ''@C16'',
ISNULL(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, -1) AS ''@C17'',
ISNULL(rec.total_forma, 0) AS ''@C18'',
rec.id_repositorio AS ''@C19'',
case when rec.calif_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then e.description  when rec.tipo_llamada = 2 then eOut.Description end  AS ''@C20'',
rec.calif_id AS ''@C21'',
rec.video AS ''@C22'',
ISNULL(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno, ''N/A'') AS ''@C23'',
'''' AS ''@C24'',
'''' AS ''@C25'',
isnull(grap.graphic_id,1) AS ''@C26'',
rec.Prefijo AS ''@C27'',    
case when  rec.califSub_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then subDisposition.califSubDesc  when rec.tipo_llamada = 2 then subDispositionOut.califSubDesc end  AS ''@C28'',    
CONVERT(BIT, ISNULL(rec.extra_info, ''1'')) AS ''@C29'',
CONVERT(BIT, ISNULL(rec.extra_info2, ''0'')) AS ''@C30''
FROM GrabacionSource rec
LEFT JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
LEFT JOIN cccamps outb ON rec.cam_id = outb.cam_id AND rec.tipo_llamada = 2
LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * -1
LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id AND rec.tipo_llamada = 1
LEFT JOIN ccTipoCalifOUT AS eOut ON rec.calif_id = eOut.calif_id AND rec.tipo_llamada = 2
LEFT JOIN cctipocalifsub AS subDisposition ON rec.califSub_id = subDisposition.califSub_id
LEFT JOIN cctipocalifsubout AS subDispositionOut ON rec.califSub_id = subDispositionOut.califSub_id AND rec.tipo_llamada = 2
LEFT JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id AND rec.tipo_llamada = 1
LEFT JOIN ccRIACampsGraph grapOut ON grapOut.cam_id = outb.cam_id AND rec.tipo_llamada = 2


insert into @XMLTable (grab_id,status, dateIn, node)       
SELECT  
    C01,0 [status],[date],
    case when C03 is null then null 
    when (C30=0 and C05 is not null and C20 is not null and C28 is not null) or  (C30=1) then   
    (
        SELECT 
            CDATE AS "@CDATE",
            CID As "@CID",
            CType As "@CType",
            C01 AS "@C01",
            C02 AS "@C02",
            C03 AS "@C03",
            C04 AS "@C04",
            C05 AS "@C05",
            C06 AS "@C06",
            C07 AS "@C07",
            C08 AS "@C08",
            C09 AS "@C09",
            C10 AS "@C10",
            C11 AS "@C11",
            C12 AS "@C12",
            C13 AS "@C13",
            C14 AS "@C14",
            C15 AS "@C15",
            C16 AS "@C16",
            C17 AS "@C17",
            C18 AS "@C18",
            C19 AS "@C19",
            C20 AS "@C20",
            C21 AS "@C21",
            C22 AS "@C22",
            C23 AS "@C23",
            C24 AS "@C24",
            C25 AS "@C25",
            C26 AS "@C26",
            C27 AS "@C27",
            C28 AS "@C28",
            C29 AS "@C29",
            C30 AS "@C30"
        FROM @RecNodeTable AS innerTable
        WHERE innerTable.C01 = outerTable.C01       
        FOR XML PATH(''R02''), TYPE
    ) 
    end AS node
FROM @RecNodeTable AS outerTable;


INSERT INTO ria_RecNode (grab_id, node, dateIn, [status]) 
select X.grab_id,X.[node],X.dateIn,-1 from @XMLTable X
left join ria_RecNode R on R.grab_id=X.grab_id
where X.node is null and R.grab_id is null

delete  from @XMLTable where node is null

update h set h.node=t.node,h.status=2
from RIA_RecNodeHistory h with(nolock)
inner join @XMLTable t on h.grab_id=t.grab_id and t.node is not null

update t set t.status=1
from RIA_RecNodeHistory h with(nolock)
inner join @XMLTable t on h.grab_id=t.grab_id and t.node is not null

if exists(select 1 from @XMLTable where status=0) begin
    update h set h.node=t.node,h.status=2
    from ria_RecNode h with(nolock)
    inner join @XMLTable t on h.grab_id=t.grab_id

    update t set t.status=1
    from ria_RecNode h with(nolock)
    inner join @XMLTable t on h.grab_id=t.grab_id
end
if exists(select 1 from @XMLTable where status=0) begin
    INSERT INTO ria_RecNode (grab_id, node, dateIn, [status]) 
    select grab_id,[node],dateIn,0 from @XMLTable where status=0    
end

END'
    EXEC(@sql)

    SET @process = 'feature/KR179003 Alter SP trsp_InsertRecNode'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_InsertRecNode]
@grabId INT, 
@type INT = 0, 
@rateEvaluationFormatKolob BIT = 0
AS
BEGIN
    declare @grabIds varchar(8000)
    set @grabIds=convert(varchar(20),@grabId)
   exec trsp_InsertRecNodeGrabIds @grabIds=@grabIds,@rateEvaluationFormatKolob=@rateEvaluationFormatKolob

END'
    EXEC(@sql)


    SET @process = 'feature/KR179003 Alter fn_RIASplitDelimited'
    SET @sql = 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
(   
    @List NVARCHAR(max),
    @SplitOn NVARCHAR(1)
)
RETURNS @RtnValue TABLE (
    Id INT IDENTITY(1,1),
    Value NVARCHAR(100)
)
AS
BEGIN
    DECLARE @Pos INT = 1
    DECLARE @NextPos INT
    DECLARE @Fragment NVARCHAR(100)

    IF LEN(@List) = 0  -- Verificar si la lista está vacía y salir
        RETURN

    WHILE @Pos > 0
    BEGIN
        SET @NextPos = CHARINDEX(@SplitOn, @List, @Pos)
        
        IF @NextPos > 0
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, @NextPos - @Pos)
            IF LEN(@Fragment) > 0  -- Solo insertar si el fragmento tiene longitud
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = @NextPos + 1
        END
        ELSE
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, LEN(@List) - @Pos + 1)
            IF LEN(@Fragment) > 0
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = 0
        END
    END

    RETURN
END
'
    EXEC(@sql)
   
	
	------------------------------End Jesus Landus
    update trec_parametros set par_valor = @Version where par_id = 30
    set @Version_Actual=@Version_Actual+1

    select par_valor from trec_parametros where par_id = 30

    commit tran

    end try
    begin catch
        select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
        RAISERROR(@errorGenerated, 11, 1)
    rollback tran
    end catch
 end
 else begin
    select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end