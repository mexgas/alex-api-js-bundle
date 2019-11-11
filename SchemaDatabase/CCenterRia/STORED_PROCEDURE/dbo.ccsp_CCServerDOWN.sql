CREATE PROCEDURE ccsp_CCServerDOWN
@Flag as varchar(1)
AS
-- 0 = Fuera de Servicio
-- 1= En Servicio
Update ccSettings Set valor=@Flag
Where setting_id=4