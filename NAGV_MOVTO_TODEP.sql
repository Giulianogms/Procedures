CREATE OR REPLACE VIEW CONSINCO.NAGV_MOVTO_TODEP AS
SELECT translate(CODPOS,' .-', ' ')  COD_COMPLETO, NROEMPRESA, 1 SEQINVLOTE, LOCAL
FROM (
SELECT '0000000'||LPAD(PC.CODACESSO,13,0)||LPAD(REPLACE(A.ESTOQUE,'-',''),7,0) CODPOS,
       A.ESTOQUE DIVERG, A.NROEMPRESA, A.LOCAL

  FROM CONSINCO.NAGV_SALDOLOCAL_CD A INNER JOIN (SELECT PCC.SEQPRODUTO, PCC.CODACESSO, ROW_NUMBER() OVER(PARTITION BY PCC.SEQPRODUTO ORDER BY PCC.SEQPRODUTO) ODR FROM
       CONSINCO.MAP_PRODCODIGO PCC WHERE PCC.QTDEMBALAGEM = 1 AND PCC.TIPCODIGO IN ('E', 'B')) PC ON A.SEQPRODUTO = PC.SEQPRODUTO AND PC.ODR = 1 AND CODACESSO NOT LIKE '0%'

 WHERE 1=1
   AND NOT EXISTS (SELECT 1 FROM MAP_PRODUTO P WHERE P.SEQPRODUTO = A.SEQPRODUTO AND EXISTS (SELECT 2 FROM MAP_FAMILIA F WHERE F.PESAVEL = 'S' AND F.SEQFAMILIA = P.SEQFAMILIA)))

WHERE DIVERG > 0;