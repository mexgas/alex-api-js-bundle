set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 103
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	-----------------------------------BEGIN MACL---------------------------------------
SET @process = 'CW-9434 - Se agrega index para mejorar rendimiento de los querys que usan las tablas'
	SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACION_cam_id_tipo_llamada_finicio'' 
and object_id = OBJECT_ID(N''RIA_GRABACION''))
begin
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACION_cam_id_tipo_llamada_finicio
	ON dbo.RIA_GRABACION (cam_id, tipo_llamada, finicio)
	INCLUDE (dni, cal_extension, duracion);
end

if not exists (select * from sys.indexes where name = N''IX_RIA_GRABACIONCONSULTA_cam_id_tipo_llamada_finicio'' 
and object_id = OBJECT_ID(N''RIA_GRABACIONCONSULTA''))
begin
	CREATE NONCLUSTERED INDEX IX_RIA_GRABACIONCONSULTA_cam_id_tipo_llamada_finicio
	ON dbo.RIA_GRABACIONCONSULTA (cam_id, tipo_llamada, finicio)
	INCLUDE (dni, cal_extension, duracion);
end'
	EXEC(@sql)
------------------------------------END MACL----------------------------------------

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
