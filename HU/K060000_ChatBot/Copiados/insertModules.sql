--exec ccsp_GalateaChatBotAdmin 1

--exec ccsp_GalateaChatBotAdmin 2,34

--exec ccsp_GalateaChatBotAdmin 3,34,1


if not exists(select * from ccGalateaModules where ModuleId=9)
begin
	insert into ccGalateaModules values(9,'Asociación de chatbot','Chatbot association','Associação de chatbot')
end

--delete from ccGalateaModules where ModuleId=10

if not exists(select * from ccGalateaOperations where OperationId=78)
begin
	insert into ccGalateaOperations values(78,'Asociar chatbot','Associate chatbot','Associar chatbot')
end
if not exists(select * from ccGalateaOperations where OperationId=79)
begin
	insert into ccGalateaOperations values(79,'Desasociar chatbot','Disassociate chatbot','Desassociar chatbot')
end

select * from ccGalateaModules
select * from ccGalateaOperations