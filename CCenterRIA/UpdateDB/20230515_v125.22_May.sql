/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @versionfix = 22
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci?n para cuando pasamos a una nueva versi?n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN

    BEGIN TRY
        -------------------------------------------- BEGIN IVAN MARTIN feature/IM-DEV1-239_Send_cal_ids_list_to_front ------------------------------
        SET @process = 'Addition of action 17 to get cal_ids list for outbout and inbound'
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
                            select grab_id,cal_id,tipo_llamada from RIA_GRABACION with(nolock) where grab_id in(''+@grabIds+'')
                            union
                            select grab_id,cal_id,tipo_llamada from RIA_GRABACIONCONSULTA with(nolock) where grab_id in(''+@grabIds+'')
                            )

                            select mark.id_marca as markId, grab.grab_id as grabId,b.login as userName, mark.user_id as [userId],mark.marca as mark,convert(bit,case when b.TipoUser_id =1 then 0 else 1 end ) as IsAdmin
                            from RIA_MARCAS mark 
                            inner join grab on grab.cal_id=mark.call_id and grab.tipo_llamada=mark.tipo_llamada
                            inner join ccUsers b on b.user_id = mark.user_id
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

        -------------------------------------------- END IVAN MARTIN feature/IM-DEV1-239_Send_cal_ids_list_to_front -------------------------------------------------------------------------------
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