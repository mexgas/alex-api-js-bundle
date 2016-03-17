/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:


-------
-------
-------
-------
-------
-------
-------


------se agrega scrip de email





Database: CCenterRia
Required version: 118.03

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 118--**********actualizar a 118 sin fix
set @versionfix = 5
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try		

		set @process = 'insert into ccSettings 178-------- '
		set @sql='if not exists (select * from ccSettings where setting_id = 178) begin
			insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values (178,'''',''Ubicacion del Twitter service'',1,''X'',''IP del servidor donde se encuentra el Email Service se actualiza automaticamente cuando se abre el Twitter service''
,''Twitter Service location (automatically updated when the email service starts)'',
1,''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'')	
		end'
		EXEC(@sql)

		set @process = 'insert into ccSettings 179-------- '
		set @sql='if not exists (select * from ccSettings where setting_id = 179) begin
			insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values (179,''3'',''Número de intentos para desactivar cuenta Twitter'',1,''GRL'',''Número de reintentos para desactivar cuenta Twitter''
,''Number of attempts to disable Twitter account'',
1,''^\d{1}$'')
		end'
		EXEC(@sql)

			set @process = 'INSERT INTO ccSettings 180-------- '
		set @sql='if not exists (select * from ccSettings where setting_id = 180) begin
		INSERT INTO ccSettings (setting_id, valor, descripcion, Status,Tipo, detalle, description, bLoadSettings, validate) 
VALUES (180, 1, ''Número máximo de WG por ACD/Campañas'', 1, ''ADM'', ''Número máximo de WG que se puede asignar po campaña/ACD'', ''Maximum number of workgroups per campaign/ACD'', 1,''^\d{1,2}$'');
 
		end'
		EXEC(@sql)

		set @process = 'update ccMenus-------- '
		set @sql='update ccMenus set parent=80,ordengral=85 where type=1 and menu_id=72'
		EXEC(@sql)

		

		set @process = 'ALTER function [dbo].[fGet_CampAcd_Area]-------- '
		set @sql='ALTER function [dbo].[fGet_CampAcd_Area] (@user int, @tipo int)
returns @camps table (cam_id int)
as
begin
if (select login from ccusers where user_id=@user) = ''root''
      set @user=0
--solo se corrigio para el usuario root
if @tipo = 3 and @user =0
	set @tipo = 1
if @tipo = 4 and @user =0
	set @tipo = 2

if @tipo = 1 begin
      insert @camps select distinct c.cam_id 
      from ccusers u join ccCamps c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end

else if @tipo = 2 begin
      insert @camps select distinct c.Inbound_id 
      from ccusers u join ccinbound c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end
if @tipo = 3 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp
      from ccusers u with(nolock)
	  inner join ccCamps c with(nolock) on u.IDArea = c.IDArea
	  inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
	  inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=1
      where u.User_id=@user
      end

else if @tipo = 4 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp cam_id from ccUsers u with(nolock)   
	  inner join ccInbound c with(nolock) on c.IDArea= c.IDArea
      inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
      inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=0      
      where u.User_id=@user 
      end
return
end'
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]-------- '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
@contactMeanId int=0,
@name	varchar(30)=null,
@conexionInfo	varchar(255)=null,
@inboundId	int=0,
@connUser	varchar(60)=null,
@ConnPass	varchar(30)=null,
@numMessages	tinyint=null,
@timeAlertMessage	tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
	select @isActiveMail = valor from ccSettings where setting_id=152
	if @isActiveMail = 1 begin
		select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
	end
	select @isActiveMail as isActiveMail
	return (0)
end
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = 1 and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
		if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
		if @name is null set @name=''''
		if @conexionInfo is null set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0

		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut)
		select 1,''insert''
	end
		else select -1,''insert''
	end
	else begin
		if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin			
			select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut)
				from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId				
			update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
				numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut
				where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
			select 1,''update''
		end
		else select -1,''update''
	end
	return (0)
end

else if @action = 5 begin--parameters check conection Mail In
	select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
	select conexionInfo,connUser,connPass
		from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
	select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
		from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
	if not exists(select * from ContactMeanOut where connUser=@connUser) begin
		insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
			values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
		select 1
		return(0)
	end
	else select -1
end
else if @action = 9 begin--update account mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

		select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
			@conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
			@connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
			from ContactMeanOut where contactMeanOutId = @contactMeanId

		update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
		 where contactMeanOutId = @contactMeanId
		 select 1,''update ''
	end
	else select -1
end
else if @action = 10 begin	--insert relation mail out and ACD
	if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
		insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
	end
end
else if @action = 11 begin --delete relation mail out and ACD
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
	delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
		update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
		select 1
	end
	else select -1
end
else if @action = 14 begin
	select * from relationContactMeanOutInbound
end
else if @action = 15 begin
	select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--	update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin	--
	select A.conexionInfo,A.connUser,A.connPass from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin	--
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass from contactMeanOut A where isActive=1

end
else if @action = 19 begin	--
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId

