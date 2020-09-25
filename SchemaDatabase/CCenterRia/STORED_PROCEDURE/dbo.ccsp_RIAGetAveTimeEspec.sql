CREATE PROCEDURE [dbo].[ccsp_RIAGetAveTimeEspec]
		@CveCamp int
		AS

		declare @fechaI as datetime, @fechaF as datetime
		declare @Dlgs as int
		declare @DlgsAveTime as int
		declare @Que as int
		declare @QueueAveTime as int
		declare @CallsLost as int
		declare @SL1 as int
		declare @SL2 as int
		declare @answ_tres as smallint
		declare @abnd_tres as smallint

		declare @nanswer as smallint
		declare @nno_answer as smallint
		declare @nlost as smallint
		declare @nabnd as smallint
		declare @ntimeout as smallint
		declare @noverflow as smallint
		declare @nno_agent as smallint
		declare @total as int
		declare @setting as tinyint

		declare @dia as varchar(11)

		declare @tresRing as smallint
		declare @tresDialog as smallint
		declare @tresDelayIn as smallint

		exec @tresRing = ccspConfigTresRing
		exec @tresDialog = ccspConfigTresDialog
		exec @tresDelayIn = ccspConfigtresDelayIn

		--select @dia = '2003/01/22' --, @CveCamp=5
		select @dia=CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))

		select @fechaI = convert(datetime, @dia, 101)
		select @fechaF = dateadd( d, 1, @fechaI )
		select @setting = valor from ccsettings where setting_id = 127


		declare @acdType tinyint 

		select @acdType= chat from ccInbound where Inbound_id = @CveCamp

		if @acdType= 0 begin --call
		SELECT 
		@Dlgs = count(case when statuscall_id = 13 then 1 else null end), 
		@DlgsAveTime = ISNULL(sum( case when statuscall_id = 13 then cal_tDialog + cal_tNotas else null end), 0),

		@Que = count(case when cal_que> 0 then 1 else null end), 
		@QueueAveTime = ISNULL(sum( case when cal_que > 0 then cal_tWait else null end), 0),

		@CallsLost= isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0), -- ODC

		@abnd_tres = COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer IS NULL)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),
		@answ_tres =  case when @setting = 0 then COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END) else Count(case when (statuscall_id = 13 and (cal_twait + cal_txfer + cal_tring<@tresDelayIn)) then 1 else null end) end,

		@SL1 = case when @setting = 0 then @abnd_tres + @answ_tres else @answ_tres end,

		@nanswer = COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),
		@nno_answer = COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),
		@nlost = COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),
		@nabnd = COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer IS NULL))THEN 1 ELSE NULL END),
		@ntimeout = COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),
		@noverflow = COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),
		@nno_agent = COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),
		@total = count(*),

		@SL2 = case when @setting = 0 then @nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent else @total end
		FROM ccCallsIN
		WHERE cal_Inicio between @fechaI AND @fechaF
		AND Inbound_id = @CveCamp

		select 
			'ID'=@CveCamp, 
			'DlgsAveTime'=@DlgsAveTime/ (@Dlgs+1), 
			'QueueAveTime'=@QueueAveTime / (@Que +1),
			'SL' = case 
				when @SL2 > 0 
				then 100 * @SL1 / @SL2 
				else 0 end, 
			'sl2' = case 
				when @setting = 0 
				then 
					case 
						when (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent) > 0 
						then 100 * (@abnd_tres + @answ_tres) / (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent)
						else 0 end 
				else case 
					when @total > 0 
					then 100 * @answ_tres/@total 
					else 0 end end
			 ,@acdType as acdType
		end

		else if @acdType= 1 begin

		declare @CC int,@CCAb int,@ccme int,@ccma int,@cAs int,@cs int,@cAb int,@cDt int,@cDe int
		select @CC=0,@ccme=0,@ccma=0,@cAs=0,@cs=0,@cAb=1,@cDt=0,@cDe=0,@DlgsAveTime=0

		select
		@CC = count(case when chatStatus=4 then 1 else null end) ,
		@CCAb = count(case when chatStatus=9 and tQueue<@tresDialog then 1 else null end) ,
		@DlgsAveTime = isnull(sum(case when chatStatus=4 then tChatting+tWrapUp else null end),0) ,
		@ccme = count(case when chatStatus=4 and tChatting<@tresDialog and finishedBy=0 then 1 else null end),
		@ccma = count(case when chatStatus=4 and tChatting>@tresDialog then 1 else null end) ,
		@cAs= count(case when chatStatus=3 then 1 else null end) ,
		@cs = count(case when chatStatus=7 then 1 else null end) ,
		@cAb = count(case when chatStatus=9 and tQueue>=@tresDialog then 1 else null end) ,
		@cDt = count(case when chatStatus=11 then 1 else null end) ,
		@cDe = count(case when chatStatus=10 then 1 else null end),
		@Que = count(case when onQueue > 0 then 1 else null end), 
		@QueueAveTime = ISNULL(sum( case when onQueue > 0 then tQueue else null end), 0),
		@SL2 = @ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe
		from ccRIAChats 
		where requestDate between @fechaI AND @fechaF
		and inboundId=@CveCamp 
		group by inboundId 

		select 
			@CveCamp as ID, 
			isnull(@DlgsAveTime/ (@CC+1),0) as DlgsAveTime, 
			isnull(@QueueAveTime / (@Que +1),0) as QueueAveTime,
			case when @SL2>0 then (@CC+@CCAb)*100/(@SL2) else 0 end as SL,
			isnull((@CC+@CCAb)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as Sl2,
			@acdType as acdType,
			@CC+@CCAb as CC,
			@SL2 as SumSL
		end