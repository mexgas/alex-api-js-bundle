CREATE PROCEDURE [dbo].[ccsp_RIAADMTemplates]
@Descripcion varchar(40),
@template_id smallint,
@user smallint,
@Tipo tinyint
AS

Declare @templ as smallint
	if ( @Tipo=1 )
	begin
		Select * from ccTemplates where user_id = @user
	end
	if ( @Tipo=2 )
	begin
		if ( select count(*) from ccTemplates where descripcion = @Descripcion and user_id = @user
		) > 0
			select 1, 'Nombre en Uso'
		else
		begin
			Insert ccTemplates ( descripcion, user_id )  Values( @Descripcion, @user )		
			select @templ = scope_identity()
			end
	end
	if ( @Tipo=3 )
	begin
		Update ccTemplates set descripcion= @Descripcion where template_id = @template_id
	end
	if ( @Tipo=4 )
	begin
		Delete ccTemplates Where template_id = @template_id
		Delete ccCampsTemplates Where template_id = @template_id
	end
	if ( @Tipo=5 )
	begin
		DELETE ccCampsTemplates WHERE template_id = @template_id
		--insert into ccCampsTemplates
		--select  template , * from "
		--(select  0 as tipo, inbound_id as cam_id, user_id, prioridad, skill from ccInboundAgentes where inbound_id in ( select cam_id from ccSupervisorCam where tipo = 0 and user_id = " & gUserID & ") "
		--Union
		--select 1, cam_id, user_id,prioridad, skill from ccCampsAgente where cam_id in ( select cam_id from ccSupervisorCam where tipo =1 and user_id = " & gUserID & "))actual"
	end