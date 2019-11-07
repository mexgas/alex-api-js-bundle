CREATE PROCEDURE [dbo].[ccspRepSpececialPromises]
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

	DECLARE @data varchar(10), @promesa INT, @promesainb INT
	select @data = isnull(valor,'1|1') from ccSettings where setting_id = 30
	SELECT @promesainb = value FROM dbo.fn_RIASplitDelimited(@data,'|') where id = 1
	SELECT @promesa = value FROM dbo.fn_RIASplitDelimited(@data,'|') where id = 2

	delete RepSpececialPromises with(rowlock)
	where [date] between @from and @to
	
	insert RepSpececialPromises SELECT convert(varchar(10),[date],121) [date], 'systemTranslated_outbound' [type],
	cout.campaignId campaignId, 0 inboundId,
	camp.cam_descripcion [campACDDescription],
	ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0) AS promises,
	ISNULL(SUM(cout.count),0) AS total,
	CASE ISNULL(SUM(cout.count),0) WHEN 0 THEN 0 ELSE  
	CONVERT(decimal,ISNULL(SUM(CASE cout.dispositionId WHEN @promesa THEN cout.count ELSE 0 END),0))/ 
	CONVERT(decimal,ISNULL(SUM(cout.count),0)) END AS percentage 
	FROM RepOutDispositions as cout JOIN ccCamps as camp ON camp.cam_id = cout.campaignId 
	WHERE cout.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cout.campaignId, camp.cam_descripcion
	union all
	SELECT convert(varchar(10),[date],121) [date], 'systemTranslated_inbound' [type],
	0 campaignId, cin.inboundId inboundId,
	espe.descripcion [campACDDescription],
	ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0) AS promises,
	ISNULL(SUM(cin.count),0) AS TOTAL,
	CASE ISNULL(SUM(cin.count),0) WHEN 0 THEN 0 ELSE
	CONVERT(decimal,ISNULL(SUM(CASE cin.dispositionId WHEN @promesainb THEN cin.count ELSE 0 END),0))/ 
	CONVERT(decimal,ISNULL(SUM(cin.count),0)) END AS percentage
	FROM RepInDispositions as cin JOIN ccInbound as espe ON espe.inbound_id = cin.inboundId
	WHERE cin.date BETWEEN @from AND @to GROUP BY convert(varchar(10),[date],121), cin.inboundId, espe.descripcion
end