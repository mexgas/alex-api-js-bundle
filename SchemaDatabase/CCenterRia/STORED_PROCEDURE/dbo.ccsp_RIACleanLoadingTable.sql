CREATE PROCEDURE [dbo].[ccsp_RIACleanLoadingTable]
AS
BEGIN

	delete from ccrialoading
	where loadDate < convert (datetime, convert (varchar(11), dateadd(mm,-1,getDate())))

END