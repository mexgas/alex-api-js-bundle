CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeSubCalif]
	@calif_id int,
	@CallType int

	AS
	BEGIN

	SET NOCOUNT ON;

	IF @CallType = 0 
	BEGIN
	      select distinct(A.califSub_id),A.califSubDesc from cctipocalifsubout as A 
	      inner join cctiposubcalifrel B  on B.calif_id=@calif_id
	      where  B.tipoSubRel=0 and b.califSub_id=A.califSub_id

	END

	ELSE IF @CallType = 1 
	BEGIN
	      select distinct(A.califSub_id),A.califSubDesc from cctipocalifsub as A 
	      inner join cctiposubcalifrel B  on B.calif_id=@calif_id
	      where  B.tipoSubRel=1 and b.califSub_id=A.califSub_id
	END
END