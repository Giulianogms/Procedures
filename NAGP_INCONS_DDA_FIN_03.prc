CREATE OR REPLACE PROCEDURE CONSINCO.NAGP_INCONS_DDA_FIN_03 (vSeqFornec IN NUMBER) AS

-- Criado por Giuliano - Versao por Fornec

  vTEXTO         CLOB;
  vTITULO        CLOB;
  vEMAIL         LONG;
  vMES           VARCHAR2(100);
  vTEXTO1        CLOB;
  OBJ_PARAM_SMTP C5_TP_PARAM_SMTP;
  vDIR           VARCHAR2(2000);
  TEXTO          SYS.UTL_FILE.FILE_TYPE;
  vARQ           VARCHAR2(2000);
  vLIN           VARCHAR2(4000);
  vCONTINUA      VARCHAR2(200);

BEGIN

   vtexto := '<HTML>
          <style="color:red;">Informativo Automático:
          <p style="font-family: Roboto, sans-serif;">Segue abaixo Títulos Não Conciliados via DDA para análise:<BODY bgColor=#ffffff>
          <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 12px; color:#8f4d4d;">
          **Este é um projeto em desenvolvimento, pode ser necessário correções/ajustes**<BODY bgColor=#ffffff>
          <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 12px; color:#8f4d4d;">
          **Os dados no campo *Inconsistencia* são referentes aos arquivos DDA enviados pelo fornecedor, que *PODEM* ou não estar relacionados aos títulos lançados**<BODY bgColor=#ffffff>

          <TABLE width=90% cellspacing=0 cellpadding=0 >
          <TR>
          <TD >
         </TD>
          <TR>
          <TD>
         </TD>
         </TR>
          <TR>
          <TD>
         </TD>
         </TR>
         </TR>
         </table>
          
          <FONT size=1>
          <TABLE width=90% style=BORDER-COLLAPSE: collapse; margin-left:100px  width=900 border=1 cellspacing=0 cellpadding=0>
          <TBODY>

          <thead>  

          <TR>
    <th width="7%" bgColor=#014ba0 >
      <B><FONT face=Calibri color=white size=2>Empresa</FONT></B>
    </th>

    <th width="10%" bgColor=#014ba0 >
      <B><FONT face=Calibri color=white size=2>Fornecedor</FONT></B>
    </th>

    <th width="20%" bgColor=#014ba0 >
      <B><FONT face=Calibri color=white size=2>Inconsistência</FONT></B>
    </th>

    <th width="7%" bgColor=#014ba0 >
      <B><FONT face=Calibri color=white size=2>Título</FONT></B>
    </th>
    
    <th width="7%" bgColor=#014ba0 >
      <B><FONT face=Calibri color=white size=2>Vencimento C5</FONT></B>
    </th>

          </TR>
         </thead>';

