CREATE PROCEDURE [dbo].[trsp_AdmAVRSReportLanguage]
@idioma as int
AS
BEGIN					
SET NOCOUNT ON;
if @idioma=1
begin
select 'Reporte de Evaluacion de Llamadas' as [001], 
'Información de la Llamada' as [002], 
'agente' as [003],
'Supervisor' as [004],
'Teléfono' as [005],
'Tipo de Llamada' as [006],
'Fecha' as [007],
'ID de LLamada' as [008],
'ID de Grabación' as [009],
'CallKey' as [010],
'Duración' as [011],
'Campaña/ACD' as [012],
'Formato de evaluación' as [013],
'Fecha de evaluación' as [014],
'Firma de Agente' as [015],
'Firma de Supervisor' as [016],
'Firma de Calidad' as [017],
'Detalles de Evaluación' as [018],
'Concepto/Pregunta' as [019],
'Respuesta' as [020],
'Puntos' as [021],
'Valor Total' as [022],
'Reporte de Evaluacion de Chat' as [023],
'Información de Chat' as [024],
'Dominio' as [025],
'ID de Chat' as [026]
end
else if @idioma=3
begin
select 'Relatório de avaliação da chamada' as [001], 
'Informação da chamada' as [002], 
'Agente' as [003],
'Supervisor' as [004],
'Telefone' as [005],
'Tipo de chamada' as [006],
'Data' as [007],
'ID da chamada' as [008],
'ID da gravação' as [009],
'CallKey' as [010],
'Duração' as [011],
'Campanha/Grupo ACD' as [012],
'Formulário de avaliação' as [013],
'Data da avaliação' as [014],
'Assinatura do agente' as [015],
'Assinatura do supervisor' as [016],
'Assinatura do Departamento de Qualidade' as [017],
'Detalhes da avaliação' as [018],
'Conceito/Pregunta' as [019],
'Resposta' as [020],
'Pontos' as [021],
'Valor Total' as [022],
'Relatório de avaliação da conversa de chat' as [023],
'Informação da conversa de chat' as [024],
'Domínio' as [025],
'ID da conversa de chat' as [026]
end
else if @idioma=2
begin
select 'Call Evaluation Report' as [001], 
'Call Information' as [002], 
'Agent' as [003],
'Supervisor' as [004],
'Phone' as [005],
'Call Type' as [006],
'Date' as [007],
'Call ID' as [008],
'Recording ID' as [009],
'CallKey' as [010],
'Length' as [011],
'Campaign/ACD group' as [012],
'Scoring template' as [013],
'Evaluation date' as [014],
'Agent signature' as [015],
'Supervisor signature' as [016],
'Quality Department signature' as [017],
'Evaluation details' as [018],
'Concept/Question' as [019],
'Answer' as [020],
'Points' as [021],
'Total score' as [022],
'Chat Evaluation Reportt' as [023],
'Chat Information' as [024],
'Dominio' as [025],
'Chat ID' as [026]
end
END