CREATE PROCEDURE [dbo].[ccspGalatea_Finder]
@action int,
@userId int = 0
AS
if @action = 1 begin--trae el nombre de la base de datos en BX
	select cast( WGCam.IdCampEsp as int) as [Value], cast(WGCam.Tipo as int) as callType, c.cam_descripcion as label
		from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		inner join ccCamps c on  WGCam.IdCampEsp=c.cam_id and WGCam.Tipo=1		
		where Wguser.User_id=@userId
	union
	select cast( WGCam.IdCampEsp as int) as [Value], cast(WGCam.Tipo as int) as callType, inb.descripcion as label
		from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		inner join ccInbound inb on  WGCam.IdCampEsp=inb.Inbound_id and WGCam.Tipo=0
		where Wguser.User_id=@userId
end
else if @action = 2 begin--trae el nombre de la base de datos en BX
	;
	with WgId as(select IDWG from ccRIAWorkGroupUsers Wguser where Wguser.User_id=@userId)

	select distinct cast(Wguser.User_id as int) as [Value],ccUsers.Login as label from ccRIAWorkGroupUsers  Wguser
	inner join WgId on Wguser.IDWG=WgId.IDWG
	inner join ccUsers on ccUsers.User_id =Wguser.User_id and TipoUser_id=1
end