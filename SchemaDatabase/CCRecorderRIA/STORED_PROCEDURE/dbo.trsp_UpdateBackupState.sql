CREATE PROCEDURE [dbo].[trsp_UpdateBackupState]
@Id 		VARCHAR(20),
@Lado 		CHAR(1),
@Done		BIT
AS
BEGIN
	UPDATE TREC_ARCHIVO_GRABACION SET hecho=@Done WHERE [id]=@Id AND lado=@Lado
END