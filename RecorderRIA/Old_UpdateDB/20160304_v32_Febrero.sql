/*
Date: 2016/03/04
Description:

 Drop Index IX_ccRIAWorkGroupUsersConsulta2
 Create Index IX_ccRIAWorkGroupUsersConsulta2

 Drop Table Numbers
 Drop Table RIA_DIRECTORY_EXPORT_PROFILES
 Drop Table RIA_ExportProfilesRecordingsManager
 create Table Numbers
 create Table RIA_DIRECTORY_EXPORT_PROFILES
 create Table RIA_ExportProfilesRecordingsManager

 Drop Function split_me
 create Function split_me

 Drop PROCEDURE trsp_AdmRecSearchNodeWgAgent
 Create PROCEDURE trsp_AdmRecSearchNodeWgAgent

 Alter trsp_AdmRecSearchNodeWgCampACDCalif

Database: CCRecorderRia
Required version: 31
*/

SET nocount ON
DECLARE @Version VARCHAR(10)
DECLARE @Version_Actual VARCHAR(10)
DECLARE @Process VARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX)
DECLARE @errorGenerated VARCHAR(max)


/* Version to release (use the version of your own databse)*/
set @version = 32

/* Actual version (use your own script to do it) */
select @Version_Actual=par_valor from trec_parametros where par_id = 30

