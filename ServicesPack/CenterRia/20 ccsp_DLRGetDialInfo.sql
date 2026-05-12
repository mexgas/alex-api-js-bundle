USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_DLRGetDialInfo]    Script Date: 01/04/2026 10:58:04 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0,
@trunkId int=0
AS
set nocount on
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15), @trunk varchar(200)
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
declare @recordHold bit, @recordIvr bit
declare @croute varchar(32)

set @prefix =''
set @tNoContesta = 25
set @ani=''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings with(nolock) where setting_id = 104
select @PrefixRec=ISNULL(prefijo,'') from ccCamps nolock where cam_id = @cam_id

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix, @trunk=isnull(trunk,'') from cstoProvedor with(nolock) where provedor_id = (
	select provedor_id from ccodialers with(nolock) where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''
	select @prefix = dialPrefix from ccCamps with(nolock) where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
	select @prefix = valor from ccsettings with(nolock) where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
,@PrefixRec=ISNULL(prefijo,''), @recordIvr=ISNULL(recordIvr,0)
from ccCamps C with(nolock) where C.cam_id=@cam_id

if @surveycamid > 0
	select @ivr_script = isnull(ivrscript,0) from cccamps with(nolock) where cam_id = @surveycamid
		
--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + ',', '') + V.msgfile
FROM ccCampsMsgs VE with(nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max), @apikeyQuantum VARCHAR(300);
set @prefixCalKey=''
select @mainPrefix = valor from ccSettings where setting_id=202
select @apikeyQuantum = ISNULL(valor, '') from dbo.ccSettings2 where setting_id=284
declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix   varchar(30) null
,cal_Key    varchar(40)
,cal_telefono   varchar(30),cal_telefono2   varchar(30),cal_telefono3   varchar(30),cal_telefono4   varchar(30),cal_telefono5   varchar(30)
,Dato1  varchar(255),Dato2  varchar(255),Dato3  varchar(255),Dato4  varchar(255),Dato5  varchar(255)
,recyclePhone   SMALLINT
,recycleType BIT
,data_api_quantum VARCHAR(MAX)
)
insert into @tmpccoCallsOutSource
SELECT 
    c.callout_id,
    c.dialPrefix,
    c.cal_Key,
    c.cal_telefono, c.cal_telefono2, c.cal_telefono3, c.cal_telefono4, c.cal_telefono5,
    c.Dato1, c.Dato2, c.Dato3, c.Dato4, c.Dato5,
    c.recyclePhone, c.recycleType,
    (
        CASE 
            WHEN RIGHT(RTRIM(ISNULL(c.data_api_quantum, N'{}')), 1) = N'}'
                THEN LEFT(RTRIM(ISNULL(c.data_api_quantum, N'{}')), LEN(RTRIM(ISNULL(c.data_api_quantum, N'{}'))) - 1)
            ELSE RTRIM(ISNULL(c.data_api_quantum, N'{}'))
        END
        +
        CASE 
            WHEN LEN(
                    LTRIM(RTRIM(
                        CASE 
                            WHEN LEFT(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N'{}'))),1) = N'{' 
                            AND RIGHT(RTRIM(ISNULL(c.data_api_quantum, N'{}')),1) = N'}'
                            THEN SUBSTRING(
                                    LTRIM(RTRIM(ISNULL(c.data_api_quantum, N'{}'))),
                                    2,
                                    LEN(LTRIM(RTRIM(ISNULL(c.data_api_quantum, N'{}')))) - 2
                                )
                            ELSE LTRIM(RTRIM(ISNULL(c.data_api_quantum, N'{}')))
                        END
                    ))
                ) > 0 
            THEN N',' ELSE N'' 
        END
        +
        N'"country": ' + CONVERT(NVARCHAR(20),@pais)
        +
        N', "time_zone": ' + CONVERT(NVARCHAR(20),
                            CASE
                                WHEN c.iZonaHoraria  > 0 THEN c.iZonaHoraria
                                WHEN c.iZonaHoraria2 > 0 THEN c.iZonaHoraria2
                                WHEN c.iZonaHoraria3 > 0 THEN c.iZonaHoraria3
                                WHEN c.iZonaHoraria4 > 0 THEN c.iZonaHoraria4
                                WHEN c.iZonaHoraria5 > 0 THEN c.iZonaHoraria5
                                ELSE 0
                            END
                        )
        +
        N'}'
    ) AS data_api_quantum
FROM ccoCallsOutSource AS c WITH (NOLOCK)
WHERE c.callout_id = @callout_id;

SELECT @prefixCalKey=CASE WHEN @mainPrefix='1' THEN isnull(dialPrefix,'') ELSE '' END,
    @phones=cal_telefono+';'+cal_telefono2+';'+cal_telefono3+';'+cal_telefono4+';'+cal_telefono5
FROM @tmpccoCallsOutSource

if @iPortNumber >= 0 
begin
    declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

    insert @Anis
    exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    if len(@sipheader)>32 and left(@sipheader,1)='@'
		select @croute=substring(@sipheader, 2, 32)
            
    SELECT c.callout_id, 'cal_key'=c.cal_key+'~'+rtrim(dato1)+'~'+rtrim(dato2)+'~'+rtrim(dato3)+'~'+rtrim(dato4)+'~'+rtrim(dato5)
    , ISNULL(cpt.Prioridad,'12345NNN') dial_tels
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '' ELSE C.cal_telefono  END cal_telefono
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '' ELSE c.cal_telefono2 END cal_telefono2
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '' ELSE c.cal_telefono3 END cal_telefono3
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '' ELSE c.cal_telefono4 END cal_telefono4
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '' Else c.cal_telefono5 END cal_telefono5
    , isnull(@message_name, '') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when anis.p1 <> '' then anis.p1 else @ani end ani
    , case when anis.p2 <> '' then anis.p2 else @ani end ani2
    , case when anis.p3 <> '' then anis.p3 else @ani end ani3
    , case when anis.p4 <> '' then anis.p4 else @ani end ani4
    , case when anis.p5 <> '' then anis.p5 else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '') as messageDNCLConfirm_name
    , isnull(@MohFiles,'') as mohFiles
    ,@ivr_script ivrScript
    ,@sipheader data
    ,@PrefixRec as Prefijo,
    dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
    dbo.GetCarrierByTel(cal_telefono2) carrier2, 
    dbo.GetCarrierByTel(cal_telefono3) carrier3, 
    dbo.GetCarrierByTel(cal_telefono4) carrier4, 
    dbo.GetCarrierByTel(cal_telefono5) carrier5,
    @recordHold as recordHold,
    @recordIvr as recordIvr,
    isnull(C.data_api_quantum, '') AS data_api_quantum,
    @apikeyQuantum AS key_api_quantum,
    dbo.GetRoute(C.cal_telefono,isnull(@croute,''),@trunkId) destination,
	@trunk trunk
    FROM @tmpccoCallsOutSource C
	left join ccoCallPriorityOrder cpo with(nolock) on cpo.callout_id = c.callout_id
    left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
    left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
    WHERE C.callout_id = @callout_id
	OPTION (RECOMPILE);
    return
end 
set nocount off
	 