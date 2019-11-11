create procedure [dbo].[CountRecorderByCampId]
@cam_id int,
@tipoLLamada int

as
select count(*) from ria_grabacion where cam_id = @cam_id and tipo_llamada = @tipoLLamada and (HasBeenToRename = 0 OR HasBeenToRename IS NULL)