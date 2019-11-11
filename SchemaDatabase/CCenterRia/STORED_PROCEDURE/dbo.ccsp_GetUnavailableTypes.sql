CREATE PROCEDURE [dbo].[ccsp_GetUnavailableTypes] @action INT
	,@startDate DATETIME =  null
	,@endDate DATETIME = null
	,@unavailable_id VARCHAR(300) = null
AS
IF (@action = 0)
BEGIN
	SELECT TipoNotReady_id AS [unavailable_id]
		,Descripcion AS [description]
		,Time_Acum AS [MaxTime]
		,Time_xEv AS [MaxTimePerEvent]
		,Pas_Sup AS [AdminPw]
		,NextStatus AS [NextStatus]
		,IsSup AS [AdminOnly]
		,StatusTipoNotReady AS [UnavailableStatus]
	FROM ccTipoNotReady
END

IF (@action = 1)
BEGIN
	DECLARE @tabla TABLE (notReadyId INT PRIMARY KEY)

	INSERT INTO @tabla
	SELECT value
	FROM dbo.fn_RIASplitDelimited(@unavailable_id, ',')
	
	SELECT user_id, sum(tstatus)
	FROM ccLogAgentesNotReady A WITH (NOLOCK)
	INNER JOIN @tabla B ON A.TipoNotReady_id = B.notReadyId
	WHERE fecha >= @startDate
		AND fecha <= @enddate
	GROUP BY user_id
END