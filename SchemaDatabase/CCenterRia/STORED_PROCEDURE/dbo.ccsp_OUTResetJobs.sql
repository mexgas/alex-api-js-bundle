CREATE PROCEDURE dbo.ccsp_OUTResetJobs 
				@camid AS INT= 0
AS
BEGIN

	CREATE TABLE #TempccoLogDials
	( 
				 callout_id INT, cam_id SMALLINT, fecha DATETIME
	);
	DECLARE @today DATETIME;

	SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
	set @today=dateadd(dd,-1,@today)

	IF @camid = 0
	BEGIN
		INSERT INTO #TempccoLogDials
			   SELECT callout_id, cam_id, MAX(fecha) AS fecha
			   FROM ccoLogDials AS ld WITH(NOLOCK)
			   WHERE fecha >= @today
			   GROUP BY callout_id, cam_id;
	END;
		 ELSE
		IF @camid > 0
		BEGIN
			INSERT INTO #TempccoLogDials
				   SELECT callout_id, cam_id, MAX(fecha) AS fecha
				   FROM ccoLogDials AS ld WITH(NOLOCK)
				   WHERE cam_id = @camid AND 
						 fecha >= @today
				   GROUP BY callout_id, cam_id;
		END;

	-- CALLBACKS Se han marcado recientemente
	UPDATE ccoWorkingTable WITH(ROWLOCK)
	  SET cal_status = 1
	FROM ccoWorkingTable wt
		 INNER JOIN
		 #TempccoLogDials ld
		 ON wt.callout_id = ld.callout_id
	WHERE wt.cal_status = 2 AND 
		  ld.fecha > DATEADD(d, -1, GETDATE());

	IF @camid = 0
	BEGIN
		-- NUEVAS - Nunca se han marcado
		UPDATE ccoWorkingTable WITH(ROWLOCK)
		  SET cal_status = 0
		WHERE cal_status = 2;
	END;
		 ELSE
	BEGIN  
		-- NUEVAS - Nunca se han marcado
		UPDATE ccoWorkingTable WITH(ROWLOCK)
		  SET cal_status = 0
		WHERE cal_status = 2 AND 
			  cam_id = @camid;
	END;

	DROP TABLE #TempccoLogDials;
END;