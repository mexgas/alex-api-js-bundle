set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 92
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

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
        -------------------------------------------- BEGIN URIEL CABRERA TT4259_Finder Bug ---------------------------------
	SET @process = 'TT4259_Finder_Bug - ALTER procedure [ccsp_BaseXmngr]'
	set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
					@action int = 0,
					@option int = 0,
					@idService int = 0,
					@name varchar(25) = NULL,
					@top varchar(max) = NULL,
					@ids varchar(max)=null,
					@dateStart dateTime= null,
					@grabIds varchar(4000) = null

					AS
					declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
					declare @parameterDefinition nvarchar(max)
					declare @status tinyint

					set @sql = ''''
					if @action in(1,6) begin--obtiene los nodos a insertar en BX
						if @option = 2 begin
							if @action = 1 set @status =0
							else if @action = 6 set @status = 2

							set @parameterDefinition =N''@status int, @top int''

							set @sql=''declare @basexName varchar(max)

					select @basexName=Xname from ccBaseXDB where serviceId=2 and isFull=0;

					with node ( grab_id,xmlString,dateNode)
					AS(
						select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
						,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
						from ria_RecNode A with(nolock)
						where A.status =@status
						union
						select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
						,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
						from ria_RecNodeHistory A with(nolock)
						where A.status =@status
					)

					select node.grab_id,node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
					left join ccBaseXDB baseX on baseX.serviceId=2  and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
					order by baseX.Xname''
						--print(@sql)
						--exec(@sql)
						EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top

						end
					end
					if @action in(2,7) begin--actualiza los nodos insertados en BX
						if @option = 2 begin
							if @action = 2 set @status=0
							else if @action = 7 set @status = 2
							set @parameterDefinition =N''@status int''
							set @sql=''update ria_RecNode with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''		
							
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
							set @sql=''update RIA_RecNodeHistory with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''
							
							EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
						end
					end
					else if @action = 3 begin--trae el nombre de la base de datos en BX
						select Xname from ccBaseXDB where serviceId = @option and isFull=0
					end
					else if @action = 4 --inserta el nombre del xml en BX
					begin
						insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, @dateStart, @name,0)
					end
					else if @action = 11 begin--trae el nombre de la base de datos en BX
						if @option =2 begin
							SELECT ISNULL(min(node.value(''(/R02/@CDATE)[1]'',''datetime'')),GETDATE()) as node FROM RIA_RecNode where status = 0
						end
						end
					else if @action =12 begin
						declare @replicationName nvarchar(500)
							select @replicationName = name from msdb.dbo.sysjobs where name like ''%-CCRecorderRIA- 0'' and name like ''%SpecialAVRS%''
							exec msdb.dbo.sp_start_job @job_name = @replicationName
							while(
							SELECT count(*) FROM msdb.dbo.sysjobactivity ja
							LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
							INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
							INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
							WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
							AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
						) > 0
						begin
							WAITFOR DELAY ''00:00:10''
						end
					end

					else if @action = 13 begin
						set @sql = ''''
						select @tableName=''RIA_RecNode'',@tableNameHistory=''RIA_RecNodeHistory'',@columnId=''grab_id''
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

					end'
	EXEC(@Sql)
-------------------------------------------- END URIEL CABRERA TT4259_Finder Bug ---------------------------------

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