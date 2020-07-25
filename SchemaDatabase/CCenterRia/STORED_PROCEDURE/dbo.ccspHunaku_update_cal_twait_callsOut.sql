create procedure ccspHunaku_update_cal_twait_callsOut
			@cal_id int,
			@time_Wait int
			as
			update ccoCallsOut set cal_twait=@time_Wait where cal_id =@cal_id