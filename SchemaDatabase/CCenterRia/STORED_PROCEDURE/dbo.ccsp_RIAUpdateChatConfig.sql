CREATE PROCEDURE [dbo].[ccsp_RIAUpdateChatConfig]
@action smallint = 0,
@idArea smallint = 0,
@maxChats smallint = 0
AS

if @action = 1 begin
	select @maxChats = maxChats from ccRIACat_Areas where IDArea = @idArea
	return @maxChats
end

if @action = 2 begin
	select @maxChats = maxChats from ccRIACat_Areas where IDArea = @idArea
	update ccInbound set maxChats = @maxChats where IDArea = @idArea
end