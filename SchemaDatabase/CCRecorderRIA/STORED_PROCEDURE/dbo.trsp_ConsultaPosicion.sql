CREATE PROCEDURE [dbo].[trsp_ConsultaPosicion]
@pos_pc varchar(25)='',
@mon_ext_id int=''
AS
BEGIN
IF @pos_pc <> ''
	BEGIN
		SELECT     TREC_MONITOR.mon_ext_id, TREC_MONITOR.pos_pc, TREC_MONITOR.mon_extension, TREC_MONITOR.IPTelefono, TREC_MONITOR.mon_activo, 
				   TREC_MONITOR.mon_graba, TREC_CLIENTE.cli_nombre
		FROM       TREC_MONITOR INNER JOIN
				   TREC_CLIENTE ON TREC_MONITOR.cli_id = TREC_CLIENTE.cli_id
		WHERE	   TREC_MONITOR.pos_pc LIKE @pos_pc
	END
ELSE IF @mon_ext_id <>''
	BEGIN
		SELECT     TREC_MONITOR.mon_ext_id, TREC_MONITOR.pos_pc, TREC_MONITOR.mon_extension, TREC_MONITOR.IPTelefono, TREC_MONITOR.mon_activo, 
				   TREC_MONITOR.mon_graba, TREC_CLIENTE.cli_nombre
		FROM       TREC_MONITOR INNER JOIN
				   TREC_CLIENTE ON TREC_MONITOR.cli_id = TREC_CLIENTE.cli_id
		WHERE	   TREC_MONITOR.mon_ext_id = @mon_ext_id
	END
END