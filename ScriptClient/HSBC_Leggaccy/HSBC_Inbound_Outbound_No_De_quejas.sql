USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Inbound_Outbound_No_De_quejas]
@from datetime =null,@to datetime =null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
	if @from is null 
	 set @from= convert(date,getdate())

	 if @to is null 
	 set @to= getdate()

	SELECT CONVERT(DATE, [date]) AS date
		,inboundId
     , COUNT(1) AS cuenta 
	 ,'Inbound' callType
	 FROM RepInCallsDetail with(nolock)
		WHERE callStatusId = 13
			  AND dispositionId IN(5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 29, 30, 31, 32, 33, 34, 48, 49)
			  and  date between @from and @to
		GROUP BY CONVERT(DATE, [date]),inboundId
		union all
		SELECT CONVERT(DATE, [cal_Inicio]) AS date
			 , cam_id
			 , COUNT(1) AS cuenta 
			 ,'Outbound' callType
			 FROM ccoCallsOut with(nolock)
		WHERE calif_id IN(31)
		and  [cal_Inicio] between @from and @to
		GROUP BY CONVERT(DATE, [cal_inicio])
       , cam_id;

END
