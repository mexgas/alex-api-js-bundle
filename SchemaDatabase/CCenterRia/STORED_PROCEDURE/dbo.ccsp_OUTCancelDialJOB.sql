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

     SELECT @RecicleSIC = ISNULL(valor, 0)
     FROM ccSettings
     WHERE setting_id = 60;

     -- En workingtable
     IF(@ExisteWT > 0)
         BEGIN
             IF(@IsAnswer = 1)
                 BEGIN
                     UPDATE ccoWorkingTable 
						SET cal_fechaDial = DATEADD(hh, 1, GETDATE()),
							cal_status = 1,
							nOcupado = 1,
							nNoContesta = 1,
							nShortCall = nShortCall + 1
                     WHERE callout_id = @callout_id;
             END
                 ELSE
                 BEGIN
                     IF(@RecicleSIC = 0)
                         BEGIN

                             DELETE ccoWorkingTable
                             WHERE callout_id = @callout_id;

                             DELETE ccoCallPriorityOrder
                             WHERE callout_id = @callout_id;
                     END
             END
     END