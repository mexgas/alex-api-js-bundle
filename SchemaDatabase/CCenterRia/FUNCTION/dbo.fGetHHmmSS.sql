CREATE FUNCTION dbo.fGetHHmmSS (@time integer)  
RETURNS varchar(10)
AS  
BEGIN 
	DECLARE @horas varchar(4)
	DECLARE @min varchar(4)
	DECLARE @seg varchar(4)
	DECLARE @Tiempo varchar(10)
             DECLARE @Temp integer

	set @horas =  @time / 3600
             set @Temp =  @time % 3600
             set @min =  @Temp / 60
             set @seg = @Temp % 60

              set @Tiempo = case when convert(varchar(3),@horas) = 0 then '00' when convert(varchar(3),@horas) < 10 then '0'+ convert(varchar(3),@horas) else convert(varchar(3),@horas) end + ':'+case when convert(varchar(2),@min) = 0 then '00' when convert(varchar(2),@min) < 10 then '0'+convert(varchar(2),@min) else convert(varchar(2),@min) end + ':'+case when convert(varchar(2),@seg)  = 0 then '00' when convert(varchar(2),@seg)  < 10 then '0'+convert(varchar(2),@seg) else convert(varchar(2),@seg)  end

	RETURN (@Tiempo)
END