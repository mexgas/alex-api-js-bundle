/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.37

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 38
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

		SET @process = 'fix/CW-7678 Alter SP ccsp_GetAgentIndividualCounters if @type = 5 se modifica para que tengamos los tiempos cada login'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
    begin
        SELECT User_id, case
            WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
                THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
            ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
                convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
            END as logintime
        FROM ccLogLogin a with(nolock,index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
        where fecha >= @fecha_ini
        and a.User_id = b.agt
        and b.sup = @sup_id
        GROUP BY User_id
    end

else if @type = 2 begin--Status agent
    
    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select User_id,TipoStatusAge_id,sum(segundos) as segundos from (
    SELECT User_id, TipoStatusAge_id, tStatus As segundos
    FROM ccLogAgentesDia a with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent b  on  a.User_id = b.userId   
    WHERE fecha >= @fecha_ini   
    union all   
    select A.User_id,
    case when A.TipoStatusAge_id in(0,1) then 3
    when A.currentStatus in (21,5,9) then 4
    else A.currentStatus end as TipoStatusAge_id,
    DATEDIFF(ss,A.fecha,getdate()) as seconds   
    from ccLogAgentesDia A with(nolock)
    inner join
    (select max(fecha) fecha,USER_ID from ccLogAgentesDia D with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent C on D.User_id=C.userId
    where fecha >= @fecha_ini    
        group by User_id) B
    on A.User_id=B.User_id and A.fecha=B.fecha and A.currentStatus not in (0,-2)

    )x
    group by User_id,TipoStatusAge_id
    ORDER BY User_id

end

else if @type = 3 begin

    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold 
    from ccusers As users ,
        (
            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
            WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
            ELSE 2                          --Llamada de OutBound
            END AS ''type_calls'',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
            from TableUserAgent as tAgent
            inner join ccoCallsOut calls WITH (NOLOCK index(IX_ccoCallsOut_10))   
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id, cal_manual--,tAgent.login
        
            union

            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
            ELSE 1                          --Llamada de InBound
            END AS ''type_calls'',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold

            from TableUserAgent as tAgent
            inner join ccCallsIn calls WITH (NOLOCK index(IX_ccCallsIn_5)) 
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id--,tAgent.login
        ) AS calls
        where users.user_id = calls.user_id     

    end

else if @type = 4
    begin
        
        ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )


        select a.user_id, a.login
        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
        inner join TableUserAgent b on a.User_id=b.userId       
    end
else if @type = 5
    begin          
	declare @users table(userId int primary key)


	if exists(select * from ccUsers_Roles where User_id=@sup_id and Rol_id=1 ) begin
		insert into @users
		select user_id from ccUsers where TipoUser_id=1
	end
	else begin
		
		insert into @users
		select distinct wgAgt.User_id as userId --,usr.login 
		from ccriaworkgroupusers wgAdmin
		inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
		inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
		where 
		wgAdmin.User_id=@sup_id 
	end

	SELECT cast(User_id AS INT) UserId
		,sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END) NotReady
		,sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END) Ready
		,sum(CASE WHEN TipoStatusAge_id = 4 THEN tStatus ELSE 0 END) Dialog
		,sum(CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE 0 END) XFer
		,sum(CASE WHEN TipoStatusAge_id = 6 THEN tStatus ELSE 0 END) Wrapup
		,sum(CASE WHEN TipoStatusAge_id = 7 THEN tStatus ELSE 0 END) Other
		,sum(CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE 0 END) Ringing
		,sum(CASE WHEN TipoStatusAge_id = 11 THEN tStatus ELSE 0 END) Problem
		FROM ccLogAgentesDia A with(nolock)
		inner join @users B on A.User_id=B.userId
		WHERE fecha >= @fecha_ini
			AND TipoStatusAge_id > 0
		GROUP BY User_id 

  
    end
set nocount on

