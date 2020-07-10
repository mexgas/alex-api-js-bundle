CREATE PROCEDURE [dbo].[CofetelUpdateData]
		@type tinyint
		as
		if @type = 1
		begin
			insert into Series
				select * from SeriesTmp
		end
		
		declare @ret bit
		set @ret = 1
		
		select @ret