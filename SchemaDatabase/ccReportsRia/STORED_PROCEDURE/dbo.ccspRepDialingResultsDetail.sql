CREATE PROCEDURE [dbo].[ccspRepDialingResultsDetail]
@action as tinyint,
@from as datetime=null,
@to as datetime=null
AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

delete from  RepDialingResultsDetail where [date] between @from and @to

insert into RepDialingResultsDetail(date,telephone,dialResultId,dialResult,userId,login,campaignId,campaign,year,month,day,hour,minutes)
select dial.fecha as [date],dial.Telefono as [telephone],dial.tipoResDial_id as dialResultId,isnull(tr.descripcion,dial.disconnectCause) as dialResult,
isnull(co.User_id,0) as userId,isnull(cast(u.Login  as varchar(50)),'systemTranslated_NoUserName') as [Login],
dial.cam_id as campaignId,isnull(camp.cam_descripcion,'N/A') as campaign
,datepart(yyyy,dial.fecha) as [year]
,datepart(mm,dial.fecha) as [month]
,datepart(dd,dial.fecha) as [day]
,datepart(hh,dial.fecha) as [hour]
,datepart(mi,dial.fecha) as [minute]
FROM ccoLogDials dial (nolock)
left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
left join cctipoResultadoDial tr ON dial.tiporesdial_id=tr.tiporesdial_id
left join ccUserView u on u.user_id =co.User_id
left join ccCamps camp on camp.cam_id=dial.cam_id
where dial.fecha>=@from and dial.fecha<@to


end