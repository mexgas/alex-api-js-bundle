CREATE PROCEDURE [dbo].[CS_getVersion]
  @directive NVARCHAR(4) = NULL,
  @Version int=null
        AS
  BEGIN

  if @directive not in ('BD') and @directive is not null 
  begin
    select 'version module not suitable'
    return (0)
  end
  else 
  begin if isnull(@version,0) = 0
  begin
      select @version =Value from CsSettings where Id=1  
      select @Version
      return (@version)
  end
  end
  END