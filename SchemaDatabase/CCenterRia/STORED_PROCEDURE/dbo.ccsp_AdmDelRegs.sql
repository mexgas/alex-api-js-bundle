CREATE PROCEDURE ccsp_AdmDelRegs
@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
@cam_id int
AS
set nocount on
if @tipoDel = 1 --nuevos
 begin
	delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0
	return(0)
 end

if @tipoDel = 2 --callbacks
 begin
	delete ccoWorkingTable  where cam_id = @cam_id and cal_status = 1
	return(0)
 end

if @tipoDel = 3 -- 3 Registros sin meter a WT
 begin
	update ccocallsoutsource set cal_Status = 5 where cam_id = @cam_id and cal_status in(0, 7)
	Delete ccUploadTemporal where cam_id = @cam_id
	return(0)
 end

if @tipoDel = 4 --callbacks
 begin
	delete ccoWorkingTable  where cam_id = @cam_id and cal_status = 1 and user_id=0
	return(0)
 end

if @tipoDel = 5 --callbacks
 begin
	delete ccoWorkingTable  where cam_id = @cam_id and cal_status = 3
	return(0)
 end
set nocount off