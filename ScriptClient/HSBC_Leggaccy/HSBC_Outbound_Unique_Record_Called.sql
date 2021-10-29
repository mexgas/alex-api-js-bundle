USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Outbound_Unique_Record_Called]
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

	;WITH t
     AS (SELECT DISTINCT
                CONVERT(DATE, [date]) AS date
              , callKey
              , telephone FROM RepOutDialDetail with(nolock)
			  where date between @from and @to)
     SELECT date
          , COUNT(*) [UniqueRecordCalled] FROM t GROUP BY date ORDER BY date;

END