FOR T2 IN (
SELECT DISTINCT /*+OPTIMIZER_FEATURES_ENABLE('11.2.0.4')*/   * FROM (

SELECT /*+OPTIMIZER_FEATURES_ENABLE('11.2.0.4')*/  FORNECEDOR, LPAD(X.NROCNPJCPF, 12, 0) || LPAD(X.DIGCNPJCPF, 2, 0) CNPJ,
CASE WHEN LPAD(X.NROCNPJCPF, 12, 0) = (SELECT MAX(LPAD(D.NROCGCCPF, 12, 0)) FROM CONSINCO.GE_PESSOA D WHERE D.NROCGCCPF = X.NROCNPJCPF AND D.STATUS = 'A')
THEN 'Cadastrado no Sistema'||CASE WHEN 
(SELECT DISTINCT SEQFILTRODDA  FROM (
SELECT DISTINCT SEQFILTRODDA FROM FI_FORNECEDOR A  RIGHT JOIN FI_DDAREGRA D  ON A.SEQFILTRODDA = D.SEQFILTRO 
RIGHT JOIN FI_DDAREGRADETALHE E ON E.SEQREGRA = D.SEQREGRA WHERE NROCNPJCPF IS NOT NULL AND A.SEQPESSOA = X.SEQ)) = 1939531 THEN ' - Bloqueado nas Regras' ELSE NULL END
WHEN LPAD(X.NROCNPJCPF,12,0)||LPAD(X.DIGCNPJCPF,2,0) IN 
(SELECT LPAD(FR.NROCNPJCPF,12,0)||LPAD(FR.DIGCNPJCPF,2,0) FROM CONSINCO.FI_DDAREGRADETALHE FR WHERE FR.NROCNPJCPF = X.NROCNPJCPF)
THEN 'Cadastrado nas Regras'||CASE WHEN LPAD(X.NROCNPJCPF,12,0) NOT IN (
SELECT DISTINCT REGRACNPJ FROM (
SELECT DISTINCT SEQFILTRODDA, A.SEQPESSOA, C.NOMERAZAO, LPAD(E.NROCNPJCPF,12,0) REGRACNPJ

                                   FROM FI_FORNECEDOR A 
                                   LEFT  JOIN GE_PESSOA C ON A.SEQPESSOA = C.SEQPESSOA
                                   RIGHT JOIN FI_DDAREGRA D  ON A.SEQFILTRODDA = D.SEQFILTRO 
                                   RIGHT JOIN FI_DDAREGRADETALHE E ON E.SEQREGRA = D.SEQREGRA
                                   WHERE NROCNPJCPF IS NOT NULL AND A.SEQPESSOA = X.SEQ)
) THEN ' - Bloqueado' ELSE NULL END
WHEN X.NROCNPJCPF IS NULL THEN NULL ELSE 'N'||
CASE WHEN (SUBSTR(LPAD(X.NROCNPJCPF,12,0),0,8)) IN
(SELECT SUBSTR(FRE.NROCGCCPF,0,8) FROM CONSINCO.GE_PESSOA FRE WHERE LPAD(FRE.NROCGCCPF,12,0) LIKE (SUBSTR(X.NROCNPJCPF,0,8)||'%') AND FRE.STATUS = 'A') THEN ' - Filial'
WHEN FORNECEDOR NOT LIKE ('%'||REGEXP_SUBSTR(DESCFORNECEDOR, '(\S*)(\s)')||'%') THEN ' - Neg - '||DESCFORNECEDOR ELSE NULL END
END CNPJ_CADASTRADO, GE.FANTASIA EMPRESA, X.CODESPECIE,
         
CASE WHEN TO_CHAR(DOC_C5) = TIT_C5 THEN TO_CHAR(DOC_C5) ELSE DOC_C5||' - Tit.: '||TIT_C5 END DOC_C5, 
CASE WHEN DIVERGENCIA IS NULL AND DOCTO IS NULL     THEN 'Titulo não encontrado' 
WHEN DIVERGENCIA IS NULL AND DOCTO IS NOT NULL THEN 'Título encontrado - '||CASE WHEN LPAD(X.NROCNPJCPF, 12, 0) = (SELECT MAX(LPAD(D.NROCGCCPF, 12, 0)) FROM CONSINCO.GE_PESSOA D WHERE D.NROCGCCPF = X.NROCNPJCPF AND D.STATUS = 'A')
OR  LPAD(X.NROCNPJCPF,12,0)||LPAD(X.DIGCNPJCPF,2,0) IN
(SELECT LPAD(FR.NROCNPJCPF,12,0)||LPAD(FR.DIGCNPJCPF,2,0) FROM CONSINCO.FI_DDAREGRADETALHE FR WHERE FR.NROCNPJCPF = X.NROCNPJCPF)     
THEN 'Divergencia Não Identificada' ELSE 'CNPJ Não Cadastrado!' END
ELSE DIVERGENCIA||CASE WHEN LPAD(X.NROCNPJCPF,12,0)||LPAD(X.DIGCNPJCPF,2,0) IN
(SELECT LPAD(FR.NROCNPJCPF,12,0)||LPAD(FR.DIGCNPJCPF,2,0) FROM CONSINCO.FI_DDAREGRADETALHE FR WHERE FR.NROCNPJCPF = X.NROCNPJCPF)
OR  LPAD(X.NROCNPJCPF, 12, 0) = (SELECT MAX(LPAD(D.NROCGCCPF, 12, 0)) FROM CONSINCO.GE_PESSOA D WHERE D.NROCGCCPF = X.NROCNPJCPF AND D.STATUS = 'A')
THEN NULL ELSE ' - CNPJ Não Cadastrado!' END END DIVERGENCIA, 
DOCTO DOCTO_DDA, Emissao, Vencimento, Valor, DESCONTO1, DATADESCONTO1, DESCONTO2, DATADESCONTO2, VALORABATIMENTO, CODIGODEBARRAS, SEQ, VENCC5

FROM (

SELECT /*+OPTIMIZER_FEATURES_ENABLE('11.2.0.4')*/ F.NROEMPRESA EMP, TO_CHAR(F.DTAVENCIMENTO, 'DD/MM/YYYY') VENCC5, 
       GE.NOMERAZAO||' - '||GE.SEQPESSOA Fornecedor, DDA2.DESCFORNECEDOR, GE.SEQPESSOA SEQ, DDA2.NRODOCUMENTO DOCTO, F.NRODOCUMENTO DOC_C5, F.NROTITULO TIT_C5, F.CODESPECIE, DDA2.NRODOCUMENTO,
       TO_CHAR(DDA2.DTAEMISSAO,'DD/MM/YYYY') EMISSAO, TO_CHAR(DDA2.DTAVENCIMENTO,'DD/MM/YYYY') VENCIMENTO, DDA2.VALORDOCUMENTO VALOR, DDA2.VALORDESCONTO1 DESCONTO1, TO_CHAR(DDA2.DTADESCONTO1,'DD/MM/YYYY') DATADESCONTO1, DDA2.VALORDESCONTO2 DESCONTO2, TO_CHAR(DDA2.DTADESCONTO2,'DD/MM/YYYY') DATADESCONTO2, DDA2.VALORABATIMENTO, DDA2.CODBARRAS CODIGODEBARRAS,
         
CASE WHEN (
SELECT SUM(F2.VLRORIGINAL) - (SUM(NVL(FF3.VLRDESCCONTRATO,0)) + SUM(NVL(F2.VLRPAGO,0)))
FROM FI_TITULO F2 INNER JOIN FI_COMPLTITULO FF3 ON F2.SEQTITULO = FF3.SEQTITULO
WHERE F2.SEQPESSOA = F.SEQPESSOA
AND F2.NROEMPRESA IN(F.NROEMPRESA)
AND F2.OBRIGDIREITO = 'O'
AND F2.ABERTOQUITADO    = 'A' 
AND F2.SITUACAO        != 'S'  
AND NVL(F2.SUSPLIB,'L') = 'L'
AND F2.SEQTITULO NOT IN (     
SELECT  SEQTITULO  
FROM  FI_AUTPAGTO 
  WHERE   FI_AUTPAGTO.SEQTITULO = F2.SEQTITULO)
AND F2.DTAVENCIMENTO BETWEEN TRUNC(SYSDATE) AND SYSDATE + 5
HAVING COUNT (NRODOCUMENTO) > 1) IN (
SELECT (VALORDOCUMENTO - A.VALORDESCONTO1 - A.VALORABATIMENTO) FROM FIV_DDATITULOSBUSCA A 
WHERE A.DTAVENCIMENTO BETWEEN (TRUNC(SYSDATE) - 10) AND (TRUNC(SYSDATE) + 10)
AND NVL(a.ACEITO,'N') = 'N'
AND  (SELECT GEE.NROEMPRESA FROM CONSINCO.GE_EMPRESA GEE
WHERE LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) = LPAD(A.NROCNPJCPFSACADO,12,0)||LPAD(A.DIGCNPJCPFSACADO,2,0)) IN(F.NROEMPRESA))
THEN 'Títulos Agrupados - DOC DDA: '||DDA2.NRODOCUMENTO||' - Valor Total: '||TO_CHAR(DDA2.VALORCOMDESCONTO,'FM999G999G999D90', 'nls_numeric_characters='',.''')

WHEN (
SELECT SUM(F2.VLRNOMINAL) - (SUM(NVL(FF3.VLRDESCCONTRATO,0)) + SUM(NVL(F2.VLRPAGO,0)))
FROM FI_TITULO F2 INNER JOIN FI_COMPLTITULO FF3 ON F2.SEQTITULO = FF3.SEQTITULO
WHERE F2.SEQPESSOA = F.SEQPESSOA
AND F2.NROEMPRESA IN(F.NROEMPRESA)
AND F2.OBRIGDIREITO = 'O'
AND F2.ABERTOQUITADO    = 'A' 
AND F2.SITUACAO        != 'S'  
AND NVL(F2.SUSPLIB,'L') = 'L'
AND F2.DTAVENCIMENTO BETWEEN TRUNC(SYSDATE) AND SYSDATE + 5
HAVING COUNT (NRODOCUMENTO) > 1) IN (
SELECT (VALORDOCUMENTO - A.VALORDESCONTO1 - A.VALORABATIMENTO) FROM FIV_DDATITULOSBUSCA A 
WHERE A.DTAVENCIMENTO BETWEEN (TRUNC(SYSDATE) - 10) AND (TRUNC(SYSDATE) + 10)
AND NVL(a.ACEITO,'N') = 'N'
AND  (SELECT GEE.NROEMPRESA FROM CONSINCO.GE_EMPRESA GEE
WHERE LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) = LPAD(A.NROCNPJCPFSACADO,12,0)||LPAD(A.DIGCNPJCPFSACADO,2,0)) IN(F.NROEMPRESA))
THEN 'Títulos Agrupados - DOC DDA: '||DDA2.NRODOCUMENTO||' - Valor Total: '||TO_CHAR(DDA2.VALORCOMDESCONTO,'FM999G999G999D90', 'nls_numeric_characters='',.''')

WHEN (
SELECT SUM(F2.VLRORIGINAL) - (SUM(NVL(FF3.VLRDESCCONTRATO,0)) + SUM(NVL(F2.VLRPAGO,0)))
AS VLRSOMADO
FROM FI_TITULO F2 INNER JOIN FI_COMPLTITULO FF3 ON F2.SEQTITULO = FF3.SEQTITULO
WHERE F2.SEQPESSOA = F.SEQPESSOA
AND F2.NROEMPRESA IN(F.NROEMPRESA)
AND F2.OBRIGDIREITO = 'O'
AND F2.ABERTOQUITADO    = 'A' 
AND F2.SITUACAO        != 'S'  
AND NVL(F2.SUSPLIB,'L') = 'L'
AND F2.DTAVENCIMENTO BETWEEN TRUNC(SYSDATE) AND SYSDATE + 5
HAVING COUNT (NRODOCUMENTO) > 1) IN (
SELECT ((VALORDOCUMENTO - 0.01)- NVL(A.VALORDESCONTO1,0) - NVL(A.VALORABATIMENTO,0))  FROM FIV_DDATITULOSBUSCA A 
WHERE A.DTAVENCIMENTO BETWEEN (TRUNC(SYSDATE) - 5) AND (TRUNC(SYSDATE) + 5)
AND NVL(a.ACEITO,'N') = 'N' 
AND  (SELECT GEE.NROEMPRESA FROM CONSINCO.GE_EMPRESA GEE
WHERE LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) = LPAD(A.NROCNPJCPFSACADO,12,0)||LPAD(A.DIGCNPJCPFSACADO,2,0)) IN(F.NROEMPRESA)
UNION ALL
SELECT ((VALORDOCUMENTO + 0.01)- NVL(A.VALORDESCONTO1,0) - NVL(A.VALORABATIMENTO,0))  FROM FIV_DDATITULOSBUSCA A 
WHERE A.DTAVENCIMENTO BETWEEN (TRUNC(SYSDATE) - 5) AND (TRUNC(SYSDATE) + 5)
AND NVL(a.ACEITO,'N') = 'N' 
AND  (SELECT GEE.NROEMPRESA FROM CONSINCO.GE_EMPRESA GEE
WHERE LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) = LPAD(A.NROCNPJCPFSACADO,12,0)||LPAD(A.DIGCNPJCPFSACADO,2,0)) IN(F.NROEMPRESA)
UNION ALL
SELECT ((VALORDOCUMENTO + 0.02)- NVL(A.VALORDESCONTO1,0) - NVL(A.VALORABATIMENTO,0))  FROM FIV_DDATITULOSBUSCA A 
WHERE A.DTAVENCIMENTO BETWEEN (TRUNC(SYSDATE) - 5) AND (TRUNC(SYSDATE) + 5)
AND NVL(a.ACEITO,'N') = 'N' 
AND  (SELECT GEE.NROEMPRESA FROM CONSINCO.GE_EMPRESA GEE
WHERE LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) = LPAD(A.NROCNPJCPFSACADO,12,0)||LPAD(A.DIGCNPJCPFSACADO,2,0)) IN(F.NROEMPRESA)
UNION ALL
SELECT ((VALORDOCUMENTO - 0.02)- NVL(A.VALORDESCONTO1,0) - NVL(A.VALORABATIMENTO,0))  FROM FIV_DDATITULOSBUSCA A 
WHERE A.DTAVENCIMENTO BETWEEN (TRUNC(SYSDATE) - 5) AND (TRUNC(SYSDATE) + 5)
AND NVL(a.ACEITO,'N') = 'N' 
AND  (SELECT GEE.NROEMPRESA FROM CONSINCO.GE_EMPRESA GEE
WHERE LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) = LPAD(A.NROCNPJCPFSACADO,12,0)||LPAD(A.DIGCNPJCPFSACADO,2,0)) IN(F.NROEMPRESA))
THEN 'Títulos Agrupados - Valor Sistema: '||TO_CHAR((
SELECT SUM(F2.VLRORIGINAL) - (SUM(NVL(FF3.VLRDESCCONTRATO,0)) + SUM(NVL(F2.VLRPAGO,0)))
AS VLRSOMADO
FROM FI_TITULO F2 INNER JOIN FI_COMPLTITULO FF3 ON F2.SEQTITULO = FF3.SEQTITULO
WHERE F2.SEQPESSOA = F.SEQPESSOA
AND F2.NROEMPRESA IN(F.NROEMPRESA)
AND F2.DTAVENCIMENTO BETWEEN TRUNC(SYSDATE) AND SYSDATE + 5
HAVING COUNT (NRODOCUMENTO) > 1),'FM999G999G999D90', 'nls_numeric_characters='',.''')||' - Valor DDA: '||
TO_CHAR(DDA2.VALORCOMDESCONTO,'FM999G999G999D90', 'nls_numeric_characters='',.''')||CASE WHEN F.DTAVENCIMENTO != DDA2.DTAVENCIMENTO
THEN ' - Data de Vencimento Sistema: '||TO_CHAR(F.DTAVENCIMENTO, 'DD/MM/YYYY')||' - DDA: '||TO_CHAR(DDA2.DTAVENCIMENTO, 'DD/MM/YYYY') ELSE NULL END

