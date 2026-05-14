USE [CCReportsRIA]
GO

/****** Objeto: View [dbo].[RepViewOutCallsDetail] Fecha de script: 11/05/2026 12:44:47 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[RepViewOutCallsDetail] AS 
	SELECT
	[date],
	[callKey],
	[originNumber],
	[telephone],
	[transfer] as transferTime,
	[queueTimes],
	[ringingTime],
	[dialog],
	[nque],
	[wrapup],
	[CallDisposition],
	[subDisposition],
	[callbackDate],
	[extension],
	[userId],
	[login] [agentName],
	[username] [login],
	[campaign],
	[duration],
	[ncost],
	[iva],
	[total] as [totalRow],
	[ByCarrier],
	[Calltypes],
	[dialType],
	[whoHangUp],
	[dialResult] as [callStatus],
	[calId],
	[year],
	[month],
	[day],
	[hour],
	[minutes],
	[trunk],
	[data1] [Dato1],
	[data2] [Dato2],
	[data3] [Dato3],
	[data4] [Dato4],
	[data5] [Dato5],
	[MessageTime],
	[grabId],
	[campaignId],
	[areaId],
	[area],
	[callStatusId]
	FROM RepOutCallsDetail nolock
GO


