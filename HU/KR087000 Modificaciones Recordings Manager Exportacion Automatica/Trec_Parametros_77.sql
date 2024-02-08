use CCRecorderRIA;

if not exists(select * from TREC_PARAMETROS where par_id =77) begin
	insert into TREC_PARAMETROS values(77,'Configuracion Automatica descarga Ftp AvrsExport','','Configuracion formato Json para exportar grabaciones');
end
if not exists(select * from TREC_PARAMETROS where par_id =78) begin
	insert into TREC_PARAMETROS values(78,'Id Export Configuration','0','Id de la tabla ccConfigurationExportManagerAutomatic');
end

alter table TREC_PARAMETROS ALTER COLUMN par_valor varchar(4000);