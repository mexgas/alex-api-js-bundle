USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_HSBC_Outbound_Dials_Complete_Ring]    Script Date: 12/02/2025 11:34:41 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[ccsp_HSBC_Outbound_Dials_Complete_Ring]
@fe_ini datetime =null,@fe_fin datetime =null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @fe_ini is null 
	 set @fe_ini= convert(date,getdate())

	 if @fe_fin is null 
	 set @fe_fin= getdate()

	 delete from HSBC_Outbound_Dials_Complete_Ring where date between @fe_ini and @fe_fin

	 insert into HSBC_Outbound_Dials_Complete_Ring
	SELECT CONVERT(DATE, [date]) AS date
     , campaignId
     ,data4
     , COUNT(1) AS [cuenta] 
	 ,data5
	 FROM RepOutDialDetail with(nolock)
	WHERE dialResultId IN(1, 2, 3, 8, 11, 13)
	and date between @fe_ini and @fe_fin
		 AND CAMPAIGN LIKE '%HSBC%'
	GROUP BY CONVERT(DATE, [date])
       , campaignId,data4,data5;

END


