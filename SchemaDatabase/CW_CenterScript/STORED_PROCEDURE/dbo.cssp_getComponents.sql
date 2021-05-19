CREATE PROCEDURE [dbo].[cssp_getComponents]
				@Template_id int
			AS
			set nocount on;

			Select 1 as Component_id,Template_id,i,x,y,w,h,Text,Name,'' as ComponentProps from dbo.labelComponent where Template_id = @Template_id
			union all
			Select 2 as Component_id,Template_id,i,x,y,w,h,Path,Name as Text,'' as ComponentProps from dbo.ImageComponent where Template_id = @Template_id
			union all
			Select Component_id,Template_id,i,x,y,w,h,Text,Name,Properties as ComponentProps from dbo.Components_per_Template where Template_id = @Template_id
			union all
			Select Component_id,Template_id,i,x,y,w,h,'' as Text,Name,'ReadOnly:true' as ComponentProps from dbo.componentsRelation where Template_id = @Template_id