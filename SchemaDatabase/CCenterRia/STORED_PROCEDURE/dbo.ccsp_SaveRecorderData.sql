CREATE PROCEDURE ccsp_SaveRecorderData
@TipoCall tinyint,	-- 1= IN,  2=Out
@cal_id int,
@grabID int,
@fecha datetime,
@duracion int 
AS
	if @TipoCall = 1
		update ccCallsIn set rec_grabId = @grabID, rec_fechaInicio =@fecha, rec_duracion = @duracion where cal_id = @cal_id

	if @TipoCall = 2
		update ccoCallsOut set rec_grabId = @grabID, rec_fechaInicio =@fecha, rec_duracion = @duracion where cal_id = @cal_id