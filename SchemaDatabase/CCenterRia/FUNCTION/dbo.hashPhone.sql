CREATE FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
  return convert(bigint,@phoneNumber) % 99999999999973
END