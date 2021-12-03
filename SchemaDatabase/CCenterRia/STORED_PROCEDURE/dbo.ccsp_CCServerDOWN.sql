CREATE PROCEDURE [dbo].[ccsp_CCServerDOWN]
@Flag as varchar(1)
AS
-- 0 = Fuera de Servicio
-- 1= En Servicio
Update ccSettings Set valor=@Flag Where setting_id=4

update ccCallsIn set statusCall_id =6 where statusCall_id = 5 
and cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))