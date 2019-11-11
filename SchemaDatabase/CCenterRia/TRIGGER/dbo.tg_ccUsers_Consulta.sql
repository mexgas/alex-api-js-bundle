CREATE TRIGGER [dbo].[tg_ccUsers_Consulta] ON [dbo].[ccUsers] 
after delete
NOT for Replication
as begin
set nocount on
insert into ccusers_Consulta (User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoStatusAge_id, Password, 
 TipoUser_id, Status, TipoLLamadas, Sexo, filter, CanChangeStatus, fCreate, DialMask, 
 XferMask, LastPasswordChange, IDArea, NotReadyRestricted, startStopRecording)
select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoStatusAge_id, Password, 
 TipoUser_id, Status, TipoLLamadas, Sexo, filter, CanChangeStatus, fCreate, DialMask, 
 XferMask, LastPasswordChange, IDArea, NotReadyRestricted, startStopRecording
from deleted
set nocount off
end