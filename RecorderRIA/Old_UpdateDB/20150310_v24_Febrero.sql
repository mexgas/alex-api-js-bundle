/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: José Velasco
Date: 2015/03/10
Description: Update Febrero 2015 AVRS

  Se actualiza el SP Alter SP  - trsp_FinderCRMNode para el CRM
  Se actualiza el SP ccsp_ADMChecaLogin  
  Se actualiza el SP trsp_GetAppParameters
	Se actualiza el SP trsp_GetFilesAnalisisGritos	
	Se actualiza el SP trsp_AdmRecSearchNodeAgent
  Se actualiza el SP ccsp_BaseXmngr
	Se actualiza el SP trsp_InsertRecNode 
  Se actualiza el SP trsp_AdmRecSearchAllRecs 

Database: CCRecorderRia
Required version: 23

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 24

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	/* Start script release */
	set @process = 'Alter SP  - trsp_FinderCRMNode'
	set @sql='ALTER PROCEDURE  [dbo].[trsp_FinderCRMNode]
@cal_id int,@type int,@node xml

AS
BEGIN

declare @realType int
if @type = 2
	set @realType = 1
else
	set @realType = 2
---Type 1 In 2 Out
if not exists(select * from ccCRMNodes where cal_id=@cal_id and type=@realtype)
	insert into ccCRMNodes (cal_id,type,node) values(@cal_id,@realtype,@node)
else 
	update ccCRMNodes  set node=@node where cal_id=@cal_id and type=@realtype

