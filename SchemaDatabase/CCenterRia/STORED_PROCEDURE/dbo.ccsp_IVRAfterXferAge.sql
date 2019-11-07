CREATE PROCEDURE [dbo].[ccsp_IVRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on
-- 2005-11-15 por ODC
-- colocar como asignada despues de transferir
Update ccCallsIn SET user_id=@User_id, cal_extension=@cal_extension,-- cal_tWait=@tWait,
cal_xfer=getdate(), statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 0

return(0)
set nocount off