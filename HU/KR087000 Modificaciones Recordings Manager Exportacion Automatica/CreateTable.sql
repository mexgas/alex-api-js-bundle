use CCRecorderRIA;
--drop table ccConfigurationExportManagerAutomatic
--drop table ccExportManagerAutomatic
--drop table ccStatusExportManager
if not exists(select * from sys.tables where name='ccConfigurationExportManagerAutomatic') begin
create table ccConfigurationExportManagerAutomatic(
	ccConfigurationExportId bigint Not null identity primary key,
	DateStartExport datetime null,
	DateEndExport  datetime null,
	Json varchar(4000) not null,	
	ExportStatus tinyint not null--0 Create,1 Process ,2 End,3 Cancelada
)
end

if not exists(select * from sys.tables where name='ccExportStatusConfiguration') begin
create table ccExportStatusConfiguration(
	ExportStatusId tinyint not null primary key,
	Description varchar(150) not null
)
end

if not exists(select * from ccExportStatusConfiguration) begin
	insert into ccExportStatusConfiguration values(0,'Create')
	insert into ccExportStatusConfiguration values(1,'Process')
	insert into ccExportStatusConfiguration values(2,'End')
	insert into ccExportStatusConfiguration values(3,'Cancelada')
end


if not exists(select * from sys.tables where name='ccExportManagerAutomatic') begin
create table ccExportManagerAutomatic(
	GrabId bigint Not null,
	ccConfigurationExportId bigint not null,
	DateDownload datetime not null,
	StatusId tinyint not null,
	FOREIGN KEY (ccConfigurationExportId) REFERENCES ccConfigurationExportManagerAutomatic(ccConfigurationExportId)
)
end

if not exists(select * from sys.tables where name='ccStatusExportManager') begin
create table ccStatusExportManager(
	StatusId tinyint not null primary key,
	Description varchar(150) not null
)
end


if not exists(select * from ccStatusExportManager) begin
	insert into ccStatusExportManager values(0,'Scheduled')
	insert into ccStatusExportManager values(1,'Downloaded')
	insert into ccStatusExportManager values(2,'Export error')
	insert into ccStatusExportManager values(3,'Cancelled')
end

update TREC_PARAMETROS 
set par_valor='1' 
where par_id=65 and par_valor='C:\Centerware/Sites/CWAdminEngine/AVRSExportRecs'