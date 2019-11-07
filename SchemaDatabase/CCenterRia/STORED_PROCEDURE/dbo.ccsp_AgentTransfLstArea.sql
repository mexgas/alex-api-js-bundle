CREATE PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int

set @value = 0
select @value = case when valor='1' then 1 else 0 end from ccSettings where setting_id = 191

	IF @value = 0
		begin
			select x.extid, Nombres + ' ' + isNull( apellidoPAterno, '') as name from ccusers cu join
			(
				select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
				join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
			)
			x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
			Order by name asc
		end

	if @value = 1
		begin
			if (@current <> 0)
				begin
					select x.extid, Nombres + ' ' + isNull( apellidoPAterno, '') as name from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
					Order by name asc
				end
			else
				begin
					select x.extid, Nombres + ' ' + isNull( apellidoPAterno, '') as name from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select IDArea from ccUsers where User_id = @userID)
					Order by name asc
				end
		end
END
set nocount off