CREATE PROCEDURE [dbo].[trsp_SaveBackup]
@Id 		VARCHAR(20),
@Lado 		CHAR(1),
@MaxGrab	INT,
@Done		BIT
AS
BEGIN
	INSERT INTO TREC_ARCHIVO_GRABACION(id,lado,grab_id_max,hecho) VALUES (@Id, @Lado, @MaxGrab, @Done)
END