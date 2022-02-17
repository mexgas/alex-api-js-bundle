CREATE PROCEDURE ccsp_GalateaGetTodaySessionTime
	AS
	BEGIN
		;with t as(
		select A.User_id,A.fecha login,S.fecha logout, DATEDIFF(ss,A.fecha,S.fecha) tlog
		from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha--convert(varchar(19),fecha,121) fecha
		from ccLogLogin a with(nolock) where convert(Date, fecha) = CONVERT(date, GETDATE())
		)A
		left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a with(nolock)  
		where  convert(Date, fecha) = CONVERT(date, GETDATE())
		) S
		on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
		where A.TipoMov=1
		)
		select CAST(user_id AS INT) AgentId,max(login) LastLogin, Isnull(sum(tlog), 0) TLoggedIn from t group by user_id
	END