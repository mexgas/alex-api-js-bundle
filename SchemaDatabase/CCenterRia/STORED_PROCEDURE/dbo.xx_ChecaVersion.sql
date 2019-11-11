CREATE procedure [dbo].[xx_ChecaVersion]
@major as integer,
@minor as integer
as

if @major=1 and @minor=15
	select 1 as ok
else
	select 0 as ok