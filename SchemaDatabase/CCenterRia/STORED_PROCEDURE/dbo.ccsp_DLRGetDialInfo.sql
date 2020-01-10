CREATE procedure [dbo].[ccsp_DLRGetDialInfo]
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
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)

set @prefix =''
set @tNoContesta = 25
set @ani=''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104
select @PrefixRec=ISNULL(prefijo,'') from ccCamps where cam_id = @cam_id

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña
if @prefix =''
    select @prefix = dialPrefix from ccCamps where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campaña
select @sipHdrFormat=isnull(sipHdrFormat,''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0)
from ccCamps C (nolock) where C.cam_id=@cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + ',', '') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo    
set @prefixCalKey=''
if (select valor from ccSettings where setting_id=202)='1' begin
    select @prefixCalKey=isnull(dialPrefix,'') from ccoCallsOutSource with(nolock) where callout_id=@callout_id 
end

if @iPortNumber >= 0 
begin
	SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
	
    SELECT c.callout_id, 'cal_key'=c.cal_key+'~'+rtrim(dato1)+'~'+rtrim(dato2)+'~'+rtrim(dato3)+'~'+rtrim(dato4)+'~'+rtrim(dato5)
    , ISNULL(cpt.Prioridad,'12345NNN') dial_tels
    , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when dbo.TelAni(c.cal_telefono,@lista_id) <> '' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani
    , case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2
    , case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3
    , case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4
    , case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5
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
	,@PrefixRec as Prefijo
    FROM ccoCallsOutSource C with(nolock)
	left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
	left join ccCampsPrioridadTel cpt on cpt.cam_id = c.cam_id
    WHERE C.callout_id = @callout_id
    return
end 

set nocount off