USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Inbound_SL_Nivel_de_Servicio]
@from datetime =null,@to datetime =null,@umbral int =20
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @from is null 
	 set @from= convert(date,getdate())

	 if @to is null 
	 set @to= getdate()

  ;With cuentaUbralMayor as(
	SELECT CONVERT(DATE, [date]) AS date
		 , inboundId
		 , COUNT(1) AS cuenta FROM RepInCallsDetail with(nolock)	 
	WHERE callStatusId = 13
		  AND queueTime <= @umbral
		and  date between @from and @to
	GROUP BY CONVERT(DATE, [date])
		   , inboundId
	), cuenta2 as( 
	select convert(date,[date]) as date,inboundId,count(1) as cuenta from RepInCallsDetail  with(nolock)	 
	where date between @from and @to
	group by convert(date,[date]),inboundId
	)

	select A.date,A.inboundId,isnull(B.cuenta/A.cuenta,0) [SLNivelServicio] from cuenta2 A
	left join cuentaUbralMayor B on A.date=B.date and A.inboundId=B.inboundId

END