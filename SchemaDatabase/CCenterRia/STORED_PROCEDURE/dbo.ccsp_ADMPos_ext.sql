CREATE PROCEDURE ccsp_ADMPos_ext
@computer varchar(20),
@extension varchar(7)
AS

declare @ext_id as smallint

	select @ext_id = ext_id from ccMonitorExt where extension=@extension

	if ( @ext_id is not null )
	begin
		if ( select count(*) from ccPosicion where computer= @computer
		) > 0
		begin
			update ccPosicion set ext_id=@ext_id where computer= @computer

			select 0, 'Update Computer: ' + @computer +' ->' +@extension
		end
		else
		begin
			Insert ccPosicion ( computer, ext_id )	Values ( @computer, @ext_id )
		
			select -1, 'Add Computer: ' + @computer +' ->' +@extension
		end
	end