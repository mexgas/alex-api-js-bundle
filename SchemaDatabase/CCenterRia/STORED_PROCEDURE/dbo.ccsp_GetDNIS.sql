create procedure ccsp_GetDNIS
@cal_id int
AS
declare @dni_numero as varchar(10)
declare @dni_id as int
set @dni_id = 0
set @dni_numero = '0'
select @dni_id = dni_id from ccCallsIn where cal_id = @cal_id
if @dni_id > 0 begin
	select @dni_numero = dni_numero from ccDnis where dni_id = @dni_id
end
select @dni_numero