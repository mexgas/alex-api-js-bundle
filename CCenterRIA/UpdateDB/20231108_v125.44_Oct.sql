/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 44
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	-----------------------------------------------------BEGIN JCL ----------------------------------------------------------------
	SET @process = ' CW-8153 alter sp ccsp_RIACampsManualCall'
	SET @sql = '
			ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			@option int,
			@UserID int = 0,
			@onChat int = 0,
			@campId int = 0
			AS
			set nocount on
			if(@option = 1)
			begin
				if (@onChat = 0)
				begin
					declare @mod smallint
					declare @IdArea smallint
					declare @DialingMode tinyint
					select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
					select @mod = defCampaing from ccRIACat_Areas A
					where A.IDArea = @IdArea 
					select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual, 
					isnull(c.selectRotativeANI, 0) selectRotativeANI
					, isnull(c.CampType,0) as CampType,
					CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
					isnull(c.timesPreview, 0) timesPreview
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID  
						and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
					order by cam_descripcion
				end
				else 
				begin 
					select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
					, isnull(c.CampType,0) as CampType
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and manualCallOnChat = 1
					order by cam_descripcion
					SET NOCOUNT OFF;
				end
			end
			if(@option = 2)
			begin
				declare @aniList int 
				declare @rotativeAniListId int
				select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId
				if @rotativeAniListId >0 begin
					select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
				end
				else begin
					select top 0 '''' telAni 
				end					
			end'
	EXEC(@sql);
	-----------------------------------------------------END JCL ----------------------------------------------------------------


	-----------------------------------------------------BEGIN Gaby -----------------------------------------------------------------
	SET @process = 'CW-8148 drop sp ccsp_GalateaGetPreviewData'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_GalateaGetPreviewData'')
		begin
			DROP PROCEDURE ccsp_GalateaGetPreviewData
		end'
	EXEC(@sql);

	SET @process = 'CW-8148 create procedure ccsp_GalateaGetPreviewData'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @option int = null,
		@callout_id int = null,
        @user_id smallint = null

        AS
        set nocount on

		if(@option = 1 or @option is null)
		begin
			declare @typePreview varchar = null

			select @typePreview= valor from ccSettings (nolock)
			where setting_id=248 and Status=1

			select ''previewData''=
			 case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
			 ISNULL(P.Headers,'''')+''~''+
			 ISNULL(O.Dato1,'''')+''~''+
			 ISNULL(O.Dato2,'''')+''~''+
			 ISNULL(O.Dato3,'''')+''~''+
			 ISNULL(O.Dato4,'''')+''~''+
			 ISNULL(O.Dato5,'''')+''~''+
			 ISNULL(P.Dato6,'''')+''~''+
			 ISNULL(P.Dato7,'''')+''~''+
			 ISNULL(P.Dato8,'''')+''~''+
			 ISNULL(P.Dato9,'''')+''~''+
			 ISNULL(P.Dato10,'''')+''~''+
			 ISNULL(P.Dato11,'''')+''~''+
			 ISNULL(P.Dato12,'''')+''~''+
			 ISNULL(P.Dato13,'''')+''~''+
			 ISNULL(P.Dato14,'''')+''~''+
			 ISNULL(P.Dato15,'''')+''~''+
			 ISNULL(O.cal_telefono2,'''')+''~''+
			 ISNULL(O.cal_telefono3,'''')+''~''+
			 ISNULL(O.cal_telefono4,'''')+''~''+
			 ISNULL(O.cal_telefono5,'''')+''~''+
			 ISNULL(cast(O.cal_Key as varchar),'''')+''~''+
			 ISNULL(cast(O.cal_telefono as varchar),'''')+''~''+
			 @typePreview+''~'',
			 C.previewDiscard,
			 CE.EditableContactData as previewUpdate
				   from ccoCallsOutSource O (nolock)
			INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
			INNER JOIN ccCamps C (nolock) on P.cam_id = C.cam_id
			INNER JOIN ccCampsExtend CE (nolock) on C.cam_id= CE.cam_id
			JOIN ccUsers U (nolock) on U.TipoUser_id=1
			Where callout_id=@callout_id and U.User_id=@user_id
		end

		if(@option = 2)
		begin
			select COUNT(*) from ccoCallsOutSource nolock where callout_id = @callout_id
		end
        set nocount off'
	EXEC(@sql);

	-----------------------------------------------------END Gaby -----------------------------------------------------------------

	


    


  


---------------------------------------Begin Jesus Gallardo hotfix/125.20230719.0.9-----------------------------------------------------------

    SET @process = 'DEV1-409 Milla Alter SP ccsp_RIARegistryLists --return SELECT 200 as ReturnValue y se agrega withNolock'
    SET @sql = 'ALTER Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0, 
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '''',
@status tinyint = 0,
@sequence smallint = 0,
@load_id int = 0
AS

--Status lista 0: inactiva, 1:pausa, 2:procesar

--Insert
IF @action = 1 begin

    IF @cam_id <> 0 begin
        select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
        set @sequence = @sequence + 1
        Insert into ccRIARegistryLists(cam_id,name,status,sequence) values (@cam_id, @name, 2, @sequence)
        select max(list_id) from ccRIARegistryLists
    end
end

--Update sequence
IF @action = 2 begin
    
    declare @oldSeq as int
    select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

    if @oldSeq <> @sequence begin
        
        if @oldSeq > @sequence begin
            update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
        end

        if @oldSeq < @sequence begin
            update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
        end

        update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

    end

end

--Change status
IF @action = 3 begin
    
    update ccRIARegistryLists set status = @status where list_id = @list_id
    SELECT 200 as ReturnValue

end

-- lista campañas y listas de registros
IF @action = 4 begin
    select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame 
    from ccRIARegistryLists a  with(nolock)
    left join cccamps b on a.cam_id = b.cam_id
    left join ccRIACampsGraph c on a.cam_id = c.cam_id
    where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists ) 
    group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

end

-- listas de registros y no. registros
IF @action = 5 
begin
    select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence   
    from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock) 
    left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_13),nolock) 
    on b.cam_id = @cam_id and a.list_id = b.list_id 
    where a.status > 0 and a.cam_id = @cam_id and status > 0 
    group by a.list_id,a.name,a.sequence 
    order by a.sequence
end

-- borrar lista
IF @action = 6 begin

    select @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id
    select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
    exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id
    exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id
    SELECT 200 as ReturnValue

end

-- Detalle de numero de registros
IF @action = 7 begin

    declare @total as int

    select @total = count(*) from ccocallsoutsource where list_id = @list_id
    select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

    if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
        select @status = status from ccRIARegistryLists where list_id = @list_id
        select @list_id as list_id,cast(cam_id as smallint) as cam_id, @status as status,
            count(case cal_status when 0 then 1 else null end) as New,
            count(case cal_status when 1 then 1 else null end) as CB,
            count(case cal_status when 2 then 1 else null end) as Pro, 
            @total as Fin
        from ccoWorkingTable where list_id = @list_id group by cam_id
    end
    ELSE begin
        select list_id, cam_id, status, 
        0 as New,
        0 as CB,
        0 as Pro,
        0 as Fin
        from ccRIARegistryLists where list_id = @list_id
    end


end

-- Cambia de nombre a la lista
IF @action = 8 begin
    
    update ccRIARegistryLists set name = @name where list_id = @list_id

end

-- Borra listas sin registros y reordena las listas
IF @action = 9 begin

    Create table #TempRegs(
        list_id int,
        [name] varchar(100),
        NoRegistros int,
        sequence int)

    insert into #TempRegs 
        select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence 
        from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock)
        left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_14),nolock)
        on a.list_id = b.list_id
        where a.status > 0 and a.cam_id = @cam_id and status > 0 
        group by a.list_id,a.name,a.sequence,a.status order by a.sequence

    while ( exists( select list_id from #TempRegs where NoRegistros = 0 ) ) begin
        declare @listToDelete as int
        select top 1 @listToDelete = list_id from #TempRegs where NoRegistros = 0
        exec ccsp_RIARegistryLists @action = 6, @list_id = @listToDelete
        delete from #TempRegs where list_id =  @listToDelete
    end

    drop table #TempRegs
    
    select @sequence=min(sequence) from ccRIARegistryLists where  cam_id = @cam_id and status = 0 

    select @list_id= list_id from ccRIARegistryLists where sequence =(
    select  max(sequence) as sequence from ccRIARegistryLists where  cam_id = @cam_id and status > 0 ) and cam_id = @cam_id
    update ccRIALoading set list_id = @list_id where load_id=@load_id
    exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

    end'
    EXEC(@sql);

    set @process = 'DEV1-409 create table ccDispositionDashboardResultOut'
    set @sql = 'if not exists(select * from sys.tables where name=''ccDispositionDashboardResultOut'') begin
create table ccDispositionDashboardResultOut (
        CamId int not null,     
        statusCallId tinyint not null,
        callId int not null,
        DispotitionId int not null,
        SubDispotitionId int not null,
        primary key (callId)
        )
end'
    EXEC(@sql)

    set @process = 'DEV1-409 create table ccDispositionDashboardResultIn'
    set @sql = 'if not exists(select * from sys.tables where name=''ccDispositionDashboardResultIn'') begin
create table ccDispositionDashboardResultIn (
        CamId int not null,     
        statusCallId tinyint not null,
        callId int not null,
        DispotitionId int not null,
        SubDispotitionId int not null,
        primary key (callId)
        )
end'
    EXEC(@sql)



    set @process = 'DEV1-409 DROP PROCEDURE ccspSaveDispositionResult'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccspSaveDispositionResult'')
    begin
        DROP PROCEDURE ccspSaveDispositionResult;
    end'
    EXEC(@sql)

       set @process = 'DEV1-409 create SP ccspSaveDispositionResult'
    set @sql = 'CREATE PROCEDURE [dbo].[ccspSaveDispositionResult]
@action int,
@callType TINYINT=null,
@camId int =null,
@callid BIGINT=0,
@statusCallId int=0,
@dispotitionId int=null,
@subDispotitionId int=null
AS

declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
declare @callTypeInOut tinyint
if @action in(3,4) begin
    select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
    from ccsettings where setting_id = 27 -- 0 esp
    
end
if @action in(5,6) begin    
    select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
    from ccsettings where setting_id = 27 -- 0 esp  
end

set @callTypeInOut= case when @callType=1 then 0 else 1 end


if @action=0 begin
    declare @today date
    set @today =CONVERT(date,getdate())

    truncate table ccDispositionDashboardResultOut
    truncate table ccDispositionDashboardResultIn

    insert into ccDispositionDashboardResultOut
    select cam_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
    from ccoCallsOut 
    where cal_Inicio>=@today

    insert into ccDispositionDashboardResultIn
    select Inbound_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
    from ccCallsIn 
    where cal_Inicio>=@today
end
else if @action=1 begin
    set @dispotitionId=0
    set @subDispotitionId=0
    if @callType=1 begin
        insert into ccDispositionDashboardResultOut values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
    else begin
        insert into ccDispositionDashboardResultIn values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
end
else if @action=2 begin
    set @subDispotitionId=case when @subDispotitionId is null then null when @subDispotitionId>0 then @subDispotitionId else 0 end
    if @callType=1 begin
        update ccDispositionDashboardResultOut set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid 
    end
    else begin
        update ccDispositionDashboardResultIn set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid 
    end
end
else if @action=3 begin 
    select @callTypeInOut as tipo,dash.CamId as CamId
    ,case when dash.statusCallId = 13 then
        case when ca.[description] is not null then ca.[description] else @nIdioma end
        else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma end
    end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId as DispotitionId
    ,count(*) Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
    from ccDispositionDashboardResultOut dash with(nolock)
    left join ccTipoCalifOut ca on dash.DispotitionId = ca.calif_id 
    left join ccTipoCalifSubOUT tcsout on dash.SubDispotitionId = tcsout.califSub_id
    left join ccstatusllamada sll on sll.statuscall_id = dash.statusCallId
    left join ccCamps ci on ci.cam_id = dash.CamId
    LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id and dash.SubDispotitionId = rel.califSub_id and tipoSubRel = 0
    where CamId=@camId
    group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor,rel.calif_id

end
else if @action=4 begin 
    select @callTypeInOut as tipo
    ,dash.CamId
    ,case when ca.[Description] is not null then ca.[Description] else @nIdioma end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId
    ,count(*)  as Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,0 IsSubDisp
    from ccDispositionDashboardResultIn dash with(nolock)
    left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id 
    left join ccInbound cci on cci.inbound_id = dash.CamId 
    where dash.CamId = @camId and dash.statusCallId = 13 
    group by ca.[Description], dash.CamId,dash.SubDispotitionId,dash.DispotitionId,GraphColor

end

else if @action=5 begin 
    select 0 as Type,co.CamId as CampId,
    case when co.statusCallId = 13
    then case when description is not null
    then description else @nIdioma end
    else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
    end as Calification,
    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
    from ccDispositionDashboardResultOut co
    left join ccTipoCalifOut ca on co.DispotitionId = ca.calif_id
    left join ccTipoCalifSubOUT cso on co.SubDispotitionId = cso.califSub_id 
    left join ccstatusllamada sll on sll.statuscall_id = co.statusCallId
    left join ccCamps ci on ci.cam_id = co.CamId
    where co.CamId = @camId
    and co.DispotitionId = @dispotitionId
    group by  co.CamId, co.statusCallId,description,descripcion,cso.califSubDesc
end
else if @action=6 begin 
    select 0 as [type],CamId as CampId
    , ca.[description] as Calification
    , isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
    , count(ctcs.califSubDesc) as Quantity
    --,dash.DispotitionId
    from ccDispositionDashboardResultIn dash
    left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id
    left join ccInbound cci on cci.inbound_id = dash.CamId
    left join ccTipoCalifSub ctcs on dash.SubDispotitionId = ctcs.califSub_id
    where dash.CamId=@camId and dash.statusCallId=13 and dash.DispotitionId=@dispotitionId
    group by ca.description, dash.CamId,ctcs.califSubDesc,dash.DispotitionId
end
'
    EXEC(@sql)



      set @process = 'DEV1-409 Alter SP ccsp_GalateaCallbacks se quita la tabla temporal y se cambia CTE'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaCallbacks]
@dateCallBack datetime,
@agentId int = 0
AS

declare @dateStart datetime,@dateEnd datetime
set @dateStart=convert(datetime,convert(varchar(10),@dateCallBack,121))
set @dateEnd=DATEADD(dd,1,@dateStart)
;with CallBackHours as(
select  DATEPART(HOUR, cal_fcallback) ''Hour'',CAST( 1 as int) callback
from ccoCallsOut with(nolock)
where cal_fcallback between @dateStart and @dateEnd
and User_id = @agentId
)

SELECT  CAST(Hour AS smallint) [Hour], SUM(callback) ''CallBacks'' FROM CallBackHours
GROUP BY [Hour]
ORDER BY Hour
'
    EXEC(@sql)


    set @process = 'DEV1-409 Alter Sp spInsertCall se agerga ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[spInsertCall]
@Pto smallint,
@DNIS varchar(14),
@ANI as varchar(14),
@inbound_id smallint=0,
@IVR_id int = 0, --Id del IVR
@CALLDATA as varchar(1275) = ''''
AS
declare @dni_id as smallint
declare @cal_id as int
declare @datacall as varchar(100)

select @Ani = left(rtrim(ltrim(@ANI)), 13)
select @DNIS = rtrim(ltrim(@DNIS))

  --busca dni_id
  select @dni_id = isnull ( ( select dni_id From ccDNIS Where dni_numero =  @DNIS and dni_status = 1 ), 0)
  
  --busca especialidad
  IF @inbound_id =0 and @dni_id >0
    select @Inbound_id=ED.Inbound_id from ccInboundDnis ED where ED.dni_id = @dni_id
  
  INSERT ccCallsIN ( cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id )
  VALUES ( @ANI, @dni_id, @Pto, getdate(), @inbound_id, @IVR_id )

  select @cal_id = scope_identity()

  exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@inbound_id,@callType=0,@statusCallId=1

  IF @inbound_id > 0 
  BEGIN
    insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
    select idwg, @cal_id, 0 as user_id, getdate() timestamp, 0 as tipo from ccRIACampEspWG wg   
    where wg.tipo = 0 and wg.IdCampEsp = @Inbound_id

  END

  IF @CALLDATA <> ''''  BEGIN -- Transfer Reminder
    set @CALLDATA=SUBSTRING(@CALLDATA,0,len(@CALLDATA)-2)
    insert into DataCallIn (CallId, Data, Description) 
    select @cal_id,value,''Dato ''+cast(id as varchar(max)) from dbo.[fn_RIASplitDelimited](@CALLDATA,''~'')
  END

  Select @cal_id as IDCall, @dni_id as IDdnis'
    EXEC(@sql)

     set @process = 'DEV1-409 DEV1-409 Alter Sp ccsp_AGENTInsertCallOut se agerga ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
    @cam_id smallint,
    @cal_Key varchar(40),
    @cal_Telefono varchar(30),
    @user_id int,
    @cal_extension varchar(7),
    @sData varchar(255) = '''', --HLAS para guardar notas de la llamada
    @existCallOut as int = 0,
    @callmode as smallint = 0,
    @odbc AS BIT = 0
    AS
    set 
    nocount on
    declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
    select @fecha=getdate()
    declare @dialPrefix integer
    select @dialPrefix = valor from ccSettings where setting_id = 202

    if @callmode = 1 begin
        INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
        select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension, @odbc
        select @cal_id = scope_identity()

exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11

        insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
        select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
        from ccRIACampEspWG wg 
        where wg.tipo = 1 and wg.idcampesp =@cam_id

        select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
        select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
      return(0)
    end

    if @existCallOut=0  begin
        declare @prefijoMarcacion varchar(100) 
        set @prefijoMarcacion = ''''
        declare @LasCallKey varchar(20)
        set @LasCallKey = @cal_Key
        declare @settingCallKey as int
        select @settingCallKey = valor from ccSettings where setting_id = 194
  
        if(@settingCallKey = 1) begin
            if (@cal_Key='''' or @cal_Key is null) begin   
                select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
                set @cal_Key= @LasCallKey
            end
        end

        if @dialPrefix = 1 and len(@cal_telefono)>20
            begin
                set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
                set @cal_telefono = RIGHT(@cal_telefono,10)     
            end
        else 
            begin
                set @prefijoMarcacion =''''          
            end
    
        INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
        select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
        select @callout_id = scope_identity()

        INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
        select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
        select @cal_id = scope_identity()

    exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
     end

    else begin --@existCallOut<>0
        Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut    
        Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
    
        set @callout_id = @existCallOut

        select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
    
        if exists(select * from ccoLogDials where cal_id=@cal_id) begin
            INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
            select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
            select @cal_id = scope_identity()

        exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
        end
     
     end
    
    insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
    select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
    from dbo.ccRIACampEspWG wg 
    where wg.tipo = 1 and wg.idcampesp =@cam_id


    select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
    select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
    return(0)
set nocount off
        '
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_DLRUpdateCallSetStatus ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRUpdateCallSetStatus]
@cal_id int,
@nStatus tinyint
AS
IF @nStatus=5   --En Espera
BEGIN
    Update ccoCallsOut SET cal_que=1, statusCall_id=5 --En Espera
    where cal_id=@cal_id
END
ELSE
BEGIN
    Update ccoCallsOut SET statusCall_id=@nStatus
    where cal_id=@cal_id    
END

exec ccspSaveDispositionResult @action=2,@callid=@cal_id,@callType=1,@statusCallId=@nStatus'
    EXEC(@sql)


    set @process = 'DEV1-409 Alter Sp ccsp_DLRAfterXferAge se agerga ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7)

AS
set nocount on
if @cal_id=0
 return(0)
        
Update ccoCallsOut SET user_id=@User_id, cal_extension=@cal_extension, statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 1

exec ccspSaveDispositionResult @action=2,@callid=@cal_id,@callType=1,@statusCallId=11

-- calcula el costo de la llamada
exec ccsp_CstoCalculaCosto @cal_id
return(0)
set nocount off'
    EXEC(@sql)

   

    set @process = 'DEV1-409 Alter Sp ccsp_AgentUpdateCallCALIF ejecucion ccspSaveDispositionResult'
    set @sql = 'Alter PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(40) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
DECLARE @userid INT
declare @statusCallId int
SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

DECLARE @hashTel INT
DECLARE @killListID INT = (
        SELECT idtipolista
        FROM ccTiposListaNegra
        WHERE Tipolista = ''default/KillList''
        )
DECLARE @killListSetting INT = (
        SELECT STATUS
        FROM ccSettings
        WHERE setting_id = 215
        )

IF @TipoCall = 1
BEGIN
    UPDATE ccCallsIN
    SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key)
    , califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    ,@statusCallId=statusCall_id
    WHERE cal_id = @IDCall


    exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=0,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=13

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 0 AND calif_id = @calif_id
            )
    BEGIN
        SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
        FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
        JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
        WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

        IF @tel IS NOT NULL AND @iddncList IS NOT NULL
        BEGIN
            --insert ccListaNegra
            INSERT INTO cclistanegra (telefono, idtipolista, calKey)
            VALUES (@tel, @iddncList, @cal_key)

            --insert cc_killlist
            IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
            BEGIN
                select @hashTel = dbo.hashPhone(@tel)

                IF NOT EXISTS (
                        SELECT hashtel
                        FROM cc_KillList
                        WHERE hashTel = @hashTel
                        )
                BEGIN
                    INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
                    VALUES (@hashTel, @iddncList, GETDATE())
                END
            END

            INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
            SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
            FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
            JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
            WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
        END
    END

    RETURN (0)
END

IF @TipoCall = 2
BEGIN
    -- Toma como prioridad la configuración de la subcalificación (en caso de existir)
    SELECT @autoCB = autocallback
    FROM ccTipoCalifSubout
    WHERE califSub_Id = @subId

    -- Si no tiene subcalificacion toma la de la calificacion
    IF @autoCB IS NULL
    BEGIN
        SELECT @autoCB = autocallback
        FROM cctipocalifout
        WHERE calif_id = @calif_id
    END

    SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
    ,@statusCallId=statusCall_id
        FROM ccocallsout
        WHERE Cal_id = @IDCall

    IF @autoCB = 1
    BEGIN
    

        SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
        FROM cccamps cam
        WHERE cam.cam_id = @camp

        EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
    END

    UPDATE ccoCallsOUT
    SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
    WHERE cal_id = @IDCall

    exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=1,
    @dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=@statusCallId

    IF EXISTS (
            SELECT idTipoLista
            FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
            WHERE tipo = 1 AND calif_id = @calif_id
            ) AND NOT EXISTS (
            SELECT co.cal_telefono
            FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
            JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
            WHERE co.cal_id = @idCall AND bl.idtipolista IN (
                    SELECT idTipoLista
                    FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
                    WHERE tipo = 1 AND calif_id = @calif_id
                    )
            )
    BEGIN --IF

        CREATE TABLE #NUMANDBL (id int identity,  iddncList int)
        CREATE TABLE #NUMBERS (id int identity, number varchar(30))
        DECLARE @allnumbersToBl BIT
        DECLARE @number varchar(30)

        SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id

        IF(@allnumbersToBl = 1)
        BEGIN
            DECLARE @camid SMALLINT
            SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall
            DECLARE @i SMALLINT = 0
            WHILE (@i < 5 )
            BEGIN
                SELECT @number = CASE @i 
                                    WHEN 0 THEN cal_telefono 
                                    WHEN 1 THEN cal_telefono2
                                    WHEN 2 THEN cal_telefono3
                                    WHEN 3 THEN cal_telefono4
                                    WHEN 4 THEN cal_telefono5
                                    END FROM ccoCallsOutSource WHERE callout_id = @callOutId AND cam_id = @camid
                SET @number = dbo.Completa_ListaNegra(@number)
                IF(LEFT(@number, 1) <> ''E'') 
                BEGIN
                    INSERT INTO #NUMBERS (number) VALUES (@number)
                END
                SET @i = @i + 1
            END
        END
        ELSE
        BEGIN
            SELECT @number = co.cal_telefono
            FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
            WHERE co.cal_id = @idCall 
            SET @number = dbo.Completa_ListaNegra(@number)
            IF(LEFT(@number, 1) <> ''E'') 
            BEGIN
                INSERT INTO #NUMBERS (number) VALUES (@number)
            END
        END

        IF((SELECT COUNT(*) FROM #NUMBERS) > 0) begin
            INSERT INTO #NUMANDBL (iddncList) 
            select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
        END

        DECLARE @Count int      
        WHILE (SELECT count(id) from #NUMANDBL) > 0
        BEGIN  --WHILE
            select @Count = count(id) from #NUMANDBL
            SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
            DECLARE @countNumbers INT, @indexNumbers INT = 1
            SELECT @countNumbers = COUNT(*) FROM #NUMBERS
            WHILE( @indexNumbers <= @countNumbers) --WHILE NUMBERS
            BEGIN 
                SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers
                IF @tel IS NOT NULL AND @iddncList IS NOT NULL
                BEGIN--Tel adn iddnclist
                    EXEC ccsp_InsertDNCList @telephone = @tel, @ln_id = @iddncList, @calKey= @cal_key;

                    IF (@killListSetting = 1 AND @iddncList = @killListID)
                    BEGIN
                        select @hashTel = dbo.hashPhone(@tel)

                        IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
                        BEGIN
                            INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
                            VALUES (@hashTel, @iddncList, GETDATE())
                        END
                    END

                    INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
                    SELECT @tel, @iddncList, co.cam_id, getdate(), co.callout_id, 6
                    FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
                    --JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
                    WHERE co.cal_id = @idCall 
                END --Tel adn iddnclist
                SET @indexNumbers = @indexNumbers + 1
            END --WHILE NUMBERS
            delete from #NUMANDBL where id = @Count
        END --WHILE
        DROP TABLE #NUMANDBL
        DROP TABLE #NUMBERS
    END --IF
    IF @RecicleSIC = 1
    BEGIN
        -- Toma como prioridad la configuración de la subcalificación (en caso de existir)
        SELECT @Reprogram = CanReprogram
        FROM ccTipoCalifSubout
        WHERE califSub_Id = @subId

        -- Si no tiene subcalificacion toma la de la calificacion
        IF @Reprogram IS NULL
        BEGIN
            SELECT @Reprogram = CanReprogram
            FROM ccTipoCalifOUT
            WHERE calif_id = @calif_id
        END

        IF @callOutId = 0
            SELECT @callOutId = callout_id
            FROM ccocallsout
            WHERE Cal_id = @IDCall

        UPDATE ccoWorkingTable
        SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
        WHERE callout_id = @callOutId
    END

    DECLARE @keepDial BIT
    DECLARE @finishPreview SMALLINT

    -- Toma como prioridad la configuración de la subcalificación (en caso de existir)
    SELECT @keepDial = keepDial
    FROM ccTipoCalifSubout
    WHERE califSub_Id = @subId

    -- Si no tiene subcalificacion toma la de la calificacion
    IF @keepDial IS NULL
    BEGIN
        SELECT @keepDial = keepDial
        FROM ccTipoCalifout
        WHERE calif_id = @calif_id
    END

    SELECT @finishPreview = isnull(finishPreview, 0)
    FROM ccTipoCalifout
    WHERE calif_id = @calif_id

    IF @keepDial = 1
    BEGIN
        UPDATE ccologdials
        SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
        WHERE logDial_id IN (
                SELECT TOP 1 L.logDial_id
                FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
                JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
                WHERE O.cal_id = @IDCall
                ORDER BY L.logDial_id DESC
                )
    END

    SELECT @keepDial, @finishPreview

    RETURN (0)
END

SET NOCOUNT OFF'
    EXEC(@sql)

    SET @process = 'DEV1-409,DEV1-397 ALTER SP ccsp_AgentUpdateCallTimes, @cal_tXfer,@cal_tRing,@cal_tDialog,@cal_tNotas type float,exec ccspSaveDispositionResult'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer float,
@cal_tDialog float,
@cal_tNotas float,
@TipoCall tinyint,
@cal_tRing float=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0,
@isTransferEngine bit =0
AS
set nocount on
if @IDCall<=0 
    return(0)

declare @tMinAVRS smallint
declare @cal_manual int
declare @minimoDialogo tinyint 
select @minimoDialogo = valor from ccSettings where setting_id = 13

set @cal_manual=0

if @TipoCall=1 begin--INBOUND
  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
  end
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, 
    cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
  cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=0,@statusCallId=13


  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  
  if @isTransferEngine = 0  begin
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
  end
end
else if @TipoCall=2 begin--OUTBOUND 
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
    cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
    cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
    
    cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
    cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
    
    cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
    totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
    Where cal_id=@IDCall

    exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=1,@statusCallId=13

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall
  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
  and not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) 
  begin 
        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
end

return(0)
set nocount off'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter SP ccsp_GalateaAdminSetPermissions Se agrega If y else 207 y se agrega cambio IF @allAgentsSelected = 0 linea 360'
    set @sql = 'Alter PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
@adminId SMALLINT,
@areaId SMALLINT,
@agentsIds VARCHAR(MAX),
@allAgentsSelected BIT, 
@permissionName VARCHAR(255),
@permissionValue INT
AS
SET NOCOUNT ON


declare @changeBitTable table(permissionName VARCHAR(255), valueBit int)

insert into @changeBitTable values(''AllowCellPhoneCalls'',1)
insert into @changeBitTable values(''startStopRecording'',1)
insert into @changeBitTable values(''XferManual'',1)
insert into @changeBitTable values(''AllowTransferCalls'',1)
insert into @changeBitTable values(''AgentPermissionDailing'',1)
insert into @changeBitTable values(''DailingMode'',1)
insert into @changeBitTable values(''AgentPermissionDelete'',1)
insert into @changeBitTable values(''AllowSelectCamp'',1)

insert into @changeBitTable values(''AllowLongDistanceCalls'',2)
insert into @changeBitTable values(''XferExt'',2)

insert into @changeBitTable values(''AllowLocalCalls'',4)
insert into @changeBitTable values(''XferCamps'',4)

insert into @changeBitTable values(''XferAgents'',8)

DECLARE @changeBit INT

set @changeBit=0

select @changeBit=valueBit from @changeBitTable where permissionName=@permissionName

--print(@changeBit)
IF @agentsIds IS NOT NULL
BEGIN
    DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
    INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

    IF @permissionName = ''AllowUnassign'' 
    BEGIN                       
        UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
        SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
    else IF @permissionName = ''AllowSpam''
    BEGIN 
        UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowSpam, AllowUnassign, AllowPlayRecordsOnCallHistory)
        SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END

else IF @permissionName = ''AllowPlayRecordsOnCallHistory''
    BEGIN 
        UPDATE permissions SET permissions.AllowPlayRecordsOnCallHistory = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign)
        SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
else begin
    UPDATE
        ccUsers
    SET DialMask =
        CASE
        WHEN @permissionName = ''AllowCellPhoneCalls''
        OR @permissionName = ''AllowLongDistanceCalls''
        OR @permissionName = ''AllowLocalCalls''
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialMask & @changeBit) <> @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialMask & @changeBit) = @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            END 
        ELSE DialMask
        END,
                        
        XferMask =
        CASE
        WHEN @permissionName = ''AllowTransferCalls''
        THEN
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferMask & @changeBit) <> @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferMask & @changeBit) = @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            END
        ELSE XferMask
        END,

        XferAgents =
        CASE
        WHEN @permissionName = ''XferAgents''
        OR @permissionName = ''XferCamps'' 
        OR @permissionName = ''XferExt'' 
        OR @permissionName = ''XferManual'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferAgents & @changeBit) <> @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferAgents & @changeBit) = @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            END
        ELSE XferAgents
        END,

        startStopRecording =
        CASE
        WHEN @permissionName = ''startStopRecording'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE startStopRecording
        END,

        DialingMode = 
        CASE
        WHEN @permissionName = ''DailingMode'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialingMode & @changeBit) <> @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialingMode & @changeBit) = @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            END 
        ELSE DialingMode
        END,
        AllowChangeDialingMode = 
        CASE
        WHEN @permissionName = ''AgentPermissionDailing'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowChangeDialingMode
        END,
        AllowDeleteRecord= 
        CASE
        WHEN @permissionName = ''AgentPermissionDelete'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowDeleteRecord
        END,
        AllowMarks= 
        CASE
        WHEN @permissionName = ''AllowMarks'' 
        THEN 
            CASE
            WHEN @permissionValue = 1 THEN 1
            WHEN @permissionValue = 0 THEN 0
            END
        ELSE AllowMarks
        END,
        allowselectcamp=
        CASE
        WHEN @permissionName = ''AllowSelectCamp'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE allowselectcamp
        END
    WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)
    end
                
    DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
    DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
    DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
    DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
    DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAAgentsPermissionsTags WHERE PermissionName = @permissionName)        
    DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
                                    FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
                                    WHERE permissions.Id = @Language + 1)

    DECLARE @AgentId INT = 0
    DECLARE @AgentName VARCHAR(20) = ''''

    set @Value = isnull(@Value,@permissionName)

    IF @allAgentsSelected = 0
    BEGIN
        WHILE EXISTS(SELECT * FROM @AgentIdsTemp WHERE Status = 0)
        BEGIN 
            SELECT TOP 1 @AgentId = AgentId FROM @AgentIdsTemp WHERE Status = 0
            SET @AgentName = (SELECT Login FROM ccUsers WHERE User_id = @AgentId)
                    
            EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
            @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                        
            UPDATE @AgentIdsTemp SET Status = 1 WHERE AgentId = @AgentId
        END
    END
    ELSE
    BEGIN
        SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
                    
        EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
        @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                        
        UPDATE @AgentIdsTemp SET Status = 1
    END


END

SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_RIAADMGetCalifDay else if @type = 2 begin linea 702, else if @type = 4 Linea 755'
    set @sql = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
    @type smallint = null,
    @inbound_id smallint = null,
    @calif_id smallint = null,
    @cam_id smallint = NULL,
    @isKolob BIT = 0
    AS
    set nocount on
    create table #CalifTemp (
    id int identity,
    tipo integer,
    Cam_id varchar(60),
    Calificacion varchar(60),
    subCalificacion varchar(60) null,
    calif_id smallint null,
    Total int,
    iTotal4Campaign int null)

    declare @typeACD smallint --= 0
    declare @today datetime
    declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

    set @today = convert(datetime, convert (varchar(11), getdate(), 101))
    select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


    select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
    @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
    from ccsettings where setting_id = 27 -- 0 esp

    ---------------OUT ----------------------------
    if @type=0 begin
        insert into #CalifTemp
        select 0 as tipo,co.cam_id as cam_id,
        case when co.statuscall_id = 13
            then case when description is not null
            then description else @nIdioma end
        else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
        else ''cw:'' + @nIdioma
        end end as Calificacion
        ,0 as subCalificaion,
        co.calif_id,count(*) cantidad,0 as iTotal4Campaign
        from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
        left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
        left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
        left join ccCamps ci on ci.cam_id = co.cam_id
        where co.cal_inicio > @today
        group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

        select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
        case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
        from #CalifTemp
        group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

    end
    ---------------IN ----------------------------
    else if @type = 1 begin

        if @typeACD = 0 begin  --Calls
        insert into #CalifTemp
        select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
                ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
                ,count(*) as total,0 as iTotal4Campaign
                from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
                left join ccTipoCalif ca on ci.calif_id = ca.calif_id
                left join ccInbound cci on cci.inbound_id = ci.inbound_id
                left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
                where ci.cal_inicio > @today and statuscall_id = 13 and cci.Inbound_id=@inbound_id
                group by description, cci.inbound_id,ci.calif_id

        if (select valor from ccSettings where setting_id = 78) = 0 begin
            update #CalifTemp set iTotal4Campaign = 0
        end
        else begin
        update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
            from (
                select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
            inner join #CalifTemp c on t.cam_id = c.cam_id
        end
        end
        else if @typeACD = 1 begin--Chats
        insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
        select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
                case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
                a.disposition as calif_id, count(disposition) as Total
                from ccriachats a
                left join ccTipoCalif b on a.disposition=b.calif_id
            where a.chatDate > @today and
            a.chatStatus=4 and a.inboundId=@inbound_id
        group by inboundId, [description],disposition
        end
        else if @typeACD = 3 begin ---Mail
        insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
        select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
        case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
        relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
        from conversation conver
        inner join message mess on mess.conversationId = conver.conversationId
        left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        where mess.date > @today and
        conver.inboundId=@inbound_id and mess.messageStatusId >= 5
        group by conver.inboundId,relmesdis.dispositionId,disp.Description

        end
        else if @typeACD = 4 begin --calif twetter
        insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
        select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
        case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
        relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
        from conversationTwitter conver
        inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
        left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        where mess.date > @today and
        conver.inboundId=@inbound_id and mess.messageStatusId >= 5
        group by conver.inboundId,relmesdis.dispositionId,disp.Description

        end
        select camtemp.tipo,camtemp.cam_id,
        case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
        camtemp.subcalificacion,camtemp.calif_id,camtemp.total
        from #CalifTemp camtemp
        left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
    end
    -------------------SUBCALIFICACIONES IN-------------------
    else if @type = 2 BEGIN
        if @typeACD = 0 begin --Calls
            exec ccspSaveDispositionResult @action=6,@callType=0,@camId=@inbound_id,@dispotitionId=@calif_id        
        end
        else if @typeACD = 1 
        BEGIN --Chat
            IF(@isKolob = 1)
            BEGIN
                select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
                isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity,
                ctcs.califSub_id AS Id
                from ccriachats a
                left join ccTipoCalif b on a.disposition=b.calif_id
                left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
                where a.chatDate > @today and
                a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id AND ctcs.califSub_id IS NOT NULL
                group by inboundId, [description],ctcs.califSubDesc, ctcs.califSub_id
            END
            ELSE
            BEGIN
                select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
                isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
                from ccriachats a
                left join ccTipoCalif b on a.disposition=b.calif_id
                left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
                where a.chatDate > @today and
                a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
                group by inboundId, [description],ctcs.califSubDesc
            END
        end
        else if @typeACD = 3 begin --Mail
        select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
        isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
        from conversation conver
        inner join message mess on mess.conversationId = conver.conversationId
        left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
        where mess.date > @today and
        mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
        group by conver.inboundId,disp.Description,subDisp.califSubDesc


        end
        else if @typeACD = 4 begin --Twitter
        select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
        isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
        from conversationTwitter conver
        inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
        left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
        where mess.date > @today and
        mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
        group by conver.inboundId,disp.Description,subDisp.califSubDesc
        end

    end
    -------------------SUBCALIFICACIONES OUT-------------------
    else if @type = 4 begin     
        exec ccspSaveDispositionResult @action=5,@callType=1,@camId=@inbound_id,@dispotitionId=@calif_id
    end


    drop table #CalifTemp
    set nocount off'
    EXEC(@sql)

    set @process = 'Alter SP ccsp_RIAADMGetCalifDayForced --Merge 20230719.0.9' 
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint,
@calif_id smallint = NULL,
@isKolob BIT = 0
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(150), 
subCalificacion varchar(150) null,
calif_id smallint null,
Total int,
GraphColor varchar(15),
IsSubDisp BIT)

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación'' WHEN 1 THEN ''No disposition''  else ''Sem classificação'' end
from ccsettings where setting_id = 27 -- 0esp

select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

if @type=0 BEGIN
    insert into #CalifTemp 
    exec ccspSaveDispositionResult @action=3,@callType=1,@camId=@cam_id
END

if @type=1 BEGIN
    insert into #CalifTemp 
    exec ccspSaveDispositionResult @action=4,@callType=0,@camId=@cam_id
END
-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0 begin
    update #CalifTemp set iTotal4Campaign = 0
end
else begin    
    update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
    from (select cam_id, sum(A.Total) iTotal4Campaign
    from #CalifTemp A group by cam_id) t join #CalifTemp c
    on t.cam_id = c.cam_id
end

if @type=1 BEGIN
    IF(@isKolob = 1)BEGIN
        select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
        select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
            else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end as Calificacion,0 as subCalificacion ,a.disposition as calif_id, COUNT(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
        from ccriachats a left join ccTipoCalif b 
        on a.disposition=b.calif_id 
        where a.chatDate > @today
        and a.inboundId = @cam_id
        group by inboundId, Description, GraphColor, a.disposition
        union all


        select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end as Calificacion,
        case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
        from #CalifTemp 
        group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end, Cam_id,calif_id, iTotal4Campaign, GraphColor
        )  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor   order by tipo,cam_id 
    END
    ELSE BEGIN
        select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
        select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
            else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
        from ccriachats a left join ccTipoCalif b 
        on a.disposition=b.calif_id 
        where a.chatDate > @today
        and a.inboundId = @cam_id
        group by inboundId, Description, GraphColor

        union all


        select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end as Calificacion,
        case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
        from #CalifTemp 
        group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end, Cam_id,calif_id, iTotal4Campaign, GraphColor
    )  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
    END
END
    
if @type=0 Begin

    select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
    then calificacion 
    else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
    end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
    ,IsSubDisp
    from #CalifTemp 
    group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
    then calificacion 
    else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
    end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor, IsSubDisp

End

if @type = 3 begin -----entrada acd''s
    select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
    else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
    end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
    from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
    left join ccInbound cci on cci.inbound_id = ci.inbound_id 
    left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
    where ci.cal_inicio > @today
    and ci.inbound_id = @cam_id
    and statuscall_id = 13 
    and ci.calif_id = @calif_id
    group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end

if @type = 4 begin --salida campañas
        select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
            then case when description is not null 
                        then description 
                        else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                        end
    else case when sll.descripcion is not null 
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
    end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
    left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
    left join ccCamps ci on ci.cam_id = co.cam_id 
    where co.cal_inicio > @today
    and co.cam_id = @cam_id
    group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 


drop table #CalifTemp 
set nocount off'
    EXEC(@sql)

    SET @process = 'DEV1-409 Alter SP ccsp_CstoCalculaCosto --> if not exists(select * from cstoTarifa) begin';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
@IDCall int = 0,
@from AS smalldatetime = NULL,
@to AS smalldatetime = NULL
AS
set nocount on
declare @minutouno decimal(10,3), @minutoadicional decimal(10,3)
declare @puerto smallint, @provedor_id smallint
declare @longitud tinyint, @tipoLlamada_id tinyint
declare @telefono varchar(20)
  
if not exists(select * from cstoTarifa) begin
return (0);
end

if @IDCall = 0 -- Para calcular todo
begin
    if @from is null and @to is null
    begin
        update ccoCallsOut
        --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
        set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
        ,provedor_id = cd.provedor_id
        ,tipoLlamada_id = t.tipoLlamada_id
        from ccoCallsOut cco with(index(IX_ccoCallsOut_7), nolock), ccoDialers cd, cstoTarifa t
        where cco.cal_puerto = cd.puerto
        and cd.provedor_id = t.provedor_id 
        and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cal_telefono)
        and cco.cal_manual <> 1
        return(0)
    end
  
    -- calcula en el rango de fechas, solo los que no tienen costo
    update ccoCallsOut
    --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
    set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
    ,provedor_id = cd.provedor_id
    ,tipoLlamada_id = t.tipoLlamada_id
    from ccoCallsOut cco with(index(IX_ccoCallsOut_8), nolock), ccoDialers cd, cstoTarifa t
    where cco.cal_puerto = cd.puerto
    and cd.provedor_id = t.provedor_id 
    and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cco.cal_telefono)
    and cco.cal_manual <> 1
    and cco.cal_inicio between @from and @to
    and cco.provedor_id is null
    return(0)
end
  
select @puerto = cal_puerto, @longitud = len(cal_telefono) , @telefono = cal_telefono 
from ccoCallsOut with(index(PK_ccoCallsOut), nolock) where cal_id = @idCall
  
if @puerto = 0
    return(0)
  
select @tipoLlamada_id = dbo.fnGetTipoLlamada(@telefono)

select @minutouno = minutouno, @minutoadicional = minutoadicional, @provedor_id = d.provedor_id
from cstoTarifa t
inner join ccoDialers d on d.provedor_id = t.provedor_id
where t.tipollamada_id = @tipoLlamada_id
and d.puerto = @puerto
  
update ccoCallsOut with(rowlock) 
--set costo = @MinutoUno + case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
set costo = @MinutoUno + case when ISNULL(totalCall_Time,0) > 0 then((ceiling(( ISNULL(totalCall_Time,0) ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
where cal_id = @idCall
  
set nocount off';
    EXEC(@sql);

    set @process = 'DEV1-409 Alter SP ccsp_DLRInsertCall ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRInsertCall]
@callout_id int,
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(14),
@Puerto smallint,
@logDial_id int=0
AS
declare @fecha as datetime
declare @cal_id as int

select @fecha=getdate()
INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --''Status 6=Pide Agente
  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto,  @fecha, 6 )

select @cal_id = scope_identity()

insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
where wg.Tipo=1 and wg.idcampesp=@cam_id


exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=6

-- calcula el costo de la llamada
exec ccsp_CstoCalculaCosto @cal_id

select @cal_id as cal_id
'
    EXEC(@sql)

    



    SET @process = 'DEV1-444 Asembis Alter SP AgentCheckCampsActive se agerga valicacion si es null @idArea';
    SET @sql = 'ALTER PROCEDURE [dbo].[AgentCheckCampsActive]
@cam_id as smallint,
@user_id as smallint,
@forceManualCall as tinyint = 0
AS

declare @isValidCall as int
declare @timeZoneRule as int
declare @idArea as int

select @isValidCall = count(*)from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
select @idArea = IDArea from ccCamps with(nolock) where cam_id = @cam_id
select @timeZoneRule = 0
if @idArea is not NULL
begin
    select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 1
    from ccCamps with(nolock) where cam_id = @cam_id
    end

    else if @idArea is null
    begin
    select  @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 0
    from ccCamps with(nolock) where cam_id = @cam_id
    end

select @isValidCall as Validation, @timeZoneRule as TimeZoneRule, isnull(@idArea,0) as Active';
    EXEC(@sql);

    SET @process = 'DEV1-444 Asembis Alter SP ccsp_GalateaAdminCampaigns IF @Option = 12 left JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
@Option AS      SMALLINT, 
@CampType AS    SMALLINT = 0, 
@WorkgroupId AS INT      = 0, 
@Id AS          INT      = 0, 
@AdminId AS     SMALLINT = 0, 
@PinUpdate AS   SMALLINT = 0, 
@LoadId AS      INT      = 0, 
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
    IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                    AND Tipo = 1
                                    ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                    AND Tipo = 0
                                    ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
                            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                            camps.cam_procesando IsStarted, 
                            ISNULL(a.AreaName, '''') AS Area, 
                            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
                            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
                            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
                            FROM ccCamps camps
                            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
                            WHERE camps.cam_id = @Id
                            ORDER BY camps.cam_descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                            CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
                            ISNULL(a.AreaName, '''') AS Area, 
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType
                            FROM ccInbound inb
                                    LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                    LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                            WHERE inb.Inbound_id = @Id
                                    ORDER BY inb.descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 3   -- Update OverallTotalNew By Campaign
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    UPDATE ccCampsNvosCB
                        SET 
                            OverallTotalNew = ccCampsNvosCB.new
                    WHERE id = @Id;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 4   -- Update Pin from Campaign per Admin
        BEGIN
            IF @Id IS NOT NULL
                AND @AdminId IS NOT NULL
                BEGIN
                    IF @PinUpdate = 1
                        BEGIN
                            INSERT INTO PinedCampaigns(CampId, AdminId, Type)
                        VALUES(@Id, @AdminId, @Type);
                    END;
                    IF @PinUpdate = 0
                        BEGIN
                            DELETE FROM PinedCampaigns
                            WHERE CampId = @Id
                                    AND AdminId = @AdminId
                                    AND Type = @Type;
                    END;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 5   -- Get Pin from Campaign Ids per Admin
        BEGIN
            IF @AdminId IS NOT NULL
                BEGIN
                    SELECT CampId AS Id
                    FROM PinedCampaigns
                    WHERE AdminId = @AdminId
                            AND Type = @Type
                            ORDER BY Id ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 6   -- Get Blacklist Ids by Campaign Id
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    DECLARE @BlackListIds VARCHAR(MAX);
                    SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                    FROM Camplistanegra
                    WHERE cam_id = @Id
                            AND STATUS = 1;
                    SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
        BEGIN
            IF(@Id IS NOT NULL
                AND EXISTS
            (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
            ))
                BEGIN
                    SELECT TOP 1 list_id
                    FROM ccRIARegistryLists
                    WHERE cam_id = @Id
                            AND STATUS = 2
                            ORDER BY list_id DESC;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
        BEGIN
            IF(@LoadId IS NOT NULL
                AND EXISTS
            (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                        AND STATUS <> 0
            ))
                BEGIN
                    UPDATE ccoCallsOutSource
                        SET 
                            cal_status = ''5''
                    WHERE list_id = @loadID;
                    DELETE FROM ccoWorkingTable
                    WHERE list_id = @LoadId;
                    EXEC ccsp_RIARegistryLists 
                            @action = 6, 
                            @list_id = @LoadId;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
        BEGIN
            DECLARE @table TABLE
            (camId    INT, 
                campType TINYINT, 
                PRIMARY KEY(camId, campType)
            );
            INSERT INTO @table
                    SELECT DISTINCT 
                            IdCampEsp, Tipo
                    FROM ccRIACampEspWG wg
                    WHERE wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE IDWG <> @WorkgroupId
                                AND User_id = @AdminId
                    );
            SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
            FROM @table A
                    RIGHT JOIN
            (
                SELECT wg.IdCampEsp, wg.Tipo
                FROM ccRIACampEspWG wg
                WHERE wg.IDWG = @WorkgroupId
            ) B ON A.camId = B.IdCampEsp
                    AND A.campType = B.Tipo
            WHERE A.camId IS NULL
                    ORDER BY IdCampEsp;
            RETURN 0;
    END;
    IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
    BEGIN
    DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
    DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
    DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
    DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
    DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
    DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
    DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

    INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
    FROM ccRIAWorkGroupUsers WG, 
        ccUsers_Roles R
    WHERE WG.User_id = @AdminId
    OR (R.User_id = @AdminId
    AND R.Rol_id = 7);
                            
    INSERT INTO @AgentsList SELECT DISTINCT A.User_id
    FROM ccRIAWorkGroupUsers A
    INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
    INNER JOIN ccUsers C ON A.User_id = C.User_id 
    AND C.TipoUser_id = 1
    ORDER BY A.User_id;

                    INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
    CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
    FROM ccRIACampEspWG campPerWg
    INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
    INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
    INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
    left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
    left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
    where C.TipoUser_id = 1
    AND campPerWg.Tipo = @CampType
    AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
                      
    ;WITH lastState AS (
    SELECT A.user_id, MAX(A.fecha) AS fecha
    FROM ccLogAgentesDia A
    INNER JOIN @AgentsList B ON A.User_id = B.id
    WHERE fecha >= @date
    GROUP BY user_id)

    INSERT INTO @CurrentStatus 
    SELECT B.User_id,
    CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
    B.IdCampEsp,
    B.Tipo
    FROM lastState A
    INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
    AND A.fecha = B.fecha;

    IF @Id = 0 AND @CampType = 0 
    BEGIN
    DELETE FROM @tmpCamAgent WHERE multimediaType = 5
    END

    DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
    IF @CampType = 1 BEGIN
    SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
    END
    ELSE BEGIN
        SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
        SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
    END 

    IF(@chatType = 1)
    BEGIN
        SET @MultimediaType = 1
    END
            
    DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
            
    INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
    (CASE 
        WHEN @chatType = 1 THEN 
        CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
        ELSE 
        CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
        ELSE null 
        END END END) AS isCampDialog, B.camType
    FROM @tmpCamAgent A
    INNER JOIN @CurrentStatus B ON A.userId = B.userId
    WHERE (@Id = 0 or A.camId = @Id)

    IF @CampType = 1
    BEGIN
    ;with  campDataTotal as(
        select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
        A.camId,
        B.cam_descripcion as campName 
        ,A.Total
        ,C.AreaName as Area
        from campDataTotal A
        INNER JOIN ccCamps B ON A.camId= B.cam_id 
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
    ELSE
    BEGIN    
    ;with  campDataTotal as(
        select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
        A.camId,
        B.descripcion as campName 
        ,A.Total
        ,C.AreaName as Area
        from campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END

    ;WITH stateCamp AS(
    SELECT A.CampId,
    count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
    count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
            WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
    COUNT(isCampDialog) AS dialog, 
    COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
    FROM @AgentStatus A
    INNER JOIN @CurrentStatus C ON A.userId = C.userId
    GROUP BY A.CampId
    )

    SELECT 
    A.camId,
    A.campName,
    A.Total,
        ISNULL(B.ready, 0) AS Ready,
    ISNULL(B.notReady, 0 ) AS NotReady, 
    ISNULL(B.dialog, 0) AS Dialog,
    CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
    A.Area
    FROM @campDataTotal A
    LEFT JOIN stateCamp B ON A.camId = B.CampId
    ORDER BY A.campName

        RETURN 0;
    END;
    IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN                
            IF Not EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                        AND Rol_id = 7
            )
                BEGIN
        print ''xxxx SIn Super''
                    ;WITH wgId
                            AS (SELECT IDWG
                                FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG A (NOLOCK)
                                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                    AND A.Tipo = @CampType;
            END;
            ELSE
                BEGIN
        --print ''xxxx Super''
        IF @CampType = 1
        BEGIN
            SELECT DISTINCT 
                CAST(cam_id AS INT) AS Id
                        FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
        END
        ELSE
        BEGIN 
            SELECT DISTINCT 
                CAST(Inbound_id AS INT) AS Id
                        FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
        END
            END;
            RETURN 0;
    END;
    IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    SELECT DISTINCT 
                    CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
                    isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                    camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
                    CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
                    ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
                    FROM ccCamps camps (NOLOCK)
                    INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
                    INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
                    left JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
                    --WHERE camps.cam_id = @Id
                    ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                                            CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId, inb.chat AS InboundType, 0 as OutboundType
                    FROM ccInbound inb (NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
                            INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
                            ORDER BY inb.descripcion ASC;
            END;
            RETURN 0;
    END;
    IF @Option = 13
    BEGIN
        BEGIN                
            IF NOT EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                        AND Rol_id = 7
            )
                BEGIN
                    IF @CampType = 1
                        BEGIN
                            WITH wgId
                                AS (SELECT IDWG
                                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
                                FROM ccRIACampEspWG A
                                    INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                        AND A.Tipo = 1
                                    INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
                        END
                    ELSE
                        BEGIN
                            WITH wgId
                                AS (SELECT IDWG
                                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                                FROM ccRIACampEspWG A (NOLOCK)
                                    INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                        AND A.Tipo = 0
                                    INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
                        END
            END;
            ELSE
                BEGIN
                IF @CampType = 1
                    BEGIN
                        SELECT DISTINCT 
                                CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
                        FROM ccCamps NOLOCK where IDArea = @AreaId
                    END
                ELSE
                    BEGIN 
                        SELECT DISTINCT 
                                CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                        FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                    END
            END;
            RETURN 0;
        END;
    END;

    IF @Option = 14
        BEGIN
            IF NOT EXISTS
            (
                    SELECT *
                    FROM ccUsers_Roles NOLOCK
                    WHERE User_id = @AdminId
                            AND Rol_id = 7
            )
                BEGIN
                    WITH wgId
                            AS (SELECT IDWG
                                FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                            FROM ccRIACampEspWG A (NOLOCK)
                                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                    AND A.Tipo = 0
                                INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
                                AND ((@multi_type is null AND cci.chat = @InboundType)
                                    OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                END
            ELSE
                BEGIN
                    SELECT DISTINCT 
                    CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                END
        END
    IF @Option = 15
        BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
        END
END;
';
    EXEC(@sql);

    set @process = 'Alter SP ccspAgent_GetLastCalls --Merge 20230719.0.9'     
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
SET NOCOUNT ON;
DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                        , tipo         VARCHAR(10) NOT NULL
                        , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                        , Telefono     VARCHAR(55) NOT NULL
                        , EspCamp      VARCHAR(55) NOT NULL
                        , Calificacion VARCHAR(150)
                        , Duracion     VARCHAR(10) NOT NULL
                        , CallBack     DATETIME
                        , cal_key      VARCHAR(40)
                        , IDCampEsp    SMALLINT NOT NULL
                        , prefijo      VARCHAR(255) NULL
                        , GraphicID    INT
                        , CamManualMode INT
                        , SelectRotativeANI INT
                        , PRIMARY KEY(id,tipo)
);

DECLARE @pais TINYINT;
DECLARE @maxHours SMALLINT;
DECLARE @topRows INT;
DECLARE @setting VARCHAR(6);
DECLARE @hidePhone BIT;
DECLARE @dateStart DATETIME;

SET @hidePhone = 1;

SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

IF @maxHours = 0
BEGIN
    SELECT Id
        , tipo
        , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
        , Telefono
        , EspCamp
        , Calificacion
        , CallBack
        , Duracion
        , '''' AS CallBack
        , cal_key
        , IDCampEsp
        , prefijo
        , GraphicID
        , SelectRotativeANI
        , @hidePhone AS HidePhone FROM @lastCallAgt;

    RETURN 0;
END;

SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

SELECT @hidePhone = CASE WHEN valor = ''0''
                    THEN 0 ELSE 1
                    END FROM ccSettings WHERE setting_id = 223;

IF @topRows = 0
BEGIN
    SET @topRows = 10000;
END;

SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

WITH timeTransfer
    AS (SELECT cal_id
            , tipo
            , SUM(tAntesXfer) AS tAntesXfer
            , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
        WHERE fechaFin > @dateStart
        GROUP BY cal_id
                , tipo)

    INSERT INTO @lastCallAgt
            ---Insert OUT
            SELECT TOP (@topRows) c.cal_id AS id
                                , ''OUT'' AS Tipo
                                , cal_inicio
                                , cal_telefono AS Telefono
                                , cam_descripcion AS EspCamp
                                , ISNULL(cal.Description, '''') AS Calificacion
                                , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                        THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                        END, 0), 114) AS Duracion
                                , cal_fcallback AS CallBack
                                , cal_key
                                , c.cam_id AS IDCampEsp
                                , ISNULL(ccCamps.prefijo, '''') Prefijo
                                , graph.graphic_id GraphicID
                                , cam_ModoManual as CamManualMode 
                                , ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
                                                                INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                            AND t.tipo = 2
            WHERE user_id = @user_id
                AND cal_inicio > @dateStart
            UNION
            --- IN
            SELECT TOP (@topRows) c.cal_id AS id
                                , ''IN'' AS Tipo
                                , cal_inicio
                                , cal_ani AS Telefono
                                , descripcion AS EspCamp
                                , ISNULL(cal.Description, '''') AS Calificacion
                                , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                END, 0), 108) Duracion
                                , NULL AS CallBack
                                , cal_key
                                , c.inbound_id AS IDCampEsp
                                , ISNULL(ccInbound.prefijo, '''') Prefijo
                                , graph.graphic_id GraphicID
                                , '''' as CamManualMode 
                                , 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                                JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                            AND t.tipo = 1
            WHERE user_id = @user_id
                AND cal_inicio > @dateStart;

SELECT Id
    , tipo
    , CASE WHEN @pais = 4
    THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
    END AS Hora
    , Telefono
    , EspCamp
    , Calificacion
    , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
    , Duracion
    , CallBack
    , cal_key
    , IDCampEsp
    , prefijo
    , GraphicID
    , @hidePhone AS HidePhone 
    , CamManualMode 
    , SelectRotativeANI FROM @lastCallAgt
ORDER BY hora DESC;
SET NOCOUNT OFF;
        ';
    EXEC(@sql);

    SET @process = 'DEV1-440 Alter SP  ccsp_BaseXmngr agrega @action 14 y 15';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null,
@grabIds varchar(4000) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
declare @filterWg varchar(max)
declare @len int
declare @tipo int
declare @serviceId varchar(10)

set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
                            
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
    else ''@CDATE''   end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
    update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
    and Xname=@name
end

else if @action = 10 begin
    
    set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
                        
    end
    else
    begin
    
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
    end


    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
    select SUBSTRING(@filterWg,0, @len)
    end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    set @sql=''
    declare @dateStart datetime
    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
    EXECUTE sp_executesql  @sql

end

else if @action = 13 begin
    set @sql = ''''
    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
    select @tableName,@tableNameHistory,@columnId
    set @sql=''
    ;
    with duplicateIds as(
    select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
    union
    select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
    )

    select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
    inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
    group by A.''+@columnId+'',A.dateIn
    Having count(*)>1
    order by Xname
    ''
    exec (@sql)

end

else if @action = 14 begin
    declare @CidNameOut varchar(100),@CidNameIn varchar(100)
    declare @filterCamId varchar(max)
    declare @campType int
    declare @cidOut varchar(max)=''''
    declare @cidin varchar(max)=''''

    set @filterWg=''''
    if @node is null begin
        set @node=''R02''
    end

    set @CidNameOut=''$CID_OUT_''+@node
    set @CidNameIn=''$CID_In_''+@node

    set @filterCamId=''''

    if @node = ''R02''
    begin
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp and c.CampType not in(5,7)
        where Wguser.User_id=@userId and WGCam.Tipo=1                               
    end
    else if @node = ''R05''
    begin       
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp and c.CampType =5
        where Wguser.User_id=@userId and WGCam.Tipo=1                       
    end

    if @filterCamId<>'''' begin
        if @node in( ''R02'',''R05'') begin
            set @filterWg=''let ''+@CidNameOut+'':=(''
        end

        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
        set @filterCamId=@filterCamId+'')''+char(10)    

        set @filterWg=@filterWg+@filterCamId
    end 
        
    set @tipo = case when @node in(''R01'',''R02'',''R03'',''R04'') then 1  
        when @node =''R05'' then 5 
        when @node =''R06'' then 6 
        else 0 end -- revisar ccsp_CreateNodeMultimedia CTYPE

    set @campType = case when @node =''R01'' then 1 
        when @node =''R02'' then 0
        when @node =''R03'' then 3
        when @node =''R04'' then 4
        when @node =''R05'' then 5
        when @node =''R06'' then 6 else 0 end

    set @filterCamId=''''
            
    select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp and c.chat =@campType
        where Wguser.User_id=@userId and WGCam.Tipo=0
    
    if @filterCamId<>'''' begin
        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
        set @filterCamId=@filterCamId+'')''+char(10)    

        set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterCamId
    end
    
    if @node = ''R02'' begin
        set @cidOut=''(exists(index-of(''+@CidNameOut+'',@CID)) and @CType=2)''
    end
    else if @node = ''R06'' begin
        set @cidOut=''(exists(index-of(''+@CidNameOut+'',@CID)) and @CType=6)''
    end
    if @node not in(''R05'') begin
        set @cidin=''(exists(index-of(''+@CidNameIn+'',@CID)) and @CType=''+ convert(varchar(max), @tipo)+'')''
    end
    
    select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
end
else if @action = 15 begin --Saber si hacer busqueda en basex
  select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
  if @node=''R02'' begin
    select 1
    return(0)
  end

  set @sql=''if exists(select * from ''+@tableName+'') begin
        select 1
    end
    else if exists(select * from ''+@tableNameHistory+'') begin
        select 1
    end
    select 0''
    exec (@sql)
    
end';
    EXEC(@sql);
    
    SET @process = 'CW-8180 ALTER PROCEDURE ccsp_GalateaGetCampsNvosCB se agrega filtro cam.cam_id = @cam_id'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int, @isExecOutbound bit

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

    declare @id AS INTEGER;

    CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,campType INT)
    CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime,campType INT)

    create table #tempoutsource (cam_id int,Pend  int)

    create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

    if @cam_id = 0 begin
        if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
            where user_id = @user_id and tipo = 1
        end
        else begin
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam (nolock)
        end
    end
    else begin
        if @Tipo = 2
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam with(nolock) 
            where cam.cam_id = @cam_id
        else
            if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
                insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
                select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
                ,isnull(cam.CampType,0) as CampType
                from ccCamps cam with(nolock) 
                inner join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
                where user_id = @user_id and tipo = 1 and cam.cam_id = @cam_id
            end
            else begin
                insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
                select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
                ,isnull(cam.CampType,0) as CampType
                from ccCamps cam (nolock) 
                where cam_activo=1  and cam.cam_id = @cam_id
            end
    end
    
    ;with ccCampsNvosCBTmp as(
    select A.*,dateUpdate from #Tcamps A
    left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
    where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null
    )
    insert into #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate,campType)
    select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate),max(campType) as campType 
    from ccCampsNvosCBTmp
    group by cam_id

    if exists(select * from #Tcamps2) BEGIN

        if exists(select * from #Tcamps2 where campType=7) BEGIN
            insert into #tempoutsource(cam_id,Pend)
            SELECT sos.cam_id, count(sos.cam_id) as Pend
            FROM dbo.smsOutSource AS sos  with(index(IX_smsOutSource_1),nolock)
            inner join #Tcamps2 tcam on sos.cam_id = tcam.cam_id
            WHERE tcam.campType=7 and sos.sms_status in(0, 7)
            GROUP BY sos.cam_id

            insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
            SELECT swt.cam_id,
            count(case swt.sms_status when 0 then 1 else null end) as New,
            count(case swt.sms_status when 1 then 1 else null end) as Cb,
            count(case swt.sms_status when 2 then 1 else null end) as Pro,
            count(case swt.sms_status when 3 then 1 else null end) as Fin
            FROM dbo.smsWorkingTable AS swt  with(index(IX_smsWorkingTable_1),nolock)
            inner join #Tcamps2 B on swt.cam_id = B.cam_id 
            where B.campType=7
            GROUP BY swt.cam_id 
        end
            insert into #tempoutsource(cam_id,Pend)
            SELECT ccos.cam_id, count(ccos.cam_id) as Pend
            FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
            join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
            WHERE tcam.campType<>7 and cal_status in(0, 7)
            GROUP BY ccos.cam_id

            insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
            SELECT A.cam_id,
            count(case cal_status when 0 then 1 else null end) as New,
            count(case cal_status when 1 then 1 else null end) as Cb,
            count(case cal_status when 2 then 1 else null end) as Pro,
            count(case cal_status when 3 then 1 else null end) as Fin
            FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
            inner join #Tcamps2 B on A.cam_id = B.cam_id
            WHERE B.campType<>7 
            GROUP BY A.cam_id   
        
        if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
            update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
        end
        else begin
            While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
                set rowcount 1
                select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
                set rowcount 0
                EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
                update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
            end
        end

        declare @TotalNew table(
            cam_id int primary key,
            OverallTotalNew int 
            )
        

        begin Tran updateccCampsNvosCB

            insert into @TotalNew
            select CampNvosCB.id,isnull(CASE WHEN CampNvosCB.OverallTotalNew = 0 THEN NULL ELSE CampNvosCB.OverallTotalNew END,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
            where CampNvosCB.id = tcamp.cam_id

            delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
            where CampNvosCB.id = tcamp.cam_id

            INSERT into ccCampsNvosCB 
            SELECT cams.cam_id, cams.cam_descripcion,
            isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
            isNull(cs.Pend,0) as pend,
            isNull(wt.Pro,0) as pro,
            isNull(cams.procesando,0) cam_procesando,
            isNull(cams.cam_tipojobs,0) cam_tipojobs,
            isNull(wt.Fin,0) Fin,
            isNull(cams.cantidad,0) cantidad,
            getdate(),
            isnull(T.OverallTotalNew,0)  as OverallTotalNew
            FROM #Tcamps2 cams with(nolock)
            LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
            LEFT JOIN #tempoutsource cs on cams.cam_id = cs.cam_id
            LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

        COMMIT TRAN updateccCampsNvosCB
    end

    if @isExecOutbound = 0 begin

    if @Tipo = 2 begin
        -- devuelve resultado de la taba, solo las camps del usuario
        SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
        isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
        FROM #Tcamps tcam
        left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
        LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
        inner join cccamps cc (nolock) on res.id=cc.cam_id
    end
    else 
        SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
        cc.aggressionFactor, OverallTotalNew
        FROM ccCampsNvosCB res (nolock)
        LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
        inner join cccamps cc (nolock) on res.id=cc.cam_id
        WHERE res.id = @cam_id
    end

    drop table #Tcamps
    drop table #Tcamps2
    drop table #tempoutsource
    drop table #temWorkinTable

    return(0)

end

set nocount off'
    EXEC(@sql)
 
    
     set @process = 'Alter SP ccsp_AgentSetCallStatus --Merge 20230719.0.9'    
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
@callout_id INT, 
@cal_id     INT, 
@TipoCall   TINYINT, -- 1= IN,  2=Out
@TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer  float    = 0, 
@cal_tring  float   = 0, 
@user_id    SMALLINT   = 0, 
@extension  VARCHAR(5) = '''', 
@isChatCall BIT        = 0
AS
 SET NOCOUNT ON
 DECLARE @RecicleSIC TINYINT

 SELECT @RecicleSIC = ISNULL(valor, 0)
 FROM ccSettings
 WHERE setting_id = 60

 DECLARE @ANI_x VARCHAR(19)
 DECLARE @cal_inicio DATETIME
 DECLARE @callout_id_IN INT
 DECLARE @cal_key VARCHAR(20)
 DECLARE @cam_id INT
 DECLARE @cal_telefono VARCHAR(30)
 DECLARE @surveycamid INT
 DECLARE @inbound_id INT
IF @TipoMov in(4 ,14) BEGIN-- DIALOG OnDialog    
   IF @TipoCall = 2 BEGIN
        IF @TipoMov = 4 BEGIN
                         UPDATE ccoCallsOUT WITH(ROWLOCK)
                           SET cal_Inicio = GETDATE(), 
                               statusCall_id = 13, 
                               cal_manual = CASE
                                                WHEN @isChatCall = 1
                                                THEN 3
                                                ELSE cal_manual
                                            END
                         WHERE cal_id = @cal_id
                 END
        ELSE IF @TipoMov = 14 begin
                         UPDATE ccoCallsOUT WITH(ROWLOCK)
                           SET statusCall_id = 13, 
                               cal_tRing = @cal_tring, 
                               user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                               cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
                         WHERE cal_id = @cal_id
                SELECT @cam_id=cam_id FROM ccoWorkingTable nolock WHERE callout_id = @callout_id
                IF @RecicleSIC = 0 AND (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) != 6
                BEGIN
                    DELETE ccoWorkingTable WITH(ROWLOCK) WHERE callout_id = @callout_id
                    DELETE ccoCallPriorityOrder WITH(ROWLOCK) WHERE callout_id = @callout_id
                END
                 UPDATE ccoCallBacks
                   SET [status] = 1, 
                       schedulerStatus = 1, 
                       cal_fcallback = cal_inicio
                 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                 WHERE a.callout_id = b.callout_id
                       AND b.callout_id = @callout_id
                       AND b.cal_id = @cal_id
                       AND [status] = 0
                       AND statusCall_id = 13

        exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=1,@statusCallId=13
                 -- calcula el costo de la llamada
                 EXEC ccsp_CstoCalculaCosto @cal_id

                 RETURN(0)
         END
    IF @TipoMov = 4 begin            
             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 13
             WHERE cal_id = @cal_id
    end

    ELSE IF @TipoMov = 14 begin
                 UPDATE ccCallsIN WITH(ROWLOCK)
                   SET statusCall_id = 13, 
                       cal_tRing = @cal_tring, 
                       user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                       cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
                 WHERE cal_id = @cal_id
    end

    exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=0,@statusCallId=13
         -- Elimina callback generado por abandono
         SELECT @ANI_x = cal_ani, 
                @cal_inicio = cal_inicio
         FROM cccallsin WITH (INDEX(PK_ccCallsIn))
         WHERE cal_id = @cal_id

         SELECT @callout_id_IN = callout_id
         FROM ccRIAUpdateCallBack_Abandon
         WHERE cal_ani = @ANI_x

         UPDATE ccoCallBacks WITH(ROWLOCK)
           SET [status] = 1, 
               schedulerStatus = 1, 
               cal_fcallback = @cal_inicio
         WHERE callout_id = @callout_id_IN
               AND [status] = 0

         DELETE ccoWorkingTable WITH(ROWLOCK)
         WHERE callout_id IN
         (
             SELECT DISTINCT
                    (callout_id)
             FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
             WHERE cal_ani = @ANI_x
         )

         DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
         WHERE cal_ANI = @ANI_x

         RETURN(0)
 END
IF @TipoMov = 7 BEGIN--OTHER OFFHook_OnXfer
         IF @cal_id <= 0
             RETURN(0)
    IF @TipoCall = 2 BEGIN
                 UPDATE ccoCallsOUT WITH(ROWLOCK)
                   SET statusCall_id = 16
                 WHERE cal_id = @cal_id
                 -- calcula el costo de la llamada

                 UPDATE ccoCallBacks
                   SET [status] = 2, 
                       schedulerStatus = 1, 
                       cal_fcallback = cal_inicio
                 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                 WHERE a.callout_id = b.callout_id
                       AND b.callout_id = @callout_id
                       AND b.cal_id = @cal_id
                       AND [status] = 0
                       AND statusCall_id = 16


        exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=1,@statusCallId=16

        EXEC ccsp_CstoCalculaCosto @cal_id

                 RETURN(0)
         END
         UPDATE ccCallsIN WITH(ROWLOCK)
           SET statusCall_id = 16
         WHERE cal_id = @cal_id

         SELECT @ANI_x = cal_ani, 
                @cal_inicio = cal_inicio
         FROM cccallsin WITH (INDEX(PK_ccCallsIn))
         WHERE cal_id = @cal_id

         SELECT @callout_id_IN
         FROM ccRIAUpdateCallBack_Abandon
         WHERE cal_ani = @ANI_x

         UPDATE ccoCallBacks WITH(ROWLOCK)
           SET [status] = 2, 
               schedulerStatus = 1, 
               cal_fcallback = @cal_inicio
         WHERE callout_id = @callout_id_IN
               AND [status] = 0

         RETURN(0)
 END
IF @TipoMov = 9 BEGIN--RING CallNoAnswered    
    IF @TipoCall = 2 BEGIN
        
                 UPDATE ccoCallsOUT WITH(ROWLOCK)
                   SET statusCall_id = 15, 
                       cal_tXFer = @cal_txFer, 
                       cal_tRing = @cal_tring
                 WHERE cal_id = @cal_id

        exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=1,@statusCallId=15

                 -- calcula el costo de la llamada

                 UPDATE ccoCallBacks
                   SET [status] = 2, 
                       schedulerStatus = 1, 
                       cal_fcallback = cal_inicio
                 FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                 WHERE a.callout_id = b.callout_id
                       AND b.callout_id = @callout_id
                       AND b.cal_id = @cal_id
                       AND [status] = 0
                       AND statusCall_id = 15

                 EXEC ccsp_CstoCalculaCosto @cal_id

        return (0);
         END

         UPDATE ccCallsIN WITH(ROWLOCK)
           SET statusCall_id = 15, 
               cal_tXFer = @cal_txFer, 
               cal_tRing = @cal_tring
         WHERE cal_id = @cal_id

         SELECT @ANI_x = cal_ani, 
                @cal_inicio = cal_inicio
         FROM cccallsin WITH (INDEX(PK_ccCallsIn))
         WHERE cal_id = @cal_id

         SELECT @callout_id_IN
         FROM ccRIAUpdateCallBack_Abandon
         WHERE cal_ani = @ANI_x

         UPDATE ccoCallBacks WITH(ROWLOCK)
           SET [status] = 2, 
               schedulerStatus = 1, 
               cal_fcallback = @cal_inicio
         WHERE callout_id = @callout_id_IN
               AND [status] = 0

         RETURN(0)
 END
 SET NOCOUNT OFF'
    EXEC(@sql)   
    -------------------------------------End Jesus Gallardo hotfix/125.20230719.0.9-----------------------------------------------------------
	
	SET @process = 'CW-8180 DROP PROCEDURE ccsp_OUTUpdateDialJob se agrega validacion ExistePriorityOrder'
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_OUTUpdateDialJob'')
    begin
        DROP PROCEDURE ccsp_OUTUpdateDialJob;
    end'
	EXEC(@sql)

SET @process = 'CW-8180 CREATE PROCEDURE ccsp_OUTUpdateDialJob se agrega validacion ExistePriorityOrder'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
		@callout_id     INT,
		@CallResultDial TINYINT,
		@isTCPA         BIT     = 0
		AS
			 SET NOCOUNT ON

		/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
		++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

			 DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
			 DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
			 DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
			 DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
			 DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
			 DECLARE @DateNextDial SMALLDATETIME, @DateNewDial SMALLDATETIME, @cam_id SMALLINT
			 DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
			 DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)
			 DECLARE @ExistePriorityOrder TINYINT
			 
			 SELECT @cam_id = cam_id,
					@nOcupado = ISNULL(nOcupado, 0),
					@nNoContesta = ISNULL(nNoContesta, 0),
					@nFax = ISNULL(nFax, 0),
					@nContestadora = ISNULL(nContestadora, 0),
					@nShortCall = ISNULL(nShortCall, 0),
					@nOtro = ISNULL(nOtro, 0),
					@DateNextDial = cal_fechaDial
			 FROM ccoWorkingTable with(nolock)
			 WHERE callout_id = @callout_id

			 SELECT @ExisteWT = CASE WHEN @cam_id IS NOT NULL THEN 1 ELSE 0 END
			 SELECT @cal_status = CASE WHEN @isTCPA = 1 THEN 0 ELSE 1 END--si esta en modo TCPA no gene|rar callbacks

			 IF @CallResultDial = 20 BEGIN-- CONTACTADO
				EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
				RETURN(0)
			 END
			 else IF @CallResultDial = 1 BEGIN-- CONTESTO
				IF @isTCPA = 1 BEGIN
						UPDATE ccoWorkingTable with(rowlock) SET cal_status = @cal_status WHERE callout_id = @callout_id
				END
				ELSE BEGIN
					IF (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) = 6
						RETURN(0)
					IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
						BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
					END
					ELSE BEGIN
						EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
					END
				END
				RETURN(0)
			 END
			 ELSE IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
				SELECT @cam_ocupado = cam_ocupado,
					@cam_inter_ocupado = cam_inter_ocupado,
					@cam_NoInt_ocupado = cam_NoInt_ocupado,
					@nOcupado = @nOcupado + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

					IF @cam_ocupado = 1 BEGIN -- Opcion Ocupado HABILITADA
						IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4 BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
							RETURN(0)
						END


			SELECT 
				@prioridadLlamada = priorityCall ,
				@ExistePriorityOrder = CASE WHEN callout_id IS NOT NULL THEN 1 ELSE 0 END 
			FROM 
				ccoCallPriorityOrder WITH(NOLOCK) 
			WHERE callout_id = @callout_id

			IF @ExistePriorityOrder IS NULL BEGIN
				SELECT 
					@prioridadLlamada = Prioridad 
				FROM ccCampsPrioridadTel WITH(NOLOCK)
				WHERE cam_id = @cam_id

				INSERT INTO ccoCallPriorityOrder 
				VALUES (@callout_id,@prioridadLlamada)
			END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
						WHERE callout_id = @callout_id


						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

						-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
						IF @DateNewDial > @DateNextDial BEGIN	-- Nueva fecha de Call BACk
							UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
							WHERE callout_id = @callout_id
							RETURN(0)
						END
						-- Mantiene la fecha de Call BACK
						UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
						WHERE callout_id = @callout_id
						RETURN(0)
					END

					-- ELSE: Opcion Ocupado DESHABILITADA
					EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
					RETURN(0)
				 END
				 ELSE IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
					--select NO Contesta
					SELECT @cam_nocontesto = cam_nocontesto,
						@cam_inter_nocontesto = cam_inter_nocontesto,
						@cam_NoInt_nocontesto = cam_NoInt_nocontesto,
						@nNoContesta = @nNoContesta + 1
					FROM ccCamps
					WHERE cam_id = @cam_id

					IF @cam_nocontesto = 1 BEGIN-- Opcion NoContesta HABILITADA
						IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4 BEGIN --select No Contesta Habilitada
							EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
							RETURN(0)
						END

			SELECT 
				@prioridadLlamada = priorityCall ,
				@ExistePriorityOrder = CASE WHEN callout_id IS NOT NULL THEN 1 ELSE 0 END 
			FROM 
				ccoCallPriorityOrder WITH(NOLOCK) 
			WHERE callout_id = @callout_id

			IF @ExistePriorityOrder IS NULL BEGIN
				SELECT 
					@prioridadLlamada = Prioridad 
				FROM ccCampsPrioridadTel WITH(NOLOCK)
				WHERE cam_id = @cam_id

				INSERT INTO ccoCallPriorityOrder 
				VALUES (@callout_id,@prioridadLlamada)
			END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
						ELSE nNoContesta END
						WHERE callout_id = @callout_id


						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

						UPDATE ccoWorkingTable with(rowlock) SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono,
							cal_fechaDial = CASE
												WHEN @DateNewDial > @DateNextDial
												THEN @DateNewDial
												ELSE cal_fechaDial
											END
						WHERE callout_id = @callout_id
						RETURN(0)
					END

					-- Opcion NoContesta DESHABILITADA
					EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
					RETURN(0)
				END
			ELSE IF @CallResultDial = 4 BEGIN-- Fax/Modem
				SELECT @cam_fax = cam_fax,
					@cam_inter_fax = cam_inter_fax,
					@cam_NoInt_fax = cam_NoInt_fax,
					@nFax = @nFax + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

				IF @cam_fax = 1 BEGIN-- Opcion Fax/Modem HABILITADA
						IF @nFax > @cam_NoInt_fax OR @nShortCall > 4 BEGIN
							EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
							RETURN(0)
						END

			SELECT 
				@prioridadLlamada = priorityCall ,
				@ExistePriorityOrder = CASE WHEN callout_id IS NOT NULL THEN 1 ELSE 0 END 
			FROM 
				ccoCallPriorityOrder WITH(NOLOCK) 
			WHERE callout_id = @callout_id

			IF @ExistePriorityOrder IS NULL BEGIN
				SELECT 
					@prioridadLlamada = Prioridad 
				FROM ccCampsPrioridadTel WITH(NOLOCK)
				WHERE cam_id = @cam_id

				INSERT INTO ccoCallPriorityOrder 
				VALUES (@callout_id,@prioridadLlamada)
			END

						-- Change priority and obtain the next telephone
						UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
						WHERE callout_id = @callout_id

						set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
						UPDATE ccoCallPriorityOrder with(rowlock)  SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

						SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
						+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
						+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
						+ CAST(@callout_id AS VARCHAR(15))

						EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

						SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

						-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
						UPDATE ccoWorkingTable with(rowlock) SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono,
							cal_fechaDial = CASE
												WHEN @DateNewDial > @DateNextDial
												THEN @DateNewDial
												ELSE cal_fechaDial
											END
						WHERE callout_id = @callout_id
						RETURN(0)
				END

				-- Opcion Fax/Modem DESHABILITADA
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial = 11 BEGIN-- Maquina Contestadora
				SELECT @cam_graba = cam_graba,
					@cam_inter_graba = cam_inter_graba,
					@cam_NoInt_graba = cam_NoInt_graba,
					@nContestadora = @nContestadora + 1
				FROM ccCamps
				WHERE cam_id = @cam_id

				IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
					IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4 BEGIN
						EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
						RETURN(0)
					END

			SELECT 
				@prioridadLlamada = priorityCall ,
				@ExistePriorityOrder = CASE WHEN callout_id IS NOT NULL THEN 1 ELSE 0 END 
			FROM 
				ccoCallPriorityOrder WITH(NOLOCK) 
			WHERE callout_id = @callout_id

			IF @ExistePriorityOrder IS NULL BEGIN
				SELECT 
					@prioridadLlamada = Prioridad 
				FROM ccCampsPrioridadTel WITH(NOLOCK)
				WHERE cam_id = @cam_id

				INSERT INTO ccoCallPriorityOrder 
				VALUES (@callout_id,@prioridadLlamada)
			END

					-- Change priority and obtain the next telephone
					UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
					WHERE callout_id = @callout_id

					set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
					UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

					SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
					+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
					+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
					+ CAST(@callout_id AS VARCHAR(15))

					EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

					SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

					-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
					UPDATE ccoWorkingTable with(rowlock) SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono,
						cal_fechaDial = CASE
											WHEN @DateNewDial > @DateNextDial
											THEN @DateNewDial
											ELSE cal_fechaDial
										END
					WHERE callout_id = @callout_id
					RETURN(0)
				END

				-- Opcion Maquina Contestadora DESHABILITADA
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial IN(10, 90) BEGIN--No Dial Tone, otros, NoService
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END
			ELSE IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
			   EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
			END

		RETURN(0)
		SET NOCOUNT OFF'
	EXEC(@sql)
	-------------------------------------End Omar Mejia hotfix/125.20230719.0.9-----------------------------------------------------------

    
    SET @process = 'DEV1-444 Asembis Alter SP ccsp_LoadGraphics se cambia inner a left join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint,
@phone varchar(50)=null
AS
BEGIN
        
    SET NOCOUNT ON  
    DECLARE @realValue int      
    exec @realValue= ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType,@phone=@phone
    
    if (@callType=1)
    begin
        DECLARE @canReprogram bit  
        create table #canReprogram (canReprogram bit)
        insert into #canReprogram
        exec ccsp_AgentGetCampReprogramData @Id, @callType
        select @canReprogram = canReprogram from #canReprogram
        drop table #canReprogram

        select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage , a2.EditableContactData,
        case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
        isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
        a2.ShowCalifWnd as ShowDisposition,
        isnull(a2.startStopRecording,0) as StartStopRecording,
        @realValue as IsStartStopRecording,
        isnull(a2.editableDtmf, 0) as isEditDtmf,
        @canReprogram  CanReprogram
        from ccRIAInboundGraph a1 
        inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
         inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
         left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id        
     end    
     else
     begin
        select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
        case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
        case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
        a2.cam_ShowCalifWnd as ShowDisposition,
        a2.callBackSurveyAgent,a2.callBackSurveyClient,
        isnull(a2.startStopRecording,0) as StartStopRecording,
        @realValue as IsStartStopRecording,
        ISNULL( a4.EditableContactData,0) as EditableContactData
        from ccRIACampsGraph a1 
        inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
        left join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)
        left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
        from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
        where M.cam_id = @Id and type = 8) b 
        on (a2.cam_id = b.cam_id) 
        where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
     end    
END
    ';
    EXEC(@sql);

    SET @process = 'DEV1-444 Asembis Alter SP ccsp_RIAACDCallParams se cambia para dar un valor fijo @RecordCalls';
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAACDCallParams]
@option int,
@campId int = 0
AS
BEGIN
    SET NOCOUNT ON;
declare @RecordCalls tinyint
set @RecordCalls=0
if(@option = 1)
begin
    select @RecordCalls= RecordCalls from ccInboundExtend where Inbound_id = @campId                
end

else if(@option = 2)
begin
    select @RecordCalls= RecordCalls from ccCampsExtend where cam_id = @campId              
end
select @RecordCalls RecordCalls

    SET NOCOUNT OFF;
END';
    EXEC(@sql);



        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END


	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
