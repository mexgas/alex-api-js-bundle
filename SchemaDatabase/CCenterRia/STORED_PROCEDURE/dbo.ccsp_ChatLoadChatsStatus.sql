CREATE PROCEDURE [dbo].[ccsp_ChatLoadChatsStatus] 
@acdId int ,
@startDate datetime ,
@endDate datetime ,
@finishedChatsThreshold int = 10,
@abandonedChatsThreshold int = 10
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.	
SET NOCOUNT ON;
SELECT a.chatStatus as 'status',
ISNULL(a.onQueue,0) as 'queued',
CASE 
	WHEN a.ChatStatus = 4 AND a.tChatting >= @finishedChatsThreshold THEN 1					--Valid chat
	WHEN a.ChatStatus = 9 AND a.onQueue = 1 AND a.tQueue <= @abandonedChatsThreshold THEN 1    --Valid abandon
ELSE 0
END As 'valid',
COUNT(*) AS 'count',
SUM(a.tChatting) as 'timeChatting',
SUM(a.tWrapUp) as 'timeWrapup',
SUM(a.tQueue) AS 'timeWaiting',
MAX(a.tQueue) AS 'maxWaiting'
FROM dbo.ccRIAChats as a
WHERE a.inboundId = @acdId     
AND a.requestDate BETWEEN @startDate AND @endDate
GROUP BY a.inboundId, a.chatStatus, ISNULL(a.onQueue,0), 
CASE 
	WHEN a.ChatStatus = 4 AND a.tChatting >= @finishedChatsThreshold THEN 1					--Valid chat
	WHEN a.ChatStatus = 9 AND a.onQueue = 1 AND a.tQueue <= @abandonedChatsThreshold THEN 1    --Valid abandon
ELSE 0
END -- As 'valid'
END