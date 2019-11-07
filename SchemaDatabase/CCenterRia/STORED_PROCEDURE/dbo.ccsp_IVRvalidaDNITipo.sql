CREATE PROCEDURE ccsp_IVRvalidaDNITipo
@DNIS as varchar(10)
AS
declare @dni_tipo tinyint
declare @dni_id int
	SELECT @dni_id=dni_id, @dni_tipo=dni_tipo
	FROM ccDNIS
	where dni_numero = @DNIS
	IF  @dni_tipo=2 
	BEGIN
		select 'dni_id'=@dni_id, 'dni_tipo'=@dni_tipo, 'Is2'=1
	END 
	ELSE
	BEGIN
		select 'dni_id'=@dni_id, 'dni_tipo'=@dni_tipo, 'Is2'=0
	END