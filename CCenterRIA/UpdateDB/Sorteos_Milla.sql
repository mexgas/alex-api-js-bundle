/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCenterRia
Required version: 125.33

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 34
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF 1=1--@version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN Jesus Gallardo hotfix/125.20230719.0.9---------------------------------------------------------

SET @process = 'Sorteos  Alter SP ccsp_DLRGetDialInfo '
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0
AS
set nocount on
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)
declare @recordHold bit

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''''
	select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
	select @prefix = valor from ccsettings nolock where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
,@PrefixRec=ISNULL(prefijo,'''')
from ccCamps C (nolock) where C.cam_id=@cam_id

if @surveycamid > 0
	select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max)
set @prefixCalKey=''''
select @mainPrefix = valor from ccSettings where setting_id=202
declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix	varchar(30) null
,cal_Key	varchar(40)
,cal_telefono	varchar(30),cal_telefono2	varchar(30),cal_telefono3	varchar(30),cal_telefono4	varchar(30),cal_telefono5	varchar(30)
,Dato1	varchar(255),Dato2	varchar(255),Dato3	varchar(255),Dato4	varchar(255),Dato5	varchar(255)
,recyclePhone	smallint,recycleType bit
)
select callout_id,dialPrefix,cal_Key,
cal_telefono,cal_telefono2,cal_telefono3,cal_telefono4,cal_telefono5,
Dato1,Dato2,Dato3,Dato4,Dato5,
recyclePhone,recycleType
FROM ccoCallsOutSource NOLOCK WHERE callout_id=@callout_id 


SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
    @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
FROM @tmpccoCallsOutSource

if @iPortNumber >= 0 
begin
    declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

    insert @Anis
    exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
    , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
	, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
	, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
	, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
	, CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
	, isnull(@message_name, '''') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when anis.p1 <> '''' then anis.p1 else @ani end ani
    , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
    , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
    , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
    , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '''') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
    , isnull(@MohFiles,'''') as mohFiles
    ,@ivr_script ivrScript
    ,@sipheader data
    ,@PrefixRec as Prefijo,
    dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
    dbo.GetCarrierByTel(cal_telefono2) carrier2, 
    dbo.GetCarrierByTel(cal_telefono3) carrier3, 
    dbo.GetCarrierByTel(cal_telefono4) carrier4, 
    dbo.GetCarrierByTel(cal_telefono5) carrier5,
	@recordHold as recordHold
    FROM @tmpccoCallsOutSource C
    left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
    left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
    left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
    WHERE C.callout_id = @callout_id
    return
end 
set nocount off'
EXEC(@sql)

SET @process = 'Sorteos Alter Sp ccsp_DLRGetRotativeANI'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]
@callout_id int,
@phones varchar(max),
@aniList int,
@algo tinyint
AS
set nocount on
DECLARE @Tels table (id int, pid varchar(2), phone varchar(32), ani varchar(32))
if @aniList<=0 begin
	SELECT * FROM @Tels
	return(0)
end

DECLARE @aniIdx varchar(500), @aniCnt smallint, @aniCurList int, @usedAniCnt int, @phoneCnt int, @ani varchar(32), @idx varchar(8)
DECLARE @id_phone INT, @phone varchar(32), @usedAni varchar(30)

SELECT @aniCnt = count(*) FROM ccRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList          
SELECT @aniCurList=isnull(id_RAniList,0),@aniIdx=isnull(ani_idx,'''') FROM ccoWorkingTable NOLOCK WHERE callout_id = @callout_id

IF @aniList != @aniCurList SET @aniIdx = ''''

IF isnull(@aniCnt,0) > 0
BEGIN
    INSERT @Tels 
    SELECT id,''p''+cast(id as varchar(1)),value,'''' FROM fn_RIASplitDelimited(@phones, '';'') WHERE len(value)>0

    IF OBJECT_ID(''tempdb..#UsedAniList'') IS NOT NULL DROP TABLE #UsedAniList;
    SELECT * INTO #UsedAniList FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0
    SELECT @usedAniCnt=count(*) FROM #UsedAniList

    IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
    SELECT @usedAni = telAni FROM RowRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList AND RowNum=(SELECT TOP 1 value from #UsedAniList)

    DECLARE CUR_TEST CURSOR FAST_FORWARD FOR SELECT Id, phone FROM @Tels ORDER BY Id;
    OPEN CUR_TEST FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone

    WHILE @@FETCH_STATUS = 0
    BEGIN
            
        IF @usedAniCnt >= @aniCnt SET @aniIdx = ''''

        IF @algo = 0
        BEGIN
            SELECT @ani = dbo.TelAni(@phone,@aniList)
        END
        ELSE IF @algo = 1
        BEGIN
            SELECT TOP 1 @ani=telAni, @idx=idx FROM fnGetRotativeANI(@aniList, @aniIdx, default, default)
        END
        ELSE IF @algo = 2 or @algo = 3
        BEGIN
            DECLARE @cld varchar(3), @serie varchar(4), @cldCnt smallint
            IF len(@phone) < 10
            BEGIN
                FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
                CONTINUE
            END
            IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@usedAni, 2))
                    SELECT @serie = substring(@usedAni, 3, 4)
                ELSE
                    SELECT @serie = substring(@usedAni, 4, 3)
            END
            IF @algo = 2 or (@algo = 3 and @usedAniCnt < 2)
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@phone, 2))
                    SET @cld = left(@phone, 2)
                ELSE
                    SET @cld = left(@phone, 3)
            END
            SELECT @cldCnt = count(*) 
            FROM ccRotativeAniListDetail NOLOCK 
            WHERE id_RAniList = @aniList 
                AND (((@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) and left(telAni, len(@cld))=@cld) or (@algo = 3 and @usedAniCnt >= 2))
                AND (@algo = 2 OR @usedAni is null OR left(telAni, 6) != left(@usedAni, 6) OR @usedAniCnt >= 2)
            IF @cldCnt > 0 and @usedAniCnt >= @cldCnt and @algo = 2 SET @aniIdx = ''''
            SELECT TOP 1 @ani=telAni, @idx=idx 
            FROM fnGetRotativeANI(@aniList, @aniIdx
                , case when @cldCnt > 0 and (@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) then @cld else '''' end
                , case when @algo = 2 then '''' when @usedAniCnt = 1 and @serie is not null then @serie else '''' end)
        END

        SELECT @aniIdx = @aniIdx+'',''+@idx, @usedAniCnt = @usedAniCnt+1, @usedAni = @ani

        UPDATE @Tels SET ani=@ani WHERE id=@id_phone

        FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
    END
    CLOSE CUR_TEST
    DEALLOCATE CUR_TEST

    UPDATE ccoWorkingTable SET id_RAniList=@aniList, ani_idx=isnull(@aniIdx,'''') WHERE callout_id=@callout_id
END

SELECT * FROM @Tels

set nocount off'
EXEC(@sql)

SET @process = 'Sorteos ALTER sp ccsp_RIAADMgetAbandonoSalida_Fix'
SET @sql = 'ALTER procedure [dbo].[ccsp_RIAADMgetAbandonoSalida_Fix]
as
set nocount on
declare @to smalldatetime, @from smalldatetime
declare @interval int
declare @i int
declare @row int

declare @tempChart table(
cam_id	int,
countAbnd int,
countAll int,
timestamp	smalldatetime
)

set @interval=10
set @to = convert(datetime, convert(varchar(13), getdate(), 121)+'':00:00'',121)

set @to = dateadd(mi,10,@to)
set @from = dateadd( mi, -@interval*30, @to)

set @row=DATEDIFF(mi,@from,@to)
select @row=ABS( CEILING(1.0*@row/@interval))


;WITH Numbers AS
(
    SELECT TOP (@row) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
    FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
)
, times as(
	SELECT  ROW_NUMBER() OVER (ORDER BY n) as [ID], DATEADD(MINUTE,@interval* (n-1), @from) as [Start], DATEADD(MINUTE,@interval* (n), @from) as [Stop]
	FROM Numbers
), tempChart as(
	select cam_id,case statuscall_id when 6 then 1 end  as countAbnd
	,convert(datetime, 	convert(varchar(15), cal_inicio, 121)+''0:00'',121) as timeSpam		
	from ccoCallsOut
	with( index(IX_ccoCallsOut_2),nolock )
	where cal_manual in (0,2 ) and cal_inicio between @from and @to
),timeCamps as(
	select c.cam_id,t.Start as timeSpam from times t
	cross join ccCamps c
	where c.IDArea is not null
),tempChartGroup as(
	select cam_id,count(countAbnd) as countAbnd,
	COUNT(*) as countAll,timeSpam
	from tempChart
	group by cam_id,timeSpam
)

insert into @tempChart
select tCamp.cam_id,isnull(countAbnd,0) as countAbnd,isnull(countAll,0) countAll
,tCamp.timeSpam from timeCamps tCamp
left join tempChartGroup chart on tCamp.cam_id=chart.cam_id and tCamp.timeSpam=chart.timeSpam

truncate table ccAbandonoSalida_Chart

insert into ccAbandonoSalida_Chart
select cam_id,
CONVERT(decimal(10,2),
case when countAll=0 then 0 else countAbnd*100.00/countAll end
),[timestamp]
  from @tempChart order by cam_id 

truncate table ccAbandonoSalida  
  
 insert into ccAbandonoSalida
 select cam_id,
 CONVERT(decimal(10,2),
 case when sum(countAll) =0 then 0 else 
 SUM(countAbnd*100.0)/sum(countAll) end 
 ) as AbndPctg 

 from @tempChart
 group by cam_id
 
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
	---------------------------------------End Jesus Gallardo hotfix/125.20230719.0.9-----------------------------------------------------------





		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
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
