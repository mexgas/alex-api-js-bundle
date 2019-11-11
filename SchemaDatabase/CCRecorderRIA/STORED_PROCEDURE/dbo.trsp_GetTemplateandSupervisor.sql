CREATE PROCEDURE [dbo].[trsp_GetTemplateandSupervisor] 
@type integer = 2,
@sIdChat Integer
AS

declare @supervisor as nvarchar(50)
declare @template as nvarchar(50)

select top 1 @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + ' ' + supervisor.ApellidoPaterno + ' ' + supervisor.ApellidoMaterno)  from
		RIA_FORMATOS as formatos inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
		inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
		where formatosCalif.tipo=@type and formatosCalif.id_grabacion=@sIdChat order by formatosCalif.fecha_calif desc	

select @Template,@supervisor