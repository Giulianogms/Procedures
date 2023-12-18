CREATE OR REPLACE PROCEDURE SPMRL_CARGALST_V2 (PSNROEMPRESA          IN   VARCHAR2,
                                               PSTIPOLOG             IN   MRL_LOGEXPORTACAO.PARAM1%TYPE,
                                               PSBALANCA             IN   MRL_LOGEXPORTACAO.PARAM2%TYPE DEFAULT 'S')
   IS
      VSTIPOCARGA  VARCHAR2(1);
      VNRETORNO    NUMBER;
      VNNROSEG     NUMBER;
   BEGIN
     FOR EMP IN (SELECT * FROM MAX_EMPRESA A
                 WHERE A.STATUS = 'A'
                 AND   A.NROEMPRESA < 500
                 AND   A.NROEMPRESA IN (SELECT * FROM TABLE(CONSINCO.FC5_STRTOKENIZE(PSNROEMPRESA, ',')))
                 ORDER BY 1 )
     LOOP
         SELECT A.NROSEGMENTOPRINC
         INTO   VNNROSEG
         FROM   MAX_EMPRESA A
         WHERE  NROEMPRESA = EMP.NROEMPRESA;
         PKG_MAD_ADMPRECO.SP_GERAPROMOCAO(VNNROSEG, EMP.NROEMPRESA, TRUNC(SYSDATE), 'AUTOMATICO');
         PKG_MAD_ADMPRECO.SP_VALIDAPRECO(VNNROSEG, EMP.NROEMPRESA,'AUTOMATICO', 'T');
         COMMIT;
         IF PSTIPOLOG = 'Parcial'  THEN
            VSTIPOCARGA := 'P';   -- PARCIAL
         ELSE
            VSTIPOCARGA := 'T';   -- TOTAL
         END IF;
         DELETE FROM MRL_CARGAPDV_PRODUTO P
         WHERE  P.NROEMPRESA = EMP.NROEMPRESA;
         VNRETORNO := PKG_PDVCORAL.FEXP_PDVCORAL(EMP.NROEMPRESA, TRUNC(SYSDATE), VSTIPOCARGA, TRUNC(SYSDATE));
         
         -- ALTERACAO PARA RESPEITAR TIPO DA CARGA NA BALANCA - ALTERADO POR GIULIANO EM 01/12/23
         
         IF PSBALANCA = 'S'
           THEN          
          -- Gera Parcial     
             BEGIN
               
               FOR EMP2 IN (SELECT * FROM MAX_EMPRESA A
                 WHERE A.STATUS = 'A'
                 AND   A.NROEMPRESA < 500
                 AND   A.NROEMPRESA IN (SELECT * FROM TABLE(CONSINCO.FC5_STRTOKENIZE(PSNROEMPRESA, ',')))
                 ORDER BY 1 )
                 
               LOOP
                ESPP_CPT_GERACARGATOLETO(EMP2.NROEMPRESA,SYSDATE, 'N');
               END LOOP;
                COMMIT;
             END;
           --
           END IF;
    END LOOP;
   EXCEPTION
     WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR (-20200, SQLERRM );
END SPMRL_CARGALST_V2;