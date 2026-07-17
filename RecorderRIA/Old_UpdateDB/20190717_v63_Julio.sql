/*
Autor: Ulises Espinosa
Descripcion: CW-3141


Version requerida: 59
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 63
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try



	SET @process = 'CW-3141 New setting 76 '
	SET @Sql = 'declare @valor varchar(600)

set @valor=''0''
if exists(select * from TREC_PARAMETROS where par_id=75 and par_descripcion=''Generacion de xml'') begin
	select @valor=par_valor from TREC_PARAMETROS where par_id=75 and par_descripcion=''Generacion de xml''
	update  TREC_PARAMETROS set par_descripcion=''Clave cifrado'',par_valor='''',par_detail=''Clave usada para la encripcion de grabaciones'' where par_id=75
end
if not exists(select * from TREC_PARAMETROS where par_id=76) begin
	insert into TREC_PARAMETROS (par_id, par_descripcion,par_valor,par_detail) values (76,''Generacion de xml'',@valor,''1=genera un XML por grabacion, 0=Genera solo un XML'')
end'
	EXEC (@Sql)

	SET @process = 'CW-3141 Formato archivo ddMMYY '
	SET @Sql = 'if not exists (select * from TREC_FORM_ARCHIVOSEXPORT where Formato = ''ddMMYY'')
	begin
		insert into TREC_FORM_ARCHIVOSEXPORT Values (24,''ddMMYY'',''convert(varchar(2),finicio,113)+convert(varchar(2),finicio,1)+convert(varchar(2),finicio,2)as fecha'',0,''fecha - 090719'')
	end'
	EXEC (@Sql)

	SET @process = 'CW-3141 Formato archivo personalizado '
	SET @Sql = 'if not exists (select * from TREC_FORM_ARCHIVOSEXPORT where Formato = ''PERSONALIZADO'')
	begin
		insert into TREC_FORM_ARCHIVOSEXPORT (ID,Formato, Campo, Orden, Comentarios) values (25,''PERSONALIZADO'',''texto_personalizad0'',0,''Texto que se puede modificar'')
	end'
	EXEC (@Sql)

	SET @process = 'CW-3141 Formato carpeta ddMMYY '
	SET @Sql = 'if not exists (select * from TREC_FORM_CARPETASEXPORT where Formato = ''ddMMYY'')
	begin
		insert into TREC_FORM_CARPETASEXPORT Values (24,''ddMMYY'',''convert(varchar(2),finicio,113)+convert(varchar(2),finicio,1)+convert(varchar(2),finicio,2)as fecha'',0,''fecha - 090719'')
	end'
	EXEC (@Sql)

		
	------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

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
