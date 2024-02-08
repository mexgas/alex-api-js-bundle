USE [CCReportsRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccspRepAnsweredCallsByDialingRetries]    Script Date: 18/1/2024 12:32:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccspRepAnsweredCallsByDialingRetries]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin	
	--Borrar lo que esta para no repetir
	delete from RepAnsweredCallsByDialingRetries where date >= @from and date < @to

	;
	with logExtension as(
		select user_id,max(Extension) ext from ccLogLogin where fecha between @from and @to
		group by user_id
	)

	INSERT INTO RepAnsweredCallsByDialingRetries
	select
	A.cal_Inicio as [date],
	A.cal_id as [calId],
	A.cal_telefono as [telephone],
	isnull(B.tipoResDial_id,0) as [dialResultId],
	isnull(resDial.descripcion,'N/A') as [dialResult],
	isnull(C.cal_intentos,0) as [tries],
	A.cam_id as [campaignId],
	E.cam_descripcion as [campaign],
	A.User_id as [userId],
	ISnull(D.Nombres + ' ' + D.ApellidoPaterno + ' ' + D.ApellidoMaterno,'systemTranslated_NoName') as [agentName],
	isnull(logExtension.ext	,'') as [extension],
	convert(varchar(12),A.cal_Inicio,108) as [startHour],
	convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour],
	cal_tDialog as [dialogTime],
	isnull(A.calif_id,0) as [dispositionId],
	isnull(A.califSub_id,0) as [subDispositionId],
	isnull(disp.Description,'systemTranslated_Dispositionless') as [disposition],
	isnull(subDisp.califSubDesc,'systemTranslated_NoSubDisposition') as [subDisposition],
	A.cal_tNotas as [wrapup],
	datepart(yyyy,cal_Inicio) AS [year],
	datepart(mm,cal_Inicio) as [month],
	datepart(dd,cal_Inicio) as [day],
	datepart(hh,cal_Inicio) as [hour],
	datepart(mi,cal_Inicio) as [minutes]
	from ccoCallsOut A with(nolock)
	left join ccoLogDials B with(nolock) on A.cal_id=B.cal_id
	left join ccoCallsOutSource C with(nolock) on C.callout_id=A.callout_id
	left join ccUserView D on A.User_id=D.User_id
	left join ccCamps E on A.cam_id=E.cam_id
	left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
	left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
	left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id
	left join logExtension on logExtension.user_id=A.User_id

	where A.cal_Inicio >= @from
	and A.cal_Inicio < @to
	and A.cal_manual in(0,2)
	order by date
END