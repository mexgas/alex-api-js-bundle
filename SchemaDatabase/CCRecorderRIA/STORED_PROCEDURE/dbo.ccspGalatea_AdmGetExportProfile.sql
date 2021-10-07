CREATE PROCEDURE [dbo].[ccspGalatea_AdmGetExportProfile]
@action int,
@grabIds varchar(max)=null,
@userId int =0
AS
BEGIN
    SET NOCOUNT ON;
	declare @sql varchar(max)
	declare @campos varchar(max)
	DECLARE @results VARCHAR(500)
	DECLARE @tempCampos TABLE(campo NVARCHAR(100))
	if @action=1 begin
		if exists(SELECT * FROM RIA_PERFILES_EXPORTACION WHERE id_usuario =@userId
                                                    AND active = 1)
													select 1
	else 
		select 0
	end
	if @action=2 begin
		SET @results = '';
		SELECT @campos = ISNULL(MAX(campos), '') FROM RIA_PERFILES_EXPORTACION WHERE id_usuario = @userId;
		if @campos is not null begin
		SET @sql = ' select Campo from TREC_FORM_ARCHIVOSEXPORT where id in (' + @campos + ');';
		INSERT INTO @tempCampos
		EXEC (@sql);
		SELECT @results = case when CHARINDEX('as ',campo) >0 then SUBSTRING(campo,0,CHARINDEX(
		' as ',campo)) else campo end
		+ ',' ++'''_'''+','+ @results FROM @tempCampos;
		SET @results = SUBSTRING(@results, 0, LEN(@results)-4);
		SET @sql = ' select concat('+ @results + ') as name from RIA_GRABACION where grab_id in (' + @grabIds + ') union 
					 select concat('+ @results + ') as name from RIA_GRABACIONCONSULTA where grab_id in (' + @grabIds + ');';
		EXEC (@sql);
	end 
end

END