-- Dropando a tabela temporária, caso ela exista.
DROP TABLE IF EXISTS #atividade_ultimo_tramite;

-- Criando a tabela temporária, caso ela ainda não exista.
CREATE TABLE  #atividade_ultimo_tramite (
    id_protocolo integer,
    id_atividade integer,
    id_unidade integer,
    dth_conclusao DateTime,
	situacao VARCHAR(50),
	responsavel CHAR(4) -- MCOM ou MCTI,
	PRIMARY KEY (id_protocolo, id_atividade)
);


-- Populando a tabela temporária com os dados dos últimos trâmites dos processos do MCOM
INSERT INTO #atividade_ultimo_tramite
SELECT 
	ativ2.id_protocolo, ativ2.id_atividade, ativ2.id_unidade, ativ2.dth_conclusao, 
	case
		when ativ2.dth_conclusao IS NULL then 'aberto'
		else 'fechado'
	end as 'situacao',
	'MCOM' as 'responsavel'
FROM atividade as ativ2
JOIN protocolo as prot2 ON ativ2.id_protocolo = prot2.id_protocolo
JOIN unidade as unid2 ON unid2.id_unidade = ativ2.id_unidade
JOIN orgao as org2 ON org2.id_orgao = unid2.id_orgao
WHERE ativ2.id_atividade = (
	SELECT TOP(1) 
	ativ.id_atividade
	FROM atividade as ativ
	JOIN protocolo as prot ON ativ.id_protocolo = prot.id_protocolo
	JOIN unidade as unid ON unid.id_unidade = ativ.id_unidade
	JOIN orgao as org ON org.id_orgao = unid.id_orgao
	WHERE prot.sta_protocolo = 'P'
	AND (
		ativ.dth_conclusao IS NULL OR (
			(ativ.id_tarefa IN (28, 41) and prot.sta_nivel_acesso_global <> '2') /*CONCLUSÃO NA UNIDADE*/ OR
			(ativ.id_tarefa = 63 and prot.sta_nivel_acesso_global = '2') /*CONCLUSÃO PELO USUÁRIO*/
		)
	)
	AND org.sigla = 'MCOM'
	AND prot2.id_protocolo = prot.id_protocolo
	ORDER BY 
		COALESCE(ativ.dth_conclusao, CAST('9999-12-31 23:59:59.997' AS DateTime)) DESC, 
		ativ.dth_abertura DESC
);

-- Populando a tabela temporária com os dados dos últimos trâmites dos processos do MCTI
INSERT INTO #atividade_ultimo_tramite
SELECT 
	ativ2.id_protocolo, ativ2.id_atividade, ativ2.id_unidade, ativ2.dth_conclusao, 
	case
		when ativ2.dth_conclusao IS NULL then 'aberto'
		else 'fechado'
	end as 'situacao',
	'MCTI' as 'responsavel'
FROM atividade as ativ2
JOIN protocolo as prot2 ON ativ2.id_protocolo = prot2.id_protocolo
JOIN unidade as unid2 ON unid2.id_unidade = ativ2.id_unidade
JOIN orgao as org2 ON org2.id_orgao = unid2.id_orgao
WHERE ativ2.id_atividade = (
	SELECT TOP(1) 
	ativ.id_atividade
	FROM atividade as ativ
	JOIN protocolo as prot ON ativ.id_protocolo = prot.id_protocolo
	JOIN unidade as unid ON unid.id_unidade = ativ.id_unidade
	JOIN orgao as org ON org.id_orgao = unid.id_orgao
	WHERE prot.sta_protocolo = 'P'
	AND (
		ativ.dth_conclusao IS NULL OR (
			(ativ.id_tarefa IN (28, 41) and prot.sta_nivel_acesso_global <> '2') /*CONCLUSÃO NA UNIDADE*/ OR
			(ativ.id_tarefa = 63 and prot.sta_nivel_acesso_global = '2') /*CONCLUSÃO PELO USUÁRIO*/
		)
	)
	AND org.sigla <> 'MCOM'
	AND prot2.id_protocolo = prot.id_protocolo
	ORDER BY 
		COALESCE(ativ.dth_conclusao, CAST('9999-12-31 23:59:59.997' AS DateTime)) DESC, 
		ativ.dth_abertura DESC
);