WHEN (F.VLRORIGINAL - NVL((FC.VLRDESCCONTRATO + F.VLRPAGO),0)) != (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0))
THEN 'Valor Total Sistema: '||TO_CHAR((F.VLRORIGINAL - NVL((FC.VLRDESCCONTRATO + F.VLRPAGO),0)),'FM999G999G999D90', 'nls_numeric_characters='',.''')||' - DDA: '||
TO_CHAR(DDA2.VALORCOMDESCONTO,'FM999G999G999D90', 'nls_numeric_characters='',.''')||' | Desconto Sistema: '||
TO_CHAR(NVL((FC.VLRDESCCONTRATO+FC.VLRDSCFINANC+F.VLRPAGO),0),'FM999G999G999D90', 'nls_numeric_characters='',.''')||' - DDA: '||
TO_CHAR((DDA2.VALORDESCONTO1 + DDA2.VALORDESCONTO2+DDA2.VALORDESCONTO3+DDA2.VALORABATIMENTO),'FM999G999G999D90', 'nls_numeric_characters='',.''')||CASE WHEN DDA2.DTAVENCIMENTO != F.DTAVENCIMENTO THEN CASE WHEN DDA2.DTAVENCIMENTO != F.DTAPROGRAMADA 
THEN ' | Data de Vencimento Sistema: '||TO_CHAR(F.DTAVENCIMENTO, 'DD/MM/YYYY')||' - DDA: '||TO_CHAR(DDA2.DTAVENCIMENTO, 'DD/MM/YYYY') ELSE NULL END ELSE NULL END
WHEN DDA2.DTAVENCIMENTO != F.DTAVENCIMENTO THEN CASE WHEN DDA2.DTAVENCIMENTO != F.DTAPROGRAMADA 
THEN 'Data de Vencimento Sistema: '||TO_CHAR(F.DTAVENCIMENTO, 'DD/MM/YYYY')||' - DDA: '||TO_CHAR(DDA2.DTAVENCIMENTO, 'DD/MM/YYYY') ELSE NULL END

