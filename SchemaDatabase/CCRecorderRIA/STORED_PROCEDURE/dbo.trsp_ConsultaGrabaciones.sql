CREATE PROCEDURE [dbo].[trsp_ConsultaGrabaciones]
@tipoGrabacion  varchar(255),
@incluidos  varchar(5000),
@inicio datetime = 0,
@fin datetime = 0,
@duracionMin int = 0,
@duracionMax int = 0

AS

declare @fecha datetime

set @fecha = CAST(convert(VARCHAR(8), GETDATE()-31, 1) AS DATETIME)

if (@inicio > @fecha)
begin
select g.grab_id as Num, g.extension as Ext, g.finicio as Inicio, g.duracion as Duracion, age_id as Agente, puerto_id as Puerto
from RIA_GRABACION g with (index(IX_RIA_GRABACION_5)) 
where g.duracion > 5
end
else
begin
select g.grab_id as Num, g.extension as Ext, g.finicio as Inicio, g.duracion as Duracion, age_id as Agente, puerto_id as Puerto
from RIA_GRABACIONCONSULTA g with (index(IX_RIA_GRABACIONCONSULTA_5)) 
where g.duracion > 5
end

/*Select g.age_id, a.age_ap_paterno, a.age_ap_materno, a.age_nombre, g.grab_id, g.tipo_grab_id, g.cli_id, g.finicio, g.dvd_id, g.ani, 
g.tamano, g.dni, g.nombre_archivo, g.duracion, c.cli_nombre, g.extension, g.pos_pc  
>From TREC_GRABACION g, TREC_AGENTE a, TREC_CLIENTE c, TREC_MONITOR_EXTENSION b 
Where g.age_id *= a.age_id  and g.cli_id *= c.cli_id and g.extension*= b.mon_extension and duracion > 5
*/