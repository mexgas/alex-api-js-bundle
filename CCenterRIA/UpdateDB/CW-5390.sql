CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
@user_id varchar(255),
@Type int
AS
set nocount on

Select distinct A.User_id as AgentId, Login as Username, Nombres + ' ' + isNull(apellidoPaterno,'') + ' ' +
isNull(ApellidoMaterno, '') as FullName, cast(dialMask & 1 as int)^1 as AllowCellPhoneCalls,
cast( (dialMask & 2) /2 as int)^1 as AllowLongDistanceCalls, cast((dialMask & 4) / 4 as int)^1 as AllowLocalCalls,
cast( xfermask as int)^1 as AllowTransferCalls, cast(CanChangeStatus as tinyint) CanChangeStatus,
cast(XferAgents as tinyint) XferAgents,
ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording
from ccUsers A
join ccRIAWorkGroupUsers B on A.user_id = B.user_id
where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
return(0)

set nocount off



-----------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[ccsp_GalateaGetAdminRelations]
@Option smallint,
@areaId AS INT = 0,
@AdminId AS INT = 0
as
declare @agentes varchar(max)
declare @wgs varchar(max)
declare @count int
declare @id int
declare @wg int

if @option =1 --Obtiene las relaciones de los Administradores con los WG
begin
	SELECT 
	ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
	IDWG,@agentes as agents
	into #Relations
	FROM ccRIAAreaWorkGroup 

	if not exists(select * from ccRIACat_Areas) or (select count(idWG) from #Relations) = 0
	begin
		select Null as IDWG ,@agentes as agents, @wgs as idsWg
		return (0)
	end

	select @count = count(idWG) from #Relations
	set @id =1
	while @id<=@count
	begin
		select @wg =idwg from #Relations where Row =@id
		select @agentes=null
		select @agentes = coalesce(@agentes + ',', '') +  convert(varchar(12),wgu.user_id)
		from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
		where TipoUser_id = 1 and wgu.IDWG =@wg
		order by u.user_id

		Update #Relations set agents= @agentes where IDWG= @wg
		set @id=@id+1
	end
	if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
		BEGIN
			select  Cast(Re.IDWG as varchar(10)) as idwg,agents
			from #Relations Re
			right JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = Re.IDWG
			where wg.StatusWorkGroup = 1
		END

		ELSE
		BEGIN
			SELECT @AdminId = ISNULL(@AdminId, 0)			
		
			select  Cast(Re.IDWG as varchar(10)) as idwg,agents
			from #Relations Re
			Left JOIN  ccRIAWorkGroupUsers wg ON wg.IDWG = Re.IDWG
			WHERE wg.User_id = @AdminId
		END		

end


-----------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
	@user_id varchar(MAX),
	@permissionName VARCHAR(255),
	@permissionValue INT
AS
SET NOCOUNT ON

IF @user_id IS NOT NULL
BEGIN
	
	UPDATE
		ccUsers
	SET DialMask =
		CASE
			WHEN @permissionName = 'AllowCellPhoneCalls' or @permissionName = 'AllowLongDistanceCalls' or @permissionName = 'AllowLocalCalls' 
			THEN @permissionValue
			ELSE DialMask
		END,
		XferMask =
		CASE
			WHEN @permissionName = 'AllowTransferCalls' 
			THEN @permissionValue
			ELSE XferMask
		END,
		XferAgents =
		CASE
			WHEN @permissionName = 'XferAgents' 
			THEN @permissionValue
			ELSE XferAgents
		END,
		startStopRecording =
		CASE
			WHEN @permissionName = 'startStopRecording' 
			THEN @permissionValue
			ELSE startStopRecording
		END
	WHERE User_id  IN (select value from dbo.fn_RIASplitDelimited(@user_id,','))

END


SET NOCOUNT OFF
