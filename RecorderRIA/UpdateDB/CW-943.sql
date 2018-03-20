/*
Autor: Miguel Trejo
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
	Set @Version = 47
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW-943 Etiquetas en Portugués'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportLanguage]
@idioma as int
AS
BEGIN					
SET NOCOUNT ON;
if @idioma=1
begin
select ''Reporte de Evaluacion de Llamadas'' as [001], 
''Información de la Llamada'' as [002], 
''agente'' as [003],
''Supervisor'' as [004],
''Teléfono'' as [005],
''Tipo de Llamada'' as [006],
''Fecha'' as [007],
''ID de LLamada'' as [008],
''ID de Grabación'' as [009],
''CallKey'' as [010],
''Duración'' as [011],
''Campaña/ACD'' as [012],
''Formato de evaluación'' as [013],
''Fecha de evaluación'' as [014],
''Firma de Agente'' as [015],
''Firma de Supervisor'' as [016],
''Firma de Calidad'' as [017],
''Detalles de Evaluación'' as [018],
''Concepto/Pregunta'' as [019],
''Respuesta'' as [020],
''Puntos'' as [021],
''Valor Total'' as [022],
''Reporte de Evaluacion de Chat'' as [023],
''Información de Chat'' as [024],
''Dominio'' as [025],
''ID de Chat'' as [026]
end
else if @idioma=3
begin
select ''Relatório de avaliação da chamada'' as [001], 
''Informação da chamada'' as [002], 
''Agente'' as [003],
''Supervisor'' as [004],
''Telefone'' as [005],
''Tipo de chamada'' as [006],
''Data'' as [007],
''ID da chamada'' as [008],
''ID da gravação'' as [009],
''CallKey'' as [010],
''Duração'' as [011],
''Campanha/Grupo ACD'' as [012],
''Formulário de avaliação'' as [013],
''Data da avaliação'' as [014],
''Assinatura do agente'' as [015],
''Assinatura do supervisor'' as [016],
''Assinatura do Departamento de Qualidade'' as [017],
''Detalhes da avaliação'' as [018],
''Conceito/Pregunta'' as [019],
''Resposta'' as [020],
''Pontos'' as [021],
''Valor Total'' as [022],
''Relatório de avaliação da conversa de chat'' as [023],
''Informação da conversa de chat'' as [024],
''Domínio'' as [025],
''ID da conversa de chat'' as [026]
end
else if @idioma=2
begin
select ''Call Evaluation Report'' as [001], 
''Call Information'' as [002], 
''Agent'' as [003],
''Supervisor'' as [004],
''Phone'' as [005],
''Call Type'' as [006],
''Date'' as [007],
''Call ID'' as [008],
''Recording ID'' as [009],
''CallKey'' as [010],
''Length'' as [011],
''Campaign/ACD group'' as [012],
''Scoring template'' as [013],
''Evaluation date'' as [014],
''Agent signature'' as [015],
''Supervisor signature'' as [016],
''Quality Department signature'' as [017],
''Evaluation details'' as [018],
''Concept/Question'' as [019],
''Answer'' as [020],
''Points'' as [021],
''Total score'' as [022],
''Chat Evaluation Reportt'' as [023],
''Chat Information'' as [024],
''Dominio'' as [025],
''Chat ID'' as [026]
end
END'
	EXEC(@sql)
 
	
	set @process = 'CW-943 Etiquetas en Portugués ccsp_getVersion'
 	set @sql ='-- =============================================
/*Catalogo de errores:
-1 / ERROR. ??? -- Este error no es controlado, es una excepcion del store, server, segun mande la alerta es lo que se mostrara
-2 / ERROR. Modulo no valido -- Cuando en el parametro de modulo no se ingresa BD|DB, AVRS, ALL
-3 / ERROR. Version no Valida para ''BD/AVRS''. Version Actual: ''#Version'' -- Cuando se quiere generar una versión que no es mayor a la actual
-4 / ERROR. generado al actualizar a version ''#Version'' -- Cuando se presento un problema al hacer el update de la version, por lo cual no se actualizo
*/
ALter procedure [dbo].[ccsp_getVersion]
@Module varchar(4) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma int
select @Idioma = cast(par_valor as int) from trec_parametros where par_id = 26
if @Module=''DB''
	set @Module=''BD''
if upper(isnull(@Module, '''')) not in (''BD'', ''AVRS'', ''ALL'')
 begin
	select ''-2'' ID, case @Idioma when 1 then ''ERROR. Modulo no valido''
	 when 2 then ''ERRO. Módulo inválido''
	else ''ERROR. Invalid Module'' end [Description]
	return(0)
 end
if @Module = ''ALL''
 begin
	select par_valor Ver_BD_AVRS from trec_parametros where par_id = 30
	return(0)
 end
declare @nVersion varchar(30)
select @nVersion = cast(par_valor as varchar(15)) from trec_parametros where par_id = 30
BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9)
	set @version_1 = substring(@nVersion, 1, charindex(''.'', @nVersion)-1)
	set @nVersion = substring(@nVersion, charindex(''.'', @nVersion) + 1, len(@nVersion))
	set @version_2 = @nVersion
END TRY
BEGIN CATCH
	select ''-1'' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH
if isnull(@Version, 0) = 0
 begin
	select @version = cast(case upper(@Module) when ''BD'' then @version_2
	else @version_1 end as int)
	select @version Version
	return(@version)
 end
if upper(@Module) = ''BD'' and (@Version <= cast(@version_2 as int) or (@Version - cast(@version_2 as int))>1)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Version no Valida para BD. Version Actual: '' + @version_2
	when 2 then ''ERRO. Versão inválida para BD, versão atual: '' + @version_2
	else ''ERROR. Invalid Version for DB. Current Version: '' + @version_2
	end [Description]
	return(0)
 end
if @Version <= cast(case upper(@Module) when ''BD'' then @version_2
else @version_1 end as int)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Version no Valida para '' + @Module + ''. Version Actual: '' +
	 case upper(@Module) when ''BD'' then @version_2 else @version_1 end
	 when 2
	then ''ERRO. Versão inválida para '' + @Module + ''. Versão atual: '' +
	 case upper(@Module) when ''BD'' then @version_2 else @version_1 end
	else ''ERROR. Invalid Version for '' + @Module + ''. Current Version: '' +
	 case upper(@Module) when ''BD'' then @version_2 else @version_1 end
	end [Description]
	return(0)
 end
if upper(@Module) = ''BD'' set @version_2 = @Version
else set @version_1 = @Version
set @nVersion = @version_1 + ''.'' + @version_2
update trec_parametros set par_valor = @nVersion where par_id = 30
if @@rowcount = 1
	select ''0'' ID, ''Actualizado a version: '' + @nVersion [Description]
else
	select ''-4'' ID, case @Idioma when 1
	then ''ERROR generado al actualizar a version '' + @nVersion
	when 2 then ''ERRO encontrado ao atualizar a versão '' + @nVersion
	else ''ERROR introduced when upgrading to version '' + @nVersion
	end [Description]
return (0)
set nocount off'
	
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
