CREATE PROCEDURE [dbo].[ccsp_Callbacks]
@cam_id as int
AS
select año,mes,dia,hora, callbacks from ccRIACallbacks where cam_id=@cam_id order by año,mes,dia,hora