CREATE PROCEDURE [dbo].[cc_DNCKillList]
	
AS
BEGIN
	DECLARE @minTime AS INT 
	declare @killListID int = (SELECT idtipolista FROM ccTiposListaNegra WHERE Tipolista = 'default/KillList')
	declare @killListSetting int = (select status from ccSettings where setting_id = 215)

	if(@killListSetting = 1)
	begin
		select @minTime = valor from ccSettings where setting_id = 215

	create table #temp(
		hashtel int not null
	)
	insert into #temp
	select a.hashtel from cc_killlist a inner join ccListaNegra b 
	on a.Hashtel = b.hashTel 
	WHERE datediff(HH, [date],getdate()) > @minTime

	delete from cc_KillList where hashTel in (select hashtel from #temp)
	delete from ccListaNegra where Hashtel in (select hashtel from #temp) and idtipolista = @killListID

	drop table #temp
	end
END