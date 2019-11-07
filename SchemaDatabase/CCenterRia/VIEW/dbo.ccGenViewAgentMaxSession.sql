CREATE VIEW dbo.ccGenViewAgentMaxSession
AS
select
	case
		when x.user_id is not null then x.user_id
		when y.user_id is not null then y.user_id
		else 0
	end as user_id,
-- 	case
-- 		when x.dia is not null then x.dia
-- 		when y.dia is not null then y.dia
-- 		else null
-- 	end as dia,
	case
		when x.lastCallEnd is null then y.lastCallEnd
		when y.lastCallEnd is null then x.lastCallEnd
		when x.lastCallEnd > y.lastCallEnd then x.lastCallEnd
		when y.lastCallEnd > x.lastCallEnd then y.lastCallEnd
		else null
	end as lastCall
from
(
	select
	user_id, 
	convert( varchar(10), cal_Inicio, 121) dia,
	max( dateadd( ss, 0.0 + cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas , cal_Inicio)) as lastCallEnd
	from ccoCallsOut
	where StatusCall_id > 10 and user_id > 0
	group by user_id, convert( varchar(10), cal_Inicio, 121)
	--order by user_id, convert( varchar(10), cal_Inicio, 121)
) x
full join
(
	select 
	user_id, 
	convert( varchar(10), cal_Inicio, 121) dia,
	max( dateadd( ss, 0.0+ cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas , cal_Inicio)) as lastCallEnd
	from ccCallsIn
	where ((statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL)) and user_id > 0
	group by user_id, convert( varchar(10), cal_Inicio, 121)
	--order by user_id, convert( varchar(10), cal_Inicio, 121)
)y
on x.user_id = y.user_id and x.dia = y.dia


-- SELECT     TOP 100 PERCENT user_id, DATEPART(dw, logout) AS dw, MAX(logout) AS maxLogout
-- FROM         dbo.ccGenSession
-- WHERE     (RIGHT(CONVERT(varchar(23), logout, 121), 12) <> '23:59:59.997')
-- GROUP BY user_id, DATEPART(dw, logout)