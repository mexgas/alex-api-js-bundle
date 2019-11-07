CREATE procedure [dbo].[ccsp_MenuViews]
@superID as int = 0,
@mView_id As smallint = null,
@mode As smallint = null
as
set nocount on
declare @langU as tinyint, @XML as xml
select @langU=valor from ccSettings where setting_id=27

if isnull(@mView_id,0) <= 0
 begin
	SELECT @XML = (
		SELECT * FROM (
			SELECT distinct 1 as TAG, NULL as Parent, [view].menu_id as "view!1!menuId",
				case @langU when 0 then substring(Menu.menu_descrip, 1, charindex('|', Menu.menu_descrip)-1)
			   else substring(Menu.menu_descrip, charindex('|', Menu.menu_descrip)+1, len(Menu.menu_descrip))
			   end as "view!1!menu_descrip", NULL as "viewMode!2!id", NULL as "viewMode!2!selected"
			FROM ccMenu_Views as [view] 
			join ccMenus as Menu on [view].menu_id = Menu.menu_id and [view].type = Menu.type
			join ccMenuUser Users on [view].menu_id = Users.id_menu and [view].type = Users.type
			where [view].status=1 and id_User = @superID
			UNION ALL
			SELECT distinct 2, 1, [view].menu_id, NULL, viewMode.typeView, case when viewMode.typeView = dbo.fn_viewMode (@superID, [view].menu_id) then 1 else 0 end
			FROM ccMenu_Views as viewMode
			join ccMenu_Views as [view] on viewMode.mView_id = [view].mView_id
			where viewMode.status=1
		) X
		ORDER BY "view!1!menuId", tag
		FOR XML EXPLICIT, TYPE
	)
	select @XML
	--select isnull(cast(@XML as varchar(max)),'')
	return(0)
 end

declare @mView_idNew smallint, @mView_idDel smallint, @menu_Log varchar(100), @language tinyint
select @language=valor from ccSettings where setting_id = 27
select @mView_idNew=mView_id from ccMenu_Views where menu_id = @mView_id and typeView = @mode

select @menu_Log=case @language when 0 then substring(menu_descrip, 1, charindex('|',menu_descrip)-1) 
else substring(menu_descrip, charindex('|',menu_descrip)+1, len(menu_descrip)) end
from ccMenus where menu_id=@mView_id

if not exists (select User_id from ccMenu_ViewsUser where User_id=@superID and mView_id=@mView_idNew)
 begin
	select @mView_idDel = a.mView_id FROM ccMenu_Views a join ccMenu_ViewsUser b on a.mView_id = b.mView_id where b.User_id = @superID and a.menu_id = @mView_id
	delete ccMenu_ViewsUser where User_id=@superID and mView_id = @mView_idDel
	insert into ccMenu_ViewsUser select @superID, @mView_idNew
 end

select isnull(@mView_idNew, -1), @menu_Log menu
return(0)

set nocount off