CREATE view [dbo].[ccGenViewRelsSupsAgent] as

--Relaciones Sup-Agt de acuerdo a WorkGroups
select distinct a1.user_id as agt, a5.user_id as sup, a5.login from ccusers a1 (nolock)
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join
(select a3.user_id, a4.IDWG, a3.login  from ccusers a3 (nolock)
inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)