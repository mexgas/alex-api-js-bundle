use CCRecorderRIA;

select A.*,B.cal_id,B.tipo_llamada ,B.finicio
from ccExportManagerAutomatic A
inner join RIA_GRABACION B on A.GrabId=B.grab_id
where ccConfigurationExportId=23
order by GrabId
--exec trsp_ExportManagerAutomatic @action=3,@ccConfigurationExportId=23


select A.*,B.Description from ccConfigurationExportManagerAutomatic A
inner join ccExportStatusConfiguration B on A.ExportStatus=B.ExportStatusId

select A.*,B.Description from ccExportManagerAutomatic A
inner join ccStatusExportManager B on A.StatusId=B.StatusId
where ccConfigurationExportId=11

--select * from ccStatusExportManager
--select * from ccExportStatusConfiguration
