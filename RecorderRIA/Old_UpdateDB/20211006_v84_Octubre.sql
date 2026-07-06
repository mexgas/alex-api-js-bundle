set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 84
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
	begin tran
	begin try

    set @process = 'CW-5758 delete store ccspGalatea_AdmGetExportProfile'
		set @Sql = 'if exists (select * from sys.procedures where name = N''ccspGalatea_AdmGetExportProfile'')
    begin
        DROP PROCEDURE ccspGalatea_AdmGetExportProfile;
    end'
 
		EXEC(@Sql)

 set @process = 'CW-5758 create store ccspGalatea_AdmGetExportProfile'
		set @Sql = '
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
		SET @results = '''';
		SELECT @campos = ISNULL(MAX(campos), '''') FROM RIA_PERFILES_EXPORTACION WHERE id_usuario = @userId;
		if @campos is not null begin
		SET @sql = '' select Campo from TREC_FORM_ARCHIVOSEXPORT where id in ('' + @campos + '');'';
		INSERT INTO @tempCampos
		EXEC (@sql);
		SELECT @results = case when CHARINDEX(''as '',campo) >0 then SUBSTRING(campo,0,CHARINDEX(
		'' as '',campo)) else campo end
		+ '','' ++''''''_''''''+'',''+ @results FROM @tempCampos;
		SET @results = SUBSTRING(@results, 0, LEN(@results)-4);
		SET @sql = '' select concat(''+ @results + '') as name from RIA_GRABACION where grab_id in ('' + @grabIds + '') union 
					 select concat(''+ @results + '') as name from RIA_GRABACIONCONSULTA where grab_id in ('' + @grabIds + '');'';
		EXEC (@sql);
	end 
end

END

'
		EXEC(@Sql)

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
