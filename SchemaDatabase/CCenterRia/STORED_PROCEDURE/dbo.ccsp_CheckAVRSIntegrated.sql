CREATE PROCEDURE [dbo].[ccsp_CheckAVRSIntegrated] 
@User_id smallint = 0
AS
Declare @valor tinyint
declare @ver int
set @ver = 0

if @User_id = 0 
begin
Select @valor=valor from ccSettings where setting_id = 124
Select @valor
end
else
begin
Select @valor=valor from ccSettings where setting_id = 124
if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@User_id and per_id in (2,6))
 begin
	set @ver = 1
 end

if (@valor=1 and @ver=1)
begin
 select 1
end
else
begin
 select 0
end
end