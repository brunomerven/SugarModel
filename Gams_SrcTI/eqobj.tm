*=============================================================================*
* EQOBJ the objective functions                                               *
*   %1 - mod or v# for the source code to be used                             *
*=============================================================================*
*GaG Questions/Comments:
*10/21
*  - V-index used in place to T for MODLYEAR
* Note: PASTYEAR always have D(V) = 1
*  - V-vintage MODLYEAR year, the point in time where the investment took place
*-----------------------------------------------------------------------------

  SET K_EOH(ALLYEAR);

* [UR] 21.06.2003: K_EOH must include pastyears, since in eqobjfix.mod it links to past vintages
  K_EOH(EACHYEAR)$((YEARVAL(EACHYEAR) >= PYR_V1) * (YEARVAL(EACHYEAR) <= MIYR_VL)) = YES;

* Set for periodic investments
  SET PERDINV(ALLYEAR,ALLYEAR) //;
  PERDINV(YK(T,K))$(YEARVAL(K) > M(T)-LEAD(T)) = YES;
  SET KYAGE(ALLYEAR,ALLYEAR,AGE);
  LOOP(SAMEAS('1',AGE),KYAGE(K(LL),Y_EOH(YEAR),AGE+(ORD(YEAR)-ORD(LL)))$YK(YEAR,LL) = YES);

* Cases for ILED and TLIFE/D(t); values assigned in EQOBJINV
  SET OBJ_1A(R,ALLYEAR,P) //;
  SET OBJ_1B(R,ALLYEAR,P) //;
  SET OBJ_2A(R,ALLYEAR,P) //;
  SET OBJ_2B(R,ALLYEAR,P) //;
* Salvage controls
  SET OBJ_SUMS(R,ALLYEAR,P)   //;
  SET OBJ_SUMS3(R,ALLYEAR,P)  //;
  SET OBJ_SUMSI(R,ALLYEAR,P,ALLYEAR) //;
  PARAMETER OBJ_DCEOH(REG,CUR) //;

*===============================================================================
* Investment Cost, Fixed Cost and Variable Cost components
*===============================================================================
$   BATINCLUDE eqobjinv.mod tm exit
$   BATINCLUDE eqobjfix.mod tm exit
$   BATINCLUDE eqobjann.tm

*===============================================================================
* Elastic Demand costs: not included
*===============================================================================

*===============================================================================
* Actual OBJ
*===============================================================================
    EQ_OBJ(R,T) ..

      SUM(RDCUR(R,CUR),

* Investment Costs, Fixed Costs and Variable Costs

         SUM(OBVANN,VAR_ANNCST(OBVANN,R,T,CUR))

* Elastic Demand costs not included

         )

    =E=

    VAR_OBJCOST(R,T);

* Clears in INITCLR.MOD
