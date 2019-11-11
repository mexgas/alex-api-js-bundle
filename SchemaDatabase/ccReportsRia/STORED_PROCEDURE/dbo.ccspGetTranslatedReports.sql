create procedure [dbo].[ccspGetTranslatedReports] @id int as

select [columns]
from [TranslatedReports]
where id = @id