-- Obtendo a lista de processos e seu responsável
SELECT
	DISTINCT
	case
		when prot_ambos_orgaos.id_protocolo is not null and prot_aberto_mcom.situacao = 'aberto' and prot_aberto_mcti.situacao = 'fechado' then 'MCOM'
		when prot_ambos_orgaos.id_protocolo is not null and prot_aberto_mcom.situacao = 'fechado' and prot_aberto_mcti.situacao = 'aberto' then 'MCTI'
		else COALESCE(prot_ambos_orgaos.responsavel_processo, prot_aberto_mcom.responsavel_processo, prot_aberto_mcti.responsavel_processo) 
	end as 'responsavel',
	protocolo.id_protocolo,
	protocolo.protocolo_formatado,
    protocolo.descricao,
    tipo_procedimento.id_tipo_procedimento,
	tipo_procedimento.nome,
	protocolo.dta_inclusao,
    protocolo.id_unidade_geradora,
    org.sigla as 'sigla_orgao_geradora', 
    unid.sigla as 'sigla_unidade_geradora', 
    unid.descricao as 'descricao_unidade_geradora',
    
	prot_aberto_mcti.dth_conclusao as 'mcti_dth_conclusao',
    prot_aberto_mcti.situacao as 'mcti_situacao',
    prot_aberto_mcti.sigla_orgao_ultimo_andamento as 'mcti_sigla_orgao_ultimo_andamento',
    prot_aberto_mcti.id_unidade_ultimo_andamento as 'mcti_id_unidade_ultimo_andamento', 
    prot_aberto_mcti.sigla_unidade_ultimo_andamento as 'mcti_sigla_unidade_ultimo_andamento',
    prot_aberto_mcti.descricao_unidade_ultimo_andamento as 'mcti_descricao_unidade_ultimo_andamento',

	prot_aberto_mcom.dth_conclusao as 'mcom_dth_conclusao',
    prot_aberto_mcom.situacao as 'mcom_situacao',
    prot_aberto_mcom.sigla_orgao_ultimo_andamento as 'mcom_sigla_orgao_ultimo_andamento',
    prot_aberto_mcom.id_unidade_ultimo_andamento as 'mcom_id_unidade_ultimo_andamento', 
    prot_aberto_mcom.sigla_unidade_ultimo_andamento as 'mcom_sigla_unidade_ultimo_andamento',
    prot_aberto_mcom.descricao_unidade_ultimo_andamento as 'mcom_descricao_unidade_ultimo_andamento'
FROM 
	protocolo
		join procedimento on protocolo.id_protocolo = procedimento.id_procedimento
		join tipo_procedimento on procedimento.id_tipo_procedimento = tipo_procedimento.id_tipo_procedimento
		join unidade unid on unid.id_unidade = protocolo.id_unidade_geradora
		join orgao org on org.id_orgao = unid.id_orgao
        
