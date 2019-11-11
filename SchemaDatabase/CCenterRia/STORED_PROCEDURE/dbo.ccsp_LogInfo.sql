CREATE PROCEDURE ccsp_LogInfo 
@sLogInfo varchar(100),
@iParentInfo smallint = 0
AS

insert ccLogInfo values (getdate(), @sLogInfo, @iParentInfo)