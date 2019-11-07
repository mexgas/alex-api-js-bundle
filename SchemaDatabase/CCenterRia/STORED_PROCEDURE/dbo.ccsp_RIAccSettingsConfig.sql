CREATE PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null
AS
set nocount on
declare @idioma tinyint
declare @activeChat tinyint
select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145
if @command=0
  begin
  SELECT case @idioma when 0 then descripcion 
            --when 2 then DescripcionPT 
            else [description] 	end descripcion
  FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
  order by descripcion
  return(0)
  end

if @command=1
  begin
  Select setting_id, 
		case @idioma  when 0 then descripcion 
            --when 2 then DescripcionPT 
            else [description] end descripcion,
			valor, tipo,validate
  from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in ('AGT','ADM','GRL','REP','SV')
  and (setting_id not in (139,140,141)
  or   setting_id     in (139,140,141) and @activeChat > 0)
  order by tipo, descripcion
  return(0)
  end

if @command=2
  begin
  if @setting_id = 27 and @value not in('0','1','2') begin
    set @value = 0
  end
  else if @setting_id = 104 and @value not in('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16') begin
    set @value = 1
  end
  update ccSettings set valor=@value where setting_id = @setting_id
  return(0)
  end
set nocount off