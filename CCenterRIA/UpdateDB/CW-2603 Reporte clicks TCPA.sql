create table ClicksByAdmin	(
	id int identity (1,1),
	userId int,
	campId int,	
	clicks int,
	date datetime
	)




create procedure SaveClicksAdminByCamp
 
@User_Id int,
@Camps varchar(1000),
@Clicks varchar(1000)
as

insert into ClicksByAdmin 
select @User_Id,A.Value,B.Value,GETDATE() from dbo.fn_RIASplitDelimited(@Camps,',') A
inner join dbo.fn_RIASplitDelimited(@clicks,',') B on A.Id=B.Id


