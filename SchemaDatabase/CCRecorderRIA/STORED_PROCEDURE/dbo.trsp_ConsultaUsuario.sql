CREATE PROCEDURE [dbo].[trsp_ConsultaUsuario]
@age_usuario nvarchar(50)='',
@age_id nvarchar(10)=''
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @culture INT
	DECLARE @sql VARCHAR(MAX)
	

	SELECT @culture = par_valor from trec_parametros where par_id = 26
	IF @culture = 1
	BEGIN
		SET @sql = 'SELECT    TREC_AGENTE.age_id, TREC_AGENTE.age_usuario,substring(TREC_PERFIL.perfil_descripcion,0,charindex(''|'',TREC_PERFIL.perfil_descripcion)) as perfil_descripcion, TREC_CLIENTE.cli_nombre
					FROM      TREC_AGENTE INNER JOIN
                    TREC_CLIENTE ON TREC_AGENTE.cli_id = TREC_CLIENTE.cli_id INNER JOIN
                    TREC_PERFIL ON TREC_AGENTE.perfil_id = TREC_PERFIL.perfil_id '

		IF @age_usuario != ''
			BEGIN 
				SET @sql = @sql + ' WHERE    TREC_AGENTE.age_usuario like ''+@age_usuario+'''
			END
		ELSE
			BEGIN
				SET @sql = @sql + ' WHERE    TREC_AGENTE.age_id = '+@age_id
			END			
	END
	IF @culture = 2
	BEGIN
		SET @sql = 'SELECT    TREC_AGENTE.age_id, TREC_AGENTE.age_usuario,substring(TREC_PERFIL.perfil_descripcion,charindex(''|'',TREC_PERFIL.perfil_descripcion)+1,len(TREC_PERFIL.perfil_descripcion)) as perfil_descripcion, TREC_CLIENTE.cli_nombre
					FROM      TREC_AGENTE INNER JOIN
                    TREC_CLIENTE ON TREC_AGENTE.cli_id = TREC_CLIENTE.cli_id INNER JOIN
                    TREC_PERFIL ON TREC_AGENTE.perfil_id = TREC_PERFIL.perfil_id '

		IF @age_usuario != ''
			BEGIN 
				SET @sql = @sql + ' WHERE    TREC_AGENTE.age_usuario like ''+@age_usuario+'''
			END
		ELSE
			BEGIN
				SET @sql = @sql + ' WHERE    TREC_AGENTE.age_id = '+@age_id
			END
	END

	exec (@sql)
END