end
else if @action = 20 begin --relation MailOut and ACD
	select B.inboundId,A.conexionInfo,A.connUser,A.connPass
	from ContactMeanOut A join relationContactMeanOutInbound B
	on B.contactMeanOutId=A.contactMeanOutId
	where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
	update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
END'
		EXEC(@sql)



		set @process = 'alter PROCEDURE [dbo].[ccsp_GetAllAgentsECRelations]  -------- '
		set @sql='create PROCEDURE [dbo].[ccsp_GetAllAgentsECRelations]  
@User_id varchar(300),@action int =0  
AS  
set nocount on  
  
declare @idioma as bit, @tipo as varchar(6)  
declare @individual varchar(20) 
set @individual=null

create table #AgentRel(
Tipo smallint,
Inbound_id int,
descripcion varchar(30),                                     
Login varchar(30),               
user_id int,
prioridad smallint,
skill int,
cli_i int)

if @action=0 begin
WHILE LEN(@User_id) > 0
BEGIN
    IF PATINDEX(''%|%'',@User_id) > 0
    BEGIN
        SET @individual = SUBSTRING(@User_id, 0, PATINDEX(''%|%'',@User_id))
        insert into #AgentRel
        select distinct ''Tipo''=1, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, E.cli_id  
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id  
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1  
		Where A.user_id = @individual and A.status > 0  
		union  
		select distinct ''Tipo''=2, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id  
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id  
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1  
		Where A.user_id = @individual and A.status > 0  
		order by ''Tipo''  
        SET @User_id = SUBSTRING(@User_id, LEN(@individual + ''|'') + 1, LEN(@User_id))
    END
    ELSE
    BEGIN
        SET @individual = @User_id
        SET @User_id = NULL
        insert into #AgentRel
        select distinct ''Tipo''=1, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, E.cli_id  
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id  
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1  
		Where A.user_id = @individual and A.status > 0  
		union  
		select distinct ''Tipo''=2, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id  
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id  
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1  
		Where A.user_id = @individual and A.status > 0  
		order by ''Tipo''  
        SET @User_id = SUBSTRING(@User_id, LEN(@individual + ''|'') + 1, LEN(@User_id))
    END
END  
select * from #AgentRel
drop table #AgentRel
end  
else begin  
 select distinct 1 tipo, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, isnull(E.cli_id,0) cli_id  
 ,right(''0''+cast(1 as varchar(1)),1) + right(''00000''+cast(E.Inbound_id as varchar(5)),5)  
 + right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias  
  from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id  
  join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1  
  Where A.user_id = @User_id and A.status > 0  
  union  
 select distinct 2 tipo, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id  
 ,right(''0''+cast(2 as varchar(1)),1) + right(''00000''+cast(C.cam_id as varchar(5)),5)  
 + right(''00''+cast(prioridad as varchar(2)),2) + right(''00''+cast(skill as varchar(2)),2) sPertenencias  
  from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id  
  join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1  
  Where A.user_id = @User_id and A.status > 0  
  order by ''Tipo''  
  
