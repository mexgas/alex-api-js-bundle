CREATE FUNCTION CambiaLada(@sOld varchar(5), @sNew varchar(5), @sTel varchar(15))
RETURNS varchar(32) AS  
BEGIN
declare @lOld tinyint
declare @lNew tinyint
select @lOld = len(@sOld)
select @lNew = len(@sNew)
declare @sNewTel varchar(15)


select @sNewTel = case len(@sTel) 
	when 7 then '01' + @sOld + @sTel 
	when 8 then '01' + @sOld + @sTel 
	when 12 then case left(@sTel, case when @lOld = 2 then 4 else 5 end) when '01' + @sNew then right(@sTel, 10 - @lNew) else @sTel end 
	when 13 then case left(@sTel, case when @lOld = 2 then 5 else 6 end) when '044' + @sOld then '045' + right(@sTel, 10) else '044' + right(@sTel, 10) end 
	else '' end

return @sNewTel
end