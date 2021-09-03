/*
Autor: Carlos Chavez
Descripcion:


Version requerida: 42
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 43
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	
	set @process = 'Modify stored procedure RIA_GRABACION.trsp_AdmGetFormatsScored CW-1001'
 	set @sql ='ALTER PROCEDURE [dbo].[trsp_AdmGetFormatsScored]
@cal_id int,
@tipo_llamada int
AS
BEGIN
	SET NOCOUNT ON;

declare @grab_id int

set @grab_id = (select min(grab_id) from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada 
UNION select min(grab_id) from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
 
select distinct id_formato from CCRecorderRIa.dbo.RIA_FORMACALIF where id_grabacion = @grab_id

END
	'
	
	EXEC(@sql)

	set @process = 'Create UNIQUE constraint RIA_GRABACION.uniqueCal_id_tipo_llamada CW-1001'
 	set @sql ='if not exists (select * from sysobjects where xtype in (N''UQ'') and name = N''uniqueCal_id_tipo_llamada'')
begin
begin try
	begin transaction addRIA_GRABACION_Constraint

		--Eliminar duplicadas inbound
		SELECT * INTO GRAB_DUPLICATE_ROWS_IN_BCKUP
			FROM RIA_GRABACION
			WHERE tipo_llamada = 1 and
			CAL_ID IN (SELECT cal_id FROM RIA_GRABACION WITH(nolock,INDEX(IX_RIA_GRABACION_7)) where tipo_llamada = 1 GROUP BY cal_id HAVING COUNT(cal_id) > 1)

		DELETE RIA_GRABACION
			WHERE tipo_llamada = 1 and
			grab_id IN (SELECT grab_id FROM GRAB_DUPLICATE_ROWS_IN_BCKUP) AND grab_id NOT IN (SELECT MIN(grab_id) FROM GRAB_DUPLICATE_ROWS_IN_BCKUP GROUP BY CAL_ID )

		--Eliminar duplicadas outbound
		SELECT * INTO GRAB_DUPLICATE_ROWS_OUT_BCKUP
			FROM RIA_GRABACION
			WHERE tipo_llamada = 2 and
			CAL_ID IN (SELECT cal_id FROM RIA_GRABACION WITH(nolock,INDEX(IX_RIA_GRABACION_7)) where tipo_llamada = 2 GROUP BY cal_id HAVING COUNT(cal_id) > 1)

		DELETE RIA_GRABACION
			WHERE tipo_llamada = 2 and
			grab_id IN (SELECT grab_id FROM GRAB_DUPLICATE_ROWS_OUT_BCKUP) AND grab_id NOT IN (SELECT MIN(grab_id) FROM GRAB_DUPLICATE_ROWS_OUT_BCKUP GROUP BY CAL_ID )

	commit transaction addRIA_GRABACION_Constraint

		ALTER TABLE RIA_GRABACION ADD CONSTRAINT uniqueCal_id_tipo_llamada UNIQUE (cal_id, tipo_llamada)

	end try
begin catch
	print ''ADD RIA_GRABACION CONSTRAINT -> '' + error_message()
end catch
end										
	'
	
	EXEC(@sql)


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