end'
		EXEC(@sql)


	
		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCWorkGroups] -------- '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCWorkGroups]
		@option smallint,
		@IDWG smallint,
		@user_Id smallint = 0,
		@Descripcion varchar(45) = null,
		@IDArea smallint = null,
		@IDCampEsp varchar(2000),
		@Type smallint
		as
		set nocount on
		if @option = 0 -- All WokGroup
		 begin
			if(@IDArea = 0 or @IDArea is null)
				select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1
			else
				select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1 and IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea=@IDArea)
			
			return(0)
		 end

		if @option = 1 -- Selected WokGroup
		 begin
			if @type = 0
			begin
				select IDWG, WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and IDWG=@IDWG
			end
			else if @type = 1
			begin
				select w.IDWG, w.WGName, a.IDArea
				from ccRIACat_WorkGroup w
				join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
				join ccRIACat_Areas a on a.IDArea = aw.IDArea
				where w.StatusWorkGroup=1
			end
			else if @type = 2
			begin
				select w.WGName, a.IDArea, a.AreaName
				from ccRIACat_WorkGroup w
				join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
				join ccRIACat_Areas a on a.IDArea = aw.IDArea
				where w.StatusWorkGroup=1 and w.IDWG=@IDWG
			end
			else if @type = 3
			begin
				select count(*)
				from ccRIAWorkGroupUsers
				where idwg=@IDWG
				and user_id=@user_Id
			end

			return(0)
		 end

		if @option = 2 -- insert WorkGroup
		 begin
			if exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 begin
				select -1 --, Nombre en Uso
				return(0)
			 end
			
			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @IDWG = scope_identity()

			else 
			 begin
				select -2 --, No se inserto correctamente
				return(0)
			 end

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
			select 1 --, WG insertado
			return(0)
		 end

		if @option = 3 -- UpdateWokGroup
		 begin
			Update ccRIACat_WorkGroup set WGName=@Descripcion where StatusWorkGroup=1 and IDWG=@IDWG
			return(0)
		 end

		if @option in (4,8) -- Delete WorkGroup (4:all / 8:only from acd/camps)
		 begin

		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG = @IDWG
			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.IDWG = @IDWG
		 	
			Delete from ccCampsAgente where IDWG = @IDWG
			Delete from ccInboundAgentes where IDWG = @IDWG

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG = @IDWG

			Delete from ccSupervisorCam where IDWG = @IDWG
			Delete from ccRIACampEspWG where IDWG = @IDWG
			
			if @option=4
			 begin
				Delete from ccRIAAreaWorkGroup where IDWG = @IDWG 
				Delete from ccRIAWorkGroupUsers where IDWG = @IDWG
				Update ccRIACat_WorkGroup set StatusWorkGroup=0 where IDWG=@IDWG
			 end
			return(0)
		 end

		if @option = 5 -- Insert WorkGroup in Camp or ACDGroup	
		 begin
		 if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) >= (select valor from ccSettings where setting_id=180) -- limit
			 begin
				select 3
				return(0)
			 end

			if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) >= (select valor from ccSettings where setting_id=64) -- limit
			 begin
				select 2
				return(0)
			 end					

			if exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- Ya existe el grupo en el ACD o Especialidad
			 begin
				select 1
				return(0)
			 end

			insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
			if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
				insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
			end
				

			exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
			if @Type not in (0, 1) -- ACDGroup
				return(0)
				
			if @Type=0 --ACDGroup
			begin

				if @IDWG is null or @IDWG = 0
				 begin
					select 48
					return(0)
				 end
				 
				insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
				SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
				FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
				 join ccusers s on u.user_id = s.user_id
				WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
				and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

				insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select b.user_id, @IDCampEsp, 0, @IDWG
				from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
				 join ccusers s on b.user_id = s.user_id
				where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
				 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
			 
				return(0)
			end
			
			if @IDWG is null or @IDWG = 0
			 begin
				select 18
				return(0)
			 end

			-- if @Type = 1 -- Camp
			insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
			SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
			FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
			join ccusers s on u.user_id = s.user_id
			WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
			 and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
			
			insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
			select b.user_id, @IDCampEsp, 1, @IDWG
			from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
			 join ccusers s on b.user_id = s.user_id
			where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
			 and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)

			return(0)
		 end

		if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @IDWG = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @IDWG
				return(0)
			 end

		 	if @IDWG=1
			 begin
				select ''-1''
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @IDWG = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
			select @IDWG
			return(0)
		 end

		if @option = 7 -- Delete WokGroup from ACD or Camp
		 begin
			if @Type = 1
				begin
					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG=@IDWG and A.cam_id=@IDCampEsp
					Delete from ccCampsAgente where IDWG=@IDWG and cam_id=@IDCampEsp
				end
			else if @Type = 0 
				begin
					insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.IDWG=@IDWG and A.inbound_id=@IDCampEsp
					Delete from ccInboundAgentes where IDWG=@IDWG and inbound_id=@IDCampEsp
				end

			Delete from ccRIACampEspWG where IDWG=@IDWG and IdCampEsp=@IDCampEsp and Tipo=@Type

			return(0)
		 end
		 
		return(0)
		set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
		@action int = 0,
		@option int = 0,
		@idF int = 0,
		@idL int = 0,
		@idService int = 0,
		@name varchar(25) = NULL,
		@top varchar(max) = NULL
		AS
		declare @sql nvarchar(max)
		set @sql = ''''
		if @action = 1 --obtiene los nodos a insertar en BX
		begin
			if @option = 1
			begin
				set @sql = ''select top '' + @top + '' chatId, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 0''
				exec(@sql)
			end
		end
		if @action = 2 --actualiza los nodos insertados en BX
			if @option = 1
			begin
				update ccChatsNode with(rowlock) set [status] = 1, dateOut = getDate() where chatId between @idF and @idL and [status] = 0
			end
		if @action = 3 --trae el nombre de la base de datos en BX
		begin
			select Xname from ccBaseXDB where serviceId = @option and isFull = 0
		end
		if @action = 4 --inserta el nombre del xml en BX
		begin
			insert into ccBaseXDB (serviceId, dateStart, Xname) values (@option, getDate(), @name)	
		end
		if @action = 5 --obtener servicios disponibles
		begin
			declare @chat int
			declare @rec int
			declare @email int
			
			set @chat = 0
			set @rec = 2
			set @email = 0

			select @chat = case when valor = 1 then 1 end
			from ccSettings
			where setting_id = 145

			select @email = case when valor = 1 then 3 end
			from ccSettings
			where setting_id = 155

			select id, ref 
			from ccFinderServices
			where id in (@chat, @rec, @email)
		end
		if @action = 6 begin --obtener valores con status 2
		set @sql = ''select top '' + @top + '' chatId,replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 2''
			exec(@sql)
		end
		if @action = 7 --actualiza los nodos insertados en BX
			if @option = 1
			begin
				update ccChatsNode with(rowlock) set [status] = 3, dateOut = getDate() where chatId between @idF and @idL and [status] = 2
			end


		--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)'
		EXEC(@sql)
	
			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version
			exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off