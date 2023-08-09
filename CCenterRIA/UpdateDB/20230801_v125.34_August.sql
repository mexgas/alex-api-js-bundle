/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.31

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
SET @versionfix = 34
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

	---------------------------------------BEGIN Uriel Cabrera e Ivan Martin---------------------------------------------------------
	/****************************************************************************
	 * CW-8007
	 * Se modifican Sps ccsp_UnassignedElementsInAreas, ccsp_RIA_ABCCamps y ccsp_RIA_ABCACDGroups
	 * para eliminar las campañas de ccCamps y registrarlas en la tabla ccCamps_Consulta
	 * ****************************************************************************/
	SET @process = 'CW-8007 ccsp_UnassignedElementsInAreas se agregan las líneas 158, 159 y 165'
	SET @sql = 'ALTER PROCEDURE [ccsp_UnassignedElementsInAreas]   
									@Action INT,   
									@AreaId INT = 0,
									@Ids VARCHAR(MAX) = ''''
				AS    
				BEGIN
					DECLARE @IdsTemp TABLE (Id INT);
					DECLARE @Id VARCHAR(MAX);
					INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

					-- Return results 
					IF @Action IN (0, 3, 6)	-- User names 
					BEGIN 
						SELECT ISNULL(login,'''')  AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccUsers users ON users.User_id = ids.Id
					END

					IF @Action IN (1, 4, 7)	-- Campaign names
					BEGIN 
						SELECT ISNULL(cam_descripcion,'''')  AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccCamps campaign ON campaign.cam_id = ids.Id
					END

					IF @Action IN (2, 5, 8)	-- Acd names
					BEGIN 
						SELECT ISNULL(descripcion,'''') AS ElementNames
						FROM @IdsTemp ids
						INNER JOIN ccInbound acd ON acd.Inbound_id = ids.Id
					END
					-------------------------------------------------------
					IF @Action = 0 -- Assign Users to Unassigned area 
					BEGIN
						UPDATE ccUsers
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
							status = 1
						FROM @IdsTemp ids
						WHERE ccUsers.User_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccUsers WHERE IDArea = @AreaId AND User_id = ids.Id)
					END

					IF @Action = 1 -- Assign Users to Campaigns area 
					BEGIN
						UPDATE ccCamps
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END
						FROM @IdsTemp ids
						WHERE ccCamps.cam_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccCamps WHERE IDArea = @AreaId AND cam_id = ids.Id)
					END

					IF @Action = 2 -- Assign Users to Acds area 
					BEGIN		
						UPDATE ccInbound
						SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
							status = 1
						FROM @IdsTemp ids
						WHERE ccInbound.Inbound_id = ids.Id
						AND NOT EXISTS (SELECT 1 FROM ccInbound WHERE IDArea = @AreaId AND Inbound_Id = ids.Id)
					END

					IF @Action in (3, 4, 5, 6, 7, 8)
					BEGIN 
						SET @Id = ''0''
						WHILE EXISTS( SELECT Id FROM @IdsTemp ) 
						BEGIN
							SELECT TOP 1 @Id =Id FROM @IdsTemp 

							IF @Action = 3 -- Unassign Users from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option = 2, @DeleteUserId = @Id
							END

							IF @Action = 4 -- Unassign Campaigns from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option=4, @DeleteCamId = @Id
							END 

							IF @Action = 5 -- Unassign Acds from area 
							BEGIN
								EXEC ccsp_RIAManageAreas @option = 6, @DeleteACDGroupId = @Id
							END

							IF @Action = 6 -- Delete Users from area 
							BEGIN
								EXEC ccsp_RIA_ABCAgents @option=4, @UserId = @Id, @Login = '''', @Nombres='''',@ApellidoPaterno='''',@ApellidoMaterno='''',@Password='''',@Sexo=0,@canChangeStatus=0,@AreaId=0,@UserType=0,@IDWG=0
							END

							IF @Action = 7 -- Delete Campaigns from area 
							BEGIN
								EXEC ccsp_RIA_ABCCamps @option = 4, @UserId = 0, @Descripcion = '''', @Cam_id = @Id, @Activa = 0, @IDArea = 0, @frame = 0
								delete ccCamps with(rowlock) where cam_id = @Id
								delete ccCampsExtend with(rowlock) where cam_id = @Id
							END

							IF @Action = 8 -- Delete Acds from area 
							BEGIN
								EXEC ccsp_RIA_ABCACDGroups @option = 4, @UserId = 0, @Descripcion = '''', @Inbound_id = @Id, @IDArea = 0, @frame = 0
								delete ccInbound with(rowlock) where Inbound_id = @Id
							END

							DELETE FROM @IdsTemp WHERE Id = @Id
						END
					END
				END'
	EXEC(@sql)

	SET @process = 'CW-8007 ccsp_RIA_ABCCamps se agregan los deletes en las lineas 228, 229 y 230'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
                    @option smallint,
                    @UserId int = null,
                    @Descripcion varchar(40) = null,
                    @Cam_id varchar(1000),
                    @Activa tinyint = null,
                    @IDArea smallint = null,
                    @frame tinyint = null, 
                    @MirrorInbound_Id smallint = null,
                    @Prefijo varchar(40) = null,
                    @MediaType int = null,
					@isCreating int = null,
					@module int = -1
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
							delete ccoCallsOut with(rowlock) where cam_id = @Cam_id
							delete ccoCallsOutSource with(rowlock) where cam_id = @Cam_id
							delete ccCampsAgente with(rowlock) where cam_id = @Cam_id
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

                        if @@rowcount = 1 BEGIN
                        select @new_cam_id = scope_identity()

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                            getDate(), 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                            CASE 
                                WHEN @MediaType = 6 THEN 44
                                WHEN @MediaType = 5 THEN 46
                                WHEN @MediaType = 4 THEN 48
                                WHEN @MediaType = 7 THEN 50
                                ELSE 42 END, 
                            3, 
                            '''',
                            '''', 
                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @new_cam_id);

                        END else
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

                            DECLARE @PrevFrame SMALLINT = (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id);

                            update ccRIACampsGraph with(rowlock)
                            set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            where cam_id = @Cam_id

							IF(@isCreating IS NOT NULL AND @isCreating = 2 AND @PrevFrame <> (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id) AND @module = 3) BEGIN
                                DECLARE @Media INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @Cam_id);

                                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                                SELECT 
                                    (SELECT CRA.[AreaName] FROM ccRIACat_Areas AS CRA, ccCamps AS CCC WHERE CRA.IDArea = CCC.IDArea AND CCC.cam_id = @Cam_id),
                                    getDate(), 
                                    (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                                    CASE
                                        WHEN @Media = 6 THEN 55
                                        WHEN @Media = 5 THEN 56
                                        WHEN @Media = 4 THEN 57
                                        WHEN @Media = 7 THEN 58
                                        ELSE 54 END, 
                                    3, 
                                    '''',
                                    ''OUT_CALL_EDIT_ICON'', 
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @Cam_id);
                            END

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
                    set nocount off'
	EXEC(@sql)

	SET @process = 'CW-8007 ccsp_RIA_ABCACDGroups se quita delete del option 4 pues ya se agrego en los otros sps y se agrega borrado de la relacion con ccSkills'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCACDGroups]
				@option smallint,
				@userid int,
				@descripcion varchar(40),
				@inbound_id varchar(1000),
				@idarea smallint = null,
				@frame tinyint,
				@Prefijo varchar(40) = null,
				@MediaType int = 0,
				@chatDomain varchar(500) = null
				AS
				SET NOCOUNT ON

				declare @new_inbound_id smallint, @graph_id smallint

				if @option = 0 -- all acd
				 begin
				     select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
				    isnull(areas.areaname,'''') as areaname
				     from ccinbound as acd with(nolock)
				     left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
				     return(0)
				 end

				if @option = 1 -- select acd
				 begin
				     select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id,
				     prefijo as Prefijo
				     from ccinbound a1 
				      inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
				      inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
				     where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
				     order by descripcion
				     return(0)
				 end

				if @option = 2 -- insert
				 begin
				 
				    if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
				    begin
				        select -1	-- ''Nombre en uso''
				        return(0)
				    end
					
					if (@MediaType = 1 and @chatDomain <> '''' and @chatDomain is not null)
					begin
						if exists (select 1 from ccInbound where chatDomain = @chatDomain and Status = 1)
						begin
							select -3	-- ''Domain in use''
							return(0)
						end
					end
				    
				    if @idarea = 0
						set @idarea = null

				    declare @pref int
				    select  @pref = valor from ccSettings where setting_id = 201
				    if (@pref = 0)
				        set @Prefijo = ''''
				    
				    DECLARE @tempDesc VARCHAR(40);
				    SET @tempDesc = CASE WHEN @MediaType = 5 THEN @descripcion ELSE @descripcion+''Tmp'' END;

				    insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd,prefijo)
				    select @tempDesc, 1, @idarea,case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end, @Prefijo
				    
				    if @@rowcount = 1
				        select @new_inbound_id = inbound_id from ccinbound where descripcion = @tempDesc and status = 1
				    else
				    begin
						select -2 -- Error al insertar
				        return(0)
				    end

				    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @new_inbound_id, @userId= @userid

				    UPDATE ccInbound SET descripcion = @descripcion, ShowCalifWnd = case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end
				    WHERE Inbound_id = @new_inbound_id

				    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

				    Create table #ccInboundTable 
				    (
				        columnInfo VARCHAR(255),
				        dataInfo VARCHAR(255),
				        identifierInfo VARCHAR(255)
				    )

				    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';  
				    
				    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				    SELECT 
				        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				        getDate(), 
				        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				        CASE 
							WHEN @MediaType = 5 THEN 40
							WHEN @MediaType = 1 THEN 63
							ELSE 60 END, 
				        3, 
				        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
				                CASE WHEN @MediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
				             WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
				        ELSE
				            CCIT.identifierInfo
				        END,
				        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
				            CASE 
				                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
				                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
				                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
				                ELSE CCIT.dataInfo END
				        ELSE '''' END, 
				        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @new_inbound_id)
				    FROM #ccInboundTable AS CCIT;

				    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid;

				    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

				    insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

				    if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
				    begin
						insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
						select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
				    end

				    if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
				    begin
				        insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
				        select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
				    end

				    if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
						insert into ccriagraphics (frame,type_id) values (@frame,1)
				    
				    select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
				     
				    insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
				    select @new_inbound_id
				    return(0) 
				 end

				if @option = 3 -- update
				 begin
				     if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
				        insert into ccriagraphics (frame, type_id) values (@frame, 1)

				     select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
				     update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
				     update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
				     return(0)
				 end

				if @option = 4 -- delete
				 begin
				     delete cccalifcamp where cam_id = @inbound_id and tipo = 0
				     delete ccinboundhorarios where inbound_id = @inbound_id
				     delete ccriainboundgraph where inbound_id = @inbound_id
				     delete ccInboundMsgs where inbound_id = @inbound_id
				     delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
					 delete ccSkills where inbound_id = @inbound_id
				     return(0)
				 end

				if @option = 5 -- asignar campaña a ACD
				 begin
				    if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
				     (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
				        not exists (select cam_id from ccCamps where cam_id=@descripcion))
				     begin
				        select -3 -- Campaña o ACD invalido
				        return(0)
				     end
				    
				    if @descripcion=0 begin

				        set @descripcion = null
				        --quitamos calificaciones relacionadas a la campaña
				        DELETE c FROM ccCalifCamp c
				        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
				        Where c.cam_id=@inbound_id and ci.CanReprogram =1
				        --quitamos subcalificaciones relacionadas a la calificacion
				        DELETE rel FROM ccCalifCamp c
				        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
				        inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
				        left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
				        Where c.cam_id=@inbound_id and sb.canReprogram=1
				                
				    end
				    
				    update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
				        
				    if @@rowcount=0
				        select -4 -- Error al actualizar

				    return(0)
				 end
				set nocount off'
	EXEC(@sql)

	
	---------------------------------------END Uriel Cabrera e Ivan Martin---------------------------------------------------------

	------------------------------------------ Begin JCL ------------------------------------------------------
