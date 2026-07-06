/*
Autor: Jesus Gallardo
Descripcion: CW-2926


Version requerida: 59
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 61
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try



	SET @process = 'CW-2926 Drop Constraint ccCRMNodes'
	SET @Sql = 'declare @nameConstraint varchar(max)
declare @sql varchar(max)


Select @nameConstraint= SysObjects.[Name] 
From SysObjects Inner Join 
(Select [Name],[ID] From SysObjects) As Tab
On Tab.[ID] = Sysobjects.[Parent_Obj] 
Inner Join sysconstraints On sysconstraints.Constid = Sysobjects.[ID] 
Inner Join SysColumns Col On Col.[ColID] = sysconstraints.[ColID] And Col.[ID] = Tab.[ID]
where tab.name=''ccCRMNodes'' and Col.[Name]=''node''


if @nameConstraint is not null begin
	set @sql=''ALTER TABLE ccCRMNodes DROP CONSTRAINT ''+@nameConstraint
	exec( @sql)
end'
	EXEC (@Sql)

		
	------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
