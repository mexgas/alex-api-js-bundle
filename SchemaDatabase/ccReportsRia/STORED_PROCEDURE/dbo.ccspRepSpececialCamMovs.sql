CREATE PROCEDURE [dbo].[ccspRepSpececialCamMovs]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()

	delete RepSpececialCamMovs with(rowlock)
	where [date] between @from and @to

	insert RepSpececialCamMovs
	SELECT movs.fecha as [date], movs.cam_id campaignId, camp.cam_descripcion campaign, 
	CASE movs.TipoMov
	WHEN 0 THEN 'systemTranslated_Stop'
	WHEN 1 THEN 'systemTranslated_Start'
	WHEN 2 THEN 'systemTranslated_newRecords'
	WHEN 3 THEN 'systemTranslated_jobNew'
	WHEN 4 THEN 'systemTranslated_jobCB'
	WHEN 5 THEN 'systemTranslated_Delete'
	WHEN 6 THEN 'systemTranslated_jobBoth'
	END AS [action],
	CASE WHEN movs.prevMovs = 0 THEN 'systemTranslated_jobNew'
	WHEN movs.prevMovs = 1 THEN 'systemTranslated_jobCB'
	WHEN movs.prevMovs = 2 THEN 'systemTranslated_jobBoth'
	WHEN movs.prevMovs IS NULL THEN 'systemTranslated_noType'
	END AS [type],
	movs.NewRecords AS nnew, movs.CBRecords AS ncallback,
	CASE WHEN movs.cant_agent IS NULL THEN 0 ELSE movs.cant_agent END AS Agents,
	CASE WHEN movs.user_id IS NULL THEN 'systemTranslated_NoName'
	WHEN movs.user_id = 0 THEN 'systemTranslated_NoName'
	ELSE usr.Nombres+' '+ISNULL(usr.ApellidoPaterno,'')+' '+ISNULL(usr.ApellidoMaterno,'')
	END AS [user]
	FROM ccCampsMovs as movs JOIN ccCamps as camp ON movs.cam_id = camp.cam_id 
	LEFT OUTER JOIN ccUserView AS usr ON movs.user_id = usr.user_id
	WHERE movs.fecha BETWEEN @from AND @to
end