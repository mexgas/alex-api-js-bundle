CREATE PROCEDURE [dbo].[ccsp_RIAApplyBlist]
@command tinyint,
@agendaid int = 0,
@idcamps int=0,
@fecharegs varchar(22),
@fechaaplica varchar(22),
@idtiposLN int = 0

AS
	if( @command=1)
		begin
			Select isNull(max(idagenda) + 1,'')  from ccagendalistanegra
		end
	If( @command=2)
		begin
			Insert Into ccAgendaListaNegra (idagenda,campsid,fecharegs,fechaaplicar) values (@agendaid,@idcamps,@fecharegs,@fechaaplica)
		end
	if( @command=3)
		begin
			Insert Into ccAgenda_TipoListaNegra (idagenda,idtipolista) values (@agendaid,@idtiposLN)
		end