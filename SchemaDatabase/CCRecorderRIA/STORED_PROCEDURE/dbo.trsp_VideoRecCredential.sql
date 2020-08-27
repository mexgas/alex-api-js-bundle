CREATE PROC [dbo].[trsp_VideoRecCredential]
		@action tinyint =1
		AS

		if @action=1 begin
			SELECT
				id_repositorio,
				InIniPort, InFinPort,
				OutIniPort, OutFinPort,
				ruta_rep_video,
				ria.domain,
				ria.[user],
				ria.password
			FROM TREC_REPOSITORIOS trec
			JOIN TREC_REPO_NWCREDENTIALS cred
			ON cred.id_repository = trec.id_repositorio
			INNER JOIN RIA_NETWORKCREDENTIALS ria 
			on ria.id = cred.id_nwCredential
		end