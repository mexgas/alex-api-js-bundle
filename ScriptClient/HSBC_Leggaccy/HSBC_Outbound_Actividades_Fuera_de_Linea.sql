USE [CCReportsRIA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HSBC_Outbound_Actividades_Fuera_de_Linea]
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
	sum(tnotav) 
	as timeAgent from RepAgentGI A  with(nolock)
	inner join @relationAgtCamp B on A.userId=B.userId
	where A.date between @from and @to
	group by convert(date,date),B.camId
	)

	select A.dateDay,A.camId,sum(A.timeAgent) [Actividades Fuera de Línea hrs] from userIdCam A
	group by A.dateDay,A.camId


END

