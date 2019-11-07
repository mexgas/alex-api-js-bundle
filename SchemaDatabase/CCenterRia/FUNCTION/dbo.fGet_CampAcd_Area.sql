CREATE function [dbo].[fGet_CampAcd_Area] (@user int, @tipo int)
returns @camps table (cam_id int)
as
begin
if (select login from ccusers where user_id=@user) = 'root'
      set @user=0
--solo se corrigio para el usuario root
if @tipo = 3 and @user =0
	set @tipo = 1
if @tipo = 4 and @user =0
	set @tipo = 2

if @tipo = 1 begin
      insert @camps select distinct c.cam_id 
      from ccusers u join ccCamps c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end

else if @tipo = 2 begin
      insert @camps select distinct c.Inbound_id 
      from ccusers u join ccinbound c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end
if @tipo = 3 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp
      from ccusers u with(nolock)
	  inner join ccCamps c with(nolock) on u.IDArea = c.IDArea
	  inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
	  inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=1
      where u.User_id=@user
      end

else if @tipo = 4 begin --Solo trae los seleccionados en el wg
      insert @camps select distinct wgCamAcd.IdCampEsp cam_id from ccUsers u with(nolock)   
	  inner join ccInbound c with(nolock) on c.IDArea= c.IDArea
      inner join ccRIAWorkGroupUsers wg with(index(IX_ccRIAWorkGroupUsers_I),nolock) on wg.User_id=u.User_id
      inner join ccRIACampEspWG wgCamAcd with(index(IX_ccRIACampEspWG_2),nolock) on wgCamAcd.IDWG=wg.IDWG and tipo=0      
      where u.User_id=@user 
      end
return
end