if @Version_Actual=@Version-1
BEGIN
BEGIN TRAN
BEGIN TRY

	--Index

	set @process = 'Drop Index IX_ccRIAWorkGroupUsersConsulta2 -on ccRIAWorkGroupUsersConsulta'
	IF EXISTS (SELECT Name FROM sysindexes WHERE Name = 'IX_ccRIAWorkGroupUsersConsulta2')  DROP INDEX ccRIAWorkGroupUsersConsulta.IX_ccRIAWorkGroupUsersConsulta2
	EXEC(@sql)

	set @process = 'create Index IX_ccRIAWorkGroupUsersConsulta2 -on ccRIAWorkGroupUsersConsulta'
  	if not exists (select * from sys.indexes where name = N'IX_ccRIAWorkGroupUsersConsulta2' and object_id = OBJECT_ID(N'ccRIAWorkGroupUsersConsulta'))
	begin
		CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsersConsulta2] ON [dbo].[ccRIAWorkGroupUsersConsulta]
			(
				[IDWG] ASC,
				[User_id] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
	end
  	EXEC(@sql)

	--Tables

	set @process = 'Numbers - Drop if exists'
  	set @sql='if exists (select * from sys.tables where name = N''Numbers'') DROP table Numbers'
  	EXEC(@sql)

  	set @process = 'RIA_DIRECTORY_EXPORT_PROFILES - Drop if exists'
  	set @sql='if exists (select * from sys.tables where name = N''RIA_DIRECTORY_EXPORT_PROFILES'') DROP table RIA_DIRECTORY_EXPORT_PROFILES'
  	EXEC(@sql)

  	set @process = 'RIA_ExportProfilesRecordingsManager - Drop if exists'
  	set @sql='if exists (select * from sys.tables where name = N''RIA_ExportProfilesRecordingsManager'') DROP table RIA_ExportProfilesRecordingsManager'
  	EXEC(@sql)

  	set @process = 'create table - Numbers'
  	set @sql='CREATE TABLE [dbo].[Numbers](
				[Number] [int] NOT NULL,
				 CONSTRAINT [PK__Numbers__3AD6B8E2] PRIMARY KEY CLUSTERED
				(
					[Number] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]'
  	EXEC(@sql)

  	set @process = 'create table - RIA_DIRECTORY_EXPORT_PROFILES'
  	set @sql='CREATE TABLE [dbo].[RIA_DIRECTORY_EXPORT_PROFILES](
				[id] [int] IDENTITY(1,1) NOT NULL,
				[user_id] [int] NULL,
				[fields] [nvarchar](500) NULL,
				[active] [bit] NULL,
				[name] [nvarchar](255) NULL,
				 CONSTRAINT [PK_RIA_DIRECTORY_EXPORT_PROFILES] PRIMARY KEY CLUSTERED
				(
					[id] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
				) ON [PRIMARY]'
  	EXEC(@sql)

  	set @process = 'create table - RIA_ExportProfilesRecordingsManager'
  	set @sql='CREATE TABLE [dbo].[RIA_ExportProfilesRecordingsManager](
				[id] [int] IDENTITY(1,1) NOT NULL,
				[profile] [nvarchar](255) NOT NULL,
				[user_id] [int] NOT NULL,
				[struct] [varchar](255) NULL,
				[active] [int] NOT NULL
				) ON [PRIMARY]'
  	EXEC(@sql)

	--Functions

  	set @process = 'Function split_me - Drop if exists'
  	set @sql='IF EXISTS (SELECT * FROM   sys.objects WHERE  object_id = OBJECT_ID(N''[dbo].[split_me]'') AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))  DROP FUNCTION [dbo].[split_me]'
  	EXEC(@sql)


	set @process = 'create Function - split_me'
  	set @sql='CREATE FUNCTION [dbo].[split_me](@param nvarchar(4000))
				RETURNS TABLE AS
				RETURN(
					SELECT ltrim(rtrim(convert(nvarchar(4000),
				                  substring(@param, Number,
				                            charindex(N'','' COLLATE Slovenian_BIN2,
				                                      @param + N'','',
				                                      Number) - Number)
				              ))) AS Value
				       FROM   Numbers
				       WHERE  Number <= convert(int, len(@param))
				         AND  substring( N'','' + @param, Number, 1) = N'','' COLLATE Slovenian_BIN2
				)'
  	EXEC(@sql)

	--SP


	set @process = 'trsp_AdmGetExportCamp - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetExportCamp'') DROP PROCEDURE trsp_AdmGetExportCamp'
  	EXEC(@sql)

  	set @process = 'trsp_DeleteDirectoryExportProfileById - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_DeleteDirectoryExportProfileById'') DROP PROCEDURE trsp_DeleteDirectoryExportProfileById'
  	EXEC(@sql)

	set @process = 'trsp_DeleteExportProfileById - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_DeleteExportProfileById'') DROP PROCEDURE trsp_DeleteExportProfileById'
  	EXEC(@sql)

	set @process = 'trsp_GetDirectoryExportFields - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetDirectoryExportFields'') DROP PROCEDURE trsp_GetDirectoryExportFields'
  	EXEC(@sql)

	set @process = 'trsp_GetDirectoryExportProfileByID - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetDirectoryExportProfileByID'') DROP PROCEDURE trsp_GetDirectoryExportProfileByID'
  	EXEC(@sql)

	set @process = 'trsp_GetDirectoryExportProfileByUserId - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetDirectoryExportProfileByUserId'') DROP PROCEDURE trsp_GetDirectoryExportProfileByUserId'
  	EXEC(@sql)

	set @process = 'trsp_GetDirectoryExportProfilesByUserId - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetDirectoryExportProfilesByUserId'') DROP PROCEDURE trsp_GetDirectoryExportProfilesByUserId'
  	EXEC(@sql)

  	set @process = 'trsp_GetExportFormats - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetExportFormats'') DROP PROCEDURE trsp_GetExportFormats'
  	EXEC(@sql)

	set @process = 'trsp_GetExportProfileByID - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetExportProfileByID'') DROP PROCEDURE trsp_GetExportProfileByID'
  	EXEC(@sql)

	set @process = 'trsp_GetExportProfilesByUserID - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetExportProfilesByUserID'') DROP PROCEDURE trsp_GetExportProfilesByUserID'
  	EXEC(@sql)

  	set @process = 'trsp_GetParametersExportService - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetParametersExportService'') DROP PROCEDURE trsp_GetParametersExportService'
  	EXEC(@sql)

 	set @process = 'trsp_saveDirectoryExportProfileByUserID - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_saveDirectoryExportProfileByUserID'') DROP PROCEDURE trsp_saveDirectoryExportProfileByUserID'
  	EXEC(@sql)

  	set @process = 'trsp_saveExportProfileByUserID - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_saveExportProfileByUserID'') DROP PROCEDURE trsp_saveExportProfileByUserID'
  	EXEC(@sql)

	set @process = 'trsp_UpdateActiveDirectoryExportProfileById - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_UpdateActiveDirectoryExportProfileById'') DROP PROCEDURE trsp_UpdateActiveDirectoryExportProfileById'
  	EXEC(@sql)

  	set @process = 'trsp_UpdateActiveExportProfileById - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_UpdateActiveExportProfileById'') DROP PROCEDURE trsp_UpdateActiveExportProfileById'
  	EXEC(@sql)


	set @process = 'Create PROCEDURE -- trsp_AdmGetExportCamp'
	set @sql='CREATE PROCEDURE [dbo].[trsp_AdmGetExportCamp]
			-- Add the parameters for the stored procedure here
			@id int
			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			select Campo from CCRecorderRIA.dbo.TREC_FORM_ARCHIVOSEXPORT where id = @id

			END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_DeleteDirectoryExportProfileById'
	set @sql='CREATE PROCEDURE [dbo].[trsp_DeleteDirectoryExportProfileById]
			@id int
			AS
			BEGIN
			SET NOCOUNT ON;
					DELETE
					FROM  RIA_DIRECTORY_EXPORT_PROFILES
					WHERE [id] = @id
			END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_DeleteDirectoryExportProfileById'
	set @sql='CREATE PROCEDURE [dbo].[trsp_DeleteExportProfileById]
			@id int
			AS
			BEGIN
			SET NOCOUNT ON;
					DELETE FROM  RIA_ExportProfilesRecordingsManager
					WHERE [id] = @id
			END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_DeleteDirectoryExportProfileById'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportFields]
				AS
				BEGIN
					select * from TREC_FORM_CARPETASEXPORT
				END'
	EXEC(@sql)


	set @process = 'Create PROCEDURE -- trsp_GetDirectoryExportProfileByID'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfileByID]
				@id int
				AS
				BEGIN
						SELECT id, name,fields,active
						FROM RIA_DIRECTORY_EXPORT_PROFILES
						WHERE [id] = @id
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_GetDirectoryExportProfileByUserId'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfileByUserId]
				@user_id int
				AS
				BEGIN
							select isnull(max(fields),'''') from RIA_DIRECTORY_EXPORT_PROFILES where user_id = @user_id and active =1
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_GetDirectoryExportProfilesByUserId'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetDirectoryExportProfilesByUserId]
				@userID int
				AS
				BEGIN
						SELECT id, user_id, name,fields,active
						FROM RIA_DIRECTORY_EXPORT_PROFILES
						WHERE [user_id] = @userID
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_GetExportFormats'
	set @sql='CREATE  PROCEDURE [dbo].[trsp_GetExportFormats]
				AS
				BEGIN
				SET NOCOUNT ON;
						select id,formato from  TREC_FORM_ARCHIVOSEXPORT order by id
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_GetExportProfileByID'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetExportProfileByID]
				@id int
				AS
				BEGIN
					SELECT id,profile,struct,active
					FROM RIA_ExportProfilesRecordingsManager
					WHERE id = @id
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_GetExportProfilesByUserID'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetExportProfilesByUserID]
				@userId int
				AS
				BEGIN
				SET NOCOUNT ON;
						select id,profile,struct,active from RIA_ExportProfilesRecordingsManager where [user_id] = @userId
				END'
	EXEC(@sql)


	set @process = 'Create PROCEDURE -- trsp_GetParametersExportService'
	set @sql='CREATE PROCEDURE [dbo].[trsp_GetParametersExportService]
				AS
				BEGIN

				DECLARE  @avrs_enviroment AS INT
				DECLARE @SQL AS NVARCHAR(MAX)

				SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

				IF @avrs_enviroment = 2
					BEGIN
						SET @SQL = ''SELECT * FROM
						(SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
						WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,61,62,63,29,2,65,66,67)
						UNION
						SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,''''''''
						FROM RIA_GRABACION)x
						ORDER BY x.par_id''
					END
				ELSE
					BEGIN

						SET @SQL = ''SELECT * FROM
						(SELECT par_valor,par_id FROM TREC_PARAMETROS
						WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,61,62,63,29,2,65,66,67)
						UNION
						SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
						FROM TREC_GRABACION)x
						ORDER BY x.par_id''
					END

					EXEC sp_executesql @SQL
			END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_saveDirectoryExportProfileByUserID'
	set @sql='CREATE PROCEDURE [dbo].[trsp_saveDirectoryExportProfileByUserID]
				@userId  as int,
				@fields as nvarchar(255),
				@name as nvarchar(255),
				@Id as int
				AS


				BEGIN
				SET NOCOUNT ON;


					IF @Id = 0
						Begin

							insert into RIA_DIRECTORY_EXPORT_PROFILES
							([name],[user_id],fields,active)
							values
							(@name,@userId,@fields,0)
							select Scope_Identity()
						End
					Else
						Begin
							update RIA_DIRECTORY_EXPORT_PROFILES
							set fields = @fields
							where id = @Id
						End
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_saveExportProfileByUserID'
	set @sql='CREATE PROCEDURE [dbo].[trsp_saveExportProfileByUserID]
				@userId  as int,
				@struct as nvarchar(255),
				@profile as nvarchar(255),
				@Id as int
				AS

				BEGIN
				SET NOCOUNT ON;

					IF @Id = 0
						Begin
							insert into RIA_ExportProfilesRecordingsManager
							([profile],[user_id],struct,active)
							values
							(@profile,@userId,@struct,0)
							select Scope_Identity()
						End
					Else
						Begin
							update RIA_ExportProfilesRecordingsManager
							set struct = @struct
							where id = @Id
						End
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_UpdateActiveDirectoryExportProfileById'
	set @sql='CREATE PROCEDURE [dbo].[trsp_UpdateActiveDirectoryExportProfileById]
				@id as int,
				@active as bit
				AS

				BEGIN

					update RIA_DIRECTORY_EXPORT_PROFILES
					set active = 0

					update RIA_DIRECTORY_EXPORT_PROFILES
					set active = @active
					where [id] = @id
				END'
	EXEC(@sql)

	set @process = 'Create PROCEDURE -- trsp_UpdateActiveDirectoryExportProfileById'
	set @sql='CREATE PROCEDURE [dbo].[trsp_UpdateActiveExportProfileById]
				@id as int,
				@active as bit
				AS

				BEGIN

					update RIA_ExportProfilesRecordingsManager
					set active = 0

					update RIA_ExportProfilesRecordingsManager
					set active = @active
					where [id] = @id
				END'
	EXEC(@sql)

	set @process = 'Alter PROCEDURE -- trsp_AdmRecSearchCallIdStr'
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
				@Sup_id int,
				@callIdList as nvarchar(max),
				@UserList varchar(MAX) =null,
				@IDWGList varchar(MAX) =null,
				@TypeCall int = null,
				@CampaingsList varchar(MAX) =null,
				@ACDList varchar(MAX) =null,
				@DispositionList varchar(MAX) =null,
				@SubdispositionList varchar(MAX) =null

				AS
				BEGIN

				SET NOCOUNT ON

				declare @sql1 nvarchar(max)

				--Tabla con toda la informaciom
				CREATE TABLE #tempRiAAllInfo(
					cal_id int,
					tipo_llamada smallint,
					cam_id smallint,
					calif_id smallint,
					duracion int,
					id_nivel_grito int,
					[user_id] int,
					finicio datetime,
					ani varchar (100),
					dni varchar (100),
					cal_key varchar (100),
					cal_manual tinyint,
					posicion int,
					computer varchar(100),
					total_forma int,
					id_repositorio tinyint,
					score varchar (100),
					formato_duracion varchar(15),
					grab_id bigint,
					IDWG varchar (800),
					califSub_id varchar(800),
					cal_tMoh smallint
				)

				CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
				(
				[finicio] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


				create table #auxOutbound(
				   	cal_id int,
					tipo_llamada smallint,
					cam_id smallint,
					calif_id smallint,
					duracion int,
					id_nivel_grito int,
					[user_id] int,
					finicio datetime,
					ani varchar (100),
					dni varchar (100),
					cal_key varchar (100),
					cal_manual tinyint,
					posicion int,
					computer varchar(100),
					total_forma int,
					id_repositorio tinyint,
					score varchar (100),
					formato_duracion varchar(15),
					grab_id bigint,
					IDWG varchar (800),
					califSub_id  varchar(800),
					cal_tMoh smallint
					)

				--Segmento de Calificaciones
				create table #tempRiaFormaCalif6(
				id_grabacion bigint,
				total_forma int)

				insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
				select r.id_grabacion, avg(r.total_forma) as total_forma
				from ria_formacalif r
				inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion


				--Segmento de Supervisor
				create table #tempCampEspWG6(
				IdCampEsp smallint,
				Tipo smallint,
				[user_id] smallint)

				CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6]
				(
				[user_id] ASc
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]

				insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id)
				  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
				from ccRIACampEspWGConsulta a
				inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG

				--Segmento de usurios asociados al supervisor
				create table #tempComplete6(
				IdCampEsp smallint,
				Tipo smallint,
				[user_id] int,
				IDWG smallint)

				CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6]
				(
				[user_id] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]



				if @UserList is not null and @UserList <> ''''
				BEGIN
					set @sql1=''insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
							select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
							from ccRIACampEspWGConsulta a  inner join
							(select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in
							(select  distinct a.IDWG from ccRIACampEspWGConsulta a
										inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
							)and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
							) b on a.IDWG=b.IDWG''
					exec (@sql1)

				END
				else
				BEGIN
					insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
					select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
					from  ccRIACampEspWGConsulta a  inner join
					(select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in
						(select  distinct a.IDWG from ccRIACampEspWGConsulta a
							inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
							)and user_id <> @Sup_id
					) b on a.IDWG=b.IDWG
				END


				if @TypeCall is not null and @TypeCall <> ''''
					BEGIN
						if @TypeCall=1 -- Only Inbound
							BEGIN
								set @sql1 =''
								insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
								where''
								if @IDWGList is not null and @IDWGList <> ''''
									set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
								else
									--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

								if @ACDList is not null and @ACDList <> ''''
									set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

								if @DispositionList is not null and @DispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

								if @SubdispositionList is not null and @SubdispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

								set @sql1 = @sql1 + '' and a.tipo_llamada=1''
								--print @sql1
								exec (@sql1)

								set @sql1 =''
								insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
								where''
								if @IDWGList is not null and @IDWGList <> ''''
									set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
								else
									--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

								if @ACDList is not null and @ACDList <> ''''
									set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

								if @DispositionList is not null and @DispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

								if @SubdispositionList is not null and @SubdispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

								set @sql1 = @sql1 + '' and a.tipo_llamada=1''
								--print @sql1
								exec (@sql1)

								if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
									begin
										set @sql1 =''
										insert into #tempRiAAllInfo
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (f.description,'''''''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
										where''

										if @IDWGList is not null and @IDWGList <> ''''
											set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
													'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
										else
											set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


										if @ACDList is not null and @ACDList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

										if @DispositionList is not null and @DispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

										if @SubdispositionList is not null and @SubdispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

										set @sql1 = @sql1 + '' and a.tipo_llamada=1''
										--print @sql1
										exec (@sql1)

										set @sql1 =''
										insert into #tempRiAAllInfo
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
													finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
													isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
													isnull (z.total_forma,0) as total_forma,a.id_repositorio,
													isnull (f.description,'''''''')  AS score,
													CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
													grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
										where''

										if @IDWGList is not null and @IDWGList <> ''''
											set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
													'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
										else
											set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

										if @ACDList is not null and @ACDList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

										if @DispositionList is not null and @DispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

										if @SubdispositionList is not null and @SubdispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

										set @sql1 = @sql1 + '' and a.tipo_llamada=1''
										--print @sql1
										exec (@sql1)
									end
							END
						ELSE
							BEGIN --Only Outbound
								set @sql1 =''
								insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
											    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
								select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (e.description,'''''''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
								left join cctipocalifsubout k on k.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								where''

								if @IDWGList is not null and @IDWGList <> ''''
									set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
								else
									--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

								if @CampaingsList is not null and @CampaingsList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

								if @DispositionList is not null and @DispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

								if @SubdispositionList is not null and @SubdispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

								set @sql1 = @sql1 + '' and a.tipo_llamada=2''
								--print @sql1
								exec (@sql1)

								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
								inner join #tempComplete6 U  on a.user_id=U.user_id

								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
								inner join #tempCampEspWG6 U  on a.user_id=U.user_id


								if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
									begin
										set @sql1 =''
										insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
										select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
														finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
														isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
														isnull (z.total_forma,0) as total_forma,a.id_repositorio,
														isnull (e.description,'''''''')  AS score,
														CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
														grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
										left join cctipocalifsubout k on k.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										where''

										if @IDWGList is not null and @IDWGList <> ''''
											set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
													'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
										else
											set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

										if @CampaingsList is not null and @CampaingsList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

										if @DispositionList is not null and @DispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

										if @SubdispositionList is not null and @SubdispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

										set @sql1 = @sql1 + '' and a.tipo_llamada=2''
										--print @sql1
										exec (@sql1)

										insert into #tempRiAAllInfo
										select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
										inner join #tempComplete6 U  on a.user_id=U.user_id

										insert into #tempRiAAllInfo
										select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
										inner join #tempCampEspWG6 U  on a.user_id=U.user_id

									end
							END
					END
				ELSE
					BEGIN --NOT Inbound or Outbound this mean both
								set @sql1 =''
								insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
								where''
								if @IDWGList is not null and @IDWGList <> ''''
									set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
								else
									--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

								if @ACDList is not null and @ACDList <> ''''
									set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

								if @DispositionList is not null and @DispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

								if @SubdispositionList is not null and @SubdispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

								set @sql1 = @sql1 + '' and a.tipo_llamada=1''
								--print @sql1
								exec (@sql1)

								set @sql1 =''
								insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
								where''
								if @IDWGList is not null and @IDWGList <> ''''
									set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
								else
									--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

								if @ACDList is not null and @ACDList <> ''''
									set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

								if @DispositionList is not null and @DispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

								if @SubdispositionList is not null and @SubdispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

								set @sql1 = @sql1 + '' and a.tipo_llamada=1''
								--print @sql1
								exec (@sql1)

								set @sql1 =''
								insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
											    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
								select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (e.description,'''''''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
								left join cctipocalifsubout k on k.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								where''

								if @IDWGList is not null and @IDWGList <> ''''
									set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
								else
									--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

								if @CampaingsList is not null and @CampaingsList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

								if @DispositionList is not null and @DispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

								if @SubdispositionList is not null and @SubdispositionList <> ''''
									set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

								set @sql1 = @sql1 + '' and a.tipo_llamada=2''
								--print @sql1
								exec (@sql1)

								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
								inner join #tempComplete6 U  on a.user_id=U.user_id

								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
								inner join #tempCampEspWG6 U  on a.user_id=U.user_id

								if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
								begin
										set @sql1 =''
										insert into #tempRiAAllInfo
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (f.description,'''''''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
										where''

										if @IDWGList is not null and @IDWGList <> ''''
											set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
													'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
										else
											set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


										if @ACDList is not null and @ACDList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

										if @DispositionList is not null and @DispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

										if @SubdispositionList is not null and @SubdispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

										set @sql1 = @sql1 + '' and a.tipo_llamada=1''
										--print @sql1
										exec (@sql1)

										set @sql1 =''
										insert into #tempRiAAllInfo
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
													finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
													isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
													isnull (z.total_forma,0) as total_forma,a.id_repositorio,
													isnull (f.description,'''''''')  AS score,
													CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
													grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
										where''

										if @IDWGList is not null and @IDWGList <> ''''
											set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
													'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
										else
											set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


										if @ACDList is not null and @ACDList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

										if @DispositionList is not null and @DispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

										if @SubdispositionList is not null and @SubdispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

										set @sql1 = @sql1 + '' and a.tipo_llamada=1''
										--print @sql1
										exec (@sql1)

										set @sql1 =''
										insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
										select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
														finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
														isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
														isnull (z.total_forma,0) as total_forma,a.id_repositorio,
														isnull (e.description,'''''''')  AS score,
														CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
														grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
										left join cctipocalifsubout k on k.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										where''

										if @IDWGList is not null and @IDWGList <> ''''
											set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
													'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
										else
											set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

										if @CampaingsList is not null and @CampaingsList <> ''''
											set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

										if @DispositionList is not null and @DispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

										if @SubdispositionList is not null and @SubdispositionList <> ''''
											set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

										set @sql1 = @sql1 + '' and a.tipo_llamada=2''
										print @sql1
										exec (@sql1)

										insert into #tempRiAAllInfo
										select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
										inner join #tempComplete6 U  on a.user_id=U.user_id

										insert into #tempRiAAllInfo
										select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
										inner join #tempCampEspWG6 U  on a.user_id=U.user_id

								end

					END



				--Seleccionar info de tabla global
				select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
					   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
					   id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh
				from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc

				drop table #tempRiaFormaCalif6
				drop table #tempCampEspWG6
				drop table #tempComplete6
				drop table #tempRiAAllInfo
				drop table #auxOutbound

				END'
	EXEC(@sql)


set @process = 'Alter PROCEDURE -- trsp_AdmRecSearchNodeWgCampACDCalif'
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWgCampACDCalif] 
  @User_id int AS
