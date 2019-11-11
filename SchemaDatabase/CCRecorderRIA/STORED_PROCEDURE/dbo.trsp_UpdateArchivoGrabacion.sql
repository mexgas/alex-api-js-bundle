CREATE PROCEDURE [dbo].[trsp_UpdateArchivoGrabacion]
@activeid int
AS
BEGIN
    DECLARE @maxid INT
	SELECT @maxid=max(grab_id_max)  from TREC_Archivo_GRABACION where hecho = 'true';
    IF @activeid > @maxid
    BEGIN
        SELECT @activeid = @maxid;
    END
    UPDATE TREC_Archivo_GRABACION set grab_id_active = @activeid where grab_id_max = @maxid;
END