-- GRUPO DE PROCESSOS QUE TRAMITARAM EM AMBOS OS �RG�OS ------------------------------------------------------------------------------------------------
        LEFT JOIN (
select 
  temp.id_protocolo, 
  case
      when temp.tipo_procedimento_finalistico = 'AMBOS' then IIF(temp.sigla_orgao_geradora <> 'MCOM', 'MCTI', 'MCOM')
      else temp.tipo_procedimento_finalistico
  end as 'responsavel_processo',
  null as 'situacao'

from (        
select 
   prot.id_protocolo,
  case
      when tp.id_tipo_procedimento in ('100000236','100000235','100000238','100000237','100000234','100000265','100000350','100000264','100000253','100000256','100000247','100000255','100000254','100000249','100000257','100000591','100000248','100000252','100000592','100000590','100000588','100000614','100000915','100000916','100000917','100000913','100000914','100000918','100000919','100000613','100000231','100000229','100000228','100000230','100000227','100000232','100000263','100000921','100000880','100000818','100000556','100000907','100000567','100000552','100000558','100000559','100000553','100000551','100000560','100000618','100000574','100000564','100000635','100000573','100000881','100000615','100000562','100000906','100000572','100000571','100000774','100000795','100000561','100000581','100000576','100000575','100000626','100000585','100000550','100000557','100000628','100000629','100000632','100000627','100000631','100000634','100000587','100000554','100000904','100000577','100000563','100000565','100000549','100000890','100000878','100000879','100000887','100000630','100000580','100000616','100000601','100000570','100000911','100000912','100000910','100000909','100000908','100000582','100000583','100000586','100000568','100000617','100000903','100000902','100000905','100000633','100000555','100000569','100000578','100000566','100000224','100000274','100000273','100000272','100000266','100000276','100000277','100000278','100000279','100000275','100000280','100000625','100000815','100000596','100000612','100000262','100000269','100000261','100000281','100000270','100000259','100000611','100000267','100000597','100000271','100000258','100000260','100000598','100000268','100000246','100000837') then 'MCOM'
      when tp.id_tipo_procedimento in ('100000641','100000693','100000691','100000692','100000694','100000645','100000646','100000643','100000644','100000642','100000682','100000678','100000680','100000677','100000679','100000681','100000676','100000657','100000660','100000661','100000659','100000656','100000655','100000654','100000658','100000663','100000665','100000664','100000666','100000672','100000671','100000668','100000667','100000669','100000670','100000662','100000859','100000770','100000674','100000675','100000860','100000673','100000650','100000648','100000649','100000647','100000868','100000866','100000865','100000870','100000886','100000869','100000867','100000811','100000755','100000752','100000841','100000842','100000727','100000840','100000791','100000832','100000843','100000742','100000844','100000729','100000836','100000748','100000835','100000730','100000744','100000734','100000839','100000831','100000743','100000830','100000738','100000736','100000737','100000838','100000747','100000834','100000891','100000749','100000833','100000790','100000723','100000722','100000721','100000652','100000651','100000653','100000854','100000785','100000853','100000855','100000850','100000851','100000847','100000856','100000789','100000849','100000852','100000846','100000845','100000786','100000892','100000848','100000794','100000686','100000690','100000688','100000687','100000696','100000684','100000695','100000685','100000697','100000689','100000683','100000828','100000792','100000829','100000765','100000767','100000766','100000764','100000724','100000726','100000725','100000704','100000707','100000705','100000709','100000708','100000698','100000706','100000702','100000701','100000714','100000719','100000718','100000713','100000716','100000920') then 'MCTI'
      else 'AMBOS' 
  end as 'tipo_procedimento_finalistico',
  org.sigla as 'sigla_orgao_geradora'
  
from 
	protocolo prot 
        join procedimento proc1 on prot.id_protocolo = proc1.id_procedimento
		join tipo_procedimento tp on proc1.id_tipo_procedimento = tp.id_tipo_procedimento
		join unidade unid on prot.id_unidade_geradora = unid.id_unidade
        join orgao org on unid.id_orgao = org.id_orgao
        join #atividade_ultimo_tramite on #atividade_ultimo_tramite.id_protocolo = prot.id_protocolo AND #atividade_ultimo_tramite.responsavel = 'MCOM'
		join unidade unid_ultimo_andamento on #atividade_ultimo_tramite.id_unidade = unid_ultimo_andamento.id_unidade
		join orgao org_ultimo_andamento on unid_ultimo_andamento.id_orgao = org_ultimo_andamento.id_orgao
where 
	prot.sta_protocolo = 'P' 
	and org_ultimo_andamento.sigla = 'MCOM'

INTERSECT

select 
   prot.id_protocolo,
  case
      when tp.id_tipo_procedimento in ('100000236','100000235','100000238','100000237','100000234','100000265','100000350','100000264','100000253','100000256','100000247','100000255','100000254','100000249','100000257','100000591','100000248','100000252','100000592','100000590','100000588','100000614','100000915','100000916','100000917','100000913','100000914','100000918','100000919','100000613','100000231','100000229','100000228','100000230','100000227','100000232','100000263','100000921','100000880','100000818','100000556','100000907','100000567','100000552','100000558','100000559','100000553','100000551','100000560','100000618','100000574','100000564','100000635','100000573','100000881','100000615','100000562','100000906','100000572','100000571','100000774','100000795','100000561','100000581','100000576','100000575','100000626','100000585','100000550','100000557','100000628','100000629','100000632','100000627','100000631','100000634','100000587','100000554','100000904','100000577','100000563','100000565','100000549','100000890','100000878','100000879','100000887','100000630','100000580','100000616','100000601','100000570','100000911','100000912','100000910','100000909','100000908','100000582','100000583','100000586','100000568','100000617','100000903','100000902','100000905','100000633','100000555','100000569','100000578','100000566','100000224','100000274','100000273','100000272','100000266','100000276','100000277','100000278','100000279','100000275','100000280','100000625','100000815','100000596','100000612','100000262','100000269','100000261','100000281','100000270','100000259','100000611','100000267','100000597','100000271','100000258','100000260','100000598','100000268','100000246','100000837') then 'MCOM'
      when tp.id_tipo_procedimento in ('100000641','100000693','100000691','100000692','100000694','100000645','100000646','100000643','100000644','100000642','100000682','100000678','100000680','100000677','100000679','100000681','100000676','100000657','100000660','100000661','100000659','100000656','100000655','100000654','100000658','100000663','100000665','100000664','100000666','100000672','100000671','100000668','100000667','100000669','100000670','100000662','100000859','100000770','100000674','100000675','100000860','100000673','100000650','100000648','100000649','100000647','100000868','100000866','100000865','100000870','100000886','100000869','100000867','100000811','100000755','100000752','100000841','100000842','100000727','100000840','100000791','100000832','100000843','100000742','100000844','100000729','100000836','100000748','100000835','100000730','100000744','100000734','100000839','100000831','100000743','100000830','100000738','100000736','100000737','100000838','100000747','100000834','100000891','100000749','100000833','100000790','100000723','100000722','100000721','100000652','100000651','100000653','100000854','100000785','100000853','100000855','100000850','100000851','100000847','100000856','100000789','100000849','100000852','100000846','100000845','100000786','100000892','100000848','100000794','100000686','100000690','100000688','100000687','100000696','100000684','100000695','100000685','100000697','100000689','100000683','100000828','100000792','100000829','100000765','100000767','100000766','100000764','100000724','100000726','100000725','100000704','100000707','100000705','100000709','100000708','100000698','100000706','100000702','100000701','100000714','100000719','100000718','100000713','100000716','100000920') then 'MCTI'
      else 'AMBOS' 
  end as 'tipo_procedimento_finalistico',
org.sigla as 'sigla_orgao_geradora'
  
from 
	protocolo prot 
        join procedimento proc1 on prot.id_protocolo = proc1.id_procedimento
		join tipo_procedimento tp on proc1.id_tipo_procedimento = tp.id_tipo_procedimento
		join unidade unid on prot.id_unidade_geradora = unid.id_unidade
        join orgao org on unid.id_orgao = org.id_orgao
        join #atividade_ultimo_tramite on #atividade_ultimo_tramite.id_protocolo = prot.id_protocolo AND #atividade_ultimo_tramite.responsavel = 'MCTI'
		join unidade unid_ultimo_andamento on #atividade_ultimo_tramite.id_unidade = unid_ultimo_andamento.id_unidade
		join orgao org_ultimo_andamento on unid_ultimo_andamento.id_orgao = org_ultimo_andamento.id_orgao
where 
	prot.sta_protocolo = 'P' 
    and org_ultimo_andamento.sigla <> 'MCOM'
) temp


		) prot_ambos_orgaos ON protocolo.id_protocolo = prot_ambos_orgaos.id_protocolo

