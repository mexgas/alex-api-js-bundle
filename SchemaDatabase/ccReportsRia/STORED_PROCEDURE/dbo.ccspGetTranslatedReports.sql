CREATE procedure [dbo].[ccspGetTranslatedReports] @id int as
declare @columns nvarchar(max)
select @columns =[columns] from [TranslatedReports] where id = @id
if @columns is null begin
	set @columns=''
end

select @columns [columns]