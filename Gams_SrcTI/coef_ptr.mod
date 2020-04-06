*=============================================================================*
* COEF_PTR is the coef and control with regard to which VAR_FLOs to create    *
*=============================================================================*
*GaG Questions/Comments:
*-----------------------------------------------------------------------------*
* hold on to the most granular specification for the p/c/s dealing with
*V06a_3 xeq - build intermediate test sets
    SET CGTEST(REG,ALLYEAR,PRC,CG,C,CG) //;
    SET CGTEST2(R,ALLYEAR,P,CG,C,CG) //;
    PARAMETER CGTS(R,S,S) //;
* [AL] Changed the building of CGTEST
* Add FLO_SUM tuples; Accept any RPC for the single commodity:
    OPTION CGTEST <= FLO_SUM;
    CGTEST(R,V,P,COM_GRP,C,CG)$(NOT RPC(R,P,C)) = NO;
* Add reverse FLO_FUNCs for matching FLO_SUM (cg2=cg1):
    LOOP((CGTEST(R,V,P,COM_GRP,C,CG),TS)$FLO_FUNC(R,V,P,CG,COM_GRP,TS),CG_GRP(R,P,COM_GRP,CG) = YES;);
    CGTEST(RTP(R,V,P),COM_GRP,C,CG)$((COM_GMAP(R,COM_GRP,C)*RPC(R,P,C))$CG_GRP(R,P,COM_GRP,CG)) = YES;
* Add forward FLO_FUNCs including all RPC in CG1:
    LOOP((RTP(R,V,P),COM_GRP,CG,TS)$FLO_FUNC(R,V,P,COM_GRP,CG,TS),
      CGTEST(R,V,P,COM_GRP,C,CG)$(COM_GMAP(R,COM_GRP,C)*RPC(R,P,C)) = YES;);

* [AL] Changed loop to direct assignment for speed-up
    COEF_PTRAN(CGTEST(R,V,P,COM_GRP,C,CG),TS)$(PRC_TS(R,P,TS)*
* a flo_sum for the c in cg1 or
* a flo_func for cg2 (as according to cgtest there must also be a flo_sum for some c in cg1), or
                ((FLO_SUM(R,V,P,COM_GRP,C,CG,TS)+FLO_FUNC(R,V,P,CG,COM_GRP,TS))$(NOT FLO_FUNC(R,V,P,COM_GRP,CG,TS)) +
* a flo_func for cg1 without a flo_sum for cg2
                 (NOT SUM(COM$FLO_SUM(R,V,P,CG,COM,COM_GRP,TS),1))$FLO_FUNC(R,V,P,COM_GRP,CG,TS)
                )
              ) =
       ((1+(1/FLO_FUNC(R,V,P,CG,COM_GRP,TS)-1)$FLO_FUNC(R,V,P,CG,COM_GRP,TS))$(NOT FLO_FUNC(R,V,P,COM_GRP,CG,TS)) + 
        FLO_FUNC(R,V,P,COM_GRP,CG,TS)) *
       (1$(NOT FLO_SUM(R,V,P,COM_GRP,C,CG,TS)) + FLO_SUM(R,V,P,COM_GRP,C,CG,TS));

* identify which coef_ptran need to be assigned
    OPTION CLEAR=TRACKPC;
    LOOP(RPCS_VAR(R,P,C,S)$(NOT PRC_TS(R,P,S)), TRACKPC(R,P,C) = YES);
    CGTEST2(CGTEST(R,V,P,COM_GRP,C,CG))$TRACKPC(R,P,C) = YES;
    CGTS(RS_TREE(R,S,TS))$(ORD(S)<>ORD(TS)) = RS_FR(R,TS,S);
*    display rps_s2, cgtest, cgtest2, coef_ptran;
*V0.5a 980806 - assign up/down to VAR level
    COEF_PTRAN(CGTEST2(R,V,P,COM_GRP,C,CG),S)$RPCS_VAR(R,P,C,S) =
               SUM(TS$CGTS(R,S,TS), COEF_PTRAN(R,V,P,COM_GRP,C,CG,TS) * CGTS(R,S,TS));
    COEF_PTRAN(CGTEST2(R,V,P,COM_GRP,C,CG),S)$PRC_TS(R,P,S) = 0;
    OPTION CG_GRP <= CGTEST;

