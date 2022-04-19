CREATE PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE RepAvgAnswerTimeChats
	WHERE DATE >= @from
		AND DATE < @to;

	WITH answerTime
	AS (
		SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), requestDate, 121) + ':00', 121) AS [date], userId, [Login] AS [login], inboundId, c.descripcion AS [inbound], nombres + ' ' + apellidopaterno + ' ' + apellidomaterno AS 
			[user], CASE 
				WHEN firstMessageTime IS NULL
					THEN convert(INT, isnull(firstMessageTime, 0))
				ELSE datediff(ss, chatdate, firstMessageTime)
				END AS [answerTime], a.chatId AS [chatId]
		FROM ccriachats a
		LEFT JOIN ccUserView b ON (a.userId = b.user_id)
		LEFT JOIN ccinbound c ON (a.inboundId = c.inbound_id)
		WHERE b.user_id IS NOT NULL
			AND c.inbound_id IS NOT NULL
			AND a.chatstatus = 4
			AND requestDate BETWEEN @from
				AND @to
		)
	INSERT INTO RepAvgAnswerTimeChats
	SELECT [date] AS [date], userId, [Login], inboundId, [inbound], [user], convert(DECIMAL(10, 2), isnull(sum([answerTime]) / count(*), 0.00)) AS [avgAnswerTime], datepart(yyyy, [date]), datepart(mm, [date]), datepart(dd
			, [date]), datepart(hh, [date]), 0 AS [minute], chatId
	FROM answerTime
	GROUP BY [date], userId, [Login], inboundId, [inbound], [user], [chatId]
END