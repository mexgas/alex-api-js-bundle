CREATE PROCEDURE [dbo].[ccsp_Multimedia]
		@action int,@inboundId tinyint=0,@userId int =0,@meanContactTypeId tinyint = 1
		AS
		BEGIN

		SET NOCOUNT ON;

		if @action = 1 begin --Cuentas acd por tipo

			if @inboundId=0 begin
				select distinct A.inbound_id as Id,A.chat as mode,cast(A.status as bit) [Status],cast(isnull(b.isActive,0) as bit) IsActive,cast(isnull(B.numMessages,3) as int) MessageLimit,
					case A.chat when 0 then 'call' when 1 then 'chat' when 2 then 'call and chat' when 3 then 'mail' when 4 then 'twitter' else 'multimedia' end  as typeMedia
					,A.IDArea as AreaId
					from ccInbound A
					left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
					where isnull(A.IDArea,0)> 0 and B.meanContactTypeId=@meanContactTypeId
			end
			else begin
				select A.inbound_id as Id,A.chat as mode,cast(A.status as bit) [Status],cast(isnull(b.isActive,0) as bit) IsActive,cast(isnull(B.numMessages,3) as int) MessageLimit,
					case A.chat when 0 then 'call' when 1 then 'chat' when 2 then 'call and chat' when 3 then 'mail' when 4 then 'twitter' else 'multimedia' end  as typeMedia,
					A.IDArea as AreaId
					from ccInbound A
					left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
					where A.inbound_id = @inboundId and B.meanContactTypeId=@meanContactTypeId

			end
		end
		else if @action = 2 begin --Relacion entre agenetes y acd
			if @inboundId=0 and @userId = 0 begin --- Carga todas las relaciones
				select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
				from ccRIAWorkGroupUsers A
				inner join ccusers B on A.User_id=B.User_id
				inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
				inner join ccInbound D on C.idCampEsp = D.inbound_id
				left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
				where B.TipoUser_id=1 and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
				order by  C.idCampEsp
			end
			else if @inboundId>0 and @userId = 0 begin
				select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
				from ccRIAWorkGroupUsers A
				inner join ccusers B on A.User_id=B.User_id
				inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
				inner join ccInbound D on C.idCampEsp = D.inbound_id
				left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
				where B.TipoUser_id=1 and D.Inbound_id=@inboundId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
				order by  C.idCampEsp
			end
			else if @inboundId=0 and @userId > 0 begin
				select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
				from ccRIAWorkGroupUsers A
				inner join ccusers B on A.User_id=B.User_id
				inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
				inner join ccInbound D on C.idCampEsp = D.inbound_id
				left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
				where B.TipoUser_id=1 and B.User_id=@userId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
				order by  C.idCampEsp
			end
		end
		else if @action =3 begin -- Cargar relacion de agentes
			if	@userId is null or @userId=0 begin
				select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
					left join ccriacat_areas area (nolock) on area.idarea=us.idarea where TipoUser_id=1
			end
			else begin
			select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
					left join ccriacat_areas area (nolock) on area.idarea=us.idarea
					where TipoUser_id=1 and  us.User_id=@userId
			end
		end
		END