CREATE PROCEDURE [dbo].[trsp_GetLabelForBackUp]
@LabelDate DATETIME,
@Grupos INTEGER
AS

DECLARE @LabelMain AS VARCHAR(20)
DECLARE @Label AS VARCHAR(20)
DECLARE @Label3 AS VARCHAR(20)
DECLARE @iLabel AS VARCHAR(20)
DECLARE @Label2 AS VARCHAR(20)
declare @Integrado as int

select @integrado =count(*) from trec_parametros where par_id = 29
if @integrado > 0
	select @integrado = par_valor from trec_parametros where par_id = 29

IF @Grupos > 1
BEGIN
	SELECT @iLabel=1	
LabelLoop:
	SELECT @Label=CONVERT(VARCHAR,YEAR(@LabelDate))+'_'+CONVERT(VARCHAR,MONTH(@LabelDate))+'_'+CONVERT(VARCHAR,DAY(@LabelDate))+'_'+CONVERT(VARCHAR,@ilabel)
	if (@integrado = 1) or (@integrado = 2)
		SELECT @Label3 = 'N'+@Label +'_A'
	else
		SELECT @Label3 = @Label +'_A'
	SELECT @Label2=[id] FROM TREC_ARCHIVO_GRABACION WHERE [id]=@Label3
	--SELECT @Label2, @Label3, @Label
	IF (@Label2 = @Label3)
	BEGIN
		SELECT @iLabel=@iLabel+1
		GOTO LabelLoop
	END
	SELECT @Label=CONVERT(VARCHAR,YEAR(@LabelDate))+'_'+CONVERT(VARCHAR,MONTH(@LabelDate))+'_'+CONVERT(VARCHAR,DAY(@LabelDate))+'_'+CONVERT(VARCHAR,@ilabel)
	SELECT @Label2=[id] FROM TREC_ARCHIVO_GRABACION WHERE [id]=@Label3
	if (@integrado = 1) or (@integrado = 2)
		SELECT @Label3 = 'N'+@Label +'_B'
	else
		SELECT @Label3 = @Label +'_B'
	IF (@Label2 = @Label3)
	BEGIN
		SELECT @iLabel=@iLabel+1
		GOTO LabelLoop
	END
END
ELSE
BEGIN
	SELECT @iLabel=1	
LabelLoopOne:
	SELECT @Label=CONVERT(VARCHAR,YEAR(@LabelDate))+'_'+CONVERT(VARCHAR,MONTH(@LabelDate))+'_'+CONVERT(VARCHAR,DAY(@LabelDate))+'_'+CONVERT(VARCHAR,@ilabel)
	if (@integrado = 1) or (@integrado = 2)
		SELECT @Label3 = 'N'+@Label
	else
		SELECT @Label3 = @Label
	SELECT @Label2=[id] FROM TREC_ARCHIVO_GRABACION WHERE [id]=@Label3
	IF (@Label2=@Label3)
	BEGIN
		SELECT @iLabel=@iLabel+1
		GOTO LabelLoopOne
	END
END

if (@integrado = 1) or (@integrado = 2)
	SELECT 'Label'='N'+@Label
else
	SELECT 'Label'= @Label