END'
	EXEC(@sql)

  	set @process = 'alter SP  - ccsp_ADMChecaLogin'
    if exists (select * from sys.procedures where name = N'ccsp_ADMChecaLogin')
    set @sql='ALTER PROCEDURE [dbo].[ccsp_ADMChecaLogin]
        @Login varchar(12),
        @Password varchar(15)
        AS
        declare @LoginOK tinyint
        declare @PswdOK tinyint
        declare @Nombre varchar(60)
        declare @UserID smallint
        declare @ADMServer varchar(20)

        SELECT @LoginOK=0, @PswdOK=0,  @UserID='''', @Nombre=''''
        SELECT @ADMServer=valor FROM ccSettings WHERE setting_id=8

        select @LoginOK= count(*)
        from ccUsers
        Where Login like @Login
        AND TipoUser_id > 1 and status > 0

        IF ( @LoginOK > 0 )
        BEGIN
          select @PswdOK= count(*)
          from ccUsers
          Where Login = @Login
          AND (Password=@Password or password = dbo.md5(@Password)) AND TipoUser_id > 1 and status > 0

          IF ( @PswdOK > 0 )
          BEGIN
            print ''entro''
            select  @UserID=user_id,
              @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,'''')
            from ccUsers
            Where Login like @Login
            AND TipoUser_id > 1 and status > 0
          END
        END
        SELECT ''LoginOK''=@LoginOK, ''PswdOK''=@PswdOK, ''UserID''=@UserID, ''Nombre''=@Nombre, ''ADMServer''=@ADMServer'
  else
    set @sql = ''

  EXEC(@sql)


  set @process = 'alter SP  - trsp_GetAppParameters'
    if exists (select * from sys.procedures where name = N'trsp_GetAppParameters')
    set @sql='ALTER PROCEDURE [dbo].[trsp_GetAppParameters]
      @app_id AS INT
      AS
      BEGIN
      DECLARE  @avrs_enviroment AS INT
      DECLARE @SQL AS NVARCHAR(MAX)

      --AVRS Record Manager
      IF @app_id = 1
      BEGIN
        SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

          IF @avrs_enviroment = 2
            BEGIN
          
              SET @SQL = ''SELECT par_valor,par_id 
                    FROM TREC_PARAMETROS 
                    WHERE par_id 
                    IN (67,68,69,70)
                    ORDER BY par_id''
            
            END 
          ELSE
            BEGIN

              SET @SQL = ''SELECT * FROM
                    (SELECT par_valor,par_id FROM TREC_PARAMETROS 
                    WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,61,62,63,29,2,65,67)
                    UNION
                    SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
                    FROM TREC_GRABACION)x
                    ORDER BY x.par_id''
            END
      END

      EXEC sp_executesql @SQL

      END'
  else
    set @sql = ''

  EXEC(@sql)

	set @process = 'alter SP  - trsp_GetFilesAnalisisGritos'
		if exists (select * from sys.procedures where name = N'trsp_GetFilesAnalisisGritos')
		set @sql='ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
			--@idRepositorios as varchar(32),
			@sExtension as varchar(10) = ''.vox''
			AS

			declare @Integrado as int
			declare @FInicio as datetime
			declare @sSql1 as nvarchar(180)
			declare @sSql2 as nvarchar (180)
			declare @sSql3 as nvarchar(180) 
			declare @sSql as nvarchar (512)
			declare @dLenAnt as tinyint
			declare @dLenNew as tinyint
			declare @Encriptado as int
			declare @ENC  as varchar(4)


			set @FInicio = dateadd(MINUTE, -1, getdate())
			set @sSql = N''
			set @sSql3 = N''
			set @sExtension = (select par_valor from trec_parametros where par_id = 54)

			select @integrado = par_valor from trec_parametros where par_id = 29
			select @Encriptado = par_valor from trec_parametros where par_id = 15

			--AVRS Integrada
			if (@integrado = 1)

				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

				END

			--AVRS Standalone
			else if(@integrado = 0)

				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

				END

			--AVRS XION
			else if(@integrado = 2)
				BEGIN
					
					if @Encriptado = 1
						begin
							set @ENC = ''.enc''
						end
					else
						begin
							set @ENC = ''''
						end
									

					set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension + @ENC+char(0x27) 
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from ria_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL and cal_id in ( select cal_id from ccRIAWorkGroup_Calid)''

				END

			set @sSql = @sSql1 + @sSql2 + N'' order by finicio asc''
			exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'alter SP  - trsp_AdmRecSearchNodeAgent'
		if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchNodeAgent')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeAgent] 

            @Workgroup int
            AS
            BEGIN

            SET NOCOUNT ON;

            select a.User_id, a.Nombres + '' '' +  a.ApellidoPaterno+ '' '' +  a.ApellidoMaterno as [Nombres], b.IDWG from ccUsers a
            inner join ccRIAWorkGroupUsersConsulta b
            on b.IDWG = @Workgroup
            where a.User_id = b.User_id and a.TipoUser_id = 1
            union 
            select a.User_id, a.Nombres + '' '' +  a.ApellidoPaterno+ '' '' +  a.ApellidoMaterno as [Nombres], b.IDWG from ccUsers a
            inner join ccRIAWorkGroupUsers b
            on b.IDWG = @Workgroup
            where a.User_id = b.User_id and a.TipoUser_id = 1
           END'
	else
		set @sql = ''

	EXEC(@sql)

  set @process = 'alter SP  - ccsp_BaseXmngr'
    if exists (select * from sys.procedures where name = N'ccsp_BaseXmngr')
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
        if @option = 2
        begin
          set @sql = ''select top '' + @top + '' grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ria_RecNode with(rowlock) where status = 0''
          exec(@sql)
        end
      end
      if @action = 2 begin--actualiza los nodos insertados en BX
        if @option = 2
        begin
          update ria_RecNode with(rowlock) set [status] = 1, dateOut = getDate() where grab_id between @idF and @idL and [status] = 0
        end
      end
      if @action = 6 begin --obtener valores con status 2
        set @sql = ''select top '' + @top + '' grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ria_RecNode with(rowlock) where status = 2''
        exec(@sql)
      end
      if @action = 7 begin--actualiza los nodos insertados en BX
        if @option = 2
        begin
          update ria_RecNode with(rowlock) set [status] = 3, dateOut = getDate() where grab_id between @idF and @idL and [status] = 2
        end
      end'
  else
    set @sql = ''

  EXEC(@sql)

	set @process = 'alter SP  - trsp_InsertRecNode'
		if exists (select * from sys.procedures where name = N'trsp_InsertRecNode')
		set @sql='ALTER procedure [dbo].[trsp_InsertRecNode]
			        @grabId int,
                    @type int 
                    as 
                    begin

                    declare @sql as nvarchar(max)
                    declare @callType as nvarchar(20)
                    declare @shoutLevel as nvarchar(20)
                    declare @date as datetime
                    declare @formatedDate as nvarchar(50)
                    declare @language as int
                    declare @start as int
                    declare @country as int
                    declare @xml as xml
                    declare @crmNode as xml
                    declare @manual as nvarchar(10)
                    declare @rating as nvarchar(20)
                    declare @sqlCRM nvarchar(2000)
                    declare @supervisor as nvarchar(50)
                    declare @template as nvarchar(50)
                    declare @callID as nvarchar(50)

                    declare @table as nvarchar(20)
                    set @table=''RIA''
                    --declare @score as nvarchar(20)

                    --Get languange
                    set @language = (
                           select valor
                           from ccSettings
                           where setting_id = 27)

                    --Get call type
                    set @callType = (
                           select tipo_llamada
                           from ria_grabacion
                           where grab_id = @grabId)

                    --Get shout level
                    set @shoutlevel = (
                           select sho.nombre_nivel
                           from 
                           ria_grabacion rec
                           inner join ria_tipo_gritos sho
                           on rec.id_nivel_grito = sho.id_nivel_grito
                           where rec.grab_id = @grabId
                    )

                    set @start = (
                           select charindex(''|'',@shoutLevel) 
                    )

                    --Spanish
                    if @language = 0
                           begin
                                  set @shoutlevel = (
                                        select substring(@shoutlevel,0,@start)
                                  )
                           end
                    else
                           begin
                                  set @shoutlevel = (
                                        select substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1))
                                  )
                           end
                    
                    --Get date
                    set @date = ( 
                           select finicio
                           from ria_grabacion
                           where grab_id = @grabId )

                    --Set format date
                    set @formatedDate = (
                           select convert(varchar(23), @date, 126))

                    --Call manual
                    declare @manualId as int
                    
                    set @manualId = (
                           select cal_manual
                           from RIA_GRABACION
                           where grab_id = @grabId
                    )

                    if @manualId = 0
                           begin
                                  set @manual = (''N/A'')
                           end
                    else
                           begin
                                  set @manual = (''Manual'')
                           end

                    --Get rating
                    set @rating = (
                           select  top 1 isnull (total_forma,0)           
                           from ria_formacalif
                           where id_grabacion = @grabId order by fecha_calif desc)

             

                    ----Get score
                    --set @score = (
                    --     select   top 1 isnull (total_forma,0)          
                    --     from ria_formacalif
                    --     where id_grabacion = @grabId order by fecha_calif desc
                           
                    --     --left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
                    --     --left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                    --     )
                    
                           
                    /*           
                           C01-----> grab_id
                           C02-----> Type of Recording (Inbound/Outbound)
                           C03-----> Camp/ACD descripcion
                           C04-----> ShoutLevel 
                           C05-----> Agent Login
                           C06-----> Formated date
                           C07-----> Position Computer
                           C08-----> Duration
                           C09-----> Ani
                           C10-----> Dnis
                           C11-----> Calkey
                           C12-----> Manual
                           C13-----> User ID
                           C14-----> cal ID
                           C15-----> Cam /ACD ID 
                           C16-----> Duration Recording as 00:00:00
                           C17-----> Position Extension
                           C18-----> rating(Scoring Template) 
                           C19-----> Reposiory ID
                           C20-----> Disposition
                           C21-----> Disposition ID
                           C22-----> Has Video
                           C23-----> Agent Full Name
                           C24-----> Supervisor Name
                           c25-----> Score Template
                    */

                    if @type =0 ---Process to Insert
                    BEGIN
					
                            if @callType = 1 --Inbound
                                  BEGIN
                                  
                                        select  @callID = cal_id from ria_grabacion where grab_id = @grabId
                    
                                        set @xml = (
                                                            select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWGConsulta cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join ccinbound inb
                                               on cewg.IdCampEsp = inb.Inbound_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 1)
                                        and (cewg.Tipo = 0)
                                        and (wgc.tipo = 0)
                                        and (inb.chat = 0)
                                        and (rec.cam_id=cewg.IdCampEsp )                      
                                        and (rec.grab_id = @grabId)

                                        for xml path(''R02''))

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end
                                  
                                  
                                  END 
                           else
                                  BEGIN  

                                        select  @callID = cal_id from ria_grabacion where grab_id = @grabId
                                  
                                        set @xml = (
                                                            select top 1 rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWG cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join cccamps inb
                                               on cewg.IdCampEsp = inb.cam_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 2)
                                        and (cewg.Tipo = 1)
                                        and (wgc.tipo = 1)
                                        and (rec.cam_id=cewg.IdCampEsp )
                                        and (rec.grab_id = @grabId)
                                        for xml path(''R02'')) 

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end

                                  END
                                               
                                  if (@xml IS NOT NULL)
                                        insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
                           
                    END

                    if @type =1 ---Process to Update
                    BEGIN
                   
                    if (select count (*) grab_id from RIA_GRABACION where grab_id=@grabId) > 0

                           begin -- Node in RIA_GRABACION
                                  
                                  select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
                                  RIA_FORMATOS as formatos 
                                  inner join RIA_FORMACALIF formatosCalif
                                        on formatosCalif.id_formato=formatos.id_formato
                                  inner join RIA_GRABACION grabacion 
                                        on grabacion.grab_id= formatosCalif.id_grabacion
                                  inner join ccUsers supervisor
                                        on supervisor.User_id = formatosCalif.id_supervisor
                                  where
                                  formatosCalif.tipo=1
                                  and grabacion.grab_id=@grabId

                                  if @callType = 1
                                  BEGIN
								
                                        select  @callID = cal_id from ria_grabacion where grab_id = @grabId
                           
                                        set @xml = (
                                                            select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', @supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWGConsulta cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join ccinbound inb
                                               on cewg.IdCampEsp = inb.Inbound_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 1)
                                        and (cewg.Tipo = 0)
                                        and (wgc.tipo = 0)
                                        and (inb.chat = 0)
                                        and (rec.cam_id=cewg.IdCampEsp )                      
                                        and (rec.grab_id = @grabId)

                                        for xml path(''R02''))

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                               
                                               select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
                                               if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                                  
                                               end
                                  
                                  
                                  END 
                           else
                                  BEGIN  
										select  @callID = cal_id from ria_grabacion where grab_id = @grabId

                                        set @xml = (
                                                            select  top 1  rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWG cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join cccamps inb
                                               on cewg.IdCampEsp = inb.cam_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 2)
                                        and (cewg.Tipo = 1)
                                        and (wgc.tipo = 1)
                                        and (rec.cam_id=cewg.IdCampEsp )
                                        and (rec.grab_id = @grabId)
                                        for xml path(''R02'')) 

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                     
                                               end

                                  END


                           end
                    else   -- Node in RIA_GRABACIONCONSULTA
                           begin 
                                  select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
                                  RIA_FORMATOS as formatos 
                                  inner join RIA_FORMACALIF formatosCalif
                                        on formatosCalif.id_formato=formatos.id_formato
                                  inner join RIA_GRABACIONCONSULTA grabacion 
                                        on grabacion.grab_id= formatosCalif.id_grabacion
                                  inner join ccUsers supervisor
                                        on supervisor.User_id = formatosCalif.id_supervisor
                                  where
                                  formatosCalif.tipo=1
                                  and grabacion.grab_id=@grabId

                                  if @callType = 1
                                  BEGIN
										select  @callID = cal_id from ria_grabacionconsulta where grab_id = @grabId
                    
                                        set @xml = (
                                                            select rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacionconsulta rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWGConsulta cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join ccinbound inb
                                               on cewg.IdCampEsp = inb.Inbound_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 1)
                                        and (cewg.Tipo = 0)
                                        and (wgc.tipo = 0)
                                        and (inb.chat = 0)
                                        and (rec.cam_id=cewg.IdCampEsp )                      
                                        and (rec.grab_id = @grabId)

                                        for xml path(''R02''))

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end
                                  
                                  
                                  END 
                           else
                                  BEGIN  

										select  @callID = cal_id from ria_grabacionconsulta where grab_id = @grabId

                                        set @xml = (
                                                            select rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacionconsulta rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWG cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join cccamps inb
                                               on cewg.IdCampEsp = inb.cam_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 2)
                                        and (cewg.Tipo = 1)
                                        and (wgc.tipo = 1)
                                        and (rec.cam_id=cewg.IdCampEsp )
                                        and (rec.grab_id = @grabId)
                                        for xml path(''R02'')) 

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end

                                  END

                           end
                           
                                               
                                  if (@xml IS NOT NULL)
                                        update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId

                    END
                    
                    
             end'
	else
		set @sql = ''

	EXEC(@sql)


  set @process = 'alter SP  - trsp_AdmRecSearchAllRecs'
    if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchAllRecs')
    set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
      @Sup_id int,
      @Finicio datetime,
      @Ffin datetime

      AS
      BEGIN

        
        SET NOCOUNT ON

        declare @sql1 nvarchar(max)
        declare @sql2 nvarchar(max)
        declare @sql3 nvarchar(max)

        select r.id_grabacion, avg(r.total_forma) as total_forma
        into #tempRiaFormaCalif from ria_formacalif r 
        inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
        on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
        group by r.id_grabacion   
        
        select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
        into #tempCampEspWG from ccRIACampEspWGConsulta a 
        inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG
        
        select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
        into #tempComplete
        from  ccRIACampEspWGConsulta a inner join 
        (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in (select  distinct a.IDWG
        from ccRIACampEspWGConsulta a 
        inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG) 
        and user_id <> @Sup_id) b
        on a.IDWG=b.IDWG 

        
        SELECT @sql1 = CASE WHEN EXISTS (
          select top 1 1 
          from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
          left join ccPosicion b on b.pos_id = a.cal_extension * -1
          left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
          left join ccTipoCalif AS f ON a.calif_id = f.calif_id
          left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
          left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
          left join #tempComplete U on
          g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
          where a.finicio BETWEEN  @Finicio AND @Ffin and U.IDWG is not null  
          ) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
          finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
          isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
          isnull (z.total_forma,0) as total_forma,a.id_repositorio,
          CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
          CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
          a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
          from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
          left join ccPosicion b on b.pos_id = a.cal_extension * -1
          left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
          left join ccTipoCalif AS f ON a.calif_id = f.calif_id
          left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
          left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
          left join #tempComplete U on
          g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
          where U.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END --+  and U.IDWG is not null 

      
        select @sql2 = '' union ''

        SELECT @sql3 = CASE WHEN EXISTS (
          select top 1 1 
          from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))     
          left join ccPosicion b on b.pos_id = a.cal_extension * -1
          left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
          left join ccTipoCalif AS f ON a.calif_id = f.calif_id
          left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
          left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
          left join #tempComplete U on
          g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
          where a.finicio BETWEEN  @Finicio AND @Ffin and U.IDWG is not null
          ) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
          finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
          isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
          isnull (z.total_forma,0) as total_forma,a.id_repositorio,
          CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
          CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
          a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
          from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))     
          left join ccPosicion b on b.pos_id = a.cal_extension * -1
          left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
          left join ccTipoCalif AS f ON a.calif_id = f.calif_id
          left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
          left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
          left join #tempComplete U on
          g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id 
          where U.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END --+ '' and U.IDWG is not null ''
        
        
          if (@sql1 <> '''' and @sql3 <> '''')
            exec (@sql1 + @sql2 + @sql3)
          else if (@sql1 <> '''' and @sql3 = '''')
            exec (@sql1)
          else if (@sql1 = '''' and @sql3 <> '''')
            exec (@sql3)
          else
            exec (@sql1)

          --if (@sql1 <> '''' and @sql3 <> '''')
          --  print (@sql1 + @sql2 + @sql3)
          --else if (@sql1 <> '''' and @sql3 = '''')
          --  print (@sql1)
          --else if (@sql1 = '''' and @sql3 <> '''')
          --  print (@sql3)
          --else
          --  print (@sql1)
                
        drop table #tempRiaFormaCalif
        drop table #tempCampEspWG 
        
      END 
    '
  else
    set @sql = ''

  EXEC(@sql)



		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		update trec_parametros set par_valor = @Version where par_id = 30 

		commit tran
		end try

		begin catch	

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)
		
		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint primariy key 
if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''yourTableName'') 
	begin
		Use DDL or DML as you need
	end

-- When constraint does not primariy key 
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''yourTableName'') 
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key 
if exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''yourTableName'' and  c1.[name]=''yourColumnName'')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key 
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''yourTableName'' and  c1.[name]=''yourColumnName'')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/