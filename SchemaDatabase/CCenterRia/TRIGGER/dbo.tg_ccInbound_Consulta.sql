CREATE TRIGGER dbo.tg_ccInbound_Consulta ON dbo.ccInbound 
after delete
as begin
set nocount on
insert into ccInbound_Consulta (cli_id, Inbound_id, descripcion, Status, dnis, standby, tNotas, tMaxWaitCall, nMaxQue, 
 Msg_id, tel_maxwait, tel_maxqueue, tel_outservice, tel_noct, bnocturno, ShowCalifWnd, 
 StartTimerOnHangUp, voicePath, IDArea, editableCallKey, cam_id)
select cli_id, Inbound_id, descripcion, Status, dnis, standby, tNotas, tMaxWaitCall, nMaxQue, 
 Msg_id, tel_maxwait, tel_maxqueue, tel_outservice, tel_noct, bnocturno, ShowCalifWnd, 
 StartTimerOnHangUp, voicePath, IDArea, editableCallKey, cam_id
from deleted
set nocount off
end