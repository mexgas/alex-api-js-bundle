CREATE PROCEDURE [dbo].[ccsp_OUTResetJobs] 
        @camid AS INT= 0
AS
BEGIN

  CREATE TABLE #TempccoLogDials ( 
    callout_id INT, PRIMARY KEY (callout_id)
  );
  DECLARE @today DATETIME;

  SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
  
  IF @camid = 0
  BEGIN
    INSERT INTO #TempccoLogDials
         SELECT callout_id
         FROM ccoLogDials AS ld WITH(NOLOCK)
         WHERE fecha >= @today
         GROUP BY callout_id;
  END;
     ELSE
    IF @camid > 0
    BEGIN
      INSERT INTO #TempccoLogDials
           SELECT callout_id
           FROM ccoLogDials AS ld WITH(NOLOCK)
           WHERE cam_id = @camid AND 
             fecha >= @today
           GROUP BY callout_id;
    END;

  -- CALLBACKS Se han marcado recientemente
  UPDATE ccoWorkingTable WITH(ROWLOCK)
    SET cal_status = 1
  FROM ccoWorkingTable wt
     INNER JOIN
     #TempccoLogDials ld
     ON wt.callout_id = ld.callout_id
  WHERE wt.cal_status = 2   

  IF @camid = 0
  BEGIN
    -- NUEVAS - Nunca se han marcado
    UPDATE ccoWorkingTable --WITH(ROWLOCK)
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