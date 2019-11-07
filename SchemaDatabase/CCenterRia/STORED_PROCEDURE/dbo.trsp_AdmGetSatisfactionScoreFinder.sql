CREATE  PROCEDURE [dbo].[trsp_AdmGetSatisfactionScoreFinder]
			@id_chat as Int
			AS
			BEGIN
				SET NOCOUNT ON;
				select top 1 fmt.id_formato format_id,nombre format_name, Nombres+' '+ApellidoPaterno+' '+ApellidoMaterno quality_sup,total_forma score
				from RIA_FORMACALIF fmt join ccusers us on us.user_id=fmt.id_calificador
				join RIA_FORMATOS cfmt on cfmt.id_formato=fmt.id_formato
				where fmt.tipo=2 AND id_grabacion = @id_chat
			END