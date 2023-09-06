set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 93
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

        --------------------------------------------BEGIN MARCO CHAGOLLA ------------------------------
        
		set @process = 'KR066000 Drop SP CW_trsp_AdmRecSearchAllRecs'
		set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''CW_trsp_AdmRecSearchAllRecs'')
				BEGIN
					DROP PROCEDURE [dbo].[CW_trsp_AdmRecSearchAllRecs]
				END'
		EXEC(@sql)
		
		SET @process = 'KR066000 - Create SP CW_trsp_AdmRecSearchAllRecs'
        SET @sql = 'CREATE PROCEDURE [dbo].[CW_trsp_AdmRecSearchAllRecs]
			@Sup_id int,
			@dateStart datetime,
			@dateEnd datetime,
			@IdCallList varchar(MAX) =null,
			@UserList varchar(MAX) =null,
			@IDWGList varchar(MAX) =null,
			@TypeCall int = null,
			@CampaingsList varchar(MAX) =null,
			@ACDList varchar(MAX) =null,
			@DispositionList varchar(MAX) =null,
			@SubdispositionList varchar(MAX) =null,
			@GrabId bigInt = null,
			@TopRecords int = 0

	AS
			declare @encrypted bit
			select @encrypted = par_valor from TREC_PARAMETROS where par_id = 15
	;
			
	IF OBJECT_ID(''tempdb..#userAgent'') IS NOT NULL
		DROP TABLE #userAgent
	IF OBJECT_ID(''tempdb..#tmpRecords'') IS NOT NULL
		DROP TABLE #tmpRecords
	IF OBJECT_ID(''tempdb..#WorkGroupCamps'') IS NOT NULL
		DROP TABLE #WorkGroupCamps
	IF OBJECT_ID(''tempdb..#tmpWGconcat'') IS NOT NULL
		DROP TABLE #tmpWGconcat

	CREATE TABLE #userAgent(UserId smallint);

	IF((select [User_id] from ccUsers WHERE [Login] = ''root'') = @Sup_id)
	BEGIN
		INSERT INTO #userAgent(UserId)
			select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta
	END
	ELSE
	BEGIN
		INSERT INTO #userAgent(UserId)
		select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta where IDWG in(
			select distinct IDWG from ccRIAWorkGroupUsersConsulta where User_id = @Sup_id)
	END

	CREATE TABLE #WorkGroupCamps(IDWG smallint, WGName varchar(50),  cam_id smallint, campType smallint, campName varchar(50));

	INSERT INTO #WorkGroupCamps(IDWG, WGName, cam_id, campType, campName)
	SELECT WG.IDWG,WG.WGName, cCamp.cam_id, cWG.Tipo, cCamp.cam_descripcion
	FROM cccamps cCamp
	inner join ccRIACampEspWG cWG on cWG.IdCampEsp = cCamp.cam_id AND cWG.Tipo = 1
	inner join ccRIACat_WorkGroup WG on WG.IDWG = cWG.IDWG
	UNION
	SELECT WG.IDWG,WG.WGName, cCamp.Inbound_id, cWG.Tipo, cCamp.descripcion
	FROM ccinbound cCamp
	inner join ccRIACampEspWG cWG on cWG.IdCampEsp = cCamp.Inbound_id AND cWG.Tipo = 0
	inner join ccRIACat_WorkGroup WG on WG.IDWG = cWG.IDWG


	SELECT  cam_id, campType,
		STUFF((
		SELECT '', '' + wgc.WGName
		FROM #WorkGroupCamps wgc WHERE (wgc.cam_id = wgc1.cam_id and wgc.campType = wgc1.campType) 
		FOR XML PATH ('''')),1,2,'' '') AS WGNames,
		STUFF((
		SELECT '', '' + CAST(wgc.IDWG AS VARCHAR(MAX))
		FROM #WorkGroupCamps wgc WHERE (wgc.cam_id = wgc1.cam_id and wgc.campType = wgc1.campType)
		FOR XML PATH ('''')),1,2,'' '') AS WGIDs
	INTO #tmpWGconcat
	FROM #WorkGroupCamps wgc1
	GROUP BY cam_id, campType


	select cal_id,tipo_llamada,A.cam_id,
	case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
	A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
		U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
	finicio,A.ani,dni,cal_key,cal_manual,
	isnull(P.pos_id,0) as posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
	case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
	convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
	case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
	a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
	@encrypted as IsEncrypted, A.Prefijo as Prefix
	INTO #tmpRecords
	from RIA_GRABACION A
	inner join #userAgent on #userAgent.userId=A.age_id
	inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
	left join ccPosicion P on A.cal_extension * -1 =P.pos_id
	left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
	left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
	left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
	left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
	left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
	left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
	left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
	left join ccUsers U on A.age_id=U.user_id
	where (A.finicio >= @dateStart and A.finicio <=@dateEnd)
	and (
		@IdCallList is null or @IdCallList ='''' or
			A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'',''))
	)
	and (
		@UserList is null or @UserList ='''' or
			A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'',''))
	)
	and (
		@TypeCall is null or a.tipo_llamada=@TypeCall
	)
	and (
		@CampaingsList is null or @CampaingsList ='''' or
		( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
	)
	and (
		@ACDList is null or @ACDList ='''' or
		( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
	)
	and (
		@DispositionList is null or @DispositionList ='''' or
		( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
	)
	and (
		@SubdispositionList is null or @SubdispositionList ='''' or
		( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
	)
	and (
		@GrabId is null or @GrabId = 0 or
			A.grab_id > @GrabId
	)
	union all
	select cal_id,tipo_llamada,A.cam_id,
	case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
	A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
		U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
	finicio,A.ani,dni,cal_key,cal_manual,
	isnull(P.pos_id,0) posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
	case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
	convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id, 
	case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
	a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
	@encrypted as IsEncrypted, A.Prefijo as Prefix 
	from RIA_GRABACIONConsulta A
	inner join #userAgent on #userAgent.userId=A.age_id
	inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
	left join ccPosicion P on A.cal_extension * -1 =P.pos_id
	left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
	left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
	left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
	left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
	left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
	left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
	left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
	left join ccUsers U on A.age_id=U.user_id
	where (A.finicio >= @dateStart and A.finicio <=@dateEnd)
	and (
		@IdCallList is null or @IdCallList ='''' or
			A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'',''))
	)
	and (
		@UserList is null or @UserList ='''' or
			A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'',''))
	)
	and (
		@TypeCall is null or a.tipo_llamada=@TypeCall
	)
	and (
		@CampaingsList is null or @CampaingsList ='''' or
		( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
	)
	and (
		@ACDList is null or @ACDList ='''' or
		( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
	)
	and (
		@DispositionList is null or @DispositionList ='''' or
		( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
	)
	and (
		@SubdispositionList is null or @SubdispositionList ='''' or
		( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
	)
	and (
		@GrabId is null or @GrabId = 0 or
			A.grab_id > @GrabId
	)
	order by finicio

	IF (@TopRecords = 0) 
	BEGIN
		SELECT cal_id, tipo_llamada, tr.cam_id, campDescription, calif_id, duracion, id_nivel_grito,
		user_id, username, FullName, finicio, ani, dni, cal_key, cal_manual, posicion, computer,
		total_forma, id_repositorio, score, formato_duracion, grab_id, ISNULL(wgc.WGIDs, ''0'') IDWG, califSub_id, 
		cal_tMoh, ruta_repositorio, IsEncrypted, Prefix, ISNULL(wgc.WGNames, ''0'') WGName
		FROM #tmpRecords tr
		LEFT JOIN #tmpWGconcat wgc on tr.cam_id = wgc.cam_id and tr.tipo_llamada-1 = wgc.campType
		order by finicio
				
	END
	ELSE BEGIN
		SELECT TOP(@TopRecords) 
		cal_id, tipo_llamada, tr.cam_id, campDescription, calif_id, duracion, id_nivel_grito,
		user_id, username, FullName, finicio, ani, dni, cal_key, cal_manual, posicion, computer,
		total_forma, id_repositorio, score, formato_duracion, grab_id, ISNULL(wgc.WGIDs, ''0'') IDWG, califSub_id, 
		cal_tMoh, ruta_repositorio, IsEncrypted, Prefix, ISNULL(wgc.WGNames, ''0'') WGName
		FROM #tmpRecords tr
		LEFT JOIN #tmpWGconcat wgc on tr.cam_id = wgc.cam_id and tr.tipo_llamada-1 = wgc.campType
		order by finicio
	END


	DROP TABLE #userAgent
	DROP TABLE #tmpRecords
	DROP TABLE #WorkGroupCamps
	DROP TABLE #tmpWGconcat'
        EXEC(@sql)

        -------------------------------------------- END Marco Chagolla -------------------------------------------------------------------------------
      
      -------------------------------------------- Begin Jesus Gallardo -------------------------------------------------------------------------------
      SET @process = 'alter SP ccspGalatea_Finder CW-7941 y DEV1-239_Send_cal_ids_list_to_front'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
@action int,
@grabIds varchar(max)=null,
@grabId int =null,
@userId int =0, 
@markTime int=null,
@markId int=null,
@isSuperUser bit=0,
@dateStart datetime=null,
@dateEnd datetime=null,
@idRepository int = 0
AS
BEGIN

    SET NOCOUNT ON;
    declare @sql varchar(max)
    declare @camType table(Id int,camType tinyint)

    if @action=0 begin          
        if @isSuperUser =0 begin            
                 SELECT WGCam.IdCampEsp AS [Id], 2 callType
                 FROM ccRIAWorkGroupUsers Wguser
                      INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                      INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                              AND WGCam.Tipo = 1
                 WHERE Wguser.User_id = @userId
                 UNION
                 SELECT WGCam.IdCampEsp AS [Id], 1 AS callType
                 FROM ccRIAWorkGroupUsers Wguser
                      INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                      INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                                  AND WGCam.Tipo = 0
                 WHERE Wguser.User_id = @userId;
             end
        else begin           
            SELECT c.cam_id as [Id], 2 AS callType FROM ccCamps c
            UNION
            SELECT inb.Inbound_id AS [Id], 1 AS callType FROM ccInbound inb;
        end
        
    end

    else if @action=1 begin
        select id_repositorio as repositoryId,dirvirtual_audio as pathAudio,dirvirtual_video as pathVideo,ruta_repositorio as pathRepositoryAudio, 
            ruta_repositorio_secundario as PathRepositoryAudioSecundario, dirvirtual_audio_secundario as PathAudioSecundario
        from TREC_REPOSITORIOS
    end
    else if @action=2 begin
                            set @sql=''
                            ;
                            with grab as (
select grab_id,cal_id,tipo_llamada,age_id as userId from RIA_GRABACION with(nolock) where grab_id in(''+@grabIds+'')
                            union
select grab_id,cal_id,tipo_llamada,age_id as userId from RIA_GRABACIONCONSULTA with(nolock) where grab_id in(''+@grabIds+'')
                            )

select isnull(mark.id_marca,0) as markId, grab.grab_id as grabId
,b.login as userName, grab.userId as [userId],isnull(mark.marca,'''''''') as mark,convert(bit,case when b.TipoUser_id =1 then 0 else 1 end ) as IsAdmin
from grab 
left join RIA_MARCAS mark  on grab.cal_id=mark.call_id and grab.tipo_llamada=mark.tipo_llamada
inner join ccUsers b on b.user_id = grab.userId
                            order by grab.grab_id,mark.tipo_marca 
                            ''
                            --print @sql
    exec (@sql)
end
else if @action =3 begin
    select cast(case when par_valor =''1'' then 1 else 0 end as bit) as isEncrypt from TREC_PARAMETROS where par_id=15
end
else if @action =4 begin
    set @sql=''declare @nameFolder table (callType int,nameFolder varchar(100),prefijo varchar(2))
insert into @nameFolder values(1,''''INBOUND'''',''''I_'''')
insert into @nameFolder values(2,''''OUTBOUND'''',''''O_'''')
declare @ext varchar(30)

select @ext = case when par_valor=''''1'''' then ''''.wav.enc'''' else ''''.wav'''' end from TREC_PARAMETROS where par_id=15
    ;
    with grab as (
    select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACION with(nolock) where grab_id in(''+@grabIds+'')
    union
    select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACIONCONSULTA with(nolock) where grab_id in(''+@grabIds+'')
    )
    
    select grab.grab_id as grabId,grab.id_repositorio as repositoryId,rep.dirvirtual_audio as virtualAudio
    ,rep.ruta_repositorio+''''\''''+f.nameFolder+''''\''''+ cast(cal_id/10000 as varchar(100))+''''\'''' as pathRep,
    rep.dirvirtual_audio_secundario as VirtualAudioSecundario, 
    rep.ruta_repositorio_secundario+''''\''''+f.nameFolder+''''\''''+ cast(cal_id/10000 as varchar(100))+''''\'''' as PathRepSecundario,
    f.prefijo+cast(cal_id as varchar(100))  + case when subFijo<>'''''''' then ''''_''''+subFijo else '''''''' end + @ext as [fileAudio]
    from grab 
    inner join TREC_REPOSITORIOS rep on grab.id_repositorio=rep.id_repositorio
    inner join @nameFolder f on f.callType=grab.tipo_llamada  
    order by repositoryId
    ''
    --print @sql
    exec (@sql)
end
else if @action =5 begin
    select top 1 id_repositorio as repositoryId,rep.ruta_repositorio as pathRep, Cred.domain, Cred.[user], Cred.[password],Rep.dirvirtual_audio as virtualAudio
    from TREC_REPOSITORIOS Rep
    inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
    inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
    where Cred.type = 1 and status=1
end
else if @action=6 begin
    declare @cal_id int,@tipo_llamada int

    select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACION with(nolock) where grab_id=@grabId

    if @cal_id is null and @tipo_llamada is null begin
        select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACIONCONSULTA with(nolock) where grab_id=@grabId
    end            
    insert RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grabId,@userId,CONVERT(varchar, DATEADD(ss, @markTime , 0), 8),2,@tipo_llamada,@cal_id )
    select cast( @@IDENTITY  as int) as markId
end
else if @action=7 begin
    delete from RIA_MARCAS  where id_marca=@markId
end
else if @action=8 begin 
    select par_valor as hexKey from TREC_PARAMETROS where par_id=75
end
else if @action=9 begin                 
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select A.grab_id from RIA_GRABACION A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select A.grab_id from RIA_GRABACIONCONSULTA A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end
else if @action=10 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select distinct A.cal_key from RIA_GRABACION A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select distinct A.cal_key from RIA_GRABACIONCONSULTA A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end
else if @action=11 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select distinct A.ani as Phone from RIA_GRABACION A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select distinct A.ani as Phone from RIA_GRABACIONCONSULTA A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end
else if @action=12 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select distinct A.dni from RIA_GRABACION A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select distinct A.dni from RIA_GRABACIONCONSULTA A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end
else if @action=13 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select distinct convert(varchar(100), A.cal_extension) as cal_extension from RIA_GRABACION A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select distinct convert(varchar(100), A.cal_extension) from RIA_GRABACIONCONSULTA A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end

else if @action=14 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser

    
    select isnull(min(minDuration),0) as MinDuration, isnull(max(maxDuration),600) as MaxDuration from (
        select max(duracion) as maxDuration,min(duracion) as minDuration from RIA_GRABACION A with(nolock) 
        inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
        where A.finicio between @dateStart and @dateEnd
        union
        select max(duracion) as maxDuration,min(duracion) as minDuration from RIA_GRABACIONCONSULTA A with(nolock)
        inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
        where A.finicio between @dateStart and @dateEnd
    )X
end

else if @action = 15 begin
    select cast(id_repositorio as int) as idRepository from RIA_GRABACION where grab_id = @grabId
end

else if @action = 16 begin
    select id_repositorio as repositoryId,rep.ruta_repositorio as pathRep, Cred.domain, Cred.[user], Cred.[password],Rep.dirvirtual_audio as virtualAudio
    from TREC_REPOSITORIOS Rep
    inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
    inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
    where Cred.type = 1 and status=1 and Rep.id_repositorio = @idRepository
end

else if @action = 17 begin  -- Get Inbound and Outbound cal_ids 
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select A.cal_id from RIA_GRABACION A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select A.cal_id from RIA_GRABACIONCONSULTA A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end

END'
  	EXEC(@sql) 

	set @process = 'Alter SP trsp_muevegrabaciones por que inserta por fecha pero borra por grabId '
	set @sql = 'ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
AS
BEGIN
Set NOCOUNT ON

declare @fecha datetime
declare @Integrado as int

select @integrado = par_valor from trec_parametros where par_id = 29
set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)
declare @top int
set @top=3000

declare @sql nvarchar(max) 
set @sql=''declare @RIA_GRABACION table(	
[grab_id] [bigint] NOT NULL,
[cli_id] [int] NULL,
[age_id] [int] NULL,
[puerto_id] [int] NULL,
[tipo_grab_id] [tinyint] NULL,
[age_id_rec] [int] NULL,
[ffin] [datetime] NOT NULL,
[finicio] [datetime] NOT NULL,
[ani] [varchar](30) NOT NULL,
[dni] [varchar](15) NULL,
[tamano] [int] NULL,
[duracion] [int] NULL,
[pos_pc] [varchar](25) NULL,
[extension] [varchar](25) NULL,
[razon_id] [tinyint] NULL,
[nombre_archivo] [varchar](20) NULL,
[info1] [varchar](50) NULL,
[info2] [varchar](50) NULL,
[info3] [varchar](50) NULL,
[info4] [varchar](50) NULL,
[info5] [varchar](50) NULL,
[id_repositorio] [tinyint] NULL,
[id_nivel_grito] [int] NULL,
[tipo_llamada] [smallint] NULL,
[cam_id] [smallint] NULL,
[calif_id] [smallint] NULL,
[cal_id] [int] NULL,
[cal_key] [varchar](40) NOT NULL,
[cal_manual] [tinyint] NULL,
[cal_extension] [int] NULL,
[cal_whoHung] [smallint] NULL,
[cal_whoRec] [int] NULL,
[id_plantilla] [smallint] NULL,
[fvalida] [datetime] NULL,
[fvalida2] [datetime] NULL,
[borra_id] [bit] NULL,
[cal_fcallback] [smalldatetime] NULL,
[dni_id] [smallint] NULL,
[extra_info] [varchar](50) NULL,
[extra_info2] [varchar](50) NULL,
[id_rep_video] [tinyint] NULL,
[video] [int] NOT NULL,
[IDWG] [varchar](800) NULL,
[califSub_id] [smallint] NOT NULL,
[cal_tMoh] [smallint] NOT NULL,
[Prefijo] [varchar](max) NULL,
primary key (grab_id)
)
''

--AVRS XION
if (@integrado = 2) BEGIN
		set @sql=@sql+''  
insert into @RIA_GRABACION
(grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)
SELECT top(@top) grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
	info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
	cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo
FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;

INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)

select A.grab_id,A.cli_id,A.age_id,A.puerto_id,A.tipo_grab_id,A.age_id_rec,A.ffin,A.finicio,A.ani,A.dni,A.tamano,A.duracion,A.pos_pc,A.extension,A.razon_id,A.nombre_archivo,A.info1,A.info2,A.info3,A.info4,A.
info5,A.id_repositorio,A.id_nivel_grito,A.tipo_Llamada,A.cam_id,A.calif_id,A.cal_id,A.cal_key,A.cal_manual,A.cal_extension,A.cal_whoHung,A.cal_whoRec,A.id_plantilla,A.fvalida,A.fvalida2,A.borra_id,A.
cal_fcallback,A.dni_id,A.extra_info,A.extra_info2,A.id_rep_video,A.video,A.IDWG,A.califSub_id,A.cal_tMoh,A.Prefijo
from @RIA_GRABACION A
left join RIA_GRABACIONCONSULTA B on A.grab_id=B.grab_id
where A.grab_id is null

delete A from RIA_GRABACION A 
inner join @RIA_GRABACION B on A.grab_id=B.grab_id
		''
END
else BEGIN  --AVRS Integrada ó AVRS Stand Alone
	
	set @sql=@sql+''
SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

insert into @RIA_GRABACION
(grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)		  
SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
	info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
	cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG)
select grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
from @RIA_GRABACION

SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

delete A from TREC_GRABACION A 
inner join @RIA_GRABACION B on A.grab_id=B.grab_id''
	
END

exec sp_executesql @sql, N''@top int, @fecha datetime'', @top,@fecha
print(@sql)
END'
	EXEC(@sql)

      -------------------------------------------- END Jesus Gallardo -------------------------------------------------------------------------------


    update trec_parametros set par_valor = @Version where par_id = 30
    set @Version_Actual=@Version_Actual+1

    select par_valor from trec_parametros where par_id = 30

    commit tran

    end try
    begin catch
        select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
        RAISERROR(@errorGenerated, 11, 1)
    rollback tran
    end catch
 end
 else begin
    select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end