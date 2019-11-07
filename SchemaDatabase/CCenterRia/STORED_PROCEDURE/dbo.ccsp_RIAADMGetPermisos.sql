CREATE PROCEDURE [dbo].[ccsp_RIAADMGetPermisos]
@user_id varchar(255),
@Type int,
@mask int = 0,
@xferMask int = 0,
@xstartStopRecording int = 0,
@CanChangeStatus bit = null,
@XferAgents int = null
AS
set nocount on

If @Type = 1
 begin
	Select distinct A.User_id as ID, Login, Nombres + ' ' + isNull(apellidoPaterno,'') + ' ' +
	isNull(ApellidoMaterno, '') as 'Nombre', cast(dialMask & 1 as int) as 'Restringe celular',
	cast( (dialMask & 2) /2 as int) as 'Restringe ld', cast((dialMask & 4) / 4 as int) as 'Restringe local',
	cast( xfermask as int) as 'Recibe transferencia', cast(CanChangeStatus as tinyint) CanChangeStatus,
	cast(XferAgents as tinyint) XferAgents,
	cast(startStopRecording as tinyint) startStopRecording
	from ccUsers A
	join ccRIAWorkGroupUsers B on A.user_id = B.user_id
	where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
	return(0)
 end

 if @Type = 3
begin
	if(@xstartStopRecording <> -1)
		UPDATE ccUsers SET startStopRecording = @xstartStopRecording where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
	if(@xferMask <> -1)
		UPDATE ccUsers SET xfermask = @xferMask where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
	if(@mask <> 0)
		UPDATE ccUsers SET dialMask = case
			when @mask > 0 and dialmask & @mask = 0 then dialmask + @mask
			when @mask < 0 and dialmask & abs(@mask) > 0 then dialmask - abs(@mask)
			else dialmask end
			where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
	if(@XferAgents <> 0)
		UPDATE ccUsers SET XferAgents = case
			when @XferAgents > 0 and XferAgents & @XferAgents = 0 then XferAgents + @XferAgents
			when @XferAgents < 0 and XferAgents & abs(@XferAgents) > 0 then XferAgents - abs(@XferAgents)
			else XferAgents end
			where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
	return(0)
end

--if @Type = 2
If @xferMask=-1 and @mask=-1 and @xstartStopRecording=-1
 begin
	update ccUsers set NotReadyRestricted = ISNULL(@CanChangeStatus, NotReadyRestricted) , XferAgents = ISNULL(@XferAgents, XferAgents)
	where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, ','))
	return(0)
 end

If @xferMask=-1 and @xstartStopRecording=-1
 begin
	UPDATE ccUsers SET dialMask = @mask where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, ','))
 end


if @mask=-1 and @xstartStopRecording=-1
 begin
	UPDATE ccUsers SET xfermask = @xferMask where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, ','))
 end

if @mask=-1 and @xferMask=-1
begin
	UPDATE ccUsers SET startStopRecording = @xstartStopRecording where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, ','))

end

return(0)
set nocount off