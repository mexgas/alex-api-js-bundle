/*
Autor: Jesus Gallardo
Descripcion:


Version requerida: 44
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 46
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW-1382 version 45 Drop SP -- tmp_detGritosOut'
	set @Sql= 'if exists (select * from sys.procedures where name = ''tmp_detGritosOut'') DROP PROCEDURE [dbo].[tmp_detGritosOut]'
	EXEC(@sql)
 
	
	set @process = 'CW-1382 version 45 Drop Job [tmp_detGritosOut]'
 	set @sql ='
	USE [msdb]
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''tmp_detGritosOut'')
EXEC msdb.dbo.sp_delete_job @job_name=N''tmp_detGritosOut'', @delete_unused_schedule=1'
	
	EXEC(@sql)
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	
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