SET @process = 'DEV2-223-Add field SimultaneousRecs'
        SET @sql = '
ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
		@CAMPID int,
		@test int=0,
		@nAgentsLogin int=1,
		@iZonas int = NULL,
		@isDashboardApi BIT = 0
		as
		--set nocount on
		declare @total int
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey INT, @campType INT;
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
		SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;

		-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
		SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
		select @revHorario=valor from ccsettings where setting_id = 112
		-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
		SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
		SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

		SET DATEFIRST 1
		--Checamos si es horario de verano
		select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

		if @iZonas is null begin

			  INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			  select @iZonas=value from @iZonasTable
		--Checamos si la campaña tiene horarios configurados
			  if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
			  begin
						  if @iZonas = 0 begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
			  else begin
					if @camSurvey > 0
						  begin
								SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
		end

		set @sql=''CREATE TABLE #NEW_JOBS
		(callout_id int,
			  cam_id int,
			  cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
			  cal_status tinyint,
			  cal_fechaDial datetime,
			  user_id int,
			  tz int,
		tz2 int,
		tz3 int,
		tz4 int,
		tz5 int,
		list_id int,
		sequence smallint,
		calkey varchar(max),
		nDescartes int,
		name_agent varchar(max),
		SimultaneousRecs int
		)''


		-- 0=Ambas, 1=CallBacks, 2=Nuevas
		select @topCount=valor from ccSettings where setting_id=94

		if isnull(@topCount,0)=0
		select @topCount=case when @nAgentsLogin<3 then 30
			  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
			  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
			  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
			  when @nAgentsLogin>=16 then 240 else 20 end

		select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

		declare @isVerano varchar(max)
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END
        
		IF(@campType = 7)
		BEGIN
			set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END
		END


		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
		begin

					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

					IF(@campType = 7)
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs
						FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						WHERE W.sms_status=1 -- CallBacks
						and W.sms_dateDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
						and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
						and (
							  ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
							  ((W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
						)
						and isnull(R.status,2) = 2
						order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
					END
					ELSE
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs
						FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						left join ccCampsExtend ce on ce.cam_id=W.cam_id
						WHERE W.cal_status=1 -- CallBacks
						and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
						and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
						and (
							  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
							  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
							  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
							  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
							  ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
						)
						and isnull(R.status,2) = 2
						order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
					END
					
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';

					IF(@campType = 7)
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, 0 SimultaneousRecs
						FROM smsWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						WHERE W.sms_status=0 -- Nuevas
						and W.sms_dateDial < dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
						and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
						and (
							  ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''2=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''3=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''4=0) or
							   ( (W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.iTimeZone''+case @bIsDaylight when 1 then ''_summer'' else '''' end+''5=0)
						)
						and isnull(R.status,2) = 2
						order by R.sequence, W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
					END
					ELSE
					BEGIN
						select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
						+@isVerano+'',''
						+@isVerano+''2,''
						+@isVerano+''3,''
						+@isVerano+''4,''
						+@isVerano+''5,
						W.list_id, isNull(R.sequence,0) as sequence,
						cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
						isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs
						FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
						left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
						left join ccUsers us (nolock) on us.User_id=w.user_id
						left join ccCampsExtend ce on ce.cam_id=W.cam_id
						WHERE W.cal_status=0 -- Nuevas
						and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
						and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
						and (
							  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
							   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
							   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
							   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
							   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
						)
						and isnull(R.status,2) = 2
						order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
					END

		end -- TOMA EN CUENTA LAS NUEVAS
		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ ''SET rowcount 0''
		if @Test=0
			  begin
					select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
					WHERE callout_id in(select callout_id from #NEW_JOBS)''
		end

		if @Test = 2
		begin
			  select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
			  declare @nSQL nvarchar(4000)
			  set @nSQL=cast(@sql as nvarchar(4000))
			  exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
			  return(@total)
		end
		else
		BEGIN
			IF(@isDashboardApi = 1)
			BEGIN
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
					isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					left join ccUsers us (nolock) on us.User_id=w.user_id
					left join ccCampsExtend ce on ce.cam_id=W.cam_id
					WHERE W.cal_status= 2 -- Procesando
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
					and (
						  ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						   ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
					or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
					 -- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
			END

			select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
			user_id, tz, tz2, tz3, tz4, tz5,
			case when tz is null then '''''''' else cal_telefono end as tel,
			case when tz2 is null then '''''''' else cal_telefono end as tel2,
			case when tz3 is null then '''''''' else cal_telefono end as tel3,
			case when tz4 is null then '''''''' else cal_telefono end as tel4,
			case when tz5 is null then '''''''' else cal_telefono end as tel5,
			NULL as dialOrder, list_id, sequence, calkey,
			0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs
			FROM #NEW_JOBS where len(cal_telefono)>0

			---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
			declare @regval int
			SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
			exec ccsp_GetCampsNvosCB @cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '',@Tipo=0,@user_id =0
			''
		end

		set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		--print (@sql)
		exec(@sql)

		return(0)
        '
        EXEC(@sql)
	------------------------------------------- End JCL -------------------------------------------------------

	------------------------------------------- Begin Rod Salazar -------------------------------------------------------

SET @process = 'DEV2-223 Drop procedure ccsp_GalateaGetPreviewData'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaGetPreviewData'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaGetPreviewData
	END
'
EXEC(@sql)
SET @process = 'DEV2-223-Create sp ccsp_GalateaGetPreviewData'
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

			select''previewData''=
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
			 C.previewDiscard
				   from ccUsers U,ccoCallsOutSource O (nolock)
			INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
			INNER JOIN ccCamps C on P.cam_id = C.cam_id
			Where callout_id=@callout_id and U.User_id=@user_id
		end

		if(@option = 2)
		begin
			select COUNT(*) from ccoCallsOutSource nolock where callout_id = @callout_id
		end
        set nocount off
        '
        EXEC(@sql)

	------------------------------------------- End Rod Salazar -------------------------------------------------------
	

	------------------------------------------- Begin HEL -------------------------------------------------------

	SET @process = 'DEV2-216-Drop SP ccsp_RIACampsManualCall'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIACampsManualCall'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			END'
	EXEC(@sql)

	SET @process = 'DEV2-216-CREATE ccsp_RIACampsManualCall'
    SET @sql = '-- Se crearon las variables @IdArea y @DialogMode, se llenaron respectivamente
			-- Se hicieron dos validaciones en la línea 32
			-- una para evitar que solo se contemplen las llamadas manuales en el select
			-- otra para que cuando el agente está en modo campañas preview, se muestren las campañas de tipo preview

			CREATE PROCEDURE [dbo].[ccsp_RIACampsManualCall]
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
					CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable where cam_id = c.cam_id) ELSE 0 END AS countJobs,
					isnull(c.timesPreview, 0) timesPreview
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
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
	EXEC(@sql)

	SET @process = 'DEV2-216-Drop SP ccsp_RegProcessPreviewRecord'
	SET @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RegProcessPreviewRecord'')
			BEGIN
				DROP PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord]
			END'
	EXEC(@sql)

	SET @process = 'DEV2-216-CREATE ccsp_RegProcessPreviewRecord'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
			@process smallint,
			@callout_id int,
			@agent_id smallint,
			@camId int,
			@previewTime smallint,
			@callId int)
			AS
			DECLARE @result_callout_id INT
			DECLARE @result_maxtimespreview INT = 0
			DECLARE @result_maxtimesdiscard INT = 0
			DECLARE @insert_date DATETIME = SYSDATETIME()
			DECLARE @process_insert int =  @process

			if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
				set @result_callout_id =1
			end

			IF (@process=1 AND @result_callout_id > 0)
			BEGIN
				DELETE ccoWorkingTable WHERE callout_id = @callout_id
			END

			IF (@process NOT IN (1, 7, 13))
			BEGIN
			DECLARE @first_date DATETIME = DATEADD(hh, 00, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
				if(
					(SELECT COUNT(process) FROM RegProcessPreviewRecord 
					WHERE reg_date BETWEEN @first_date AND @insert_date
					and (process NOT IN (1, 7, 9, 13)) 
					and (callout_id=@callout_id)
					)
					>=
					(SELECT timesPreview FROM ccCamps WHERE cam_id = @camId)
					)
				begin
						set @result_maxtimespreview = 1
						set @process_insert = 8
						DELETE ccoWorkingTable WHERE callout_id = @callout_id
				end
			END

			IF (@process NOT IN (1, 5, 7, 8, 13))
			BEGIN
				update ccoWorkingTable set timesDiscard+=1 where callout_id=@callout_id
			END

			IF (@result_callout_id > 0 or @process in (4, 5, 7, 13))
			BEGIN
				INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview,callID) VALUES (@agent_id,@process_insert,@callout_id,@camId,@insert_date,@previewTime,@callId)
			END

			CREATE TABLE #result (result INT);
			INSERT INTO #result
			exec ccsp_CheckTimesDiscard @action=1,@camId=@camId, @calloutId=@callout_id
			select @result_maxtimesdiscard=result from #result
			DROP TABLE #result

			select case when @result_maxtimespreview = 1 or @result_maxtimesdiscard = 1 then 1 else 0 end as ''value'''
	EXEC(@sql)

	SET @process = 'DEV2-223-Add Llamadas por agente'
    SET @sql = 'if exists(select top 1 1 from ccsettings where setting_id=251)
		begin
			delete ccsettings where setting_id=251
		end
		INSERT INTO [dbo].[ccSettings]
			   ([setting_id]
			   ,[valor]
			   ,[descripcion]
			   ,[Status]
			   ,[Tipo]
			   ,[detalle]
			   ,[description]
			   ,[bLoadSettings]
			   ,[validate])
		 VALUES
			   (251
			   ,3
			   ,''Permite configurar la cantidad máxima de marcaciones que el agente puede realizar en simultáneo de vista previa''
			   ,1
			   ,''X''
			   ,''Valor indica la cantidad máxima de marcaciones que el agente puede realizar en simultáneo de vista previa''
			   ,''Allows configuring the maximum number of simultaneous preview dialing attempts the agent can make''
			   ,0
			   ,''^(10|[0-9])$'')'
	EXEC(@sql)

	------------------------------------------- End HEL -------------------------------------------------------
	-------------------------------------------Begin MACL------------------------------------------------------

	SET @process = 'CW-7990 Se actualiza SP ccsp_GalateaLoadUsersForManagement para agregar UserType'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
	 @option SMALLINT,
	 @AreaId SMALLINT,
	 @UserType INT = null,
	 @Username VARCHAR(200)=null,
	 @userId INT = 0
	as

	--Obtiene el idioma de de Centerware
	Declare @lenguageXion varchar
	select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

	IF @option = 1 --Agentes/supervisores de un Area
	BEGIN
	  SELECT  TipoUser_id as UserType,
	  User_id as UserId,
	  LOGIN as Username,
	  Nombres as Names,
	  CASE
		WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
		ELSE isnull(ApellidoPaterno, '''')
	  END as LastName,

	  CASE
		WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
		ELSE isnull(ApellidoMaterno, '''')
	  END as OptionalExtraName,

	  Password as Password,
	  Sexo as IsMan,
	  CanChangeStatus as EnableNotReady,
	  isnull(IDArea, 0) as AreaId
	  FROM ccusers
	  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
		AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
	  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

	  RETURN (0)
	END

	IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
	BEGIN
	  SELECT  TipoUser_id as UserType,
	  User_id as UserId,
	  LOGIN as Username,
	  Nombres as Names,
	  CASE
		WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
		ELSE isnull(ApellidoPaterno, '''')
	  END as LastName,

	  CASE
		WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
		ELSE isnull(ApellidoMaterno, '''')
	  END as OptionalExtraName,

	  Password as Password,
	  Sexo as IsMan,
	  CanChangeStatus as EnableNotReady,
	  isnull(IDArea, 0) as AreaId
	  FROM ccusers
	  WHERE Login=@Username

	  RETURN (0)
	END

	IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
	BEGIN
	  SELECT  TipoUser_id as UserType,
	  User_id as UserId,
	  LOGIN as Username,
	  Nombres as Names,
	  CASE
		WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
		ELSE isnull(ApellidoPaterno, '''')
	  END as LastName,

	  CASE
		WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
		ELSE isnull(ApellidoMaterno, '''')
	  END as OptionalExtraName,

	  Password as Password,
	  Sexo as IsMan,
	  CanChangeStatus as EnableNotReady,
	  isnull(IDArea, 0) as AreaId
	  FROM ccusers
	  WHERE user_id=@userId

	  RETURN (0)
	END




	IF @option = 4 -- supervisores en Area/Sistema
	BEGIN
		DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
		INSERT INTO @Admins
		SELECT User_id as UserId,
		LOGIN as Username,
		Nombres as Names,
		CASE
		  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
		  ELSE isnull(ApellidoPaterno, '''')
		END as LastName,

		CASE
		  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
		  ELSE isnull(ApellidoMaterno, '''')
		END as OptionalExtraName,

		isnull(IDArea, 0) as AreaId
		FROM ccusers
		WHERE TipoUser_id = 2 AND STATUS = 1


		IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
			SELECT UserId, Username, Names, LastName, OptionalExtraName
			FROM @Admins
			WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
			ORDER BY Username, Names, LastName, UserId
		END
		ELSE BEGIN
			SELECT UserId, Username, Names, LastName, OptionalExtraName
			FROM @Admins
			ORDER BY Username, Names, LastName, UserId
		END
		Return(0)
	END

	IF @option = 5 --Usuarios inactivos por mas de 60 días por área
		BEGIN
			SELECT [User_id] as UserId,
			LOGIN as Username, TipoUser_id as UserType
			FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
			AND @AreaId = IDArea
			RETURN 0;
		END'
	EXEC(@sql)
	--------------------------------------------END MACL-------------------------------------------------------

	
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