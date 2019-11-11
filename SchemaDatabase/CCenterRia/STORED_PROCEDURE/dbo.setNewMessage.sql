create PROCEDURE dbo.setNewMessage
@archivo varchar(255),
@calId int
 AS
insert into ccRIA_vmMessages (archivo, cal_id)values( @archivo, @calId)