--         -- GRUPO DE PROCESSOS COM �LTIMO ANDAMENTO REGISTRADO NO MCOM
        LEFT JOIN (


select 
  prot.id_protocolo, 
  'MCOM' as 'responsavel_processo',
  org.sigla as 'sigla_orgao_geradora',
  #atividade_ultimo_tramite.dth_conclusao,
  #atividade_ultimo_tramite.situacao,
  org_ultimo_andamento.sigla as 'sigla_orgao_ultimo_andamento',
  unid_ultimo_andamento.id_unidade as 'id_unidade_ultimo_andamento', 
  unid_ultimo_andamento.sigla as 'sigla_unidade_ultimo_andamento',
  unid_ultimo_andamento.descricao as 'descricao_unidade_ultimo_andamento'
  
from 
	protocolo prot 
        join procedimento proc1 on prot.id_protocolo = proc1.id_procedimento
		--join tipo_procedimento tp on proc1.id_tipo_procedimento = tp.id_tipo_procedimento
		join unidade unid on prot.id_unidade_geradora = unid.id_unidade
        join orgao org on unid.id_orgao = org.id_orgao
        join #atividade_ultimo_tramite on #atividade_ultimo_tramite.id_protocolo = prot.id_protocolo AND #atividade_ultimo_tramite.responsavel = 'MCOM'
		join unidade unid_ultimo_andamento on #atividade_ultimo_tramite.id_unidade = unid_ultimo_andamento.id_unidade
		join orgao org_ultimo_andamento on unid_ultimo_andamento.id_orgao = org_ultimo_andamento.id_orgao
where 
	prot.sta_protocolo = 'P' 
    and org_ultimo_andamento.sigla = 'MCOM'

        ) AS prot_aberto_mcom ON protocolo.id_protocolo = prot_aberto_mcom.id_protocolo

        -- GRUPO DE PROCESSOS COM �LTIMO ANDAMENTO REGISTRADO NO MCTI
        LEFT JOIN (

select 
  prot.id_protocolo, 
  'MCTI' as 'responsavel_processo',
  org.sigla as 'sigla_orgao_geradora',
  #atividade_ultimo_tramite.dth_conclusao,
  #atividade_ultimo_tramite.situacao,
  org_ultimo_andamento.sigla as 'sigla_orgao_ultimo_andamento',
  unid_ultimo_andamento.id_unidade as 'id_unidade_ultimo_andamento', 
  unid_ultimo_andamento.sigla as 'sigla_unidade_ultimo_andamento',
  unid_ultimo_andamento.descricao as 'descricao_unidade_ultimo_andamento'  
from 
	protocolo prot 
        join procedimento proc1 on prot.id_protocolo = proc1.id_procedimento
		-- join tipo_procedimento tp on proc1.id_tipo_procedimento = tp.id_tipo_procedimento
		join unidade unid on prot.id_unidade_geradora = unid.id_unidade
        join orgao org on unid.id_orgao = org.id_orgao
        join #atividade_ultimo_tramite on #atividade_ultimo_tramite.id_protocolo = prot.id_protocolo AND #atividade_ultimo_tramite.responsavel = 'MCTI'
		join unidade unid_ultimo_andamento on #atividade_ultimo_tramite.id_unidade = unid_ultimo_andamento.id_unidade
		join orgao org_ultimo_andamento on unid_ultimo_andamento.id_orgao = org_ultimo_andamento.id_orgao
where 
	prot.sta_protocolo = 'P' 
    and org_ultimo_andamento.sigla <> 'MCOM'
        ) AS prot_aberto_mcti ON protocolo.id_protocolo = prot_aberto_mcti.id_protocolo

WHERE 
	protocolo.sta_protocolo = 'P'
	AND protocolo.sta_estado IN (0, 1, 4)
	--AND case
	--	when prot_ambos_orgaos.id_protocolo is not null and prot_aberto_mcom.situacao = 'aberto' and prot_aberto_mcti.situacao = 'fechado' then 'MCOM'
	--	when prot_ambos_orgaos.id_protocolo is not null and prot_aberto_mcom.situacao = 'fechado' and prot_aberto_mcti.situacao = 'aberto' then 'MCTI'
	--	else COALESCE(prot_ambos_orgaos.responsavel_processo, prot_aberto_mcom.responsavel_processo, prot_aberto_mcti.responsavel_processo) 
	--end <> 'MCTI'
;