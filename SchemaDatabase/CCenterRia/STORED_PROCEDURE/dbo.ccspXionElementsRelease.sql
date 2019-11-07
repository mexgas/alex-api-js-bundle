CREATE PROCEDURE  [dbo].[ccspXionElementsRelease]
@Type as tinyint,
@menu_id as smallint

AS
if @Type = 0
begin
	if (@menu_id=47)
		select menu_id,element from [dbo].[ccXionElementsRelease] where menu_id in(47,10)
	else
		select menu_id,element from [dbo].[ccXionElementsRelease] where menu_id=@menu_id
end