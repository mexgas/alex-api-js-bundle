CREATE FUNCTION dbo.getDaygroup (@date datetime)
		RETURNS datetime
		AS
		BEGIN
			declare @daygroup datetime
			declare @temp datetime
	
			set @temp= 
				case 
					when DATEPART(hh, @date) < 5 
					then 
					DATEADD(day, -1, @date) 
					else 
						DATEADD(day, 0,@date)
				end 
	
			set @daygroup = CAST(CONVERT(varchar(10), @temp,121) + ' 00:00:00' as datetime)

			RETURN (@daygroup)

		END