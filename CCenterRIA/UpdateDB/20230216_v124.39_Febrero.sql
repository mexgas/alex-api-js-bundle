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
SET @versionfix = 39
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

		SET @process = 'K051000 create table ccGalateaModules'
		SET @sql = 'if not exists (select * from sys.tables where name = N''ccGalateaModules'')
		begin
		  create table ccGalateaModules (
		 ModuleId int not null primary key,
		 MTagEs varchar(250) not null,
		 MTagEn varchar(250) not null,
		 MTagPt varchar(250) not null
		) 
		end';
		EXEC(@sql);

		SET @process = 'K051000 create table ccGalateaOperations'
		SET @sql = 'if not exists (select * from sys.tables where name = N''ccGalateaOperations'')
		begin
		  create table ccGalateaOperations (
		 OperationId int not null primary key,
		 OpTagEs varchar(250)not null,
		 OpTagEn varchar(250) not null,
		 OpTagPt varchar(250) not null
		)
		end';
		EXEC(@sql);

		SET @process = 'K051000 create table ccGalateaIdentifiers'
		SET @sql = 'if not exists (select * from sys.tables where name = N''ccGalateaIdentifiers'')
		begin
		  create table ccGalateaIdentifiers (
		 Description varchar(100) not null primary key,
		 TagEs varchar(250) not null,
		 TagEn varchar(250) not null,
		 TagPt varchar(250) not null
		)
		end';
		EXEC(@sql);

		SET @process = 'K051000 create table ccGalateaModOpRelation'
		SET @sql = 'if not exists (select * from sys.tables where name = N''ccGalateaModOpRelation'')
		begin
		  create table ccGalateaModOpRelation (
		 ModuleId int,
		 OperationId int,
		)
		end';
		EXEC(@sql);

		SET @process = 'K0451000 create table ccGalateaActivityLog'
		SET @sql = 'if not exists (select * from sys.tables where name = N''ccGalateaActivityLog'')
		begin
		  create table ccGalateaActivityLog (
		 LogId int not null primary key identity(1,1),
		 Area varchar(50),
		 ActivityDate datetime,
		 Login varchar(50),
		 OperationId int,
		 ModuleId int,
		 Identifier varchar(250),
		 Value varchar(250),
		 Target varchar(250)
		)
		end';
		EXEC(@sql);

		SET @process = 'K051000 create index IX_ccGalateaModules_Mod'
		SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccGalateaModules_Mod'' and object_id = OBJECT_ID(N''ccGalateaModules''))
		begin
		  CREATE INDEX IX_ccGalateaModules_Mod ON ccGalateaModules (ModuleId asc)
		end';
		EXEC(@sql);

		SET @process = 'K051000 create index IX_ccGalateaOperations_Op'
		SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccGalateaOperations_Op'' and object_id = OBJECT_ID(N''ccGalateaOperations''))
		begin
		  CREATE INDEX IX_ccGalateaOperations_Op ON ccGalateaOperations (OperationId asc)
		end';
		EXEC(@sql);

		SET @process = 'K051000 create index IX_ccGalateaIdentifiers_Desc'
		SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccGalateaIdentifiers_Desc'' and object_id = OBJECT_ID(N''ccGalateaIdentifiers''))
		begin
		  CREATE INDEX IX_ccGalateaIdentifiers_Desc ON ccGalateaIdentifiers (Description asc)
		end';
		EXEC(@sql);

		SET @process = 'K051000 create index IX_ccGalateaActivityLog_Id'
		SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccGalateaActivityLog_Id'' and object_id = OBJECT_ID(N''ccGalateaActivityLog''))
		begin
		  CREATE INDEX IX_ccGalateaActivityLog_Id ON ccGalateaActivityLog (LogId asc)
		end';
		EXEC(@sql);

		SET @process = 'K051000 insert modules'
		SET @sql = 'if not exists (select * from ccGalateaModules)
		begin
		  insert into ccGalateaModules(ModuleId,MTagEs,MTagEn,MTagPt) values (1,''Sesión de usuario'',''User session'',''Sessão de usuário'')
		  insert into ccGalateaModules(ModuleId,MTagEs,MTagEn,MTagPt) values (2,''Tablero de control'',''Dashboard'',''Painel de controle'')
		end';
		EXEC(@sql);

		SET @process = 'K051000 insert operations'
		SET @sql = 'if not exists (select * from ccGalateaOperations)
		begin
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (1,''Iniciar sesión'',''Log in'',''Entrar'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (2,''Cerrar sesión'',''Log out'',''Sair'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (3,''Cambiar a no disponible'',''Set agent to unavailable'',''Alterar status para não disponível'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (4,''Cambiar a disponible'',''Set agent to ready'',''Alterar status para disponível'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (5,''Deshabilitar uso de no disponible'',''Deny use of unavailable options'',''Desativar o uso de status não disponível'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (6,''Habilitar uso de no disponible'',''Allow use of unavailable options'',''Ativar o uso de status não disponível'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (7,''Desconectar agente '',''Disconnect agent'',''Desconectar agente'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (8,''Iniciar campaña de salida'',''Start outbound campaign'',''Iniciar campanha de saída'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (9,''Detener campaña de salida'',''Stop outbound campaign'',''Parar campanha de saída'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (10,''Habilitar campaña de entrada'',''Enable inbound campaign'',''Ativar campanha de entrada'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (11,''Deshabilitar campaña de entrada'',''Disable inbound campaign'',''Desativar campanha de entrada'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (12,''Cambiar tipo de registros a marcar'',''Change records to dial'',''Alterar tipo de registros a discar'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (13,''Eliminar registros nuevos'',''Delete new records'',''Excluir registros novos'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (14,''Eliminar registros devolver llamada'',''Delete callback records'',''Excluir registros retornar chamada'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (15,''Cargar registros nuevos'',''Load new records'',''Carregar registros novos'')
		  insert into ccGalateaOperations(OperationId,OpTagEs,OpTagEn,OpTagPt) values (16,''Reciclar registros devolver llamada'',''Recycle callbacks records'',''Reciclar registros retornar chamada'')
		end';
		EXEC(@sql);

		SET @process = 'K051000 insert identifiers'
		SET @sql = 'if not exists (select * from ccGalateaIdentifiers)
		begin
		  insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt) values (''T$NEW_RECORDS'',''Registros nuevos'',''New records'',''Registros novos'')
		  insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt) values (''T$N&C_RECORDS'',''Registros nuevos y devolver llamada'',''New and callback records'',''Registros novos e retornar chamada'')
		  insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt) values (''T$CB_RECORDS'',''Registros devolver llamada'',''Callback records'',''Registros retornar chamada'')
		end';
		EXEC(@sql);

		SET @process = 'K051000 insert module-operation relations'
		SET @sql = 'if not exists (select * from ccRIALog_Operation)
		begin
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (1,1)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (1,2)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,3)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,4)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,5)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,6)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,7)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,8)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,9)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,10)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,11)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,12)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,13)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,14)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,15)
		  insert into ccGalateaModOpRelation(ModuleId,OperationId) values (2,16)
		end';
		EXEC(@sql);

		SET @process = 'K049000 delete procedure ccsp_GalateaChangeHistory'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaChangeHistory'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaChangeHistory;
			END';
		EXEC(@sql);

		SET @process = 'K051000 create procedure ccsp_GalateaChangeHistory'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaChangeHistory]
	@option TINYINT,
	@loginLst VARCHAR(max) = NULL,
	@moduleWithOperation varchar(max) = NULL,
	@operationDateIni SMALLDATETIME = NULL,
	@operationDateFin SMALLDATETIME = NULL,
	@top INT = 0
	AS
	SET NOCOUNT ON

	DECLARE @lang TINYINT

	SELECT @lang = valor
	FROM ccsettings
	WHERE setting_id = 27

	IF @option = 1 -- Catalogo de modulos
	BEGIN
		WITH Catalog AS(
		SELECT m.ModuleId as module_id, o.OperationId as operationType, 
		CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS mDescripcion, 
		CASE @lang WHEN 0 THEN OpTagEs WHEN 2 THEN OpTagPt ELSE OpTagEn END AS oDescripcion
		FROM ccGalateaOperations o WITH (INDEX (IX_ccGalateaOperations_Op))
		JOIN ccGalateaModOpRelation r ON o.OperationId = r.OperationId
		JOIN ccGalateaModules m WITH (INDEX (IX_ccGalateaModules_Mod)) ON r.ModuleId = m.ModuleId --WITH (INDEX (IX_ccGalateaModules_Mod))

		UNION

		SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''

		UNION

		SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

		UNION

		SELECT ModuleId as module_id, 0, CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, 
		CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
		FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod))

		UNION

		SELECT ModuleId as module_id, - 1 , CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, '' - ''
		FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod)))

		SELECT module_id,operationType,mDescripcion,oDescripcion 
		FROM Catalog
		ORDER BY mDescripcion, oDescripcion

		RETURN (0)
	END

	IF @option = 2 -- Muestra informacion por filtros
	BEGIN

		declare @sql as nvarchar(max)
		DECLARE @table TABLE(id int,value varchar(max))
		declare @id int
		declare @moduleId varchar(max)
		declare @operationLst varchar(max)
		declare @query varchar(max) = '' and (''
		declare @value varchar(max)
		declare @first int = 1
		declare @pos int

		insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
		while exists(select * from @table)
		begin
			select top 1 @id = id, @value = value from @table
			set @pos = charindex('':'', @value)
			if(@pos <> 0)
			begin
				set @moduleId = substring(@value, 1, @pos-1)
				set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
				if(@first = 1)
				begin
					set @query = @query + ''l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
					set @first = 0
				end
				else
				begin
					set @query = @query + '' or l.module_id='' + @moduleId + '' and l.operationType in ('' + @operationLst + '')''
				end
			end

			delete @table where id = @id
		end
		set @query = @query + '')''


		SET ROWCOUNT @top

		set @sql =
		''DECLARE @tableLogin TABLE(id int,value varchar(255))
		insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

		SELECT L.LogId as log_id, L.Area as areaName, L.ActivityDate as operationDate,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN O.OpTagEs WHEN 2 THEN O.OpTagPt ELSE O.OpTagEn END operationType,
		L.LOGIN,
		CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN M.MTagEs WHEN 2 THEN M.MTagPt ELSE M.MTagEn END module_id,
		CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
		CASE WHEN i.description IS NULL THEN L.Identifier ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN i.TagEs WHEN 2 THEN i.TagPt ELSE i.TagEn END END +
		CASE WHEN L.Identifier<>'''''''' AND L.Value<>'''''''' THEN '''' : '''' ELSE '''''''' END +
		CASE WHEN V.description IS NULL THEN L.value ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.TagEs WHEN 2 THEN v.TagPt ELSE v.TagEn END END AS value
		FROM ccGalateaActivityLog L
		JOIN ccGalateaModules M WITH (INDEX (IX_ccGalateaModules_Mod)) ON L.ModuleId = M.ModuleId
		JOIN ccGalateaOperations O WITH (INDEX (IX_ccGalateaOperations_Op)) ON L.OperationId = O.OperationId
		LEFT JOIN targetRecord t ON t.targetT = L.target
		LEFT JOIN ccGalateaIdentifiers i ON i.Description = L.Identifier
		LEFT JOIN ccGalateaIdentifiers v ON v.Description = L.Value
		LEFT JOIN ccUsers CU ON CU.Login = L.login
		WHERE 1=1 
		AND
		CU.TipoUser_id = 2''
		+
		case isnull(@loginLst, '''') when '''' then '''' else
		'' AND L.LOGIN in (select value from @tableLogin) ''
		END
		+
		case isnull(@moduleWithOperation, '''') when '''' then '''' else
		@query
		end
		+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
		''AND L.ActivityDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.ActivityDate END ''
		+ '' AND L.ActivityDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.ActivityDate END''
		end
		+
		'' ORDER BY L.ActivityDate DESC''
		execute sp_executesql @sql
		--print @sql
	END


	SET NOCOUNT OFF';
		EXEC(@sql);

		SET @process = 'K051000 delete procedure ccsp_GalateaActivityLog'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaActivityLog'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaActivityLog;
			END';
		EXEC(@sql);

		SET @process = 'K051000 create procedure ccsp_GalateaActivityLog'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaActivityLog]
