CREATE PROCEDURE [dbo].[ccsp_ChatLoadCatalogues]
@action smallint,
@inboundId smallint = 0,
@userId smallint = 0
AS 
declare @language as tinyint

-- Carga grupos acd, cuando se añada el dominio hay que cambiar la segunda descripcion por dominio
if @action = 1
begin
select inbound_id, chatDomain, inactiveChatTime from ccinbound where chat > 0 and (chatDomain <> null or chatDomain <> '')
end

if @action = 2
begin
select chatQueueOverflow, chatTimeOverflow from ccinbound where inbound_id = @inboundId
end

if @action = 3  --Se verifica el lenguaje debido a que en ingles el apellido paterno se guarda en el materno
begin	
select @language = valor  from ccsettings where setting_id = 27	
select user_id,Login,Nombres,case when @language = 1 then  apellidoMaterno  else apellidoPaterno end as lastname
from ccusers where status = 1 and TipoUser_id = 1
end

if @action = 4  --Se verifica el lenguaje debido a que en ingles el apellido paterno se guarda en el materno
begin	
select @language = valor  from ccsettings where setting_id = 27		
select Login,Nombres,case when @language = 1 then  apellidoMaterno  else apellidoPaterno end as lastname
from ccusers where status = 1 and TipoUser_id = 1 and user_id = @userId
end