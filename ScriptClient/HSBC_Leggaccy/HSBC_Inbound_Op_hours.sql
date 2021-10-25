USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[HSBC_Inbound_Op_hours]
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
	inner join ccRIACampEspWG C on C.IDWG=A.IDWG and C.Tipo=0
	inner join ccUsers users on users.User_id=A.User_id and users.TipoUser_id=1

	;with userIdCam as(
	select convert(date, [date]) as dateDay,B.camId,
	sum(tunknown) +
	sum(tav) +
	sum(tother) +
	sum(tprob) +
	sum(tundefined) +
	sum(tChatting) 
	as timeAgent from RepAgentGI A with(nolock)
	inner join @relationAgtCamp B on A.userId=B.userId
	where A.date between @from and @to
	group by convert(date,date),B.camId
	)
	, timeCampOut as(
	SELECT CONVERT(DATE, [cal_inicio]) AS date
		 ,  SUM(cal_tDialog) + SUM(cal_tNotas) + SUM(cal_tXfer) + SUM(cal_tRing) AS timeDialog
		 , Inbound_id cam_id FROM ccCallsIn with(nolock)
		 where cal_Inicio between @from and @to
	GROUP BY CONVERT(DATE, [cal_inicio])
		   , Inbound_id
	)

	select A.dateDay,A.camId,sum(A.timeAgent) +isnull(sum(B.timeDialog),0) as [Inbound_Op_hours] from userIdCam A
	left join timeCampOut B on A.camId=B.cam_id
	group by A.dateDay,A.camId


END

