CREATE PROCEDURE [dbo].[ccsp_RIAChatMailbox]
@action int,
@session varchar(80),
@pathFile varchar(500)
AS
if @action = 1 begin

	declare @chatId as int
	--El where de la fecha es para acotar resultados
	select @chatId = isnull(chatId,0) from ccriachats with(nolock) where session = @session and requestDate >= dateadd(hh, -1, getdate())  

	if @chatId <> 0 begin
		insert into ccRIAChatMailbox(chatId,[file]) values (@chatId, @pathFile)								
	end				

end