CREATE PROCEDURE [dbo].[trsp_AgtHasRecordingMark]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @count int
set @count =(select COUNT(*) from ria_marcas where call_id = @cal_id and tipo_llamada = @tipo_llamada)

if @count>1 begin
select '1'
end
else
begin
select '0'
end

END