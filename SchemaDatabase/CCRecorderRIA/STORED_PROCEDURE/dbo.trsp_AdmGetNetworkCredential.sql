CREATE PROCEDURE [dbo].[trsp_AdmGetNetworkCredential]
@domain varchar(50)
AS
BEGIN
	
	SELECT [domain],[user],[password]
	FROM RIA_NETWORKCREDENTIALS
	WHERE domain like @domain

END