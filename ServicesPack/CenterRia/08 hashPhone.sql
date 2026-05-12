USE [CCenterRIA]
GO
/****** Object:  UserDefinedFunction [dbo].[hashPhone]    Script Date: 12/03/2026 11:42:19 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
	set @phoneNumber=dbo.Limpia(@phoneNumber)
	if @phoneNumber='' or @phoneNumber is null return 0

  return convert(bigint,@phoneNumber) % 99999999999973
END
