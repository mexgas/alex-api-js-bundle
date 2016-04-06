/*

Fecha: 2013/05/31
Descripcion: 	

Version requerida: 2
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 3
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	--begin tran
	begin try
	declare @Sql varchar(max)

	---------------- inicio SCRIPT @Sql ----------------



--- Cambiamos la vista de RIA_GRABACION
set @Sql = '
ALTER VIEW [dbo].[trvw_tl_RIA_GRABACION]
AS
SELECT     grab_id, age_id, finicio, duracion, id_repositorio, tipo_llamada, cam_id, calif_id, cal_id, ffin, ani, dni, id_nivel_grito, cal_key, cal_manual, cal_extension
FROM         dbo.RIA_GRABACION
UNION
SELECT     grab_id, age_id, finicio, duracion, id_repositorio, tipo_llamada, cam_id, calif_id, cal_id, ffin, ani, dni, id_nivel_grito, cal_key, cal_manual, cal_extension
FROM         dbo.RIA_GRABACIONCONSULTA
'
IF EXISTS(select * FROM sys.views where name = 'trvw_tl_RIA_GRABACION')
EXEC(@Sql)



-- Se modifica Trec_backups

set @Sql = '
IF EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''TREC_BACKUPS'' AND  COLUMN_NAME = ''status'')
BEGIN
ALTER TABLE TREC_BACKUPS
DROP COLUMN status
END
IF EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''TREC_BACKUPS'' AND  COLUMN_NAME = ''id_ruta_backup'')
BEGIN
ALTER TABLE TREC_BACKUPS
DROP COLUMN id_ruta_backup
END
IF NOT EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''TREC_BACKUPS'' AND  COLUMN_NAME = ''status_audio'')
BEGIN
ALTER TABLE TREC_BACKUPS
ADD  status_audio smallint
END
IF NOT EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''TREC_BACKUPS'' AND  COLUMN_NAME = ''status_video'')
BEGIN
ALTER TABLE TREC_BACKUPS
ADD  status_video smallint
END
IF NOT EXISTS( SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''TREC_BACKUPS'' AND  COLUMN_NAME = ''id_ruta_backup'')
BEGIN
ALTER TABLE TREC_BACKUPS
ADD  id_ruta_backup int NOT NULL
END
  '
  IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='trec_backups')
  EXEC(@Sql)



	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
update trec_parametros set par_valor = '3' where par_id = 30 

	--commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
	--rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
