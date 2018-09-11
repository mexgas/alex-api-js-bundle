/*
Autor: Daniel vega
Descripcion:


Version requerida: 50
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 52
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW-2216  Alter SP trsp_UpdateShoutDetection'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_UpdateShoutDetection]
@isXION int,
@shoutLevel int,
@grabId int,
@hasVideo int,
@duration int = 0
AS
BEGIN
	IF @isXION = 1 	BEGIN
		IF  EXISTS (SELECT 1 FROM RIA_GRABACION WHERE grab_id = @grabId) BEGIN
			UPDATE RIA_GRABACION SET id_nivel_grito = @shoutLevel,video= @hasVideo, 
			duracion=case when @duration>0 then @duration else duracion end WHERE grab_id = @grabId
		END
		ELSE BEGIN
			UPDATE RIA_GRABACIONCONSULTA SET id_nivel_grito = @shoutLevel,video= @hasVideo,
			duracion=case when @duration>0 then @duration else duracion end WHERE grab_id = @grabId
		END
		--Only in XION to build the finder
		exec trsp_InsertRecNode  @grabId,0

	END
	ELSE BEGIN
		IF EXISTS (SELECT 1 FROM RIA_GRABACION WHERE grab_id = @grabId) BEGIN
			UPDATE TREC_GRABACION SET id_nivel_grito = @shoutLevel WHERE grab_id = @grabId 
		END 
		ELSE BEGIN
			UPDATE TREC_GRABACIONCONSULTA SET id_nivel_grito = @shoutLevel WHERE grab_id = @grabId
		END
	END

END
			'
    EXEC(@Sql)
		
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
