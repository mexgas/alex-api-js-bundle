USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Inbound_Avd_AHT_seconds]
@from datetime =null,@to datetime =null
AS
BEGIN
	
	SET NOCOUNT ON;

	if @from is null 
	set @from= convert(date,getdate())

	if @to is null 
	set @to= getdate()
	
	;with  timeCall as(
	SELECT CONVERT(DATE, [cal_Inicio]) AS date
		 , Inbound_id cam_id
		 , isnull(SUM(cal_tDIalog),0) + isnull(SUM(cal_tNotas),0) as  timeAgent
		 , COUNT(DISTINCT User_id) AS cuenta FROM ccCallsIn with(nolock)
	WHERE cal_Inicio between @from and @to and user_id > 0
	GROUP BY CONVERT(DATE, [cal_Inicio])
		   , Inbound_id 
	)

	select date,cam_id,timeAgent/cuenta as [Avd_AHT_seconds] from timeCall

END