ELSE NULL END Divergencia, DDA2.NROCNPJCPF, DDA2.DIGCNPJCPF
         
FROM CONSINCO.FI_TITULO F 

INNER JOIN CONSINCO.FI_ESPECIE FI      ON F.CODESPECIE = FI.CODESPECIE AND F.NROEMPRESAMAE = FI.NROEMPRESAMAE
INNER JOIN CONSINCO.GE_PESSOA  GE      ON F.SEQPESSOA  = GE.SEQPESSOA  
INNER JOIN CONSINCO.FI_COMPLTITULO  FC ON F.SEQTITULO  = FC.SEQTITULO
                   
  LEFT JOIN CONSINCO.FIV_DDATITULOSBUSCA DDA2 ON /* Variaveis Valodarores Não Conciliados */
(LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND DDA2.DTAVENCIMENTO = F.DTAVENCIMENTO AND DDA2.NRODOCUMENTO LIKE ('%'||F.NROTITULO||'%') AND (LENGTH(DDA2.NRODOCUMENTO)) > 4 AND NVL(DDA2.ACEITO,'N') = 'N'
OR (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND DDA2.DTAVENCIMENTO = F.DTAPROGRAMADA AND DDA2.NRODOCUMENTO LIKE ('%'||F.NROTITULO||'%')AND (LENGTH(DDA2.NRODOCUMENTO)) > 4 AND NVL(DDA2.ACEITO,'N') = 'N'
OR (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND DDA2.DTAVENCIMENTO = F.DTAVENCIMENTO AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND (LENGTH(DDA2.NRODOCUMENTO)) > 4 AND NVL(DDA2.ACEITO,'N') = 'N' 
OR (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND DDA2.DTAVENCIMENTO = F.DTAPROGRAMADA AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%')AND (LENGTH(DDA2.NRODOCUMENTO)) > 4 AND NVL(DDA2.ACEITO,'N') = 'N' 
OR (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND DDA2.NRODOCUMENTO LIKE ('%'||F.NROTITULO||'%') AND ((F.VLRORIGINAL - (FC.VLRDESCCONTRATO + F.VLRPAGO)) = (DDA2.VALORDOCUMENTO - (DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO)))AND (LENGTH(DDA2.NRODOCUMENTO)) > 4 AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR DDA2.DTAVENCIMENTO = F.DTAVENCIMENTO AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%')AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA)))  AND NVL(DDA2.ACEITO,'N') = 'N' 
OR DDA2.DTAVENCIMENTO = F.DTAPROGRAMADA AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%')AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND DDA2.NRODOCUMENTO LIKE ('%'||F.NROTITULO||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND ((F.VLRORIGINAL - (FC.VLRDESCCONTRATO + F.VLRPAGO)) = (DDA2.VALORDOCUMENTO - (DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO)))   AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR GE.NOMERAZAO LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND ((F.VLRORIGINAL - (FC.VLRDESCCONTRATO + F.VLRPAGO)) = (DDA2.VALORDOCUMENTO - (DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO))) AND NVL(DDA2.ACEITO,'N') = 'N' AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0)  FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA)))AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND (F.VLRORIGINAL) = (DDA2.VALORDOCUMENTO) AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20) AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND NVL(DDA2.ACEITO,'N') = 'N' 
OR (F.VLRORIGINAL) = (DDA2.VALORDOCUMENTO) AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20) AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR ((F.VLRORIGINAL - (FC.VLRDESCCONTRATO + F.VLRPAGO)) = (DDA2.VALORDOCUMENTO - (DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO))) AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0) FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND (F.VLRORIGINAL) = (DDA2.VALORDOCUMENTO) AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20) AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND NVL(DDA2.ACEITO,'N') = 'N' 
OR GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0)  FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND (F.DTAVENCIMENTO - DDA2.DTAVENCIMENTO) IN (1,2) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR DDA2.DTAVENCIMENTO = F.DTAVENCIMENTO AND GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0)  FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO, 'N') = 'N' AND REPLACE(DDA2.NRODOCUMENTO,'.','') LIKE ('%'||F.NRODOCUMENTO||'%') AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)',1,2)||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0)  FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO, 'N') = 'N' AND (DDA2.VALORDOCUMENTO - DDA2.VALORDESCONTO1) = (F.VLRORIGINAL - FC.VLRDESCCONTRATO) AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(DDA2.DESCFORNECEDOR, '(\S*)(\s)')||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT  A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND ((F.VLRORIGINAL - (NVL(FC.VLRDESCCONTRATO,0) + NVL(F.VLRPAGO,0))) - (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0))) 
IN (0.06,0.07,0.08,0.09,0.10,0.11,0.12,0.13,0.14,0.15,-0.06,-0.07,-0.08,-0.09,-0.10,-0.11,-0.12,-0.13,-0.14,-0.15)AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(REPLACE(DDA2.DESCFORNECEDOR,'-',' '), '(\S*)(\s)')||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND ((F.VLRORIGINAL - NVL((FC.VLRDESCCONTRATO + F.VLRPAGO),0)) - (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0))) 
IN (0.06,0.07,0.08,0.09,0.10,0.11,0.12,0.13,0.14,0.15,-0.06,-0.07,-0.08,-0.09,-0.10,-0.11,-0.12,-0.13,-0.14,-0.15) AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 7) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND ((F.VLRORIGINAL - NVL((FC.VLRDESCCONTRATO + F.VLRPAGO),0)) - (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0))) 
IN (0.06,0.07,0.08,0.09,0.10,0.11,0.12,0.13,0.14,0.15,-0.06,-0.07,-0.08,-0.09,-0.10,-0.11,-0.12,-0.13,-0.14,-0.15) AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 7) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(REPLACE(DDA2.DESCFORNECEDOR,'-',' '), '(\S*)(\s)',1,2)||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO, 'N') = 'N' AND DDA2.VALORDOCUMENTO = F.VLRORIGINAL AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20) AND NVL(DDA2.ACEITO,'N') = 'N' AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20)
OR DDA2.NRODOCUMENTO LIKE ('%'||F.NRODOCUMENTO||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 20) AND (F.DTAVENCIMENTO + 20) AND NVL(DDA2.ACEITO,'N') = 'N' AND  (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0)) < ((F.VLRORIGINAL - NVL((FC.VLRDESCCONTRATO + F.VLRPAGO),0)) *2) AND (LENGTH(F.NRODOCUMENTO)) >= 4 
OR GE.NOMERAZAO LIKE ('%'||REGEXP_SUBSTR(REPLACE(DDA2.DESCFORNECEDOR,'-',' '), '(\S*)(\s)',1,2)||'%') AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND ((F.VLRORIGINAL - (NVL(FC.VLRDESCCONTRATO,0) + NVL(F.VLRPAGO,0))) - (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0))) 
IN (0.06,0.07,0.08,0.09,0.10,0.11,0.12,0.13,0.14,0.15,-0.06,-0.07,-0.08,-0.09,-0.10,-0.11,-0.12,-0.13,-0.14,-0.15) AND DDA2.DTAVENCIMENTO = F.DTAVENCIMENTO AND NVL(DDA2.ACEITO,'N') = 'N' 
OR LPAD(DDA2.NROCNPJCPF,12,0)||LPAD(DDA2.DIGCNPJCPF,2,0) IN (SELECT DISTINCT LPAD(GEG.NROCGCCPF,12,0)||LPAD(GEG.DIGCGCCPF,2,0) FROM GE_PESSOA GEG WHERE GEG.SEQPESSOA = F.SEQPESSOA) AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0)) IN (SELECT LPAD(GEE.NROCGC,12,0)||LPAD(GEE.DIGCGC,2,0) FROM GE_EMPRESA GEE WHERE GEE.NROEMPRESA IN (SELECT A.MATRIZ FROM  GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA) UNION SELECT A.NROEMPRESA FROM GE_EMPRESA A WHERE  A.NROEMPRESA IN(F.NROEMPRESA))) AND ((F.VLRORIGINAL - (NVL(FC.VLRDESCCONTRATO,0) + NVL(F.VLRPAGO,0))) - (DDA2.VALORDOCUMENTO - NVL((DDA2.VALORDESCONTO1 + DDA2.VALORABATIMENTO),0))) 
IN (0.06,0.07,0.08,0.09,0.10,0.11,0.12,0.13,0.14,0.15,-0.06,-0.07,-0.08,-0.09,-0.10,-0.11,-0.12,-0.13,-0.14,-0.15) AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO -7) AND (F.DTAVENCIMENTO +7) AND NVL(DDA2.ACEITO,'N') = 'N' 
OR REPLACE(GE.NOMERAZAO, '.',' ') LIKE ('%'||DDA2.DESCFORNECEDOR||'%') AND F.VLRORIGINAL = DDA2.VALORDOCUMENTO AND DDA2.DTAVENCIMENTO BETWEEN (F.DTAVENCIMENTO - 10) AND (F.DTAVENCIMENTO + 10) AND (LPAD(DDA2.NROCNPJCPFSACADO,12,0)||LPAD(DDA2.DIGCNPJCPFSACADO,2,0) IN (SELECT LPAD(DE.NROCGCCPF,12,0)||LPAD(DE.DIGCGCCPF,2,0)  FROM CONSINCO.GE_PESSOA DE WHERE SEQPESSOA IN(F.NROEMPRESA))) AND NVL(DDA2.ACEITO,'N') = 'N'

