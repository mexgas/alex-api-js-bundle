CREATE PROCEDURE [dbo].[ccsp_RIAMarkHold]
@call_id int,@callType int,@marca int,@status int
--@status 0|1 hold
--@marca Se pone en segundos
AS
set nocount on
	if not exists(select * from RiaMarkHold where tipo_llamada=@callType and tipo_marca= @status and marca = @marca and call_id=@call_id)
		INSERT INTO RiaMarkHold (marca, tipo_marca, tipo_llamada, call_id) VALUES (@marca,@status,@callType,@call_id)	
set nocount off