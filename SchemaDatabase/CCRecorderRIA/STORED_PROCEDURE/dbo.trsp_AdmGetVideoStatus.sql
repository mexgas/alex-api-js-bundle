CREATE PROCEDURE trsp_AdmGetVideoStatus

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @Sql varchar(MAX),
		@value varchar(2) 
				
set @Sql = (select par_valor from trec_parametros where par_id = 60)
 
 if @Sql = 'FLV' OR @Sql = 'flv' OR @Sql = 'Flv' begin
	set @value = '1'
 end
 else
 begin
	set @value = '0'
 end

select @value

END