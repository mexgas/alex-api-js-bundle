CREATE PROCEDURE CW_trsp_Get_Values_All_Fields

			 @callId int,
			 @callType int-- 1 para inbound, 2 para outbound --2
			AS

			CREATE TABLE #All_Values_temp (
			ItemId int unique,
				Value VARCHAR(500),
			    Description VARCHAR(20)   
			);

			insert into #All_Values_temp 
					Select 1,*,'Year_long' from ( 
						Select convert(varchar(4),finicio,126) as x
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(4),finicio,126) as x
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) Year_long

			insert into #All_Values_temp 
					Select 2,*,'Year_short' from ( 
						Select convert(varchar(2),finicio,2)  as x
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(2),finicio,2) as x
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) Year_short

			insert into #All_Values_temp 
					Select 3,*,'month_number' from ( 
						Select convert(varchar(2),finicio,1)  as x
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(2),finicio,1) as x
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) month_Number

			insert into #All_Values_temp 
					Select 4,*,'month_text' from ( 
						Select convert(varchar(3),finicio,7)  as x
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(3),finicio,7) as x
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) month_text

			insert into #All_Values_temp 
					Select 5,*,'day' from ( 
						Select convert(varchar(2),finicio,113)  as x
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(2),finicio,113) as x
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) day

			insert into #All_Values_temp 
					Select 6,*,'extension' from ( 
						Select extension 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  extension
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) ext

			insert into #All_Values_temp 
					Select 7,*,'cli_id' from ( 
						Select cli_id  
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  cli_id 
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) cli_id

			insert into #All_Values_temp 
					Select 8,*,'puerto_id' from ( 
						Select puerto_id 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  puerto_id
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) puerto_id

			insert into #All_Values_temp 
					Select 9,*,'age_id' from ( 
						Select age_id 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  age_id
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) age_id

			insert into #All_Values_temp 
					Select 10,*,'ANI' from ( 
						Select ANI 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  ANI
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) ANI

			insert into #All_Values_temp 
					Select 11,*,'info1' from ( 
						Select info1 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  info1
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) info1

			insert into #All_Values_temp 
					Select 12,*,'info2' from ( 
						Select info2 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  info2
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) info2

			insert into #All_Values_temp 
					Select 13,*,'info3' from ( 
						Select info3 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  info3
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) info3

			insert into #All_Values_temp 
					Select 14,*,'info4' from ( 
						Select info4 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  info4
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) info4

			insert into #All_Values_temp 
					Select 15,*,'info5' from ( 
						Select info5 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  info5
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) info5

			insert into #All_Values_temp 
					Select 16,*,'cam_id' from ( 
						Select cam_id 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  cam_id
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) cam_id

			insert into #All_Values_temp 
					Select 17,*,'calif_id' from ( 
						Select calif_id 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  calif_id
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) calif_id

			insert into #All_Values_temp 
					Select 18,*,'cal_key' from ( 
						Select cal_key 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  cal_key
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) cal_key

			insert into #All_Values_temp 
					Select 19,*,'cal_id' from ( 
						Select cal_id 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  cal_id
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) cal_id

			insert into #All_Values_temp 
					Select 20,*,'grab_id' from ( 
						Select grab_id 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  grab_id
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) grab_id

			insert into #All_Values_temp 
					Select 21,*,'hour' from ( 
						Select convert(varchar(8),finicio,114) as hour 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(8),finicio,114) as hour 
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) hour

			insert into #All_Values_temp 
					Select 22,*,'extra_info' from ( 
						Select extra_info
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  extra_info
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) extra_info

			insert into #All_Values_temp 
					Select 23,*,'hour_HHMM' from ( 
						Select REPLACE(CONVERT(varchar(5), finicio, 108), ':', '') as hour_HHMM 
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  REPLACE(CONVERT(varchar(5), finicio, 108), ':', '') as hour_HHMM 
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) hour_HHMM

			insert into #All_Values_temp 
					Select 24,*,'date' from ( 
						Select convert(varchar(2),finicio,113)+convert(varchar(2),finicio,1)+convert(varchar(2),finicio,2)as date
						from dbo.RIA_Grabacion where cal_id =  @callId  and tipo_llamada = @callType 
					union	 
						Select  convert(varchar(2),finicio,113)+convert(varchar(2),finicio,1)+convert(varchar(2),finicio,2)as date
						from dbo.RIA_GrabacionConsulta where cal_id =  @callId  and tipo_llamada =  @callType 
					) date

			insert into #All_Values_temp 
				select 25,Campo ,'customText' from TREC_FORM_ARCHIVOSEXPORT where ID=25

			select * from #All_Values_temp 
			DROP TABLE #All_Values_temp