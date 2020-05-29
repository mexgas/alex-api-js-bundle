/*
Autor: Raymundo Gonzalez
Fecha: 2013/10/21
Descripcion:
	Se crea la tabla TranslatedReports para traduccion de reportes
	Se insertan los valores en la tabla TranslatedReports para traduccion de reportes
	Se actualiza el campo totalColumns de la tabla ReportsTotals para reporte de efectividad
	Se renombran las columnas nanswer, tatention y tabndtot en la tabla RepInEffectiveness para traduccion
	Se actualiza estructura y datos de la tabla RepAgentNotReadyDet para fix de traduccion
	Se actualizan datos de la tabla RepOutCallsDetail para fix de traduccion
	Se actualizan datos de la tabla RepInEffectiveness para fix de traduccion
	Se actualizan datos de la tabla RepOutCallBacks para fix de traduccion
	Se actualizan datos de la tabla RepOutDialDetail para fix de traduccion
	Se actualizan datos de la tabla RepOutCallBilling para fix de traduccion
	Se actualiza estructura y datos de la tabla RepInNotTransferred para fix de traduccion
	Se actualiza estructura y datos de la tabla RepInDispositions para fix de traduccion
	Se actualiza estructura y datos de la tabla RepInSubDispositions para fix de traduccion
	Se actualiza estructura y datos de la tabla RepOutDispositions para fix de traduccion
	Se actualiza estructura y datos de la tabla RepOutSubDispositions para fix de traduccion
	Se crea el SP ccspGetTranslatedReports para obtener reportes a traducir
	Se modifica el SP GetReportMenus para ocultar menu de AVRS en caso de que no este habilitada la grabadora
	Se modifica el SP ccspRepAgentNotReadyDet para fix de traduccion
	Se modifica el SP ccspRepInDispositions para fix de traduccion
	Se modifica el SP ccspRepInEffectiveness para fix de traduccion y de valores en reporte
	Se modifica el SP ccspRepInNotTransferred para fix de traduccion
	Se modifica el SP ccspRepInSubDispositions para fix de traduccion
	Se modifica el SP ccspRepOutCallBacks para fix de traduccion
	Se modifica el SP ccspRepOutCallBilling para fix de traduccion
	Se modifica el SP ccspRepOutCallsDetail para fix de traduccion
	Se modifica el SP ccspRepOutDialDetail para fix de traduccion
	Se modifica el SP ccspRepOutDispositions para fix de traduccion
	Se modifica el SP ccspRepOutSubDispositions para fix de traduccion
	Se reconstruye el reporte RepInEffectiveness por cambios en valores y traducciones

Version requerida: 5
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '6'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'TranslatedReports - Create Table'
		set @Sql = 'create table [dbo].[TranslatedReports](
[id] [int] NOT NULL,
[columns] [nvarchar](max) NOT NULL
)'
		
	EXEC(@Sql)
	
		set @process = 'TranslatedReports - Insert'
		set @Sql = 'insert into [TranslatedReports]
values (2030, ''login|user|status'')
insert into [TranslatedReports]
values (3030, ''wg'')
insert into [TranslatedReports]
values (3040, ''wg|disposition'')
insert into [TranslatedReports]
values (3060, ''inbound'')
insert into [TranslatedReports]
values (3120, ''wg|subDisposition'')
insert into [TranslatedReports]
values (4010, ''campaign'')
insert into [TranslatedReports]
values (4020, ''login|campaign|ByCarrier|Calltypes|dialType|whoHangUp|subDisposition'')
insert into [TranslatedReports]
values (4040, ''wg|disposition'')
insert into [TranslatedReports]
values (4100, ''wg|subDisposition'')
insert into [TranslatedReports]
values (4110, ''status'')'
		
	EXEC(@Sql)
	
		set @process = 'ccspGetTranslatedReports - Create Procedure'
		set @Sql = 'create procedure [dbo].[ccspGetTranslatedReports] @id int as

select [columns]
from [TranslatedReports]
where id = @id'
		
	EXEC(@Sql)

		set @process = 'ReportsTotals - Update'
		set @Sql = 'update [dbo].[ReportsTotals]
set totalColumns = ''sum:ntotalin|sum:nanswer2|sum:nabnd|special:tatencion:sum(tatencion*nanswer2)/sum(nanswer2)|sum:tqueavg|sum:tQuetot|sum:nQuetot|sum:avgAbandonTime|sum:tresp|avg:poscount|special:Porcentaje:ISNULL(SUM(SLP1) * 100/ NULLIF(SUM(SLP2)_ 0)_ 0)''
where id = 3060'
		
	EXEC(@Sql)

		set @process = 'RepInEffectiveness - Rename Column'
		set @Sql = 'exec sp_RENAME ''RepInEffectiveness.nanswer'' , ''nanswer2'', ''COLUMN''
exec sp_RENAME ''RepInEffectiveness.tatention'' , ''tatencion'', ''COLUMN''
exec sp_RENAME ''RepInEffectiveness.tabndtot'' , ''avgAbandonTime'', ''COLUMN'''
		
	EXEC(@Sql)

		set @process = 'RepAgentNotReadyDet - Alter and Update'
		set @Sql = 'alter table RepAgentNotReadyDet
	alter column [login] [varchar](255)

update RepAgentNotReadyDet
set [login] = ''systemTranslated_NoUserName''
where [login] = ''No agent''

update RepAgentNotReadyDet
set [user] = ''systemTranslated_NoName''
where [user] = ''No name''

update RepAgentNotReadyDet
set [status] = ''systemTranslated_NoStatus''
where [status] = ''No status'''
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallsDetail - Update'
		set @Sql = 'update RepOutCallsDetail
set [login] = ''systemTranslated_NoUserName''
where [login] = ''Sin nombre de usuario''

update RepOutCallsDetail
set [campaign] = ''systemTranslated_NoCampaign''
where [campaign] = ''Sin campaña''

update RepOutCallsDetail
set [ByCarrier] = ''systemTranslated_NoCarrier''
where [ByCarrier] = ''Sin proveedor''

update RepOutCallsDetail
set [Calltypes] = ''systemTranslated_Indefinite''
where [Calltypes] = ''Indefinido''

update RepOutCallsDetail
set [dialType] = ''systemTranslated_Auto''
where [dialType] = ''Auto''

update RepOutCallsDetail
set [dialType] = ''systemTranslated_Manual''
where [dialType] = ''Manual''

update RepOutCallsDetail
set [whoHangUp] = ''systemTranslated_Client''
where [whoHangUp] = ''Cliente''

update RepOutCallsDetail
set [whoHangUp] = ''systemTranslated_Agent''
where [whoHangUp] = ''Agente''

update RepOutCallsDetail
set [subDisposition] = ''systemTranslated_NoSubDisposition''
where [subDisposition] = ''Sin Calificar'''
		
	EXEC(@Sql)

		set @process = 'RepInEffectiveness - Update'
		set @Sql = 'update RepInEffectiveness
set [inbound] = ''systemTranslated_NoACDGroup''
where [inbound] = ''No ACD group'''
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallBacks - Update'
		set @Sql = 'update RepOutCallBacks
set [status] = ''systemTranslated_Pending''
where [status] = ''Pending / Pendiente''

update RepOutCallBacks
set [status] = ''systemTranslated_Answer''
where [status] = ''Answer / Contestado''

update RepOutCallBacks
set [status] = ''systemTranslated_NoAnswer''
where [status] = ''No Answer / No Contestado''

update RepOutCallBacks
set [status] = ''systemTranslated_Recicled''
where [status] = ''Recicled / Reciclado''

update RepOutCallBacks
set [status] = ''systemTranslated_Expired''
where [status] = ''Expired / Expirado''

update RepOutCallBacks
set [status] = ''systemTranslated_OldRecord''
where [status] = ''Old Record / Registro Viejo''

update RepOutCallBacks
set [status] = ''systemTranslated_LoadRecord''
where [status] = ''Load Record / Carga de Registro'''
		
	EXEC(@Sql)
	
		set @process = 'RepOutDialDetail - Update'
		set @Sql = 'update RepOutDialDetail
set [campaign] = ''systemTranslated_NoCampaign''
where [campaign] = ''Sin campaña'''
		
	EXEC(@Sql)
	
		set @process = 'RepOutCallBilling - Update'
		set @Sql = 'update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_01800Calls_Count''
where [tipoLLamada_Count] = ''01800Llamadas_ / 01800Calls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_01800MinBilled_Count''
where [tipoLLamada_Count] = ''01800_Min_Facturados / 01800_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_01800Cost_Count''
where [tipoLLamada_Count] = ''01800_costo / 01800_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_01800Tax_Count''
where [tipoLLamada_Count] = ''01800_IVA / 01800_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelCalls_Count''
where [tipoLLamada_Count] = ''CelLlamadas_ / CelCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelMinBilled_Count''
where [tipoLLamada_Count] = ''Cel_Min_Facturados / Cel_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelCost_Count''
where [tipoLLamada_Count] = ''Cel_costo / Cel_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelTax_Count''
where [tipoLLamada_Count] = ''Cel_IVA / Cel_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CellargadistanciaCalls_Count''
where [tipoLLamada_Count] = ''Cel larga distanciaLlamadas_ / Cel larga distanciaCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CellargadistanciaCallsMinBilled_Count''
where [tipoLLamada_Count] = ''Cel larga distancia_Min_Facturados / Cel larga distancia_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CellargadistanciaCost_Count''
where [tipoLLamada_Count] = ''Cel larga distancia_costo / Cel larga distancia_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CellargadistanciaTax_Count''
where [tipoLLamada_Count] = ''Cel larga distancia_IVA / Cel larga distancia_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelLDCalls_Count''
where [tipoLLamada_Count] = ''Cel LDLlamadas_ / Cel LDCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelLDMinBilled_Count''
where [tipoLLamada_Count] = ''Cel LD_Min_Facturados / Cel LD_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelLDCost_Count''
where [tipoLLamada_Count] = ''Cel LD_costo / Cel LD_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelLDTax_Count''
where [tipoLLamada_Count] = ''Cel LD_IVA / Cel LD_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada2digitosCalls_Count''
where [tipoLLamada_Count] = ''Cel local lada 2 digitosLlamadas_ / Cel local lada 2 digitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada2digitosMinBilled_Count''
where [tipoLLamada_Count] = ''Cel local lada 2 digitos_Min_Facturados / Cel local lada 2 digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada2digitosCost_Count''
where [tipoLLamada_Count] = ''Cel local lada 2 digitos_costo / Cel local lada 2 digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada2digitosTax_Count''
where [tipoLLamada_Count] = ''Cel local lada 2 digitos_IVA / Cel local lada 2 digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada3digitosCalls_Count''
where [tipoLLamada_Count] = ''Cel local lada 3 digitosLlamadas_ / Cel local lada 3 digitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada3digitosMinBilled_Count''
where [tipoLLamada_Count] = ''Cel local lada 3 digitos_Min_Facturados / Cel local lada 3 digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada3digitosCost_Count''
where [tipoLLamada_Count] = ''Cel local lada 3 digitos_costo / Cel local lada 3 digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada3digitosTax_Count''
where [tipoLLamada_Count] = ''Cel local lada 3 digitos_IVA / Cel local lada 3 digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada4digitosCalls_Count''
where [tipoLLamada_Count] = ''Cel local lada 4 digitosLlamadas_ / Cel local lada 4 digitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada4digitosMinBilled_Count''
where [tipoLLamada_Count] = ''Cel local lada 4 digitos_Min_Facturados / Cel local lada 4 digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada4digitosCost_Count''
where [tipoLLamada_Count] = ''Cel local lada 4 digitos_costo / Cel local lada 4 digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Cellocallada4digitosTax_Count''
where [tipoLLamada_Count] = ''Cel local lada 4 digitos_IVA / Cel local lada 4 digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelularCalls_Count''
where [tipoLLamada_Count] = ''CelularLlamadas_ / CelularCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelularMinBilled_Count''
where [tipoLLamada_Count] = ''Celular_Min_Facturados / Celular_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelularCost_Count''
where [tipoLLamada_Count] = ''Celular_costo / Celular_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_CelularTax_Count''
where [tipoLLamada_Count] = ''Celular_IVA / Celular_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LargadistanciaCalls_Count''
where [tipoLLamada_Count] = ''Larga distanciaLlamadas_ / Larga distanciaCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LargadistanciaMinBilled_Count''
where [tipoLLamada_Count] = ''Larga distancia_Min_Facturados / Larga distancia_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LargadistanciaCost_Count''
where [tipoLLamada_Count] = ''Larga distancia_costo / Larga distancia_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LargadistanciaTax_Count''
where [tipoLLamada_Count] = ''Larga distancia_IVA / Larga distancia_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDCalls_Count''
where [tipoLLamada_Count] = ''LDLlamadas_ / LDCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDMinBilled_Count''
where [tipoLLamada_Count] = ''LD_Min_Facturados / LD_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDCost_Count''
where [tipoLLamada_Count] = ''LD_costo / LD_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDTax_Count''
where [tipoLLamada_Count] = ''LD_IVA / LD_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInterCalls_Count''
where [tipoLLamada_Count] = ''LD InterLlamadas_ / LD InterCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInterMinBilled_Count''
where [tipoLLamada_Count] = ''LD Inter_Min_Facturados / LD Inter_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInterCost_Count''
where [tipoLLamada_Count] = ''LD Inter_costo / LD Inter_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInterTax_Count''
where [tipoLLamada_Count] = ''LD Inter_IVA / LD Inter_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInternacionalCalls_Count''
where [tipoLLamada_Count] = ''LD InternacionalLlamadas_ / LD InternacionalCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInternacionalMinBilled_Count''
where [tipoLLamada_Count] = ''LD Internacional_Min_Facturados / LD Internacional_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInternacionalCost_Count''
where [tipoLLamada_Count] = ''LD Internacional_costo / LD Internacional_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDInternacionalTax_Count''
where [tipoLLamada_Count] = ''LD Internacional_IVA / LD Internacional_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDnacionalCalls_Count''
where [tipoLLamada_Count] = ''LD nacionalLlamadas_ / LD nacionalCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDnacionalMinBilled_Count''
where [tipoLLamada_Count] = ''LD nacional_Min_Facturados / LD nacional_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDnacionalCost_Count''
where [tipoLLamada_Count] = ''LD nacional_costo / LD nacional_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDnacionalTax_Count''
where [tipoLLamada_Count] = ''LD nacional_IVA / LD nacional_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovilCalls_Count''
where [tipoLLamada_Count] = ''LD Nacional MovilLlamadas_ / LD Nacional MovilCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovilMinBilled_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil_Min_Facturados / LD Nacional Movil_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovilCost_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil_costo / LD Nacional Movil_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovilTax_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil_IVA / LD Nacional Movil_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovil9DigitosCalls_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil 9 DigitosLlamadas_ / LD Nacional Movil 9 DigitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovil9DigitosMinBilled_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil 9 Digitos_Min_Facturados / LD Nacional Movil 9 Digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovil9DigitosCost_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil 9 Digitos_costo / LD Nacional Movil 9 Digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNacionalMovil9DigitosTax_Count''
where [tipoLLamada_Count] = ''LD Nacional Movil 9 Digitos_IVA / LD Nacional Movil 9 Digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNewCalls_Count''
where [tipoLLamada_Count] = ''LD NewLlamadas_ / LD NewCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNewMinBilled_Count''
where [tipoLLamada_Count] = ''LD New_Min_Facturados / LD New_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNewCost_Count''
where [tipoLLamada_Count] = ''LD New_costo / LD New_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDNewTax_Count''
where [tipoLLamada_Count] = ''LD New_IVA / LD New_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDOldCalls_Count''
where [tipoLLamada_Count] = ''LD OldLlamadas_ / LD OldCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDOldMinBilled_Count''
where [tipoLLamada_Count] = ''LD Old_Min_Facturados / LD Old_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDOldCost_Count''
where [tipoLLamada_Count] = ''LD Old_costo / LD Old_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDOldTax_Count''
where [tipoLLamada_Count] = ''LD Old_IVA / LD Old_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDusaCalls_Count''
where [tipoLLamada_Count] = ''LD usaLlamadas_ / LD usaCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDusaMinBilled_Count''
where [tipoLLamada_Count] = ''LD usa_Min_Facturados / LD usa_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDusaCost_Count''
where [tipoLLamada_Count] = ''LD usa_costo / LD usa_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LDusaTax_Count''
where [tipoLLamada_Count] = ''LD usa_IVA / LD usa_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LocalCalls_Count''
where [tipoLLamada_Count] = ''LocalLlamadas_ / LocalCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LocalMinBilled_Count''
where [tipoLLamada_Count] = ''Local_Min_Facturados / Local_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LocalCost_Count''
where [tipoLLamada_Count] = ''Local_costo / Local_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_LocalTax_Count''
where [tipoLLamada_Count] = ''Local_IVA / Local_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada2digitosCalls_Count''
where [tipoLLamada_Count] = ''Local lada 2 digitosLlamadas_ / Local lada 2 digitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada2digitosMinBilled_Count''
where [tipoLLamada_Count] = ''Local lada 2 digitos_Min_Facturados / Local lada 2 digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada2digitosCost_Count''
where [tipoLLamada_Count] = ''Local lada 2 digitos_costo / Local lada 2 digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada2digitosTax_Count''
where [tipoLLamada_Count] = ''Local lada 2 digitos_IVA / Local lada 2 digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada3digitosCalls_Count''
where [tipoLLamada_Count] = ''Local lada 3 digitosLlamadas_ / Local lada 3 digitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada3digitosMinBilled_Count''
where [tipoLLamada_Count] = ''Local lada 3 digitos_Min_Facturados / Local lada 3 digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada3digitosCost_Count''
where [tipoLLamada_Count] = ''Local lada 3 digitos_costo / Local lada 3 digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada3digitosTax_Count''
where [tipoLLamada_Count] = ''Local lada 3 digitos_IVA / Local lada 3 digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada4digitosCalls_Count''
where [tipoLLamada_Count] = ''Local lada 4 digitosLlamadas_ / Local lada 4 digitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada4digitosMinBilled_Count''
where [tipoLLamada_Count] = ''Local lada 4 digitos_Min_Facturados / Local lada 4 digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada4digitosCost_Count''
where [tipoLLamada_Count] = ''Local lada 4 digitos_costo / Local lada 4 digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Locallada4digitosTax_Count''
where [tipoLLamada_Count] = ''Local lada 4 digitos_IVA / Local lada 4 digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_MovilCalls_Count''
where [tipoLLamada_Count] = ''MovilLlamadas_ / MovilCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_MovilMinBilled_Count''
where [tipoLLamada_Count] = ''Movil_Min_Facturados / Movil_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_MovilCost_Count''
where [tipoLLamada_Count] = ''Movil_costo / Movil_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_MovilTax_Count''
where [tipoLLamada_Count] = ''Movil_IVA / Movil_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Movil9DigitosCalls_Count''
where [tipoLLamada_Count] = ''Movil 9 DigitosLlamadas_ / Movil 9 DigitosCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Movil9DigitosMinBilled_Count''
where [tipoLLamada_Count] = ''Movil 9 Digitos_Min_Facturados / Movil 9 Digitos_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Movil9DigitosCost_Count''
where [tipoLLamada_Count] = ''Movil 9 Digitos_costo / Movil 9 Digitos_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_Movil9DigitosTax_Count''
where [tipoLLamada_Count] = ''Movil 9 Digitos_IVA / Movil 9 Digitos_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OffNetCalls_Count''
where [tipoLLamada_Count] = ''Off NetLlamadas_ / Off NetCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OffNetMinBilled_Count''
where [tipoLLamada_Count] = ''Off Net_Min_Facturados / Off Net_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OffNetCost_Count''
where [tipoLLamada_Count] = ''Off Net_costo / Off Net_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OffNetTax_Count''
where [tipoLLamada_Count] = ''Off Net_IVA / Off Net_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnNetCalls_Count''
where [tipoLLamada_Count] = ''On NetLlamadas_ / On NetCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnNetMinBilled_Count''
where [tipoLLamada_Count] = ''On Net_Min_Facturados / On Net_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnNetCost_Count''
where [tipoLLamada_Count] = ''On Net_costo / On Net_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnNetTax_Count''
where [tipoLLamada_Count] = ''On Net_IVA / On Net_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnRingCalls_Count''
where [tipoLLamada_Count] = ''On RingLlamadas_ / On RingCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnRingMinBilled_Count''
where [tipoLLamada_Count] = ''On Ring_Min_Facturados / On Ring_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnRingCost_Count''
where [tipoLLamada_Count] = ''On Ring_costo / On Ring_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_OnRingTax_Count''
where [tipoLLamada_Count] = ''On Ring_IVA / On Ring_Tax_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_TriangleCalls_Count''
where [tipoLLamada_Count] = ''TriangleLlamadas_ / TriangleCalls__Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_TriangleMinBilled_Count''
where [tipoLLamada_Count] = ''Triangle_Min_Facturados / Triangle_Min_Facturados_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_TriangleCost_Count''
where [tipoLLamada_Count] = ''Triangle_costo / Triangle_Cost_Count''

update RepOutCallBilling
set [tipoLLamada_Count] = ''systemTranslated_TriangleTax_Count''
where [tipoLLamada_Count] = ''Triangle_IVA / Triangle_Tax_Count'''
		
	EXEC(@Sql)

		set @process = 'RepInNotTransferred - Alter and Update'
		set @Sql = 'alter table RepInNotTransferred
	alter column [wg] [varchar](255)

update RepInNotTransferred
set [wg] = ''systemTranslated_WorkGroup''
where [wg] = ''Workgroup1'''
		
	EXEC(@Sql)

		set @process = 'RepInDispositions - Alter and Update'
		set @Sql = 'alter table RepInDispositions
	alter column [wg] [varchar](255)

update RepInDispositions
set [wg] = ''systemTranslated_WorkGroup''
where [wg] = ''Workgroup1''

update RepInDispositions
set [disposition] = ''systemTranslated_Dispositionless''
where [disposition] = ''Dispositionless''

update RepInDispositions
set [disposition_count] = ''systemTranslated_Dispositionless_Count''
where [disposition_count] = ''Dispositionless_Count'''
		
	EXEC(@Sql)
	
		set @process = 'RepInSubDispositions - Alter and Update'
		set @Sql = 'alter table RepInSubDispositions
	alter column [wg] [varchar](255)

update RepInSubDispositions
set [wg] = ''systemTranslated_WorkGroup''
where [wg] = ''Workgroup1''

update RepInSubDispositions
set [subDisposition] = ''systemTranslated_Dispositionless''
where [subDisposition] = ''Dispositionless''

update RepInSubDispositions
set [subDisposition_count] = ''systemTranslated_Dispositionless_Count''
where [subDisposition_count] = ''Dispositionless_Count'''
		
	EXEC(@Sql)
	
		set @process = 'RepOutDispositions - Alter and Update'
		set @Sql = 'alter table RepOutDispositions
	alter column [wg] [varchar](255)

update RepOutDispositions
set [wg] = ''systemTranslated_WorkGroup''
where [wg] = ''Workgroup1''

update RepOutDispositions
set [disposition] = ''systemTranslated_Dispositionless''
where [disposition] = ''Dispositionless''

update RepOutDispositions
set [disposition_count] = ''systemTranslated_Dispositionless_Count''
where [disposition_count] = ''Dispositionless_Count'''
		
	EXEC(@Sql)
	
		set @process = 'RepOutSubDispositions - Alter and Update'
		set @Sql = 'alter table RepOutSubDispositions
	alter column [wg] [varchar](255)

update RepOutSubDispositions
set [wg] = ''systemTranslated_WorkGroup''
where [wg] = ''Workgroup1''

update RepOutSubDispositions
set [subDisposition] = ''systemTranslated_Dispositionless''
where [subDisposition] = ''Dispositionless''

update RepOutSubDispositions
set [subDisposition_count] = ''systemTranslated_Dispositionless_Count''
where [subDisposition_count] = ''Dispositionless_Count'''
		
	EXEC(@Sql)
	
		set @process = 'GetReportMenus - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].GetReportMenus
	@userId int,
	@activeChat tinyint,
	@activeAVRS tinyint
AS
BEGIN
	Select distinct Nivel, menu_descrip, menu_id,ordengral, 5 as filtersType
	from ccmenus
	where type = 2
	and (menu_id >= 2000) 
	and (menu_id not in (3130,3131,3132,3133,3134,3135,3136,8050,8060,8061,8062,8063,8070,8071,8072,8080)
	or   menu_id     in (3130,3131,3132,3133,3134,3135,3136) and @activeChat = 1
	or   menu_id     in (8050,8060,8061,8062,8063,8070,8071,8072,8080) and @activeAVRS = 1)
	
	order by ordengral asc
END'
	EXEC(@Sql)

		set @process = 'ccspRepAgentNotReadyDet - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()


if @action = 1
begin
	delete from RepAgentNotReadyDet where date >= @from AND date < @to
	
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(datetime,convert(varchar(11),fechaInicio)) as [date], isNull(usr.Login,''systemTranslated_NoUserName'') as login, usr.user_id as userId, 
	isNull(usr.ApellidoPaterno,'''') + '' '' + isNull(usr.ApellidoMaterno, '''') + '' '' + IsNull(usr.Nombres, ''systemTranslated_NoName'') as [user],
	isnull(tn.tiponotready_id,0) as tiponotreadyId,  
	isNull(tn.Descripcion, ''systemTranslated_NoStatus'')as [status], 
	fechaInicio as startDate, 
	case when fechaFin is null then fecha when separado = 0 then fecha when separado = 3  or separado = 1 then fechaFin end as endDate,
	case when fechafin is null then
			tStatus
		 when separado = 0 then 
			tStatus
		 when separado = 3  or separado = 1 then
			datediff( s, fechaInicio, fechaFin) end as statusTime,
	case when fechafin is null then tStatus when separado = 0 then tStatus when separado = 3  or separado = 1 then datediff( s, fechaInicio, fechaFin) end as statusTimeSeconds,
	datepart(yyyy,fechaInicio), datepart(mm,fechaInicio), datepart(dd,fechaInicio), datepart(hh,fechaInicio), datepart(mi,fechaInicio)
	From (select distinct user_id, 
		tiponotready_id, 
		DATEADD(s, -tstatus, fecha) AS fechaInicio, 
		separado, 
		tStatus, 
		fecha, 
		( select min( sub.fecha) 
			from ccLogAgentesNotReady sub 
			where sub.separado = 1 
			and sub.fecha = nr.fecha 
			and nr.user_id = sub.user_id 
			and nr.tiponotready_id = sub.tiponotready_id ) as fechaFin 
		from ccLogAgentesNotReady nr 
		WHERE fecha >= @from 
		AND fecha < @to )xdet 
	left join ccUsers usr on usr.user_id = xdet.user_id  
	left join ccTipoNotReady tn on tn.tipoNotready_id = xdet.tiponotready_id 
	where usr.user_id is not null
	order by [user], [status], fechaInicio

end'
		
	EXEC(@Sql)

		set @process = 'ccspRepInDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInDispositions where date >= @from AND date < @to
	
	insert into RepInDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, dispositionId, '''' as DispName,'''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''systemTranslated_WorkGroup'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
		FROM (
			SELECT 
				a.cal_inicio as dateHour, a.Inbound_id, a.calif_id as dispositionId, user_id, b.IDArea
				from cccallsin a 		
				left join ccInbound b
				on	b.Inbound_id = a.Inbound_id		
				where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13	--Constestada
				and b.IDArea is not null
			UNION 
			SELECT 		
				requestDate,a.inboundId, a.disposition, a.userId, b.IDArea
				FROM ccRIAChats a
				left join ccInbound b
				on	b.Inbound_id = a.inboundId
				where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
				and b.IDArea is not null		
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, dispositionId, user_id, IDArea
	
	update a set acdGroup = isnull(descripcion,'''')
	from RepInDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''systemTranslated_Dispositionless''), disposition_count = isnull(description,''systemTranslated_Dispositionless'') + ''_Count''
	from RepInDispositions a
	left join cctipocalif b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInEffectiveness - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInEffectiveness]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

if @action = 1
begin
CREATE TABLE [dbo].[#ccGenInCall](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[dni_id] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[ntotal] [smallint] NOT NULL,
[ninitial] [smallint] NOT NULL,
[nout_hour] [smallint] NOT NULL,
[nout_service] [smallint] NOT NULL,
[nabnd] [smallint] NOT NULL,
[nno_agent] [smallint] NOT NULL,
[nque] [smallint] NOT NULL,
[ntimeout] [smallint] NOT NULL,
[noverflow] [smallint] NOT NULL,
[nxfer] [smallint] NOT NULL,
[nxfer_que] [smallint] NOT NULL,
[nabnd_xfer] [smallint] NOT NULL,
[nabnd_ring] [smallint] NOT NULL,
[nno_answer] [smallint] NOT NULL,
[nabnd_dialog] [smallint] NOT NULL,
[nanswer] [smallint] NOT NULL,
[nlost] [smallint] NOT NULL,
[nmsg] [smallint] NOT NULL,
[nabnd_tres] [smallint] NOT NULL,
[nansw_tres] [smallint] NOT NULL,
[tque_max] [smallint] NOT NULL,
[tque] [int] NOT NULL,
[txfer] [int] NOT NULL,
[tdialog] [int] NOT NULL,
[tnotes] [int] NOT NULL,
[tring] [int] NOT NULL,
[tresp] [int] NOT NULL,
[nMoh] [smallint] NOT NULL DEFAULT ((0)),
[nWHag] [smallint] NOT NULL DEFAULT ((0)),
[nWHcl] [smallint] NOT NULL DEFAULT ((0))
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenSession](
[user_id] [smallint] NOT NULL,
[login] [datetime] NOT NULL,
[logout] [datetime] NOT NULL,
[extension] [varchar](7) NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#agents](
[timegroup] [smalldatetime] NOT NULL,
[user_id] [smallint] NOT NULL,
[tlog] [int] NOT NULL DEFAULT (0),
[treq] [int] NOT NULL DEFAULT (0),
[tnot_av] [int] NOT NULL,
[tav] [int] NOT NULL DEFAULT (0),
[tprob] [int] NOT NULL DEFAULT (0),
[tunknown] [int] NOT NULL DEFAULT (0),
[tother] [int] NOT NULL DEFAULT (0),
[nother] [int] NOT NULL DEFAULT (0),
[nMoh] [int] NOT NULL DEFAULT ((0)),
[nWHag] [int] NOT NULL DEFAULT ((0)),
[nWHcl] [int] NOT NULL DEFAULT ((0))
) ON [PRIMARY]	

CREATE TABLE [dbo].[#ccGenInSpec](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[pos_tot] [smallint] NOT NULL,
[pos_time] [int] NOT NULL,
[pos_efect] [smallint] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[#ccGenInAbnd](
[timegroup] [smalldatetime] NOT NULL,
[inbound_id] [smallint] NOT NULL,
[amount] [smallint] NOT NULL,
[time_max] [smallint] NOT NULL,
[time_tot] [bigint] NOT NULL,
[<10] [smallint] NOT NULL,
[<20] [smallint] NOT NULL,
[<30] [smallint] NOT NULL,
[<40] [smallint] NOT NULL,
[<50] [smallint] NOT NULL,
[<60] [smallint] NOT NULL,
[<120] [smallint] NOT NULL,
[<180] [smallint] NOT NULL,
[<240] [smallint] NOT NULL,
[<300] [smallint] NOT NULL,
[+300] [smallint] NOT NULL
) ON [PRIMARY]

INSERT INTO #ccGenInCall(timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,inbound_id,dni_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.dni_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,dni_id,[user_id]
,COUNT(cal_id)AS ntotal
,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,dni_id,[user_id])xDetailCount
right JOIN(SELECT timegroup,inbound_id,dni_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
FROM(SELECT timegroup,inbound_id,dni_id,[user_id]
,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
,*
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
UNION
SELECT timegroup_next,inbound_id,dni_id,[user_id]
,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
GROUP BY timegroup,inbound_id,dni_id,[user_id])xDetailTime
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.dni_id=xDetailCount.dni_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
WHERE timegroup>=@from AND timegroup<@to
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
ORDER BY timegroup,inbound_id,dni_id,[user_id]

INSERT INTO #ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin /*with (nolock, index(ccLogLogin_fecha))*/
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
FROM
	(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
	FROM 
		(SELECT uid, ext, MAX(login) as login, logout
		FROM
			(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
			FROM ccLogLogin subLogin /*with (nolock, index(ccLogLogin_fecha))*/ WHERE subLogin.tipomov = 0 
			AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
			FROM ccLogLogin Login /*with (nolock, index(ccLogLogin_fecha))*/
			WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
			GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
		WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
	RIGHT OUTER JOIN ccLogLogin  /*with (nolock, index(ccLogLogin_fecha))*/
	ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
	WHERE tipomov = 1
	and ccLogLogin.fecha >= dateadd( dd, -5, @from)) Det 
) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from and login < @to
GROUP BY uid, login

INSERT INTO #agents(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
SELECT timegroup,[user_id],tlog,tnot_av
,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
,nother,nMoh,nWHag,nWHcl
FROM(
	SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
		,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
	 FROM(
		SELECT 
			xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
			,ISNULL(SUM(#ccGenInCall.txfer),0) as txfer
			,ISNULL(SUM(#ccGenInCall.tdialog),0) as tdialog
			,ISNULL(SUM(#ccGenInCall.tnotes),0) as tnotes
			,ISNULL(SUM(#ccGenInCall.tring),0) as tring
			,ISNULL(SUM(#ccGenInCall.nMoh),0) as nMoh
			,ISNULL(SUM(#ccGenInCall.nWHag),0) as nWHag
			,ISNULL(SUM(#ccGenInCall.nWHcl),0) as nWHcl

			,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t1
			,ISNULL((SELECT top 1 3600
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t2
			,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t3
			,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
						 FROM #ccGenSession
						 WHERE [user_id]=xTimeDetail.[user_id]
							AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
				),0)AS t4

		 FROM(
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
					,ccLogAgentesDia.[user_id]
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
					,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
					,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
				 FROM ccLogAgentesDia
				 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
			)xTimeDetail
				LEFT OUTER JOIN #ccGenInCall ON(xTimeDetail.timegroup=#ccGenInCall.timegroup AND xTimeDetail.[user_id]=#ccGenInCall.[user_id])
			GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		)xDetail
)xAllTimes
WHERE tlog>0
ORDER BY timegroup,[user_id]

INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
SELECT timegroup, ccInboundAgentes.inbound_id
	, COUNT(DISTINCT #agents.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
 FROM #agents
	INNER JOIN ccInboundAgentes ON (#agents.[user_id] = ccInboundAgentes.[user_id])
 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
 GROUP BY timegroup, ccInboundAgentes.inbound_id

insert into #ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
SELECT timegroup
, inbound_id
, COUNT(cal_inicio) AS amount
, MAX(tAbnd) AS time_max
, SUM(tAbnd) AS time_tot
, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
FROM	(
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cal_inicio
	, inbound_id
	, statuscall_id
	, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (isnull(cal_xfer,'''') = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
	, (cal_twait + cal_txfer + cal_tring) AS tAbnd
 FROM ccCallsIn
	WHERE cal_inicio >= @from AND  cal_inicio < @to
	AND INBOUND_ID > 0
) xCalls
WHERE (abnd IS NOT NULL) 
GROUP BY timegroup, inbound_id

--Borrar lo que esta para no repetir
delete from RepInEffectiveness where date >= @from AND date < @to

insert into RepInEffectiveness
SELECT timegroup as date, xDetail.inbound_id, isnull(descripcion, ''systemTranslated_NoACDGroup'') descripcion , ntotal, nanswer, nabnd , isnull(tatention / nullif(nanswer,0),0), 
tque_avg as tqueavg, tQue_tot as tQuetot, nQue_tot as nQuetot, isnull(tabnd_tot / NULLIF(nabnd,0),0) as tabndtot, SL_P_1 as SLP1, SL_P_2 as SLP2, tresp, 
/*pos_tot as postot,*/ pos_count as poscount, ISNULL(SL_P_1 * 100/ NULLIF(SL_P_2, 0), 0)  as Porcentaje
, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
FROM ( 

SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, 
ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, 
ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) tabnd_tot, 
ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot, ISNULL(pos_count, 0) pos_count 

FROM (

SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, 
ISNULL(sum(tque)/ NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) as tQue_tot, sum(nQue) as nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, 
SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp  
FROM #ccGenInCall  
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetCall  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect, COUNT(pos_tot) AS pos_count  
FROM #ccGenInSpec 
WHERE timegroup >= @from
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetSpec 
ON (xDetCall.timegroup = xDetSpec.timegroup AND xDetCall.inbound_id = xDetSpec.inbound_id)  
LEFT JOIN (
SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot   
FROM #ccGenInAbnd  
WHERE timegroup >= @from 
AND timegroup < @to 
GROUP BY timegroup , inbound_id) xDetAbnd 
ON (xDetCall.timegroup = xDetAbnd.timegroup AND xDetCall.inbound_id = xDetAbnd.inbound_id) 
) xDetail  
LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id)  
ORDER BY date

drop table #ccGenInCall
drop table #ccGenInSpec
drop table #ccGenSession
drop table #agents
drop table #ccGenInAbnd
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInNotTransferred - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInNotTransferred where date >= @from AND date < @to

	insert into RepInNotTransferred
	select a.cal_Inicio as [date], a.Inbound_id, 
	'''' as acd, statusCall_id, '''' as statusCall,'''' as statusCallCount,1 as [count],  b.IDArea, 
	'''' as area, 1 as wgId, ''systemTranslated_WorkGroup'' as wg
	,datepart(yyyy,cal_inicio) as [year]
	,datepart(mm,cal_inicio) as [mount]
	,datepart(dd,cal_inicio) as [day]
	,datepart(hh,cal_inicio) as [hour]
	,datepart(mi,cal_inicio) as [minutes]
	,0 as cal_id,isnull(a.cal_Ani,'''') as phone_in
	from cccallsin a 		
	left join ccInbound b
	on	b.Inbound_id = a.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to and statuscall_id in (2,3,4,6,7,8)
	and  b.IDArea is not null	

	update a set acdGroup = isnull(descripcion,'''')
	from RepInNotTransferred a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set callStatus = isnull(descripcion,''''), callStatus_Count = isnull(descripcion,'''') + ''_Count''
	from RepInNotTransferred a
	left join ccstatusllamada b 
	on a.callStatusId = b.statusCall_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInNotTransferred a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepInSubDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepInSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInSubDispositions where date >= @from AND date < @to

	insert into RepInSubDispositions 
	SELECT 
		CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),
		Inbound_id,'''' as ACDGroup, subDispositionId, '''' as DispName, '''',
		count(dispositionId) DispAmount,user_id, '''' as login,'''' as username,IDArea, '''' as areaName,1 as wgId ,''systemTranslated_WorkGroup'' as wg ,
		datepart(yyyy,max(dateHour)) as year, datepart(mm,max(dateHour)), datepart(dd,max(dateHour)),
		datepart(hh,max(dateHour)), 0
	 FROM 
	(
		select 
		cal_inicio as dateHour, a.Inbound_id,isnull(a.califSub_id,0) as subDispositionId, calif_id as dispositionId, user_id, b.IDArea
		from cccallsin a 		
		left join ccInbound b
		on	b.Inbound_id = a.Inbound_id		
		where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
		and b.IDArea is not null
		UNION 
		SELECT 		
			requestDate,a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
			FROM ccRIAChats a
			left join ccInbound b
			on	b.Inbound_id = a.inboundId
			where requestDate >= @from AND requestDate < @to and a.chatStatus = 3 --Assigned
			and b.IDArea is not null
	) as x group by CONVERT(smalldatetime,CONVERT(varchar(13),dateHour,121)+ '':00'',121),Inbound_id, subDispositionId, user_id, IDArea

	update a set acdGroup = isnull(descripcion,'''')
	from RepInSubDispositions a
	left join ccInbound b 
	on a.inboundId = b.Inbound_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc,''systemTranslated_Dispositionless'') + ''_Count''
	from RepInSubDispositions a
	left join cctipocalifsub b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepInSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepInSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBacks - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallBacks]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepOutCallBacks where date >= @from and date < @to

		insert into RepOutCallBacks
		select cal_fecha as [date], b.user_id as [userId], b.login as [user], c.cam_id as [campaignId], c.cam_descripcion as [campaign],
		cal_key as [callKey], cal_telefono as [originalTel], cal_telCB as [scheduledTel], cal_fecha as [originalDate], 
		cal_fusercallback as [scheduledDate],
		case a.status when 0 then ''systemTranslated_Pending''
		when 1 then ''systemTranslated_Answer''
		when 2 then ''systemTranslated_NoAnswer''
		when 3 then ''systemTranslated_Recicled''
		when 4 then ''systemTranslated_Expired''
		when 5 then ''systemTranslated_OldRecord''
		when 6 then ''systemTranslated_LoadRecord'' end as [status], 
		case when cal_fcallback is null then ''''
			when convert(varchar(13),cal_fcallback) = ''jan 1 1900'' then ''''
			else convert(varchar(255),cal_fcallback) end as [dialDate]
		, datepart(yyyy,cal_fecha) as [year]
		, datepart(mm,cal_fecha) as [month]
		, datepart(dd,cal_fecha) as [day]
		, datepart(hh,cal_fecha) as [hour]
		, datepart(mi,cal_fecha) as [minutes]
		from ccocallbacks a, ccusers b, cccamps c
		where cal_fecha between @from and @to
		and a.user_id = b.user_id
		and a.cam_id = c.cam_id
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallBilling - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallBilling]
	@action as tinyint,
	@from as datetime = null,
	@to as datetime = null
AS

declare @country as tinyint
declare @iva as decimal(3,2)
declare @aux as varchar(3)

select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104
select @aux = isnull(valor,0) from ccsettings where setting_id = 25
set @iva=convert(decimal(3,2),''1.''+@aux)

if @country is null set @country = 1

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	
	delete from RepOutCallBilling where date >= @from AND date < @to
	
		SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS date
			, cam_id, [user_id],
			provedor_id, tipoLlamada_id , min(tipoLlamada) as tipoLlamada
			, COUNT(*) as amount
			, SUM( mins) as mins
			, SUM( costo ) as costo
			, SUM( costo ) * @iva as costoIva
			into #TempOutCallBilling 
		FROM
		(
			SELECT cal_inicio, cco.cam_id as cam_id,
					cco.user_id as user_id,
					cco.provedor_id,
					cco.tipoLlamada_id, t.descrip as tipoLlamada, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
				FROM ccoCallsOut cco 
					inner join cstoTipoLlamada t on cco.tipoLlamada_id = t.tipoLlamada_id			
				WHERE cal_inicio >= @from AND  cal_inicio < @to and cco.provedor_id is not null and cal_manual in (0,2) and country_id = @country
			
			-- Tambien las llamdas que fueron fax
			UNION ALL

			SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, l.descrip as tipoLlamada,1, t.MinutoUno as costo
				FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
				WHERE 
				l.country_id = @country
				and cco.answerbit = 1 and cco.tiporesdial_id <> 1
				and cco.fecha >=  @from AND cco.fecha < @to
				and cco.puerto = cd.puerto
				and cd.provedor_id = p.provedor_id	
				and p.provedor_id = t.provedor_id
				and l.longitud = len(cco.telefono)
				and cco.telefono like l.prefijo
				and t.tipoLlamada_id = l.tipoLlamada_id
		
		) costo
		GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id	

	insert RepOutCallBilling
		select [date], [cam_id], [campaign], [user_id], [agentName], [username], [provedor_id],[provedor], [tipoLlamada_id], 
			(case when tipo = ''amount'' then ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Calls_Count''
				  when tipo = ''mins'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''MinBilled_Count''
				  when tipo = ''costo'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Cost_Count''
				  when tipo = ''costoIva'' then + ''systemTranslated_'' + replace([tipoLLamada],'' '','''') + ''Tax_Count''
				  else tipo end ) as tipoLLamada_Count
			,convert(varchar,[tipollamada_Count])  as [count]
			, [tipoLLamada] as tipoLlamadaDesp, case when tipo = ''costo'' then convert(int,convert(decimal(10,2),[tipollamada_Count]) ) else 0 end 			
			, datepart(yyyy,[date]) as [year]
			, datepart(mm,[date]) as [month]
			, datepart(dd,[date]) as [day]
			, datepart(hh,[date]) as [hour]
			, datepart(mi,[date]) as [min]
		from 
		   (
				select [date], temp.cam_id as cam_id, camps.cam_descripcion as campaign, 
					temp.user_id as user_id, ccuse.Nombres+'' ''+ ccuse.ApellidoPaterno+'' ''+ccuse.ApellidoMaterno as agentName, ccuse.Login as username,
					temp.provedor_id as provedor_id, prov.descrip as provedor,
					[tipoLlamada_id], [tipoLLamada],[tipoLLamada] as tipoLlamadaDesp,convert(varchar,[amount]) as [amount], convert(varchar,[mins]) as [mins], convert(varchar,[costo]) as [costo], convert(varchar,[costoIva]) as [costoIva]
			   from #TempOutCallBilling temp
				inner join ccCamps camps on camps.cam_id = temp.cam_id
				inner join ccUsers ccuse on ccuse.User_id = temp.user_id
				inner join cstoprovedor prov on prov.provedor_id = temp.provedor_id
			) p
		UNPIVOT
		   ([tipollamada_Count] for tipo IN 
			  ([amount], [mins], [costo], [costoIva])
		)AS unpvt

	drop table #TempOutCallBilling
	
end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutCallsDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

DECLARE @IVA INT
SELECT @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25

if @action = 1
	begin		
		--Borrar lo que esta para no repetir
		delete from RepOutCallsDetail where date >= @from AND date < @to

		INSERT INTO RepOutCallsDetail
		SELECT Call.cal_inicio as [date],
		cal_key as [callKey],
		Call.cal_telefono AS [telephone], 
		Call.cal_txfer + call.cal_tring AS [transfer], 
		Call.cal_tdialog AS [dialog], 
		ISNULL(Call.cal_tMoh,0) as [nque],
		Call.cal_tnotas AS [wrapup], 
		ISNULL( Tipo.[description], '''') AS [CallDisposition], 
		Call.cal_extension AS [extension],
		Usr.user_id as [userId],
		ISNULL(Usr.login,''systemTranslated_NoUserName'') [login], 
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username], 
		camps.cam_id as [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign], 
		(CEILING((cal_tXfer + cal_tRing + cal_tDialog +1) / 60.0 )* 60) AS [duration], 
		ISNULL(Call.costo,0.00) as [ncost], 
		@IVA as iva, 
		convert(decimal(10,2),ISNULL(Call.costo,0.00) * (1 + (@IVA / 100.00))) as total,
		ISNULL(prov.descrip, ''systemTranslated_NoCarrier'') as [ByCarrier], 
		ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [Calltypes], 
		case when Call.cal_manual = 0 then ''systemTranslated_Auto'' else ''systemTranslated_Manual'' end as [dialType], 
		case when cal_whoHung = 0 then ''systemTranslated_Client'' else ''systemTranslated_Agent'' end [whoHangUp], 
		case when call.califsub_id = 0 then ''systemTranslated_NoSubDisposition'' else isnull(sub.califSubDesc, '''') end as [subDisposition],
		sta.descripcion as [dialResult],
		Call.cal_id as [calId]
		, datepart(yyyy,Call.cal_inicio) AS [year]
		, datepart(mm,Call.cal_inicio) as [month]
		, datepart(dd,Call.cal_inicio) as [day]
		, datepart(hh,Call.cal_inicio) as [hour]
		, datepart(mi,Call.cal_inicio) as [minutes]
		FROM ccoCallsOut Call  
		LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id=Tipo.calif_id  
		INNER JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]  
		LEFT JOIN ccStatusLlamada sta on call.statuscall_id = sta.statuscall_id  
		LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]  
		LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] and tl.Country_id = 1)  
		LEFT JOIN ccTipoCalifSubOut sub on call.califsub_id = sub.califsub_id 
		WHERE Call.cal_inicio >= @from
		AND Call.cal_inicio < @to
		and cal_manual in (0, 2) 
		order by date
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDialDetail - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1 
	begin
		--Borrar lo que esta para no repetir
		delete from RepOutDialDetail where date >= @from AND date < @to

		--Inserta información de reporte
		insert into RepOutDialDetail
		SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado,
		dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime, datepart(yyyy,fecha),
		datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha)
		FROM
			(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key
			FROM ccoLogDials dial
			left join ccocallsout co on (dial.callout_id = co.callout_id and dial.Telefono=co.cal_telefono and 
			tiporesdial_id = 1 and convert(datetime,convert(varchar(19),co.cal_inicio,121),121) >= 
			convert(datetime,convert(varchar(19),dateadd(mi,-1,dial.fecha),121),121) and 
			convert(datetime,convert(varchar(19),co.cal_inicio,121),121) <= convert(datetime,convert(varchar(19),dateadd(mi,1,dial.fecha),121),121))
			WHERE fecha >= @from AND fecha < @to) dials     
		LEFT JOIN ccoCallsOutSource cs ON dials.callout_id = cs.callout_id LEFT JOIN cctipoResultadoDial tr
		ON dials.tiporesdial_id=tr.tiporesdial_id LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]    
		WHERE fecha >= @from AND fecha < @to
		order by fecha
	end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutDispositions where date >= @from AND date < @to

	insert into RepOutDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, a.calif_id, '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join cccamps b
	on	b.cam_id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
	and b.idArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.calif_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutDispositions a
	left join cccamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,''systemTranslated_Dispositionless''), disposition_count = isnull(description,''systemTranslated_Dispositionless'') + ''_Count''
	from RepOutDispositions a
	left join cctipocalifout b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to


end'
		
	EXEC(@Sql)
	
		set @process = 'ccspRepOutSubDispositions - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccspRepOutSubDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutSubDispositions where date >= @from AND date < @to

	insert into RepOutSubDispositions 
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121) as dateHour, a.cam_id, '''' as Campaign, isnull(a.califSub_id,0), '''' as DispName, '''', count(calif_id) DispAmount, user_id, '''' as login
	, '''' as username, b.IDArea, '''' as areaName, 1 as wgId, ''systemTranslated_WorkGroup'' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join ccCamps b
	on	b.cam_Id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13
	and b.IDArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ '':00'',121),a.cam_id, a.califSub_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'''')
	from RepOutSubDispositions a
	left join ccCamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set subDisposition = isnull(califSubDesc,''systemTranslated_Dispositionless''), subDisposition_count = isnull(califSubDesc,''systemTranslated_Dispositionless'') + ''_Count''
	from RepOutSubDispositions a
	left join cctipocalifsubout b 
	on a.subDispositionId = b.califSub_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno,'''')
	from RepOutSubDispositions a
	left join ccusers b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'''')
	from RepOutSubDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to
end'
		
	EXEC(@Sql)
	
		set @process = 'Reports Rebuild'
		set @Sql = 'declare @from datetime
select @from =dateadd(hh,-1,min(date)) from RepInEffectiveness
exec ccspRepIneffectiveness 1,@from'
		
	EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
