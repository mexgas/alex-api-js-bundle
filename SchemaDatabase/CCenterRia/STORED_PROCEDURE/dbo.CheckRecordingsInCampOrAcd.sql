CREATE procedure [dbo].[CheckRecordingsInCampOrAcd]
@id integer,
@cam_mode  bit
as
declare @PrefixEnable int
select @PrefixEnable=valor from ccSettings where setting_id = 201
if @PrefixEnable =0 
	select '0'
else
	if (@cam_mode = 0)
		if( exists (select * from ccoCallsOut where cam_id = @id) )
		select ISNULL(prefijo,'') from ccCamps where cam_id =@id
		else
		select '0'
	else

	if( exists (select * from ccCallsIn where inbound_id = @id ) )
		select ISNULL(prefijo,'') from ccInbound where inbound_id = @id
		else
		select '0'