WHERE F.OBRIGDIREITO     = 'O'
-- Simone solicitou que envie apenas DUPP
AND F.CODESPECIE = 'DUPP'
/*
AND F.CODESPECIE NOT IN ('13SAL','ADIEMP','ADIPRP','ADISAL','ANTREC','ATIPCO','ATIVOC','BONIAC','BONIDV','CHQPG','DEVCOM','DEVPAG','DEVPCO',
                         'DUPCIM','DUPPCO','DUPPCX','DVRBEC','EMPAG','EMPAIM','FATNAG','FERIAS','FINAIM','FINANC','LEIROU','ORDSAL','PAGEST','PENSAO',
                         'RECARG','REEMB','RESCIS','VLDESC','COFINS','CONTDV','DSSLL','FGTS','FGTSQT','ICMS','IMPOST','INSS','INSSNF','INSTANG','IPI',
                         'IR','IRRFFP','IRRFNF','ISSQN','ISSQNP','ISSST','LEASIM','LEASIN','PCCNF','PIS','PROTRA','ALUGPG','FATICD', 'QTPRP','ADIPPG',
                         'DESP','ATVEFU','ATIVOC','ATIVO')
                         */
                         
AND F.ABERTOQUITADO    = 'A' 
AND FI.TIPOESPECIE     = 'T' 
AND F.SITUACAO        != 'S'  
AND NVL(F.SUSPLIB,'L') = 'L'
AND FC.CODBARRA         IS NULL     
AND F.DTAVENCIMENTO BETWEEN TRUNC(SYSDATE) AND SYSDATE + 5
AND NVL(DDA2.ACEITO,'N') = 'N'
AND FC.CODBARRA IS NULL
AND F.SEQPESSOA = vSeqFornec
    
) X, GE_EMPRESA GE

