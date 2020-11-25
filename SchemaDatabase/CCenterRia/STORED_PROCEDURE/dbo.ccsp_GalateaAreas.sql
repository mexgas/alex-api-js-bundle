CREATE procedure [dbo].[ccsp_GalateaAreas] 
	@option int = NULL,
	@IDArea smallint = NULL,
	@Descripcion varchar(40) = NULL,
	@maxMails smallint = 3,
	@maxChats smallint = 3,
	@maxTweets smallint = 3,
	@defCampaing smallint = NULL,
	@movesfromArea bit = 0,
	@userId int = NULL,
	@groupAreas varchar (MAX) = NULL
AS

SET NOCOUNT ON;
	
	declare @opt int = @option -1
	if @option = 1 --Superuser info
	begin
		create table #campsIds(
			id int,
			cadena varchar(max)
		)
			
		declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
			
		set @idPivots =''
		set @idConcat=''
			
		select @idPivots=@idPivots+Id+',',
			@idConcat=@idConcat+'case when '+id+' is not null then convert(varchar(max),'+ id+') + '','' else '''' end + 
			'
			from (
			select distinct '['+convert(varchar(max),cam_id)+']' as Id from ccCamps   
			)x
			
		set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
		set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
			
		set @sql='
			select IDArea,'+@idConcat+' from 
			(	select IDArea, cam_id from ccCamps) as T
			PIVOT (
			max(cam_id) for cam_id in ('+@idPivots+') ) as P'

		insert into #campsIds
		exec(@sql)
			
		select a.IDArea Id, 
			a.AreaName Name, 
			a.StatusArea Status, 
			a.maxMails Mails, 
			a.maxChats Chats, 
			a.maxTweets Tweets, 
			a.CreateDate as CreateDate,			
			ISNULL(b.cadena, 0) as CampaignIds  
		from ccRIACat_Areas a --Falta el datetime 
		left join #campsIds b on a.IDArea = b.id

		drop table #campsIds
	end
	if @option = 2 -- Select de las areas
	begin
		IF OBJECT_ID('tempdb..#Areas') IS NOT NULL DROP TABLE #Areas;
		Create table #Areas(
			IDArea smallint,
			AreaName varchar(MAX),
			maxChats tinyint ,
			maxMails tinyint ,
			users int,
			admins int,
			camps int,
			acds int,
			maxTweets tinyint
		)
		insert into #Areas
		EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing
		select a.*,rca.CreateDate 
		from #Areas a
		inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea
	end
	if @option = 3 -- Insert new area
	begin
	IF OBJECT_ID('tempdb..#InsertAreas') IS NOT NULL DROP TABLE #InsertAreas;
		Create table #InsertAreas(
			result int,
			idAreas decimal
		)
		insert into #InsertAreas
		EXEC ccsp_RIA_ABCAreas 
			@option = @opt,
			@IDArea=@IDArea,
			@Descripcion=@Descripcion,
			@maxMails=@maxMails,
			@maxChats=@maxChats,
			@maxTweets=@maxTweets,
			@defCampaing=@defCampaing
		if (select result from #InsertAreas) = 1 and @movesfromArea = 1
			begin
				Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
			end
		Select * from #InsertAreas
	end
	if @option = 4 -- Delete Areas
	begin
		IF OBJECT_ID('tempdb..#AreasDelete') IS NOT NULL DROP TABLE #AreasDelete;
		SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, ',')
		
		
		if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
		  or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
		BEGIN
			Select -1 as result
		END
		ELSE
		BEGIN
			declare @DWorkGroups as varchar(500)
			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
			select user_id,cam_id,prioridad,skill,rel_id,IDWG
			from ccCampsAgente
			where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
			select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
			from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
			Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
			select user_id,cam_id,tipo,IDWG,monitored
			from ccSupervisorCam
			where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

			delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
			delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
			delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
			where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

			Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
			Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

			Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
			Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
			Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

			select @DWorkGroups = coalesce(@DWorkGroups + '','', '') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
			Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

			if (select valor from ccSettings where setting_id=95)=1
			begin
			Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
			Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
			Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
			end

			Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

			select 1 as result
		END
	end
	if @option = 5 -- update Areas
	begin
		if(@Descripcion is null)
		begin
			Update ccRIACat_Areas set maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=@defCampaing where IDArea=@IDArea
		end
		else 
		if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
			begin
				select -1 as result
				return
			end
		else
			begin
				update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=@defCampaing where IDArea=@IDArea	
			end
		if @maxChats is not null
			begin
				Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
			end
		if @movesfromArea = 1
		Begin
			Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
		End
		select 1 as result
	end
SET NOCOUNT ON;