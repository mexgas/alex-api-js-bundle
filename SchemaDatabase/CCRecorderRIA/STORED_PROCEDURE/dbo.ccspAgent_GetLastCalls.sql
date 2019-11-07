CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls]

@User_id int

AS
BEGIN

	SET NOCOUNT ON;

	
	Select primera.id_formato, convert(nvarchar(20),segunda.finicio,120), tercera.cam_descripcion, convert(nvarchar(20),primera.fecha_calif,120), 
primera.total_forma, segunda.tipo_llamada, primera.id_grabacion, cuarta.login from

RIA_FormaCalif primera 

inner join 

RIA_Grabacion segunda on primera.age_id = @User_id and segunda.grab_id = primera.id_grabacion 

inner join 

ccCamps tercera on segunda.cam_id = tercera.cam_id

inner join

ccUsers cuarta on primera.id_calificador = cuarta.user_id

	
END