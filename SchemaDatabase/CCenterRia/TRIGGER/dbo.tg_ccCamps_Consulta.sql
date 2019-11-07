CREATE TRIGGER [dbo].[tg_ccCamps_Consulta] ON [dbo].[ccCamps]
after delete
as begin
set nocount on
insert into ccCamps_Consulta (cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, 
cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, 
cam_inter_ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, 
cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql ,cam_tnotas, 
cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, 
cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, 
cam_fCreate, cam_MaxDlrXage, ani, IDArea, EditableCallKey, iTipoDial, detectAnswerMachine, 
detectVoiceMail, compliance, surveyCamId)
select cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, 
cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, 
cam_inter_ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, 
cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql ,cam_tnotas, 
cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, 
cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, 
cam_fCreate, cam_MaxDlrXage, ani, IDArea, EditableCallKey, iTipoDial, detectAnswerMachine, 
detectVoiceMail, compliance, surveyCamId
from deleted
set nocount off
end