BEGIN

	SET NOCOUNT ON

	select b.IDWG, c.WGName
	into #nodeWorkgroup
	from ccusers a 
	inner join ccRIAWorkGroupUsersConsulta b on b.user_id = @User_id 
	inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
	where a.user_id = @User_id
	order by b.IDWG

	create table #tempFinal(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100),
	califSub_id smallint,
	califSubDesc varchar(100) 
    )  

	create table #tempFinalOut(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100),
	califSub_id smallint,
	califSubDesc varchar(100) 
    )  

	create table #tempInbound(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100)   
    )  
		  
	create table #tempOutbound(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100)  
    )  

	insert into #tempInbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
		select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.descripcion, isnull(d.frame,1) frame, 
		isnull(f.calif_id,0) as calif_id, isnull(g.Description,'''') as califDescription
		from ccRIACampEspWGConsulta a
		inner join ccInbound b on b.Inbound_id = a.idCampEsp
		left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		left join #nodeWorkgroup e on a.IDWG = e.IDWG
		left join ccCalifCamp f on b.inbound_id = f.cam_id and f.tipo = 0
		left join ccTipoCalif g on f.calif_id = g.calif_id and g.Calif_Status = 1
		where a.Tipo = 0
		and e.IDWG is not null
		and a.idCampEsp is not null	
		and g.Description <> ''''
		order by IDWG, tipo, idCampEsp, calif_id

	insert into #tempOutbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
		select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.cam_descripcion as descripcion,
		isnull(d.frame,1) frame, isnull(f.calif_id,0) as calif_id, isnull(g.Description,'''') as califDescription
		from ccRIACampEspWGConsulta a
		inner join ccCamps b on b.cam_id = a.idCampEsp
		left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		left join #nodeWorkgroup e on a.IDWG = e.IDWG
		left join ccCalifCamp f on b.cam_id = f.cam_id and f.tipo = 1
		left join ccTipoCalifOUT g on f.calif_id = g.calif_id and g.CalifOut_Status = 1
		where a.Tipo = 1
		and e.IDWG is not null
		and a.idCampEsp is not null
		and g.Description <> ''''
		order by IDWG, tipo, idCampEsp, calif_id

	---Seccion Inbound

	insert into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'''') as califSubDesc from #tempInbound B
		inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
		inner join cctipocalifsub as C on C.califSub_id = A.califSub_id
		where  A.tipoSubRel=1
		and C.califSub_id=A.califSub_id	
		and C.califSubDesc <>''''


	insert  into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'''','''' from #tempInbound where calif_id not in (select distinct (calif_id) from #tempFinal)

	---Seccion Outbound

	insert into #tempFinalOut (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'''') as califSubDesc from #tempOutbound B
		inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
		inner join cctipocalifsubout as C on C.califSub_id = A.califSub_id
		where  A.tipoSubRel=0
		and C.califSub_id=A.califSub_id
		and C.califSubDesc <>''''

	insert  into #tempFinalOut (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'''','''' from #tempOutbound where calif_id not in (select distinct (calif_id) from #tempFinalOut)

	
	--Seleccion de Toda la Info
	select * from #tempFinal
	union select * from #tempFinalOut
	order by IDWG, tipo, idCampEsp, calif_id
	
	drop table #nodeWorkgroup
	drop table #tempInbound
	drop table #tempOutbound
	drop table #tempFinal
	drop table #tempFinalOut
	
END'
	EXEC(@sql)
------------------ End Script @Sql ------------------

UPDATE trec_parametros SET par_valor = @version WHERE par_id = 30

COMMIT tran
END try

BEGIN catch
	SELECT @errorGenerated = 'DB Script Version: ' + cast(@Version AS NVARCHAR) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)
	ROLLBACK tran
END catch
END

ELSE
 BEGIN
	SELECT 'Data base incorrect version ' + cast(@Version_Actual AS VARCHAR(5)) + ', please update to  ' + cast(@Version AS VARCHAR(5))
 END
SET nocount off
