/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 24
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	 set @process = 'CW-5749 Setting Ubicación del CallCenterSvrDotNet'
     set @sql = 'if not exists(select * from ccSettings where setting_id=20) begin
insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values(20,''127.0.0.1'',''Ubicación del CallCenterSvrDotNet'',1,''X'',''IP o Hostname del servidor donde se encuentra el CallCenterSvrDotNet'',
''CallCenterSvrDotNet location'',0,''.*'')
end'
    EXEC(@sql)

	set @process = 'CW-5749 ccsp_ccActivityDataQuery - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ccActivityDataQuery'')
            begin
          DROP PROCEDURE ccsp_GalateaLoadUsersForManagement;
            end'
    EXEC(@sql)

    set @process = 'CW-5749 '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ccActivityDataQuery]
@action int,@userId int=0,@camId int=0,@dnisId int=0,@WgId int=0,@tipo int =null
,@camIdOuts varchar(1000)='''',@camIdIns varchar(1000)=''''
AS
set nocount on

declare @valdiate int
declare @packageData varchar(2000)
declare @nTipoCallTotal int
set @packageData =''''
set @valdiate=0
set @nTipoCallTotal=0

if @action=1 begin	
	if exists(select * from cccamps nolock where cam_bNew=1) begin
		set @valdiate=1
		Update ccCamps SET cam_bNew=0 Where cam_bNew=2
		Update ccCamps SET cam_bNew=2 Where cam_bNew=1
	end	
	select @valdiate as isUpdate
end
else if @action=2 begin		
	if exists(select * from cccamps nolock where cam_bNew=3) begin
	set @valdiate=1
		Update ccCamps SET cam_bNew=0 Where cam_bNew=4
		Update ccCamps SET cam_bNew=4 Where cam_bNew=3
	end
	select @valdiate as isUpdate
end
else if @action=3 begin		
SELECT User_id, TipoLlamadas FROM ccUsers WHERE User_ID = @userId
end
else if @action=4 begin	
SELECT A.Login, A.User_id, prioridad, skill, A.TipoLlamadas, C.cam_id, C.cam_descripcion, C.cli_id 
FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
JOIN ccUsers A  ON A.User_id = CA.User_id 
AND A.TipoUser_Id =1 AND C.cam_id =  @camId
order by A.Login, A.User_id, CA.prioridad, CA.skill, C.cam_id
end
else if @action=5 begin	
SELECT Login, TipoLlamadas, User_id, password, Nombres +'' ''+ ApellidoPaterno FROM ccUsers nolock WHERE User_id = @userId
end
else if @action=6 begin	
SELECT Inbound_id, descripcion, cli_id FROM ccInbound nolock WHERE Inbound_id =@camId
end
else if @action=7 begin	
SELECT Inbound_id, descripcion, cli_id, tnotas, nMaxQue FROM ccInbound WHERE Inbound_id = @camId
end
else if @action=8 begin	
SELECT dni_id, dni_numero, T.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id = T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=9 begin	
SELECT dni_id, dni_numero, dni_tipo, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id=T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=10 begin	
SELECT dni_id, dni_numero, D.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join cctipoDnis TD on D.tipodni_id = TD.tipodni_id
WHERE dni_tipo=2
end
else if @action=11 begin	
SELECT Inbound_id, descripcion, tNotas, nMaxQue FROM ccInbound
end
else if @action = 12 begin 
	; with WgUser AS(
	select 
	WG.IDWG,A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
	inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
	inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
	where WG.IDWG<>@WgId
	)
	, wGCamp AS(
	select IDWG, IdCampEsp,Tipo from ccRIACampEspWG A
	where A.IDWG in(select IDWG from WgUser) or A.IDWG=@WgId
	), dataDiferent as
	(
	select distinct	
	convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
	+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
	+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
	as CampAndType
	from wGCamp A
	left join WgUser B on A.IdCampEsp=B.IdCampEsp and A.Tipo=B.Tipo	
	left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1
	left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0
	where B.IdCampEsp is null
	)
	select @packageData=CampAndType+'',''+@packageData from dataDiferent	
		
	select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
	from ccRIAWorkGroupUsers WG
	inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
	inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
	where WG.User_id=@userId
	group by A.Tipo 

	select @packageData as packageData, @nTipoCallTotal as nTipoCallTotal

end

else if @action = 13 begin 
	; with WgCamp As(
	select IDWG,IdCampEsp,tipo from ccRIACampEspWG A
	where tipo=@tipo and IdCampEsp=@camId and IDWG<>@WgId
	)
	, WgUserCamp as(
	select C.Login,WGUser.User_id,WgCamp.* from ccRIAWorkGroupUsers WGUser
	inner join WgCamp on WGUser.IDWG=WgCamp.IDWG 
	inner join ccUsers C on WGUser.User_id=C.User_id and C.TipoUser_id=1
	), dataDiferent as(	
	
	select distinct convert(varchar, WG.User_id)
	+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1))
	+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))	CampAndType
	from ccRIAWorkGroupUsers WG	
	inner join ccUsers C on WG.User_id=C.User_id and C.TipoUser_id=1
	left join ccCampsAgente campAgent on campAgent.cam_id =@camId 
	left join ccInboundAgentes inboundAgent on inboundAgent.inbound_id =@camId 
	where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from WgUserCamp)

	)
	select @packageData=CampAndType+'',''+@packageData from dataDiferent

	select @packageData  as packageData
end
else if @action = 14 begin --Delete WG
	; with wgCam as (
	select Value as camId,1 calltype from dbo.fn_RIASplitDelimited(@camIdOuts,'','')
	union
	select Value as camId,0 calltype from dbo.fn_RIASplitDelimited(@camIdIns,'','')
	)
	, relationUser as(

	select campWg.IdCampEsp as camId,campWg.Tipo from ccRIAWorkGroupUsers WG
	inner join ccRIACampEspWG campWg on campWg.IDWG=Wg.IDWG 	
	where WG.User_id=@userId
	)
	, dataDiferent  as
	(	
	select distinct convert(varchar, wgCam.camId)+''-''+convert(varchar,wgCam.callType+1)   as CampAndType
	from wgCam
	left join relationUser A on wgCam.camId=A.camId and wgCam.calltype=A.Tipo
	where A.camId is null
	)

	select @packageData=CampAndType+'',''+@packageData from dataDiferent

	select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
	from ccRIAWorkGroupUsers WG
	inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
	inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
	where WG.User_id=@userId
	group by A.Tipo 

	select @packageData  as packageData, @nTipoCallTotal as nTipoCallTotal
end'
    EXEC(@sql)   

    set @process = ''
    set @sql = ''
    EXEC(@sql)
    
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
