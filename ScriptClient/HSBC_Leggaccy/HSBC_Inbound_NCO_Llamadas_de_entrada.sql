USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Inbound_NCO_Llamadas_de_entrada]
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
     , inboundId
     , COUNT(1) AS [NCOLlamadasEntrada] FROM RepInCallsDetail with(nolock)
	 where [date] between @from and @to
	GROUP BY CONVERT(DATE, [date])
		   , inboundId;
END

GO

