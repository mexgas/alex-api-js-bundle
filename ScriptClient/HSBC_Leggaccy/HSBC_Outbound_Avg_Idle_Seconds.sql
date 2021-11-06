USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Outbound_Avg_Idle_Seconds]
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


	declare @relationAgtCamp table ( userId int not null, camId int,tipo int, primary key(userId,camId,tipo))

	insert into @relationAgtCamp
	select
	A.User_id,C.IdCampEsp, C.Tipo
	from ccRIAWorkGroupUsers  A
	inner join ccRIACampEspWG C on C.IDWG=A.IDWG and C.Tipo=1
	inner join ccUsers users on users.User_id=A.User_id and users.TipoUser_id=1

	;with userIdCam as(
	select convert(date, [date]) as dateDay,B.camId,
	sum(tav) 
	as timeAgent from RepAgentGI A with(nolock)
	inner join @relationAgtCamp B on A.userId=B.userId
	where  A.date between @from and @to
	group by convert(date,date),B.camId
	)
	, timeCampOut as(
	SELECT CONVERT(DATE, [cal_Inicio]) AS date
		 , cam_id
		 , COUNT(DISTINCT User_id) AS cuenta FROM ccoCallsOut with(nolock)
	where  [cal_Inicio] between @from and @to and user_id > 0
	GROUP BY CONVERT(DATE, [cal_Inicio])
		   , cam_id
	)

	select A.dateDay,A.camId,case when sum(B.cuenta) is null or sum(B.cuenta)=0 then sum(A.timeAgent) else sum(A.timeAgent)/sum(B.cuenta) end [Avg Idle seconds] 
	from userIdCam A
	left join timeCampOut B on A.camId=B.cam_id
	group by A.dateDay,A.camId


END

