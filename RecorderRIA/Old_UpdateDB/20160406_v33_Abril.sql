/*
Date: 2016/03/04
Description:


 Drop PROCEDURE trsp_SaveAVRSExportParameters
 Create PROCEDURE trsp_SaveAVRSExportParameters

 Alter SP trsp_AdmRecSearchNodeWgCampACDCalif
 Alter SP trsp_GetRecordigsExportService

Database: CCRecorderRia
Required version: 32
*/

SET nocount ON
DECLARE @Version VARCHAR(10)
DECLARE @Version_Actual VARCHAR(10)
DECLARE @Process VARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX)
DECLARE @errorGenerated VARCHAR(max)


/* Version to release (use the version of your own databse)*/
set @version = 33

/* Actual version (use your own script to do it) */
select @Version_Actual=par_valor from trec_parametros where par_id = 30

if @Version_Actual=@Version-1
BEGIN
BEGIN TRAN
BEGIN TRY

	--Index

	--Tables

	--Functions

  	--SP

  	set @process = 'trsp_SaveAVRSExportParameters - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_SaveAVRSExportParameters'') DROP PROCEDURE trsp_SaveAVRSExportParameters'
  	EXEC(@sql)

  	set @process = 'Alter SP -- trsp_AdmVerifyingChatFormatEditing'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmVerifyingChatFormatEditing]
@id_chat int,@id_formato int,@type tinyint = 2


AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


	-- Insert statements for procedure here

Select isnull(max(id_forma),0) from RIA_FORMACALIF
where id_grabacion = @id_chat and id_formato = @id_formato and tipo=@type

END'
  	EXEC(@sql)


  	set @process = 'ALTER PROCEDURE [dbo].[trsp_AdmGetMarkTimeToCut2]'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetMarkTimeToCut2]
@grabId bigint

AS
BEGIN

declare @sql nvarchar(max)

set @sql=''select top 1 isnull(SUM(DATEDIFF(SECOND, 0, marca)),0) from (select * from RIA_Grabacion where grab_id=''+cast(@grabId as nvarchar(max))
+''union select * from RIA_GrabacionConsulta where grab_id=''+cast(@grabId as nvarchar(max))
+'') A left join RIA_MARCAS B on B.tipo_llamada = A.tipo_llamada and B.call_Id=A.cal_id''
--print (@sql)
exec(@sql)

END	'
  	EXEC(@sql)

  	set @process = 'ALTER PROCEDURE [dbo].[trsp_AdmSaveChatScoresFormaCalif]--------'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmSaveChatScoresFormaCalif]
@chat_id int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@age_id int,
@version int,
@typeServices tinyint =2

AS

BEGIN

SET NOCOUNT ON;

declare @cam_id int
if @typeServices = 2 begin
	select @cam_id= InboundId from ccriachats where chatId = @chat_id
end
else if @typeServices = 3 begin --Email
	select  @cam_id=min(B.inboundId) from message A
	inner join conversation B on A.conversationId=A.conversationId
	where A.conversationId=@chat_id
end
else if @typeServices = 4 begin --Twitter
	select  @cam_id=min(B.inboundId) from messageOutTwitter A
	inner join conversationTwitter B on A.conversationTwitterId=A.conversationTwitterId
	where A.conversationTwitterId=@chat_id
end

insert RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version, tipo,cam_id)
values (GetDate(),@id_calificador,@id_supervisor,@chat_id,@id_formato,@total_forma,@age_id,@version, @typeServices,@cam_id)

select Scope_Identity()

END'
  	EXEC(@sql)



  	set @process = 'ALTER PROCEDURE [dbo].[trsp_GetNetworkCredentials]---------'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_GetNetworkCredentials]
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

IF @id <> 0 and @type <> 0 BEGIN

	--Get network credential for id
	SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
FROM RIA_NETWORKCREDENTIALS
JOIN TREC_REPO_NWCREDENTIALS
ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
WHERE RIA_NETWORKCREDENTIALS.[id] = '' +	CONVERT(varchar(20), @id) + '' AND RIA_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) + '' AND RIA_NETWORKCREDENTIALS.[status]=1''

END
ELSE IF LEN(@domain) > 0 and @type <> 0 BEGIN

	--Get network credential for domail
	SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
FROM RIA_NETWORKCREDENTIALS
JOIN TREC_REPO_NWCREDENTIALS
ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
WHERE RIA_NETWORKCREDENTIALS.domain = '''''' + @domain + '''''''' + '' AND RIA_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) +''AND RIA_NETWORKCREDENTIALS.[status]=1''

END
ELSE IF @type <> 0 and @id = 0 and LEN(@domain) = 0 BEGIN
	--Get network credential for domail
	SET @SQL = ''SELECT TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
FROM RIA_NETWORKCREDENTIALS
JOIN TREC_REPO_NWCREDENTIALS
ON RIA_NETWORKCREDENTIALS.id=TREC_REPO_NWCREDENTIALS.[id_nwCredential]
WHERE RIA_NETWORKCREDENTIALS.[type] = ''+ CONVERT(varchar(20), @TYPE) +''AND RIA_NETWORKCREDENTIALS.[status]=1''

END
ELSE  BEGIN

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
  	EXEC(@sql)

	set @process = 'Create PROCEDURE trsp_SaveAVRSExportParameters '
  	set @sql='CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
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
@delete_rec AS INT = -1,
@export_format AS INT = 1,
@export_encrypted AS BIT = 0,
@file_encrypted AS Bit
AS
BEGIN

DECLARE @repo_Id AS INT

	-- Update FTP Parameters

	IF @export_mode = 1
		BEGIN

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_format
			WHERE
			par_id = 35

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

			UPDATE TREC_PARAMETROS
			SET par_valor = @file_encrypted
			WHERE
			par_id = 61

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_encrypted
			WHERE
			par_id = 62

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
			declare @avrs_enviroment as int
			SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

			IF @avrs_enviroment = 2
				BEGIN

					UPDATE RIA_NETWORKCREDENTIALS
					SET
					[domain] = @net_sever,
					[user] = @net_user,
					[password] = @net_password
					WHERE
					id = @netcred_id

				END
			ELSE
				BEGIN

					UPDATE TREC_NETWORKCREDENTIALS
					SET
					[domain] = @net_sever,
					[user] = @net_user,
					[password] = @net_password
					WHERE
					id = @netcred_id

				END

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_format
			WHERE
			par_id = 35

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

			UPDATE TREC_PARAMETROS
			SET par_valor = @file_encrypted
			WHERE
			par_id = 61

			UPDATE TREC_PARAMETROS
			SET par_valor = @export_encrypted
			WHERE
			par_id = 62

		END
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

	set @process = 'Alter PROCEDURE -- trsp_GetRecordigsExportService'
	set @sql='ALTER PROCEDURE [dbo].[trsp_GetRecordigsExportService]
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
