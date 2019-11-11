CREATE PROCEDURE [dbo].[trsp_ConsultaRepositorio]
		@id_repositorio tinyint =1 ,
		@action tinyint  =1
		AS
		BEGIN
		if @action = 1
			begin
				SELECT     Cast(id_repositorio as Int ) as id_repositorio, ruta_repositorio, ruta_local
				FROM       TREC_REPOSITORIOS
				WHERE      id_repositorio=@id_repositorio
			end
		if @action = 2
			begin
				SELECT     Cast(id_repositorio as Int ) as id_repositorio, ruta_repositorio, ruta_local,ruta_local_imagenes
				FROM       TREC_REPOSITORIOS
			end
		if @action = 3
			begin
				SELECT    id,domain,[user],[password]
				FROM       RIA_NETWORKCREDENTIALS
			end
		if @action = 4
			begin
				SELECT    id_repository,id_nwCredential
				FROM       TREC_REPO_NWCREDENTIALS
			end
		END