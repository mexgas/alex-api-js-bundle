CREATE PROCEDURE xx_ChecaHorario
		as
		declare @hora integer

		set  @hora = datepart( hh, getdate())

		if @hora > 6 or @hora < 22
			select 1 as ok	-- valido (dentro de horario de operaciones)
		else
			select 0 as ok -- invalido (fuera de horario de operaciones)