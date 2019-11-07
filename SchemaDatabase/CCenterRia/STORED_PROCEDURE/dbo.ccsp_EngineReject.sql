CREATE procedure ccsp_EngineReject
@ANI as varchar(15),
@DNIS varchar(15),
@Pto smallint
AS
set nocount on
declare @Inbound_id smallint, @cal_id int
select @Inbound_id=ID.Inbound_id from ccInboundDnis ID join ccDnis D on D.dni_id = ID.dni_id where D.dni_numero = @DNIS

insert into ccCallsReject (ani, dnis, puerto) values (@ANI, @DNIS, @Pto)
select @cal_id=SCOPE_IDENTITY()

if isnull(@Inbound_id,0)>0
 begin
	update ccCallsReject set Inbound_id=@Inbound_id where cal_id=@cal_id
 end

set nocount off