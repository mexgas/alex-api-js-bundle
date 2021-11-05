CREATE proc [dbo].[ccsp_ccRIACallBack_Queue]
		@Que_id int = null,
		@cal_id int = null,
		@CAL_ANI varchar(15) = null,
		@callout_id int = null,
		@inbound_id int = null,
		@retry tinyint = null,
		@action smallint = null,
		@xfer_date datetime = null,
		@call_key varchar(40) = null
		as
		set nocount on

		if @action = 2 and @Que_id is not null
		begin
			update ccRIACallBack_Queue set xferDate=isnull(@xfer_date,xferDate), status_queue=2 where Que_id=@Que_id
			return(0)
		end

		if @cal_id is null or @CAL_ANI is null or @inbound_id is null
		 begin
			select -1
			return(0)
		 end

		declare @retries smallint, @custom tinyint
		declare @ANI_CB varchar(13)
		declare @pais varchar(2)
		declare @ld varchar(5)

		select @retries=isnull(callBackRetries,0), @custom=isnull(callBackCustomPhone,0) from ccInbound nolock where Inbound_id=@inbound_id

		if @custom=0
		begin
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @ANI_CB=dbo.completa(@CAL_ANI, @pais, @ld)
		end
		else
		begin
			select @ANI_CB=@CAL_ANI
		end

		select @retry = count(*)+1 from ccRIACallBack_Queue where cal_id = @cal_id

		insert ccRIACallBack_Queue (cal_id, CAL_ANI, callout_id, inbound_id, status_queue, datestamp, retry)
		select @cal_id, @ANI_CB, @callout_id, @inbound_id, case when @custom & 4 = 4 then 2 else case when @retry>=@retries then 1 else 0 end end, 
			GETDATE(), case when @custom & 4 = 4 then 0 else @retry end

		select @Que_id = SCOPE_IDENTITY()

		if len(@call_key) > 0
		begin
			update ccCallsIn set cal_Key=@call_key where cal_id=@cal_id
		end

		select @Que_id Que_id, @ANI_CB ANI_CB, @retry Retry, @retries Retries

		set nocount off