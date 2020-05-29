/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Erick Muñoz
Date: 2017/07/25
Description:
	se agrega en la tabla ccRIACat_Areas el campo defCampaing para almacenar la campaña por default de cada area
	se modfiica el SP ccsp_RIA_ABCAreas para almacenar la campaña por default de cada area
	se modifica el SP ccsp_RIACampsManualCall para obtener la campaña por default en la marcación manual

Database: CCenterRia
Required version: 119.08-2

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 83
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = @versionfix-2 or @actualVersionFix = 8)
	begin
		begin tran
		begin try

	    set @process = 'ALTER TABLE ccRIACat_Areas -- CW-679 Default Campaign on manual call component'
    	set @Sql= '
    	IF COL_LENGTH(''[dbo].[ccRIACat_Areas]'', ''defCampaing'') IS NULL
		BEGIN
		    ALTER TABLE ccRIACat_Areas ADD defCampaing smallint
		END
		'
    	EXEC(@Sql)
		


		set @process = 'ALTER PROCEDURE ccsp_RIA_ABCAreas -- CW-679 Default Campaign on manual call component'
	    set @Sql= '
	    ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
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

			 select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
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
	    '
	    EXEC(@Sql)

	    set @process = 'ALTER PROCEDURE ccsp_RIACampsManualCall -- CW-679 Default Campaign on manual call component'
    	set @Sql= '
    	ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
		@UserID int,
		@onChat int = 0
		AS
		set nocount on

		if (@onChat = 0)
		begin
			declare @mod smallint
			select @mod = defCampaing from ccRIACat_Areas A
			where A.IDArea = (select IDArea from ccUsers where User_id = @UserID) 

			select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [default]
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			where (ca.user_id = @UserID and cam_modoManual = 1) or ca.cam_id=@mod
			order by cam_descripcion
		end
		else
			select distinct c.cam_id, c.cam_descripcion
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			where ca.user_id = @UserID and manualCallOnChat = 1
			order by cam_descripcion

		set nocount off
    	'
    	EXEC(@Sql)

    	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end