USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepAgentNotReadyDet]    Script Date: 2/6/2024 12:28:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE
	FROM RepAgentNotReadyDet
	WHERE startDate >= @from
		AND startDate < @to;

	WITH notReadyDetail
	AS (
		SELECT user_id, DATEADD(s, - tstatus, fecha) AS fechaInicio, fecha, tStatus, separado, TipoNotReady_id		
		FROM ccLogAgentesNotReady
		WHERE fecha BETWEEN @from
				AND @to
		)
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(DATE, fechaInicio, 121) [date], isNull(usr.[Login], 'systemTranslated_NoUserName') AS [login], xdet.user_Id AS userId, isNull(usr.ApellidoPaterno + ' ' + usr.ApellidoMaterno + ' ' + usr.Nombres, 
			'systemTranslated_NoName') AS [user], xdet.TipoNotReady_id AS tiponotreadyId, isNull(tn.Descripcion, 'systemTranslated_NoStatus') AS [status], fechaInicio AS startDate, fecha AS endDate, tStatus AS 
		statusTime, tStatus AS statusTimeSeconds, datepart(yyyy, fechaInicio) [year], datepart(mm, fechaInicio) [mounth], datepart(dd, fechaInicio) [day], datepart(hh, fechaInicio) [hour], datepart(mi, fechaInicio) 
		[minute]
	FROM notReadyDetail xdet
	LEFT JOIN ccUserView usr
		ON usr.user_id = xdet.user_id
	LEFT JOIN ccTipoNotReady tn
		ON tn.tipoNotready_id = xdet.tiponotready_id
	ORDER BY startDate
END