@UserId           SMALLINT,
@Operations       VARCHAR(MAX)= '''',
@Identifiers	  VARCHAR(MAX) = '''',
@Values			  VARCHAR(MAX) = '''',
@Module			  SMALLINT,
@Target			  VARCHAR(40) = ''''
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	create table #OperationType(
			id smallint IDENTITY(1,1),
			operationId int
	)
	insert into #OperationType SELECT value FROM fn_RIASplitDelimited(@Operations, '','')	

	IF OBJECT_ID(''tempdb..#Identifiers'') IS NOT NULL DROP TABLE #Identifiers
	create table #Identifiers(
			id smallint IDENTITY(1,1),
			identifier varchar(MAX)
	)
	insert into #Identifiers SELECT value FROM fn_RIASplitDelimited(@Identifiers, ''^^'')

	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	create table #Value(
			id smallint IDENTITY(1,1),
			value varchar(MAX)
	)
	insert into #Value SELECT value FROM fn_RIASplitDelimited(@Values, ''^^'')
	
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	select operationId,isnull(identifier,'''') identifier,isnull(value,'''') value
	into #Params
	from #OperationType o
	inner join #Value v with(nolock) on o.id = v.id
	inner join #Identifiers i with(nolock) on i.id = o.id


	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	create table #PreLog(
			areaName varchar(40),
			operationDate DATETIME,
			login varchar(40),
			module_id smallint,
			target varchar(40)
	)
	insert into #PreLog
	select AreaName, GETDATE() as operationDate,u.login,@Module module_id,@target as target
	from ccUsers U
	INNER JOIN ccRIACat_Areas A with(nolock) on u.IDArea = a.IDArea
	where U.User_id = @userId

	Insert into ccGalateaActivityLog (Area,ActivityDate,OperationId,Login,ModuleId,Identifier,Value,Target)
	select areaName,operationDate,operationId,login,module_id,identifier,value,target
	from #PreLog,#Params

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	IF OBJECT_ID(''tempdb..#Identifiers'') IS NOT NULL DROP TABLE #Identifiers
	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	Select 1
	return
END';
		EXEC(@sql);


		SET @process = 'K049000 delete procedure ccsp_RIA_ABCAgents'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIA_ABCAgents'')
			BEGIN
				DROP PROCEDURE ccsp_RIA_ABCAgents;
			END';
		EXEC(@sql);


		SET @process = 'K049000 create procedure ccsp_RIA_ABCAgents'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
          @option smallint,
          @UserId int,
          @Login varchar(40)='''',
          @Nombres varchar(25)=null,
          @ApellidoPaterno varchar(25)='''',
          @ApellidoMaterno varchar(25)='''',
          @Password varchar(33)='''',
          @Sexo bit=null,
          @canChangeStatus bit=null,
          @AreaId int=null,
          @UserType tinyint=1,
          @IDWG int=0,
          @DeleteUsers int=1,
          @inOut int=null,
          @IDCampEsp int=null,
          @multipleUsers varchar(1000)=null
          as
          set nocount on

          if @option=0--All Users
            begin
            select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

          from ccusers as users with(nolock)
              left join ccRIACat_Areas as areas with(nolock)
              on users.IDArea=areas.IDArea
            return(0)
            end

          if @option=1--selected User
            begin
            select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
              isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
            from ccusers where User_id=@UserId
            order by IDArea,Nombres,ApellidoPaterno,User_id
            return(0)
            end

          if @option=2--insert
            begin
            if exists(select Login from ccUsers where Login=@Login)
              begin
              select -1--,''Login en Uso''
              return(0)
              end

            if exists(select Login from ccUsers_Consulta where Login = @Login)
            begin
              select -4 -- ''Login habia estado en Uso''
              return(0)
            end

            if exists(select Nombres from ccUsers where Nombres=@Nombres
            and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
              begin
              select -2--,''Nombre en Uso''
              return(0)
              end

          IF( select isnull(max(user_id),0) from ccusers) > 32700
          BEGIN
            set @UserId = null
            SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
            FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
            LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
            INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
            FROM ccusers) AS w ON w.recID = d.recID

            if @UserId is null
            begin
              select -2--insert Error
              return(0)
            end

            set identity_insert ccusers on
            insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
              Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
            select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
              1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
            set identity_insert ccusers off

            delete ccMenuUser where id_User = @UserId
            delete ccRIAUserRole where user_id = @UserId

            exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

          END
          ELSE
          BEGIN
            insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
              Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
            select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
              1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

            if @@rowcount=1
              select @UserId=scope_identity()
            else
              begin
              select -2--insert Error
              return(0)
              end
          END
            insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
            insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
            insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
            --Menu para roles RepotsRia
            exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

            select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
            return(0)
            end

          if @option=3--Update
            begin
            if @Login='''' and @Password <> ''''
              begin
              Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
              return(0)
              end

            Update ccUsers
            set Login= case when @Login <> '''' then @Login else Login end,
            Nombres=@Nombres,
            ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
            Password=case when @Password <> '''' then @Password else Password end,
            Sexo=@Sexo,canChangeStatus=@canChangeStatus
            where User_id=@UserId
            return(0)
            end

          if @option=4--Delete
            begin
            delete from ccSkills where user_id =@UserId
            delete from ccMenu_ViewsUser where user_id =@UserId
            delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
            delete from ccUsers where user_id=@UserId
            return(0)
            end

          declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

          if @option=5--insert Agente-Supervisor in WorkGroup
            begin
            select @Type=TipoUser_id from ccUsers where User_id=@UserId

            if @Type not in(1,2,6)
              return(0)

            if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
              begin
              select 3
              return(0)
              end

            if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
              begin
              select 1
              return(0)
              end

            insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

            if @Type=1
              begin

              if @IDWG is null or @IDWG = 0
                begin
                select 28
                return(0)
                end
              insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

              select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
              from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
                and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

              insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
              select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
              from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
                and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

              return(0)
              end

          --else @Type=2 or @Type=6--Supervisor
            insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
            select @UserId,idCampEsp,0,@IDWG
            from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
              and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

            insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
            select @UserId,idCampEsp,1,@IDWG
            from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
              and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
            return(0)
            end

          if @option=6--Delete Agent-Supervisor from WorkGroup
            begin
            if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
              select @UserId = @multipleUsers

                  else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
                    select @UserId = cast(substring(@multipleUsers, 1,
                    CHARINDEX('','', @multipleUsers)-1) as int)

              select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
              @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
            from ccUsers where User_id=@UserId

            Declare @sqlDelete nvarchar(4000)
            if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
              begin
              set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
              + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
              + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
              + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
              exec(@sqlDelete)
              end

            if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
              begin
              select -9 -- Se ingreso mal el id del usuario
              --delete ccinboundagentes where idwg=@IDWG
              --delete cccampsagente where idwg=@IDWG
              --delete ccSupervisorCam where idwg=@IDWG
              end

            if @DeleteUsers=1
              Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

            return(0)
            end

          if @option=7--Delete Agent from WorkGroup
            begin
            select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
            set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
              '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
              ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
              '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
            exec(@sql)
            --update preview permission
            set @sql = ''update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
                where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
            exec(@sql)
          return(0)
            end

          if @option=8--Delete Supervisor from WorkGroup
            begin
            select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

                  set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
                    + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
                    delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
                  exec(@sql)

            set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
              ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
            exec(@sql)
            return(0)
            end

          if @option=9
            begin
	
            update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId

			select Login from ccUsers where [User_id]=@UserId
            return(0)
            end
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
