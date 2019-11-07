CREATE function dbo.fn_viewMode (@User_id as smallint, @menu_id as smallint)
returns smallint
as
begin
declare @typeView tinyint, @default tinyint

select @default=valor from ccsettings where setting_id = 113

select @typeView=typeView from 
ccMenu_Views V join ccMenu_ViewsUser U on V.mView_id = U.mView_id
where User_id=@User_id and menu_id=@menu_id
return isnull(@typeView, @default)
end