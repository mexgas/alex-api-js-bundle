USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Outbound_Avg_Wrap_Seconds]
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

	
	;with  timeCampOut as(
	SELECT CONVERT(DATE, [cal_Inicio]) AS date
		 , cam_id
		 , SUM(cal_tNotas) as  timeAgent
		 , COUNT(DISTINCT User_id) AS cuenta FROM ccoCallsOut with(nolock)
	WHERE cal_Inicio between @from and @to and user_id > 0
	GROUP BY CONVERT(DATE, [cal_Inicio])
		   , cam_id
	)

	select date,cam_id,timeAgent/cuenta as [Avg Talk secods] from timeCampOut


END