$IF %RELAX_PRC_CG%==YES OPTION RP_GRP <= CG_GRP; PRC_CG(RP_GRP)=YES; OPTION RP_GRP < CG_GRP; PRC_CG(RP_GRP)=YES; OPTION CLEAR=RP_GRP;

* Build the control set for EQ_PTRANS by removing REDUCEd tuples:
  CG_GRP(RPCC_FFUNC) = NO;
  OPTION RPCC_FFUNC <= CG_GRP;

* Remove derived commodities not in process topology
  RPCC_FFUNC(R,P,CG,C)$(RC(R,C)$(NOT RPC(R,P,C))) = NO;

* Free memory
  OPTION CLEAR=TRACKPC,CLEAR=CG_GRP,CLEAR=CGTEST,CLEAR=CGTEST2;

*------------------------------------------------------------------------------
* Shaping of COEF_PTRANS
*------------------------------------------------------------------------------
  PARAMETER RTP_FFCX(R,ALLYEAR,ALLYEAR,P,CG,CG) //;
  SET AGEJ(J,AGE) / 1.1 /;

* Remove FLO_FUNCX indexes that won't have any effect
  Z=CARD(J)/2+1;
  FLO_FUNCX(R,V,P,CG1,CG2)$(ABS(FLO_FUNCX(R,V,P,CG1,CG2)-Z)>Z-1.5) = 0;
  OPTION CLEAR=TRACKP; OPTION CLEAR=PRC_YMAX;
  LOOP((RTP(R,V,P),CG1,CG2)$FLO_FUNCX(R,V,P,CG1,CG2), TRACKP(R,P) = YES;);
  TRACKP(R,P)$(NOT PRC_VINT(R,P)) = NO;

  IF(CARD(TRACKP), LOOP(AGEJ(J,AGE),
    LOOP(V,
*   Set the starting and ending years taking into account NCAP_ILED:
      PRC_YMIN(TRACKP(R,P)) = B(V)+ROUND(NCAP_ILED(R,V,P));
      PRC_YMAX(TRACKP(R,P)) = PRC_YMIN(R,P)+ROUND(NCAP_TLIFE(R,V,P))-1;
*   Calculate average SHAPE for plants still operating in each period:
      RTP_FFCX(RTP_VINTYR(R,V,T,P),CG1,CG2)$FLO_FUNCX(R,V,P,CG1,CG2) =
        SUM(PERIODYR(T,EOHYEARS)$(YEARVAL(EOHYEARS) LE MAX(B(T),PRC_YMAX(R,P))),
          SHAPE(J+(FLO_FUNCX(R,V,P,CG1,CG2)-1),AGE+(MIN(YEARVAL(EOHYEARS),PRC_YMAX(R,P))-PRC_YMIN(R,P))))
        / (MAX(1,MIN(E(T),PRC_YMAX(R,P))-MAX(B(T),PRC_YMIN(R,P))+1)) -1;
  );
* For repeated investments, use the average SHAPE over lifetime:
    LOOP(TT, PRC_YMAX(TRACKP(R,P)) = ROUND(NCAP_TLIFE(R,TT,P))$(COEF_RPTI(R,TT,P) GT 1);
      RTP_FFCX(RTP_VINTYR(R,TT,T,P),CG1,CG2)$(PRC_YMAX(R,P)*FLO_FUNCX(R,TT,P,CG1,CG2)) =
        SUM(LIFE$(ORD(LIFE) LE PRC_YMAX(R,P)),SHAPE(J+(FLO_FUNCX(R,TT,P,CG1,CG2)-1),LIFE))
        / PRC_YMAX(R,P) -1;);
  ));
  OPTION CLEAR=PRC_YMIN,CLEAR=PRC_YMAX,CLEAR=TRACKP;
