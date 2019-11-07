CREATE function dbo.fn_Ext_X_ip (@ip varchar(80))
returns varchar(20)
as
begin
declare @Ext_id varchar(20)

select top 1 @Ext_id=m.Extension from ccPosicion p join ccMonitorExt m on p.ext_id = m.ext_id
where p.computer = @ip or p.ip = @ip and p.Status=1 and m.Status=1 order by p.computer, p.ip

if @Ext_id is null or (select valor from ccSettings where setting_id=71) = 0
	set @Ext_id = 0

return (@Ext_id)
end