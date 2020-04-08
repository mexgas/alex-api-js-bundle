CREATE PROCEDURE [dbo].[CofetelUpdateData]
@type tinyint
as
if @type = 1
begin
	insert into Series
select * from SeriesTmp
end