CREATE PROCEDURE [dbo].[ccsp_DLRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7)
--@tWait smallint=0 --no se usa
AS
set nocount on
if @cal_id=0
 return(0)
		
Update ccoCallsOut SET user_id=@User_id, cal_extension=@cal_extension, statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 1

-- calcula el costo de la llamada
exec ccsp_CstoCalculaCosto @cal_id
return(0)
set nocount off