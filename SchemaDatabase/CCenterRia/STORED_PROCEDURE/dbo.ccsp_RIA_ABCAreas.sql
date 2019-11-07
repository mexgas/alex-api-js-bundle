CREATE PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
		@option smallint,
		@IDArea smallint,
		@Descripcion varchar(40),
		@maxMails smallint = 3,
		@maxChats smallint = 3,
		@maxTweets smallint = 3,
		@defCampaing smallint = NULL
		AS

		set nocount on



		if @option = 1 begin --Selected Area
		 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
		 isnull(users,0) users, isnull(admins,0) admins,
		 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets
		 from ccRIACat_Areas a (nolock)
		 left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
		 left join (select IDArea,count(case when TipoUser_id = 1 then 1 else null end) users, count(case when TipoUser_id > 1 then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) userswg on userswg.IDArea=a.IDArea
		 left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
		 left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
		 where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
		 when 0 then isnull(a.IDArea,0) else @IDArea end
		 order by AreaName
		 return(0)
		end
		else if @option=2 begin --Insert Area
			 if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion) begin
			  select -1--, Nombre en Uso
			  return(0)
			 end
			Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,defCampaing) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@defCampaing)
			select 1, scope_identity()--, Area Insertada
			return(0)
		end
		else if @option=3 begin--Update Area
			if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
				Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea
			else
				Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea

			if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
				Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
		 return(0)
		end

		else if @option=4 begin --Delete Area
		 if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
		  or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
		 begin
		  select -1
		  return(0)
		 end

			declare @DWorkGroups as varchar(500)

			 insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			 select user_id,cam_id,prioridad,skill,rel_id,IDWG
			 from ccCampsAgente
			 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
			 select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
			 from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
			 Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
			 select user_id,cam_id,tipo,IDWG,monitored
			 from ccSupervisorCam
			 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

			 delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
			 delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
			 delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
			 where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

			 Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
			 Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

			 Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
			 Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
			 Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

			 select @DWorkGroups = coalesce(@DWorkGroups + '','', '') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
			 Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

			 if (select valor from ccSettings where setting_id=95)=1
			 begin
			  Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
			  Update ccCamps set IDArea=NULL where IDArea=@IDArea
			  Update ccUsers set IDArea=NULL where IDArea=@IDArea
			 end

			 Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

			 select @DWorkGroups

		 return(0)
		end
		else if @option=5 begin -- Select Areas Campaings and show its default Campaing 
			select A.IDArea as IDArea, C.cam_id as campID, C.cam_descripcion as campName,
			case when A.defCampaing=C.cam_id then 1 else 0 end as isDefault
			from ccRIACat_Areas A (nolock)
			inner join ccCamps C on A.IDArea=C.IDArea
			order by IDArea asc, isDefault desc, campName
			return(0)
		 end