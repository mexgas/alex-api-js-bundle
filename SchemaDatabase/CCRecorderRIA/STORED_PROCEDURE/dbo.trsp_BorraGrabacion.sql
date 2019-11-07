CREATE PROCEDURE [dbo].[trsp_BorraGrabacion]
@grab_id INT,
@usr_id INT
AS

Update trec_grabacion Set borra_id = 1 Where  grab_id = @grab_id

Insert trec_borrado ( grab_id, age_id, fecha ) values ( @grab_id, @usr_id, getdate() )