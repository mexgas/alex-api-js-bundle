CREATE PROCEDURE [dbo].[ccsp_OutGenerateAutoinicio]
AS
set nocount on

declare @today smalldatetime
set @today = getdate()

/**************************/
/*** Iniciar la campaña ***/
/**************************/

--Actualiza ccCamps si es necesario iniciar una campaa
update ccCamps set cam_procesando = 1, cam_bNew = 3 where cam_id in	(
--buscar las que se tienen que iniciar por hora
select ccCampsAutoInicio.cam_id from ccCampsAutoInicio
join ccCamps  on ccCamps.cam_id = ccCampsAutoInicio.cam_id
where AutoInicioHora = 1
and hora between dateadd( mi, -10, @today ) and dateadd( mi, 5, @today )
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas

union
--buscar las que se tienen que iniciar con base a otra campaa
select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 0 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.cam_id
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 0
and cai.tiporegistros2 is NULL
and condicion2 is NULL
and numero2 is NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (		
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2) --solo las que estan detendias, para iniciarlas

/**************************/
/*** Detener la campaña ***/
/**************************/

update ccCamps set cam_procesando = 0, cam_bNew = 0 where cam_id in	(
select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 0 -- -- CONDICION (<)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) < cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 1 -- -- CONDICION (>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) > cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 2 -- -- CONDICION (=)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) = cai.numero2

union

select cai.delacampana
from ccCampsAutoInicio cai
join ccCamps  on ccCamps.cam_id = cai.cam_id
where AutoInicio = 1 and cai.condicion = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero
and cam_procesando = 1 --solo las que estan detendias, para iniciarlas
and cai.tiporegistros2 is not NULL
and condicion2 is not NULL
and numero2 is not NULL
and cai.tiporegistros <> cai.tiporegistros2
and cai.condicion2 = 3 -- -- CONDICION (<>)
and (
	select case cai.tiporegistros2 when 0 then new when 1 then cb when 2 then pro end
	from ccCampsNvosCB wt
	where wt.id = cai.delacampana) <> cai.numero2)

set nocount off