CREATE procedure [dbo].[ccsp_RIAUpdateHangUpAgent]
@IDCall int,
@TipoCall tinyint, --1 = entrada, 2 = salida
@isTransferSurvey bit=0 --0 Callback, 1 Realiza Transferencia inmediata 
as
set nocount on
--declare @cam_id int,@surveycamId int
--declare @cal_telefono varchar(30)
--declare @cal_key varchar(20)
--declare @inbound_id int

if @TipoCall = 1 begin
	UPDATE ccCallsIn   SET cal_whoHung = case when @isTransferSurvey = 0 then 1 else 2 end WHERE cal_id = @IDCall	
end
else begin
	UPDATE ccoCallsOut SET cal_whoHung = case when @isTransferSurvey =0 then 1 else 2 end WHERE cal_id = @IDCall	
end

set nocount off