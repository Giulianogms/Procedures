ALTER SESSION SET CURRENT_SCHEMA = CONSINCO;

CREATE OR REPLACE VIEW CONSINCO.NAGV_14_ALIMENTACAO AS

-- Criado por Giuliano em 05/08/2024
-- Ticket 430626
-- Replica da base 14 - GMD - Apenas CGO 33

SELECT X.NRO_EMPRESA, TO_CHAR(X.DTAENTRADASAIDA, 'YYYY') ANO,
       TO_CHAR(X.DTAENTRADASAIDA, 'MM') MES, DTAENTRADASAIDA DTA_ENTRADA,
       ZZ.CATEGORIA_NIVEL_1 CATEGORIA_NVL01, S.EMBALAGEM,
       (SELECT D.CGO || '-' || D.DESCRICAO
           FROM QLV_CGO@BI D
          WHERE D.CGO = X.CODGERALOPER) OPERACAO,
       (SELECT D.TIPO_PERDA FROM QLV_CGO@BI D WHERE D.CGO = X.CODGERALOPER) TIPO,
       TO_CHAR(SUM(X.QTDLANCTO),
                'FM999G999G990',
                'NLS_NUMERIC_CHARACTERS='',.''') QTD,
       TO_CHAR(ROUND(SUM(X.VALOR_LANCTO_BRT_UNIT * X.QTDLANCTO), 2),
                'FM999G999G990D90',
                'NLS_NUMERIC_CHARACTERS='',.''') VLR_PERDA
  FROM QLV_PERDA@BI X
 INNER JOIN QLV_CATEGORIA@BI ZZ
    ON (X.SEQFAMILIA = ZZ.SEQFAMILIA)
 INNER JOIN DIM_PRODUTOEMBALAGEM@BI S
    ON (S.SEQPRODUTO = X.SEQPRODUTO AND S.QTDEMBALAGEM = 1)
 WHERE 1 = 1
   AND X.DTAENTRADASAIDA BETWEEN SYSDATE - 10 AND SYSDATE
   AND X.CODGERALOPER = 33

 GROUP BY X.NRO_EMPRESA, TO_CHAR(X.DTAENTRADASAIDA, 'YYYY'),
          TO_CHAR(X.DTAENTRADASAIDA, 'MM'), ZZ.CATEGORIA_NIVEL_1,
          S.EMBALAGEM, X.CODGERALOPER, DTAENTRADASAIDA

