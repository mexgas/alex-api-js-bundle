CREATE PROCEDURE [dbo].[ccsp_SaveLogoutLastState]
@UserID smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@call_id int=0,
@tDialog int =0 ,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@fecha datetime=null,
@tMusicHold int=0
AS
set nocount on

if @fecha is null set @fecha=getdate()

exec ccsp_AgentLogINOUT @UserID=@UserID,@Extension=@Extension,@Computer=@Computer,@TipoMov=0,@fecha=@fecha
exec ccsp_SaveStatusAgent @User_id=@UserID,@TipoStatusAge_id=@TipoStatusAge_id,@TipoNotReady=@TipoNotReady,@tStatus=@tStatus,@TipoCall=@TipoCall,@Camp=0,@callout_id=0,@call_id=@call_id,@isLogout=1,@tDialog =@tDialog,@Fecha4=@fecha,@tMusicHold=@tMusicHold