CREATE procedure [dbo].[ccsp_DLRSaveDialResult]
@callout_id int,
@cam_id smallint,
@tipoResDial_id tinyint,
@Telefono varchar(30),
@Puerto smallint,
@tDialing tinyint=0,
@tBusy smallint=0,
@call_id int = 0,
@answerbit bit = null,
@tAnswerBit smallint = 0,
@canceledNoAgents bit =0,
@disconnectCause varchar(250) = '',
@cal_key varchar(20) = '',
@call_TS varchar(15) = ''
AS
set nocount on
declare @tNow as datetime, @RecicleSIC tinyint
declare @logDial_id int, @preview smallint
declare @tAnswerBitFinal as datetime
		
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
select @tNow=getdate()
		
select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)
		
if @call_id > 0 and @tipoResDial_id = 1
BEGIN
    INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id)
    select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, '00000000', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(@Telefono)
END
ELSE
BEGIN
    INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id)
    select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, '00000000', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(@Telefono)
END
		
select @logDial_id=scope_identity()
		
if (@RecicleSIC=1) begin
    UPDATE ccoWorkingTable with(rowlock) SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
end
		
select @logDial_id
		
-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
if @call_id > 0 and @tipoResDial_id = 1
begin
    select @preview = case when progdial=2 then 1 else 0 end from cccamps nolock where cam_id=@cam_id
    if @preview = 1
    begin
	   update ccoCallsOut with(rowlock) set cal_puerto = @Puerto where cal_id = @call_id and cal_puerto = 0
    end
    else
    begin
	   update ccoCallsOut with(rowlock) set cal_manual = 2, cal_puerto = @Puerto where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
    end
    exec ccsp_CstoCalculaCosto @call_id
		
    if @cal_key ='' begin
	   select @cal_key=cal_key from ccoCallsOutSource with(nolock) where @callout_id=callout_id
	   update ccologdials with(rowlock) set cal_key=@cal_key where logDial_id=@logDial_id
    end
		
end
		
-- inserta informacion para reportes de workgroup
insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
select IDWG, @logDial_id, IdCampEsp, getdate() 
from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id
		
-- Guarda configuracion de TipoDialingMode
update ccoLogDials with(rowlock) set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
set nocount off