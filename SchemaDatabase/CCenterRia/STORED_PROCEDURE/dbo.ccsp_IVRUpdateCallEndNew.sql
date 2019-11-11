CREATE procEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
@cal_id int,
@cal_tIVRCallDuration smallint,
@statuscal_id tinyint, 
-- Aqui solo se Aceptan Edos Terminales 2(Fuera de Horario), 3(Fuera de Servicio), 4(NoAgentesFirmados), 7(TimeOut), 8(DesbordeQue),
@cal_opciones varchar(10),
@cal_colgada tinyint,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on

Update ccCallsIn SET statusCall_id = case when @statuscal_id in (2, 3, 4, 7, 8) then @statuscal_id else case when statusCall_id = 5 then 6 else statuscall_id end end, 
 user_id=@User_id, cal_extension=@cal_extension, cal_tWait=@tWait where cal_id=@cal_id

exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id

--Actualizar tiempo total de llamada
exec ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

set nocount off