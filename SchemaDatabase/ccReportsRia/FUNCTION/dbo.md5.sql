CREATE FUNCTION [dbo].[md5] (@data varchar(255)) 
RETURNS CHAR(32) AS
BEGIN
  return UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(HashBytes('MD5', lower(@data))), 3, 32))  
END