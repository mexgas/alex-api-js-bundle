CREATE PROCEDURE dbo.ccsp_OUTDailyContact
@telefono varchar(15),
@callout_id int,
@isManualCall bit
AS	

declare @allowDuplicateDial as bit
select @allowDuplicateDial = valor from ccSettings where setting_id = 105

if @isManualCall = 1 begin
	if exists(select logDial_id from ccoLogDials where telefono = @telefono and tipoResDial_id = 1 and fecha > convert(varchar(8),getDate(),112)) and
	 @allowDuplicateDial = 0  begin
		select 1
	end
	else begin 
		select 0
	end
end
else
begin
declare @allowedPhones as varchar(5)
	declare @phone1 as varchar(15)
	declare @phone2 as varchar(15)
	declare @phone3 as varchar(15)
	declare @phone4 as varchar(15)
	declare @phone5 as varchar(15)
	select @phone1=cal_telefono,@phone2=cal_telefono2,@phone3=cal_telefono3,@phone4=cal_telefono4,@phone5=cal_telefono5 from ccocallsoutSource where callout_id = @callout_id
	
	if @allowDuplicateDial = 0 begin
		if exists(select logDial_id from ccoLogDials where telefono = isnull(@phone1,'') and tipoResDial_id = 1 and fecha > convert(varchar(8),getDate(),112)) begin
			set @allowedPhones = '0'
		end
		else begin 
			set @allowedPhones = '1'
		end	

		if exists(select logDial_id from ccoLogDials where telefono = isnull(@phone2,'') and tipoResDial_id = 1 and fecha > convert(varchar(8),getDate(),112)) begin
			set @allowedPhones = @allowedPhones + '0'
		end
		else begin 
			set @allowedPhones = @allowedPhones + '1'
		end	

		if exists(select logDial_id from ccoLogDials where telefono = isnull(@phone3,'') and tipoResDial_id = 1 and fecha > convert(varchar(8),getDate(),112)) begin
			set @allowedPhones = @allowedPhones + '0'
		end
		else begin 
			set @allowedPhones = @allowedPhones + '1'
		end	

		if exists(select logDial_id from ccoLogDials where telefono = isnull(@phone4,'') and tipoResDial_id = 1 and fecha > convert(varchar(8),getDate(),112)) begin
			set @allowedPhones = @allowedPhones + '0'
		end
		else begin 
			set @allowedPhones = @allowedPhones + '1'
		end	

		if exists(select logDial_id from ccoLogDials where telefono = isnull(@phone5,'') and tipoResDial_id = 1 and fecha > convert(varchar(8),getDate(),112)) begin
			set @allowedPhones = @allowedPhones + '0'
		end
		else begin 
			set @allowedPhones = @allowedPhones + '1'
		end	
	end
	else begin	
	set @allowedPhones = '11111'
	end

	select @allowedPhones
end