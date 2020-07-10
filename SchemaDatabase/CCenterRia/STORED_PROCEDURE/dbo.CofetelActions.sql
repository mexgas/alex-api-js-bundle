CREATE PROCEDURE [dbo].[CofetelActions]
		@type tinyint
		as
		if @type = 1
		begin
			truncate table SeriesTmp
		end
		
		if @type = 2
		begin
			truncate table Series
		end
		
		declare @ret bit
		set @ret = 1
		
select @ret