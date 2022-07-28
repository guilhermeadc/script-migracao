-- BLOQUEIO: Script de bloqueio individual de processo baseado no seu NUP sem registro de andamento
UPDATE protocolo SET sta_estado = '4'
WHERE 
	sta_protocolo = 'P'
	AND sta_estado IN (0, 1)
	-- DEVE SER INFORMADO ABAIXO A LISTA DE NUPS DOS PROCESSOS QUE SERÃO BLOQUEADOS. 
	AND protocolo_formatado IN (
		'NUP_PROCESSO_1',
		'NUP_PROCESSO_2',
		'NUP_PROCESSO_3'
	)
;


-- DESBLOQUEIO: Script de bloqueio individual de processo baseado no seu NUP sem registro de andamento
UPDATE protocolo SET sta_estado = '0'
WHERE 
	sta_protocolo = 'P'
	AND sta_estado IN (0, 1)
	-- DEVE SER INFORMADO ABAIXO A LISTA DE NUPS DOS PROCESSOS QUE SERÃO DESBLOQUEADOS. 
	AND protocolo_formatado IN (
		'NUP_PROCESSO_1',
		'NUP_PROCESSO_2',
		'NUP_PROCESSO_3'
	)
;
