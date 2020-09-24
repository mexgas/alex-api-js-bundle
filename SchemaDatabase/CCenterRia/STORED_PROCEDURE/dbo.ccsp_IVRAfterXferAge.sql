CREATE PROCEDURE [dbo].[ccsp_IVRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on
-- 2005-11-15 por ODC
-- colocar como asignada despues de transferir
Update ccCallsIn SET user_id= case when user_id=0 and @User_id>0 then @User_id else user_id end, cal_extension= case when cal_extension=0 and @cal_extension>0 then @cal_extension else cal_extension end,-- cal_tWait=@tWait,
cal_xfer=getdate(), statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 0

return(0)
set nocount off