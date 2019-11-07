CREATE PROCEDURE ccsp_OUTStarStopCamp
@cam_id int,
@nStatusNEW tinyint
AS
declare @nStatusNOW tinyint
declare @nNewJobs int
declare @nCBJobs int
	IF  (@nStatusNEW <0 OR @nStatusNEW>1)
	BEGIN
		SELECT 0 --No se hizo Cambio
	END
	ELSE
	BEGIN
		SELECT @nStatusNOW= cam_procesando FROM ccCamps WHERE cam_id = @cam_id
	
		IF ( @nStatusNOW <> @nStatusNEW )
		BEGIN
			SELECT @nNewJobs= count(*)
			FROM ccoWorkingTable
			WHERE cal_status =0  -- New Jobs
			and len(cal_telefono) > 0	and cam_id =  @cam_id
			SELECT @nCBJobs= count(*)
			FROM ccoWorkingTable
			WHERE cal_status =1  -- CallBacks
			and cal_fechaDial < getdate()  --// Los vencidos hasta Ahora
			and len(cal_telefono) > 0	and cam_id =  @cam_id
			UPDATE ccCamps SET cam_procesando=@nStatusNEW  WHERE cam_id=@cam_id
	
			--INSERT tbcima_campperiodos ( cam_id,  cap_tipomov, cap_registros) Values ( @cam_id , @nStatusNEW, @nNewJobs +@nCBJobs )
	
			SELECT 1 --SI se hizo Cambio
		END
		ELSE
		BEGIN
			SELECT 0 --No se hizo Cambio
		END
	END