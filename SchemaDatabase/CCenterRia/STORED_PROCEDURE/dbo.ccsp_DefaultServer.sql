CREATE PROCEDURE [dbo].[ccsp_DefaultServer]

AS

declare @IsDefault as tinyint

select @IsDefault = valor from ccSettings where setting_id = 72

If ( @IsDefault = 1)
	begin
		select valor from ccSettings where setting_id = 73
	end
else
	begin
		select '0,0,0,0,0'
	end