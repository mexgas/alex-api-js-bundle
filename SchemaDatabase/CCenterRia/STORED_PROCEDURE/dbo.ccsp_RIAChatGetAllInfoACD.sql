CREATE PROCEDURE [dbo].[ccsp_RIAChatGetAllInfoACD]
@Option AS SMALLINT,
@User_id AS SMALLINT,
@Date AS DATETIME = NULL
AS
SET NOCOUNT ON

DECLARE @dateStart DATETIME
DECLARE @dateEnd   DATETIME

IF @Date IS NULL
BEGIN
	SET @Date = GETDATE()
END

SET @dateStart = CONVERT(DATETIME, DATEDIFF(DAY, 0, @Date))
SET @dateEnd   = DATEADD (DAY, 1, @datestart)
SET @dateEnd   = DATEADD (SECOND, -1, @dateend)

IF @Option = 1 -- Chats
BEGIN

SELECT
	InboundId,
	Chats             = ISNULL (COUNT(*), 0),
	Request           = ISNULL (COUNT (CASE WHEN chatStatus =  0 THEN 1 ELSE NULL END), 0),
	InactiveDomain    = ISNULL (COUNT (CASE WHEN chatStatus =  1 THEN 1 ELSE NULL END), 0),
	UnavailableAgents = ISNULL (COUNT (CASE WHEN chatStatus =  2 THEN 1 ELSE NULL END), 0),
	Assigned          = ISNULL (COUNT (CASE WHEN chatStatus =  3 THEN 1 ELSE NULL END), 0),
	Connected         = ISNULL (COUNT (CASE WHEN chatStatus =  4 THEN 1 ELSE NULL END), 0),
	OutOfService      = ISNULL (COUNT (CASE WHEN chatStatus =  5 THEN 1 ELSE NULL END), 0),
	OutOfSchedule     = ISNULL (COUNT (CASE WHEN chatStatus =  6 THEN 1 ELSE NULL END), 0),
	NoSignedAgents    = ISNULL (COUNT (CASE WHEN chatStatus =  7 THEN 1 ELSE NULL END), 0),
	Queued            = ISNULL (COUNT (CASE WHEN chatStatus =  8 THEN 1 ELSE NULL END), 0),
	Abandon           = ISNULL (COUNT (CASE WHEN chatStatus =  9 THEN 1 ELSE NULL END), 0),
	QueueOverflow     = ISNULL (COUNT (CASE WHEN chatStatus = 10 THEN 1 ELSE NULL END), 0),
	TimeOverflow      = ISNULL (COUNT (CASE WHEN chatStatus = 11 THEN 1 ELSE NULL END), 0),

	ChattingAveTime   = ISNULL (CONVERT (INT, ROUND (AVG (CASE WHEN chatStatus = 4 THEN (tChatting + tWrapUp) * 1.0 ELSE NULL END), 0)), 0),
	QueueAveTime      = ISNULL (CONVERT (INT, ROUND (AVG (CASE WHEN onQueue    = 1 THEN  tQueue               * 1.0 ELSE NULL END), 0)), 0),
	QueueMaxTime      = ISNULL (                     MAX (CASE WHEN onQueue    = 1 THEN  tQueue                     ELSE NULL END)     , 0)

	FROM ccRIAChats
	WHERE requestDate >= @dateStart AND requestDate <= @dateEnd
	AND InboundId IN (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0)
	GROUP BY InboundId
END

SET NOCOUNT OFF