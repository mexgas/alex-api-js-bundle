CREATE procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
		@cal_id int,
		@nStatus tinyint,
		@cbPhone varchar(20) = NULL
		as
		set nocount on
		declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
		 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5), @telFormat tinyint

		declare @lenExt int

		select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
		@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon,@telFormat = I.telFormato
		from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

		if datalength(isnull(@cbPhone,'')) > 0
		begin
			set @ANI=@cbPhone
		end

		select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

		select @pais = valor from ccSettings with(nolock) where setting_id = 104
		select @ld = valor from ccSettings with(nolock) where setting_id = 17
		select @lenExt = case when valor=''then 0 else valor end from ccSettings with(nolock) where setting_id = 108
		if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, ',')) or isnull(@cal_id,0)=0
		 return(0)
 
		if isnull(@cam_id, 0)=0
		  return(0)

  
		--set @ANI =dbo.Limpia(@ANI)
		--if @lenExt<>len(@ANI)
		--  select @ANI = dbo.completa(@ANI, @pais, @ld)

		  if @telFormat = 0
		  set @ANI =dbo.Limpia(@ANI)
		  else if @telFormat = 1
		  select @ANI = dbo.completa(@ANI, @pais, @ld)

		if (select substring(@ANI,1,1))= 'E'
		  return(0)

		if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
		  return(0)

		 begin try
		  insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
		  select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial
		  declare @dato1 varchar (max),  @dato2 varchar (max), @dato3 varchar (max), @dato4 varchar (max), @dato5 varchar (max)
		  set @dato1 = '' set @dato2 = '' set @dato3 = '' set @dato4 = '' set @dato5 = ''
  
		  declare @datosToAgent varchar(max)
		  select @datosToAgent= addDataCallBackReminder from ccInbound where Inbound_id = @inbound_id
  
		  if(@datosToAgent = 1)
		  begin
			select @dato1 = Isnull(Data,'') from DataCallIn where CallId = @cal_id and Description = 'Dato 1'
			select @dato2 = Isnull(Data,'') from DataCallIn where CallId = @cal_id and Description = 'Dato 2'
			select @dato3 = Isnull(Data,'') from DataCallIn where CallId = @cal_id and Description = 'Dato 3'
			select @dato4 = Isnull(Data,'') from DataCallIn where CallId = @cal_id and Description = 'Dato 4'
			select @dato5 = Isnull(Data,'') from DataCallIn where CallId = @cal_id and Description = 'Dato 5'
		  end 
		  exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1

		  select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
		  select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
		  update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
		  return(0)
		 end try

		 begin catch
		  return(0)
		 end catch
		set nocount off