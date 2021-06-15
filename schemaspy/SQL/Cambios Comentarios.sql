select columnName,count(*) as numColumn from DataInformation 
where comments is null
group by columnName
having count(*)>3
order by numColumn ,columnName


select * from DataInformation where columnName like 'prefix' and comments is null


select * from ccTipoResultadoDial

update DataInformation
set comments='Cantidad de registros en la agrupacion'
where columnName like 'amount' and comments is null

