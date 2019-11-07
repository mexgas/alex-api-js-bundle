CREATE PROCEDURE [dbo].[ccsp_RIAExternalApplications]
AS
select ccRIAExternalApplications.id,ccRIACatFunExt.type,ccRIAExternalApplications.title,ccRIAExternalApplications.iconURL,ccRIAExternalApplications.appURL,ccRIAClassPath.path,ccRIAExternalApplications.autoRun 
from ccRIAExternalApplications, ccRIAClassPath, ccRIACatFunExt
where ccRIAExternalApplications.id = ccRIAClassPath.id and ccRIAExternalApplications.type = ccRIACatFunExt.id
order by ccRIAExternalApplications.id asc