CREATE PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
@action tinyint = 0,
@logDial_id int = null
As
Begin

	If @action = 1 begin
		select count(*) from ccologdials with(nolock) where logDial_id >= @logDial_id
	end

	if @action = 2 begin
		select top 500 logDial_id, callout_id, isnull(a.cam_id,0) as camId, isnull(c.cam_descripcion,'') as camDescription,
		isnull(b.descripcion,'Unknown') as DialResult, Telefono, fecha, tDialing, tBusy, isnull(cal_id,0) as cal_id, cal_key
		from ccologdials a with(nolock)
		inner join ccTipoResultadoDial b
		on a.tiporesdial_id = b.tiporesdial_id
		inner join ccCamps c
		on a.cam_id = c.cam_id
		where logDial_id >= @logDial_id
		order by logDial_id
	end

End