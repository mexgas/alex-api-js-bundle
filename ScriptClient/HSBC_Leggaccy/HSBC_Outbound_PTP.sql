USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Outbound_PTP]
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

	SELECT CONVERT(DATE, [cal_Inicio]) AS date
     , cam_id
     , COUNT(1) AS [PTP] FROM ccoCallsOut with(nolock)
	WHERE calif_id IN(5, 6, 7, 8, 9)
	and [cal_Inicio] between @from and @to
	GROUP BY CONVERT(DATE, [cal_inicio])
		   , cam_id
	ORDER BY CONVERT(DATE, [cal_inicio])
       , cam_id;

END

