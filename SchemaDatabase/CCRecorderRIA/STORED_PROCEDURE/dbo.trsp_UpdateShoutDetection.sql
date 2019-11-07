CREATE PROCEDURE [dbo].[trsp_UpdateShoutDetection]
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