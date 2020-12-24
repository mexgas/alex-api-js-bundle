-- =============================================
-- Author: UEspinosa
-- Create date: 16/12/2020
-- Description:	Sabe to ccRIALog
-- =============================================
CREATE PROCEDURE ccsp_GalateaRIALog
@userId           SMALLINT,
@OperationType    VARCHAR(MAX)= '',
@Value			  VARCHAR(40) = '',
@Module			  SMALLINT,
@target			  VARCHAR(40) = ''
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#OperationType') IS NOT NULL DROP TABLE #OperationType
	create table #OperationType(
			id smallint IDENTITY(1,1),
			operationType varchar(MAX)
	)
	insert into #OperationType SELECT value FROM fn_RIASplitDelimited(@OperationType, ',')	

	IF OBJECT_ID('tempdb..#Value') IS NOT NULL DROP TABLE #Value
	create table #Value(
			id smallint IDENTITY(1,1),
			value varchar(MAX)
	)
	insert into #Value SELECT value FROM fn_RIASplitDelimited(@Value, '^^')
	
	IF OBJECT_ID('tempdb..#Params') IS NOT NULL DROP TABLE #Params
	select operationType,value 
	into #Params
	from #OperationType o
	inner join #Value v with(nolock) on o.id = v.id


	IF OBJECT_ID('tempdb..#PreLog') IS NOT NULL DROP TABLE #PreLog
	create table #PreLog(
			areaName varchar(40),
			operatioDate DATETIME,
			login varchar(40),
			module_id smallint,
			target varchar(40)
	)
	insert into #PreLog
	select AreaName, GETDATE() as operatioDate,u.login,@Module module_id,@target as target
	from ccUsers U
	INNER JOIN ccRIACat_Areas A with(nolock) on u.IDArea = a.IDArea
	where U.User_id = @userId

	Insert into ccRIALog
	select areaName,operatioDate,operationType,login,module_id,value,target
	from #PreLog,#Params

	IF OBJECT_ID('tempdb..#OperationType') IS NOT NULL DROP TABLE #OperationType
	IF OBJECT_ID('tempdb..#Value') IS NOT NULL DROP TABLE #Value
	IF OBJECT_ID('tempdb..#Params') IS NOT NULL DROP TABLE #Params
	IF OBJECT_ID('tempdb..#PreLog') IS NOT NULL DROP TABLE #PreLog
	Select 1
	return
END