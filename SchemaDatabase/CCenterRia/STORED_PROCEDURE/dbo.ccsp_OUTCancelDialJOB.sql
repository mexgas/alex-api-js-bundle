CREATE PROCEDURE [dbo].[ccsp_OUTCancelDialJOB]
@callout_id    INT,
@IsAnswer      TINYINT,
@nOcupado      TINYINT,
@nNoContesta   TINYINT,
@nFax          TINYINT,
@nContestadora TINYINT,
@nShortCall    TINYINT,
@nOtro         TINYINT,
@ExisteWT      TINYINT = 1
AS
DECLARE @RecicleSIC TINYINT;

SELECT @RecicleSIC = valor FROM ccSettings WHERE setting_id = 60;
IF @RecicleSIC IS NULL
    SET @RecicleSIC = 0;

-- En workingtable
IF @ExisteWT > 0 BEGIN
	IF @IsAnswer = 1 BEGIN
			UPDATE ccoWorkingTable WITH(ROWLOCK)
			SET
				cal_fechaDial = DATEADD(hh, 1, GETDATE()),
				cal_status = 1,
				nOcupado = 1,
				nNoContesta = 1,
				nShortCall = nShortCall + 1
			WHERE callout_id = @callout_id;
	END;
		ELSE
		IF @RecicleSIC = 0 BEGIN
				DELETE ccoWorkingTable WITH(ROWLOCK) WHERE callout_id = @callout_id;
				DELETE ccoCallPriorityOrder WITH(ROWLOCK) WHERE callout_id = @callout_id;
		END;
END;