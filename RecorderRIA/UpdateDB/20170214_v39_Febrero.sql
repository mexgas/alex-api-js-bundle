/*
Autor: Jesus Gallardo
Fecha: 2016/12/20
Descripcion:

	SP ccsp_CleanNodeBaseX se modifica para guardar el historial y regresar el primer y ultimo fecha
Version requerida: 35
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 39
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

---------------- inicio SCRIPT @Sql ----------------

	--Index

	--Tables

	--Functions

  	--SP

  	set @process = 'ALTER SP -- ccsp_BaseXmngr'
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
declare @status tinyint

set @sql = ''''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2

		set @sql = ''select top '' + @top + '' grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ria_RecNode with(rowlock) where status = '' + cast(@status as nvarchar(max))
		exec(@sql)
	end
end
if @action in(2,7) begin--actualiza los nodos insertados en BX
	if @option = 2 begin
		if @action = 2 set @status=0
		else if @action = 7 set @status = 2

		update ria_RecNode with(rowlock) set [status] = @status + 1 , dateOut = getDate() where grab_id between @idF and @idL and [status] = @status
	end
end
else if @action = 3 begin--trae el nombre de la base de datos en BX
	select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, getDate(), @name,0)
end'
  	EXEC(@sql)

  	set @process = 'ALTER SP -- trsp_AdmGetAllRepositories'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
@Mode int
AS
BEGIN
	SET NOCOUNT ON;
	IF @Mode = 1 Begin
		select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio, ruta_rep_video
		from TREC_REPOSITORIOS Rep
		inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
		inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
		where Cred.type = 1 and status=1
	End
	Else IF @Mode =2 Begin
		--select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_rep_video  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio
		select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_rep_video
		from TREC_REPOSITORIOS Rep
		inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
		inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
		where Cred.type = 1 and status=1
	End
	Else IF @Mode = 3 Begin
		--select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio, ruta_rep_video  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio
		select top 1 id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio, ruta_rep_video
		from TREC_REPOSITORIOS Rep
		inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
		inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
		where Cred.type = 1 and status=1
	End
END'
  	EXEC(@sql)

  	set @process = 'ALTER SP -- trsp_GetNetworkCredentials'
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
	SET @SQL = ''SELECT top 1 TREC_REPO_NWCREDENTIALS.[id_repository],RIA_NETWORKCREDENTIALS.[user], RIA_NETWORKCREDENTIALS.[domain],RIA_NETWORKCREDENTIALS.[password], RIA_NETWORKCREDENTIALS.[id] AS id_credential
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

END'
  	EXEC(@sql)

  	set @process = ''
  	set @sql=''
  	EXEC(@sql)



------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