';
		EXEC(@sql);

		SET @process = 'fix/CW-7746 Alter SP ccsp_RIA_ABCCamps if @option = 2 -> if (select valor from ccsettings with(nolock) where setting_id=152) = 1 se modifica para que no ejecutemos un segundo insert en esta petición y no arroje error al crear campañas'
		SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
					@option smallint,
					@UserId int = null,
					@Descripcion varchar(40) = null,
					@Cam_id varchar(1000),
					@Activa tinyint = null,
					@IDArea smallint = null,
					@frame tinyint = null, 
					@MirrorInbound_Id smallint = null,
					@Prefijo varchar(40) = null
					as
					set nocount on

					if @option = 0
						begin
							select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
							from ccCamps as CAMP with(nolock) 
							left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
							return(0)
						end

					if @option = 1 -- select Camp
						begin
							select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
							prefijo as Prefijo
							from ccCamps a1 with(nolock) 
							inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
							inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
							where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
							return(0)
						end

					if @option = 4 --Delete
						begin
							if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
							begin
							declare @error varchar(70)
							Select @error=case valor when 0 then ''No es posible eliminar la campa?a, esta asociada a una especialidad''
								else ''Campaign can not be deleted, it has an association with an ACD'' end
							from ccsettings with(nolock) where setting_id = 27
							raiserror (@error,18,1)		
							return(0)
							end

							delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
							insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
							Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
							Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
							delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
							delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
							return(0)
						end

					if @option = 2 --Insert
						begin
						declare @new_cam_id smallint
						declare @isAssingPortbyCam bit

						DECLARE @CampTypeNormal INT = 1

						if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
							begin
							select -1 --, ''Nombre en Uso''
							return(0)  
							end

						-- ODC: la campa?a siempre esta activa
						set @Activa = 1
						declare @pref int
						select  @pref = valor from ccSettings where setting_id = 201
						if (@pref = 0)
							set @Prefijo = ''''


						Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
						select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
						case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

						if @@rowcount = 1
						select @new_cam_id = scope_identity()

						else
							begin
							select -2 --, ''Error al crear campa?a''
							return(0)
							end

						if isnull(@MirrorInbound_Id, 0)<>0
							begin
							if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
								begin
								select -3 -- Error al asignar campa?a a ACD, el ACD no existe o no pertenece a la misma area
								return(0)
								end

							update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
							update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
							end
						set @isAssingPortbyCam=1

						select @isAssingPortbyCam=valor from ccSettings where setting_id=232

						if @isAssingPortbyCam=1 begin
							insert into ccoDialerCamp (dialer_id, cam_id) 
							select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
						end

						insert into ccCalifCamp (calif_id, cam_id, tipo) 
						select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

						update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

						If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
							begin
							insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
							end

						insert into ccRIACampsGraph (cam_id, graphic_id)
						select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

						--inserta la lista negra por default
						if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
						begin
							declare @tempId as int = 0
							select @tempId = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
							exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
						end

						--select * from cctiposlistanegra

						select @new_cam_id
						return(0)
						end

					if @option = 3 -- Update
						begin
							if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
							insert into ccRIAGraphics (frame,type_id) values (@frame,1)

							Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

							update ccRIACampsGraph with(rowlock)
							set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
							where cam_id = @Cam_id

							return(0)
						end

						if @option = 5 --Obtener relaciones de campa?as - campa?as
						begin
							if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
							(@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
							not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
							begin
							select -3 -- Campa?a invalida
							return(0)
							end
									
						if @descripcion=0
							set @descripcion = null

						update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
						if @@rowcount=0
							select -4 -- Error al actualizar
										
						else
							begin
							delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

							end

						return(0)
						end

					if @option = 6
						begin
							select cam_id, isnull(surveycamid,0)
							from cccamps with(index(PK_ccCamps),nolock)
							where cam_id = @Cam_id
							return(0)
						end

					if @option = 7 -- Checa si la campa?a no tiene grabaciones y se puede modificar el prefijo
						begin	
							select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
							--select 0 as Grabaciones	
						end

					if @option = 8 -- Checa si la campa?a tiene asignada una campa?a tipo encuesta
						begin	
							SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
							from cccamps with(index(PK_ccCamps),nolock)
							where cam_id = @Cam_id
							return(0)
						end

					return(0)
					set nocount off';
		EXEC(@sql);

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
