CREATE FUNCTION fGetReqTime (@hour AS datetime, @user_id AS smallint)  
RETURNS int 
AS  
BEGIN 
DECLARE @ret AS int
SELECT @ret=ISNULL(DATEDIFF(s,  CASE WHEN start1>start2 THEN start2 ELSE start1 END,  CASE WHEN end1>end2 THEN end2 ELSE end1 END), 0)
 FROM (
		SELECT type
			, CASE WHEN t1 >= start1 THEN t1 ELSE start1 END AS start1
			, CASE WHEN DATEADD(hh, 1, t1) <= end1 THEN DATEADD(hh, 1, t1) ELSE end1 END AS end1
			, CASE WHEN t2 >= start2 THEN t2 ELSE start2 END AS start2
			, CASE WHEN DATEADD(hh, 1, t2) <= end2 THEN DATEADD(hh, 1, t2) ELSE end2 END AS end2
		 FROM (
				SELECT MAX(type) AS type
					, DATEADD(s, DATEDIFF(s, CAST(0 as datetime), MAX(CASE WHEN (type>0) AND (start1 > end1) AND CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime) < end1 THEN DATEADD(d, 1,  CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime)) ELSE  CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime) END)), CAST((CONVERT(varchar, @hour, 12)) AS smalldatetime)) AS t1
					, DATEADD(s, DATEDIFF(s, CAST(0 as datetime), MAX(CASE WHEN (type>0) THEN start1 ELSE NULL END)), CAST((CONVERT(varchar, @hour, 12)) AS smalldatetime)) AS start1
					, DATEADD(s, DATEDIFF(s, CAST(0 as datetime), MAX(CASE WHEN (type>0) AND (start1 > end1) THEN DATEADD(d, 1, end1) WHEN (type>0) THEN end1 ELSE NULL END)), CAST((CONVERT(varchar, @hour, 12)) AS smalldatetime)) AS end1
					, DATEADD(s, DATEDIFF(s, CAST(0 as datetime), MAX(CASE WHEN (type>1) AND (start2 > end2) AND  CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime) < end2 THEN DATEADD(d, 1,  CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime)) ELSE  CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime) END)), CAST((CONVERT(varchar, @hour, 12)) AS smalldatetime)) AS t2
					, DATEADD(s, DATEDIFF(s, CAST(0 as datetime), MAX(CASE WHEN (type>1) THEN start2 ELSE NULL END)), CAST((CONVERT(varchar, @hour, 12)) AS smalldatetime)) AS start2
					, DATEADD(s, DATEDIFF(s, CAST(0 as datetime), MAX(CASE WHEN (type>1) AND (start2 > end2) THEN DATEADD(d, 1, end2) WHEN (type>1) THEN end2 ELSE NULL END)), CAST((CONVERT(varchar, @hour, 12)) AS smalldatetime)) AS end2
				 FROM (
						(
						SELECT type, start1, end1, start2, end2
						 FROM ccTimetabledetail
							INNER JOIN ccTimetable ON (ccTimetable.[id]=ccTimetabledetail.timetable)
						 WHERE [user_id] = 3 AND startdate <= CAST((CONVERT(varchar, @hour, 12)) AS datetime) AND enddate >= CAST((CONVERT(varchar, @hour, 12)) AS datetime)
							AND (((fixed = 1) AND ([weekday] = 0) AND ((days & dbo.fGetWeekdayMask(@hour)) > 0)) 
							      OR ((fixed = 0) AND ([weekday] = dbo.fGetWeekday(@hour))))
						
						AND (
							(
								(type > 0)
								 AND 
								(
									(
										(start1 < end1)
									 AND
										((CAST((CONVERT(varchar(2), start1, 8) + ':00') AS smalldatetime)) <= CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
									 AND
										(end1 > CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
									)
									OR
									(
										(start1>=end1)
									 AND 
										(
											(
												(@hour < start1)
												 AND 
												((CAST((CONVERT(varchar(2), start1, 8) + ':00') AS smalldatetime)) <= CAST((CONVERT(varchar, DATEADD(d, 1, @hour), 8)) AS smalldatetime))
												 AND 
												(DATEADD(d, 1, end1) > CAST((CONVERT(varchar, DATEADD(d, 1, @hour) , 8)) AS smalldatetime))
											)
											OR
											(
												(@hour >= start1)
												 AND 
												((CAST((CONVERT(varchar(2), start1, 8) + ':00') AS smalldatetime)) <= CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
												 AND 
												(DATEADD(d, 1, end1) > CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
											)
										)
									)
								)
							)
							OR
							(
								(type > 1)
								 AND 
								(
									(
										(start2 < end2)
									 AND
										((CAST((CONVERT(varchar(2), start2, 8) + ':00') AS smalldatetime)) <= CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
									 AND
										(end2 > CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
									)
									OR
									(
										(start2>=end2)
									 AND 
										(
											(
												(@hour < start2)
												 AND 
												((CAST((CONVERT(varchar(2), start2, 8) + ':00') AS smalldatetime)) <= CAST((CONVERT(varchar, DATEADD(d, 1, @hour), 8)) AS smalldatetime))
												 AND 
												(end2 > CAST((CONVERT(varchar, DATEADD(d, 1, @hour) , 8)) AS smalldatetime))
											)
											OR
											(
												(@hour >= start2)
												 AND 
												((CAST((CONVERT(varchar(2), start2, 8) + ':00') AS smalldatetime)) <= CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
												 AND 
												(end2 > CAST((CONVERT(varchar, @hour, 8)) AS smalldatetime))
											)
										)
									)
								)
							)
						)
					)
				) xOrigHoursDetail
			) xRealHoursDetail
	) xTimeCalculation
RETURN(@ret)
END