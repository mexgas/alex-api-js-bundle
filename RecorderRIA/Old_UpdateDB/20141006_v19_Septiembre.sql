/*
Autor: Jose Velasco
Fecha: 2014/10/06
Descripcion:
	
	Se crea tabla RIA_MARCAS_VIDEO
	Se crea tabla TREC_NETWORKCREDENTIAL_TYPE
	
	Se agrega columna type a tabla RIA_NETWORKCREDENTIALS
	Se actualizan los valores para columna nueva 
	Se actualizan valores para trec parametros

	Se crea SP ccsp_ADMChecaLogin
	Se crea SP trsp_SaveAVRSExportParameters

	Se modifica SP trsp_AdmRecSearchCalID 
	Se modifica SP trsp_AdmGetAllRepositories
	Se modifica SP trsp_GetNetworkCredentials
	Se modifica SP trsp_GetParametersExportService
	Se modifica SP trsp_GetNetworkCredentials
		
Version requerida: 18
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
	Set @Version = 19
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

	if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Create table -- RIA_MARCAS_VIDEO'
	set @Sql='
			CREATE TABLE [dbo].[RIA_MARCAS_VIDEO](
		       [id_marca] [int] IDENTITY(1,1) NOT NULL,
		       [marca] [varchar](20) NOT NULL,
		       [tipo_marca] [int] NOT NULL,
		       [tipo_llamada] [int] NOT NULL,
		       [call_id] [int] NULL
		) ON [PRIMARY]
	'
	EXEC(@Sql)

	set @process = 'create table -- TREC_NETWORKCREDENTIAL_TYPE'
	set @Sql='			
			CREATE TABLE TREC_NETWORKCREDENTIAL_TYPE(
			[id] int,
			[media] nvarchar(1000),
			[application] nvarchar(1000)
			)
	'
	EXEC(@Sql)



	set @process = 'Alter table -- RIA_NETWORKCREDENTIALS'
	set @Sql='			
			ALTER TABLE [dbo].[RIA_NETWORKCREDENTIALS] ADD [type] tinyint
	'
	EXEC(@Sql)

	set @process = 'update table -- RIA_NETWORKCREDENTIALS'
	set @Sql='			
				UPDATE [dbo].[RIA_NETWORKCREDENTIALS] SET [type] = 1	
	'
	EXEC(@Sql)

	set @process = 'update table -- TREC_PARAMETROS'
	set @Sql='			
			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''Ruta FTP'', par_valor = ''/home/FTP'', par_detail = ''Ruta ftp para el AVRS Export''
			WHERE par_id = 41

			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''FTP Protocol'', par_valor = 1, par_detail = ''Protocolo ftp para el AVRS Export''
			WHERE par_id = 42

			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''FTP Server'', par_valor = ''127.0.0.1'',  par_detail = ''Servirdor ftp para el AVRS Export''
			WHERE par_id = 43

			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''FTP User'', par_valor = ''f445de98e8e59800a7b3e76ce21327eb'',  par_detail = ''Usuario ftp para el AVRS Export''
			WHERE par_id = 44

			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''FTP Password'', par_valor = ''f445de98e8e59800a7b3e76ce21327eb'',  par_detail = ''Contraseña ftp para el AVRS Export''
			WHERE par_id = 45

			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''FTP Port'', par_valor = 21,  par_detail = ''Puerto ftp para el AVRS Export''
			WHERE par_id = 46

			UPDATE TREC_PARAMETROS
			SET par_descripcion = ''Network Credential'', par_valor = 1,  par_detail = ''Credencial de red para la exportacion NetBios en el AVRS Export''
			WHERE par_id = 65	
	'
	EXEC(@Sql)


	set @process = 'insert  table -- TREC_NETWORKCREDENTIAL_TYPE'
	set @Sql='			
	INSERT INTO [dbo].[TREC_NETWORKCREDENTIAL_TYPE] ([id],[media],[application]) VALUES (1,''Recordings,Video'',''IP Recorder,Backup,AVRS Export(Source),Site'')
	INSERT INTO [dbo].[TREC_NETWORKCREDENTIAL_TYPE]([id],[media],[application]) VALUES (2,''Recordings'',''AVRS Export(Destination)'')
	'
	EXEC(@Sql)	

	set @process = 'create PROCEDURE  -- ccsp_ADMChecaLogin'
	set @Sql='	
	CREATE PROCEDURE [dbo].[ccsp_ADMChecaLogin]
	@Login varchar(12),
	@Password varchar(15)
	AS
	declare @LoginOK tinyint
	declare @PswdOK tinyint
	declare @Nombre varchar(60)
	declare @UserID smallint
	declare @ADMServer varchar(20)

	SELECT @LoginOK=0, @PswdOK=0,  @UserID='', @Nombre=''
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
			select	@UserID=user_id,
				@Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,'''')
			from ccUsers
			Where Login like @Login
			AND TipoUser_id > 1 and status > 0
		END
	END
	SELECT ''LoginOK''=@LoginOK, ''PswdOK''=@PswdOK, ''UserID''=@UserID, ''Nombre''=@Nombre, ''ADMServer''=@ADMServer
	'	
	EXEC(@Sql)

	set @process = 'create PROCEDURE  -- trsp_SaveAVRSExportParameters'
	set @Sql='	
	CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
	@export_mode AS INT,
	@netcred_id AS INT = -1,
	@net_user AS VARCHAR(100) = '''',
	@net_password AS VARCHAR(100) = '''',
	@net_sever AS VARCHAR(max) = '''',
	@net_path AS VARCHAR(max) = '''',
	@ftp_user AS VARCHAR(100) = '''',
	@ftp_password AS VARCHAR(100) = '''',
	@ftp_sever AS VARCHAR(max) = '''',
	@ftp_path AS VARCHAR(max) = '''',
	@ftp_port AS INT = -1,
	@ftp_protocol AS INT = -1,
	@time_export AS VARCHAR(20) = '''',
	@grabid_start AS INT = -1,
	@csv_log AS INT = -1,
	@delete_rec AS INT = -1
	AS
	BEGIN

	DECLARE @repo_Id AS INT

		-- Update FTP Parameters	

		IF @export_mode = 1
			BEGIN

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_path
				WHERE
				par_id = 41

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_protocol
				WHERE
				par_id = 42

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_sever
				WHERE
				par_id = 43

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_user
				WHERE
				par_id = 44

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_password
				WHERE
				par_id = 45

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_port
				WHERE
				par_id = 46

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50	

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					
					END
			END
		ELSE
			BEGIN

				-- Update NetBios parameters

				UPDATE RIA_NETWORKCREDENTIALS
				SET
				[domain] = @net_sever,
				[user] = @net_user,
				[password] = @net_password,
				[status] = 1,
				[type] = 2
				WHERE
				id = @netcred_id
					
				UPDATE TREC_PARAMETROS
				SET par_valor = @net_path
				WHERE 
				par_id = 36
					
				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					END

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

			END
	END
		'	
	EXEC(@Sql)


	set @process = 'alter PROCEDURE  -- trsp_AdmRecSearchCalID'
	set @Sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
		@Sup_id int,
		@call_id as int

		AS
		BEGIN

			SET NOCOUNT ON;

		declare @fecha  datetime

		set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

			select r.id_grabacion, avg(r.total_forma) as total_forma
			into #tempRiaFormaCalif from ria_formacalif r 
			inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
			on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
			group by r.id_grabacion		
			
			select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
			into #tempCampEspWG from ccRIACampEspWGConsulta a 
			inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

			select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, 
			a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.cal_id = @call_id
			union
			select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
			from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.cal_id = @call_id

			drop table #tempRiaFormaCalif
			drop table #tempCampEspWG
			
	END
	'
	EXEC(@Sql)


	set @process = 'alter PROCEDURE  -- trsp_AdmGetAllRepositories'
	set @Sql='	
	ALTER PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
		-- Add the parameters for the stored procedure here
	@Mode int
	-- Mode 1 para busqueda de grabaciones
	-- Mode 2 para configuracion de repositorios

	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	    -- Insert statements for procedure here
	IF @Mode = 1
	Begin

	select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio
		End
	Else IF @Mode =2
		Begin
		
	select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio

	End


	END

	'
	EXEC(@Sql)


	set @process = 'alter PROCEDURE  -- trsp_GetNetworkCredentials'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_GetNetworkCredentials]
	@id integer = 0,
	@domain nvarchar(50) = '''',
	@type integer = 0
	AS
	BEGIN

	DECLARE @SQL as nvarchar(MAX)
	DECLARE @isXION as integer

		--Get AVRS enviroment
		SET @isXION = (SELECT par_valor FROM  TREC_PARAMETROS WHERE par_id = 29)

		IF @isXION = 2
			BEGIN
					
				IF @id <> 0 and @type <> 0
					BEGIN

						--Get network credential for id
						SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
									FROM RIA_NETWORKCREDENTIALS 
									JOIN TREC_REPO_NWCREDENTIALS
									ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
									WHERE RIA_NETWORKCREDENTIALS.[id] = '' +	CONVERT(varchar(20), @id) + '' AND RIA_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) + '' AND RIA_NETWORKCREDENTIALS.[status]=1''

					END
				ELSE IF LEN(@domain) > 0 and @type <> 0
						BEGIN

							--Get network credential for domail
							SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
										FROM RIA_NETWORKCREDENTIALS 
										JOIN TREC_REPO_NWCREDENTIALS
										ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
										WHERE RIA_NETWORKCREDENTIALS.domain = '''''' + @domain + '''''''' + '' AND RIA_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) +''AND RIA_NETWORKCREDENTIALS.[status]=1''

						END
				ELSE IF @type <> 0 and @id = 0 and LEN(@domain) = 0
						BEGIN
							--Get network credential for domail
							SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
										FROM RIA_NETWORKCREDENTIALS 
										JOIN TREC_REPO_NWCREDENTIALS
										ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
										WHERE RIA_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) +''AND RIA_NETWORKCREDENTIALS.[status]=1''

						END
				ELSE			
						BEGIN

							--Get all network credentials						
							SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
										FROM RIA_NETWORKCREDENTIALS 
										JOIN TREC_REPO_NWCREDENTIALS
										ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
										WHERE RIA_NETWORKCREDENTIALS.[status]=1''

						END
						
			END
		ELSE
			BEGIN

				IF @id <> 0 and @type <> 0
					BEGIN

						--Get network credential for id
						SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
									FROM TREC_NETWORKCREDENTIALS 
									JOIN TREC_REPO_NWCREDENTIALS
									ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
									WHERE TREC_NETWORKCREDENTIALS.[id] = '' +	CONVERT(varchar(20), @id) + '' AND TREC_NETWORKCREDENTIALS.[type] = ''''+ CONVERT(varchar(20), @TYPE) + '''' AND TREC_NETWORKCREDENTIALS.[status]=1''

					END
				ELSE IF LEN(@domain) > 0 and @type <> 0
						BEGIN

							--Get network credential for domain
							SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
										FROM TREC_NETWORKCREDENTIALS 
										JOIN TREC_REPO_NWCREDENTIALS
										ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
										WHERE TREC_NETWORKCREDENTIALS.domain = '''''' + @domain + '''''''' + '' AND TREC_NETWORKCREDENTIALS.[type] = ''''+ CONVERT(varchar(20), @TYPE) +''''AND TREC_NETWORKCREDENTIALSe.[status]=1''

						END
				ELSE IF @type <> 0 and @id = 0 and LEN(@domain) = 0
					BEGIN
							--Get network credential for type
							SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
										FROM TREC_NETWORKCREDENTIALS 
										JOIN TREC_REPO_NWCREDENTIALS
										ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
										WHERE TREC_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) +''AND TREC_NETWORKCREDENTIALSe.[status]=1''

					END
				ELSE
						BEGIN

							--Get all network credentials						
							SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],TREC_NETWORKCREDENTIALS.[user], TREC_NETWORKCREDENTIALS.[domain],TREC_NETWORKCREDENTIALS.[password], TREC_NETWORKCREDENTIALS.[id] AS id_credential
										FROM TREC_NETWORKCREDENTIALS 
										JOIN TREC_REPO_NWCREDENTIALS
										ON TREC_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
										WHERE TREC_NETWORKCREDENTIALS.[status]=1''

						END

			END

		EXEC SP_EXECUTESQL @SQL
		
	END	
	
	'
	EXEC(@Sql)


	set @process = 'Create PROCEDURE  -- trsp_GetParametersExportService'
	set @Sql='	
	CREATE PROCEDURE [dbo].[trsp_GetParametersExportService]
	AS
	BEGIN
	DECLARE  @avrs_enviroment AS INT
	DECLARE @SQL AS NVARCHAR(MAX)

	SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

		IF @avrs_enviroment = 2
			BEGIN
			
				SET @SQL = ''SELECT * FROM
							(SELECT par_valor,par_id FROM TREC_PARAMETROS 
							WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,61,62,63,29,2,65,67)
							UNION
							SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
							FROM RIA_GRABACION)x
							ORDER BY x.par_id''
				
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

	EXEC sp_executesql @SQL

	END
	'
	EXEC(@Sql)

	set @process = 'Create PROCEDURE  -- trsp_GetRecordigsExportService'
	set @Sql='	
	CREATE PROCEDURE [dbo].[trsp_GetRecordigsExportService]
	@grabId AS INT,
	@integrated AS INT
	AS
	BEGIN
	DECLARE @SQL AS NVARCHAR(MAX)

		IF @integrated = 1
			BEGIN

				SET @SQL = ''SELECT TOP 10000 * FROM(
					 SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio 
					 FROM RIA_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
						  t.id_repositorio = r.id_repositorio 
					 UNION 
					 SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio 
					 FROM RIA_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
						  t.id_repositorio = r.id_repositorio)x
					 WHERE x.grab_id >=''+ CONVERT(VARCHAR(10), @grabId) +''AND x.finicio < GETDATE()
					 ORDER BY x.grab_id''

			END
		ELSE IF @integrated = 0
			BEGIN

				 SET @SQL = ''SELECT TOP 10000 * FROM(
					 SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio 
					 FROM TREC_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
						  t.id_repositorio = r.id_repositorio 
					 UNION 
					 SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio 
					 FROM TREC_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
						  t.id_repositorio = r.id_repositorio)x
					 WHERE x.grab_id >=''+ CONVERT(VARCHAR(10), @grabId) +''AND x.finicio < GETDATE()
					 ORDER BY x.grab_id''

			END

		EXEC SP_EXECUTESQL @SQL

	END
	
	'
	EXEC(@Sql)

	
------------------ fin SCRIPT @Sql ------------------
	--Generamos nueva version
	--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 	update trec_parametros set par_valor = @Version where par_id = 30 

	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off