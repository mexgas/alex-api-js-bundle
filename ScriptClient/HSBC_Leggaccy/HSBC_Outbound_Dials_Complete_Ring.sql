USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Outbound_Dials_Complete_Ring]
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
     , campaignId
     , COUNT(1) AS [DialsCompleteRing] FROM RepOutDialDetail with(nolock)
	WHERE dialResultId IN(1, 2, 3, 8, 11, 13)
	and date between @from and @to
	GROUP BY CONVERT(DATE, [date])
       , campaignId;

END

