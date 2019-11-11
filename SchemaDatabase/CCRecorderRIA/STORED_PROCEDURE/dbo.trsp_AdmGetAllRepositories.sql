CREATE PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
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
END