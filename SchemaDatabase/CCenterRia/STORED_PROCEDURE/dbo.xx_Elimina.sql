CREATE procedure [dbo].[xx_Elimina] 
@cal_key varchar(20),
@cam_id integer
as
delete ccoWorkingTable where cal_keyw = @cal_key and cam_id =@cam_id and cal_status in (0,1)