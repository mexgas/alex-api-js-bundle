CREATE PROCEDURE [dbo].[ccspRepSpecialCallKeyHistory]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpecialCallKeyHistory where [date] between @from and @to
	
	insert RepSpecialCallKeyHistory
		select CONVERT(varchar(16),fecha,121) [date], ISNULL(ld.cam_id, 0) campaignId,
		ISNULL(cam_descripcion, 'systemTranslated_NoCampaign') campaign,
		ld.cal_Key callKey,ld.Telefono telephone,ISNULL(rd.descripcion, 'systemTranslated_NoStatus') dialResult,
		ISNULL(cal.Description, 'systemTranslated_Dispositionless') disposition, 
		ISNULL(cal_tdialog, 0) dialogTime, ISNULL(convert(varchar(30),cal_fcallback,121),'systemTranslated_NoCallback') CallBacks,
		isNull(cast(us.Login as varchar(100)),'systemTranslated_NoUserName') [login],
		isNull(us.ApellidoPaterno,'') + ' ' + isNull(us.ApellidoMaterno, '') + ' ' + IsNull(us.Nombres, 'systemTranslated_NoName') as [user]
		from ccoLogDials ld  with(nolock)
		left join ccoCallsOut co (nolock) on co.cal_id = ld.cal_id
		left join ccTipoResultadoDial rd on rd.tipoResDial_id = ld.tipoResDial_id left join ccCamps ca on ca.cam_id = ld.cam_id
		left join ccTipoCalifOUT cal on cal.calif_id=co.calif_id 
		left join ccUserView us on us.User_id=co.User_id
		where ld.fecha between @from and @to and len(ld.cal_key)>0
end