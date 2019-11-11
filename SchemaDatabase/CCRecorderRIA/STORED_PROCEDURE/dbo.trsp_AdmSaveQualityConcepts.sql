-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveQualityConcepts]
	-- Add the parameters for the stored procedure here

@nombre_formato varchar(50),
@numero_concepto int,
@nombre_concepto varchar(80)

AS
BEGIN

Declare @id_formato int, @version int


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

-- Retrieves the id_format from the format created before (RIA_FORMATOS)
set @id_formato = (select distinct id_formato from CCRecorderRIA.dbo.RIA_FORMATOS where nombre = @nombre_formato)
set @version = (select max(version) as version  from CCRecorderRIA.dbo.RIA_FORMATOS where nombre  = @nombre_formato)


--Inserts the concept in RIA_CONCEPTOS
insert CCRecorderRIA.dbo.RIA_CONCEPTOS (id_formato,num_concepto,con_descripcion,version) 
values (@id_formato,@numero_concepto, @nombre_concepto, @version)

select CAST(SCOPE_IDENTITY() as varchar(MAX)) as id_concept

END