WHERE GE.NROEMPRESA = X.EMP
   
) XX

WHERE XX.DIVERGENCIA NOT LIKE '%Divergencia Não Identificada%' AND XX.DIVERGENCIA != 'Titulo não encontrado'
   OR XX.DIVERGENCIA NOT LIKE '%Titulo não encontrado%'
   OR XX.CNPJ_CADASTRADO LIKE '%N%'         AND XX.DIVERGENCIA != 'Titulo não encontrado'
   OR XX.CNPJ_CADASTRADO LIKE '%Bloqueado%' AND XX.DIVERGENCIA != 'Titulo não encontrado'
   
   ORDER BY XX.EMPRESA)

LOOP
  
    vtexto := vtexto ||
              to_char(

                '<TR>
                           <TD vAlign=top align=middle ><FONT face=Calibri size=2> ' ||  T2.EMPRESA ||        ' </FONT></TD>
                           <TD vAlign=top align=left   ><FONT face=Calibri size=2> ' ||  T2.FORNECEDOR ||     ' </FONT></TD>
                           <TD vAlign=top align=middle ><FONT face=Calibri size=2> ' ||  T2.DIVERGENCIA ||    ' </FONT></TD>
                           <TD vAlign=top align=middle ><FONT face=Calibri size=2> ' ||  'DOC C5 :'||TO_CHAR(T2.DOC_C5) ||' - DDA: '||T2.DOCTO_DDA||         ' </FONT></TD>
                           <TD vAlign=top align=middle ><FONT face=Calibri size=2> ' ||  T2.VENCC5 ||         ' </FONT></TD>


                 <TR>');
                 
    vContinua := TO_CHAR(T2.FORNECEDOR);
    
    END LOOP;
    
    vtexto := vtexto ||
                 -- Começa a Assinatura
              '</html>
              <!doctype html>
              
                <HTML>
                <head>
                <meta charset="UTF-8">
                <title>Supermercados Nagumo</title>
                </head>

                <body>
                <table width="726" border="0" cellspacing="0" cellpadding="0">
                  <tbody>
                  <tr> <td> </td> </tr>
                    <tr>
                      <td colspan="3" style="font-family: Arial, Helvetica, Sans Serif; font-size: 14px; color: #707070;">
                    </td>
                    </tr>
                  <tr>

                    </tr>
                      
                    <tr> </tr>
                      <font>
                      <p></p>
                        <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 14px; color: #003865; font-weight: bold; margin-bottom: 0px;">
                        E-mail Automático - Não Responda
                      </p>

                        <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 14px; color: #D50037; font-weight: bold; margin: 0px;">
                        Nagumo - TI | ERP | Sistemas
                      </p>

                      <p></p>

                      <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 14px; color:lightgray; font-weight: bold; margin: 0px;">
                        Desenvolvido por Giuliano Gomes | Marcel Cipolla
                      </p>
                      
                    <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 12px; color:lightgray; font-weight: bold;">
                      PRIVACIDADE E CONFIDENCIALIDADE
                    </p>

                    <p style="font-family: Arial, Helvetica, Sans Serif; font-size: 12px; color:lightgray;">
                      Esta mensagem e seu conteúdo tem caráter absolutamente privativo e confidencial entre o remetente e o real destinatário, protegida pelas legislações brasileira e internacional. Se você recebeu indevida ou equivocadamente esta mensagem, pedimos desculpas pelo inconveniente e solicitamos que seja deletado imediatamente a mensagem e seus anexos da sua caixa postal, bem como da sua lixeira, construindo potencial infração o armazenamento indevido de qualquer das informações aqui veiculadas.
                    </p>
                    </font>

                     </table>

                    </td>
                    </tr>
                    </td>
                    </tr>
                  </tbody>
                </table>

                </body>
                </HTML>';
        
    IF vContinua IS NOT NULL THEN
    
    CONSINCO.SP_ENVIA_EMAIL(CONSINCO.C5_TP_PARAM_SMTP(1),
    'email@email.com.br;email@email.com.br',
    'Inconsistencias DDA - Fornec.: '||vContinua|| ' - '||TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
    vtexto,
    'S');
    
    END IF;
    
  END;
