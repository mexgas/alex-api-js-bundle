CREATE PROCEDURE [dbo].[SPSendCharge]
@CC varchar(20) = '',
@Exp varchar(5) = '',
@CVV varchar(5) = '',
@Charge varchar(7) = '',
@Cents varchar(7) = '',
@Phone varchar(20) = ''
AS
BEGIN
	
	declare @var1 varchar(200)
	declare @url varchar(200)
	declare @var2 varchar(200)
	declare @var3 varchar(200)
	declare @var4 varchar(200)
	declare @response varchar(200)
	declare @newExp varchar(10)
	
	--if len(@Exp)=3 begin
	--	set @Exp = '0' + @Exp
	--end
	
	--set @newExp = '20' + RIGHT(@Exp,2) + '-' + LEFT(@Exp,2)
	--set @var1 = @Phone+'^'+@Charge+'^'+@Cents+'^'+@cc+'^'+@newExp+'^'+@cvv+'^'+@Phone
	--set @url = 'http://localhost/ccws/AuthCharge.asmx/sendData?s=' + @var1 
	
	
	----select @url
	----s=8012091317^35^01^5424000000000015^2020-12^214^8012091317
	
	--select @response = dbo.GetHttp(@url)
	
	
	--select @var2 = value from dbo.fn_RIASplitDelimited(@response,'^') where id =1
	--select @var3 = value from dbo.fn_RIASplitDelimited(@response,'^') where id =2	
	--select @var4 = value from dbo.fn_RIASplitDelimited(@response,'^') where id =3
	
	--insert into IVRLog values(@url,@var2,@var3,@var4,getdate())

	set @var2='1'
	set @var4='123'


	--WAITFOR DELAY '000:01:30'

	select @var2,'ADR'+@Phone,@var4

END