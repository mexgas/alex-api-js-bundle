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
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UnassignedElementsInAreas]   
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

	SET @process = 'CW-8007 ccsp_RIA_ABCACDGroups se quita delete del option 4 pues ya se agrego en los otros sps '
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