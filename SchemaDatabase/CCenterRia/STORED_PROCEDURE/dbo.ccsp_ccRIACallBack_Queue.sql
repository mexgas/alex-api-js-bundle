CREATE proc [dbo].[ccsp_ccRIACallBack_Queue]
@Que_id int = null,
@cal_id int = null,
@CAL_ANI varchar(15) = null,
@callout_id int = null,
@inbound_id int = null
as
set nocount on

if (isnull(@Que_id, '') = '') and (isnull(@cal_id, '') = '' or isnull(@CAL_ANI, '') = '')
 begin
	select -1
	return(0)
 end

declare @ANI_CB varchar(13)
declare @pais varchar(2)
declare @ld varchar(5)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @ANI_CB=dbo.completa(@CAL_ANI, @pais, @ld)

if isnull(@Que_id, '') <> ''
 begin
	update ccRIACallBack_Queue set cal_id = isnull(@cal_id,cal_id),
	 CAL_ANI = isnull(@CAL_ANI,CAL_ANI), callout_id = isnull(@callout_id,callout_id),
	 inbound_id = isnull(@inbound_id,inbound_id), status_queue = 1
	where Que_id=@Que_id

	select 0 Que_id, @ANI_CB ANI_CB
	return(0)
 end

insert ccRIACallBack_Queue (cal_id, CAL_ANI, callout_id, inbound_id, status_queue, datestamp)
select @cal_id, @CAL_ANI, @callout_id, @inbound_id, 0, GETDATE()

select @Que_id = SCOPE_IDENTITY()
select @Que_id Que_id, @ANI_CB ANI_CB

set nocount off