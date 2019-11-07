CREATE PROCEDURE [dbo].[ccsp_RIADispMonitor]
@action tinyint = 0,
@userId smallint = 0,
@dispositionsIn varchar(40) = '',
@dispositionsOUT varchar(40) = ''
as
begin
	if @action = 1 begin			
		delete from ccRIADispMonitorRel where userId = @userId

		if @dispositionsIn <> '' and left(@dispositionsIn,1) <> ',' begin
			insert into ccRIADispMonitorRel select @userId,value,0 from dbo.fn_RIASplitDelimited( @dispositionsIn ,',')
		end

		if @dispositionsOUT <> '' and left(@dispositionsOUT,1) <> ',' begin
			insert into ccRIADispMonitorRel select @userId,value,1 from dbo.fn_RIASplitDelimited( @dispositionsOUT ,',')
		end

		select 1
	end

	if @action = 2 begin
		select relId, userId, dispositionId,type from ccRIADispMonitorRel where userId = @userId order by relId desc		
	end
end