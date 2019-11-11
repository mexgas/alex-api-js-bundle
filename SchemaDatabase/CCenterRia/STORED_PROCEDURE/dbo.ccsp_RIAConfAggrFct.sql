create PROCEDURE dbo.ccsp_RIAConfAggrFct
@Type tinyint,    -- 1:Muestra | 2:Actualiza Camp | 3:Actualiza Todas por Usuario
@cam_id varchar(255) = null,
@User_id int = null,
@aggressionFactor float = null
AS
set nocount on
if @Type=1
 begin
    select cam_id, cam_Descripcion, aggressionFactor
    from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
    order by cam_descripcion
    return(0)
 end

if @Type=2
 begin
    UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor) 
    Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, ','))
    return(0)
 end

if @Type=3
 begin
    UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
    Where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
    return(0)
 end

set nocount off