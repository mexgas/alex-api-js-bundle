CREATE procedure [dbo].[ccsp_RIAGetNotReadyTypes_xUser]
@user_id int
as
set nocount on

declare @NotReadybyCampACD int
select @NotReadybyCampACD = valor from ccsettings where setting_id = 135

declare @NotReadyRestricted tinyint
set @NotReadyRestricted =0
select @NotReadyRestricted = NotReadyRestricted from ccUsers where User_id = @user_id

if (@NotReadybyCampACD = 0)
	begin
		select a1.TipoNotReady_id, Descripcion, frame, 
		dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()) as NumEvents, @NotReadyRestricted NotReadyRestricted,
		CONVERT(CHAR(8),DATEADD(second,time_Acum,0),108) as maxTimeAcum
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on a1.tiponotready_id = a2.tiponotready_id
		inner join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		where a1.TipoNotReady_id > 0 and a1.IsSup = 0
	end
else if (@NotReadybyCampACD = 1)
	begin
		select a1.TipoNotReady_id, Descripcion, frame, dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate()) as NumEvents, @NotReadyRestricted NotReadyRestricted,
		CONVERT(CHAR(8),DATEADD(second,time_Acum,0),108) as maxTimeAcum
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id = a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = 0
		and a4.idCampACD in (select distinct(inbound_id) from ccInboundAgentes where user_id = @user_id)
		AND a4.type = 0
		union
		select a1.TipoNotReady_id, Descripcion, frame, dbo.NeventsNRdisp(@user_id, a1.tiponotready_id, getdate())as NumEvents, @NotReadyRestricted NotReadyRestricted,
		CONVERT(CHAR(8),DATEADD(second,time_Acum,0),108) as maxTimeAcum
		from ccTipoNotReady a1 
		inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id = a2.tiponotready_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		inner join ccUnavailableRelation a4 on (idunavailable = a1.tiponotready_id)
		where a1.TipoNotReady_id > 0 
		and a1.IsSup = 0
		and a4.idCampACD in (select distinct(cam_id) from ccCampsAgente where user_id = @user_id)
		AND a4.type = 1
	end

return(0)

set nocount off