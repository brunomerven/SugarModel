*=============================================================================*
* PP_MICRO.MOD coefficient calculations for the Micro extension
*=============================================================================*
  SET MI_DMAS(REG,COM,COM);
  PARAMETERS DDF_QREF(R,T,C), DDF_PREF(R,T,C);
  PARAMETERS
    MI_AGC(R,T,C,C,J,L) integral demand prices //
    MI_DOPE(R,T,C) demand own price elasticity //
    MI_ESUB(R,T,C) elasticity of substitution  //;
$ GOTO %1
*-----------------------------------------------------------------------------
$LABEL PRE
* Identify aggregation groups
  OPTION MI_DMAS<COM_AGG, OBJ_PVT<SOL_BPRICE; MI_DMAS(R,C,COM)$COM_GMAP(R,C,C)=NO;
  MI_DMAS(R,C,COM)$(NOT DEM(R,COM)*COM_TMAP(R,'DEM',C)*COM_TSL(R,C,'ANNUAL')) =NO;
  MI_DMAS(R,COM,C)$SUM(MI_DMAS(R,C,COM2),1)=NO; OPTION RD_AGG<=MI_DMAS; DEM(RD_AGG)=YES;
* Preprocess elasticities
  MI_ESUB(R,T,C)$DEM(R,C) = ABS(COM_ELAST(R,T,C,'ANNUAL','N'));
  MI_ESUB(R,T,C)$((MI_ESUB(R,T,C)=1)$MI_ESUB(R,T,C)) = 0.9999;
  COM_ELAST(RTC,S,BDNEQ)$(NOT COM_ELAST(RTC,S,BDNEQ)) $= COM_ELAST(RTC,S,'FX');
  LOOP(MI_DMAS(R,COM,C),COM_ELAST(R,T,C,S,BDNEQ)$COM_TS(R,C,S)=MIN(COM_ELAST(R,T,C,S,BDNEQ),-MI_ESUB(R,T,COM)));
* Get base prices and set price ratio
  DDF_PREF(R,T,C)$DEM(R,C) = SUM((COM_TS(R,C,S),RDCUR(R,CUR)),SOL_BPRICE(R,T,C,S,CUR)*COM_FR(R,T,C,S));
  DDF_PREF(R,T,C)$RD_AGG(R,C) = SUM(MI_DMAS(R,C,COM),COM_PROJ(R,T,COM)*DDF_PREF(R,T,COM))/SUM(MI_DMAS(R,C,COM),COM_PROJ(R,T,COM));
  COM_AGG(R,T,COM,C)$((COM_AGG(R,T,COM,C)=0)$MI_DMAS(R,C,COM))=1+(DDF_PREF(R,T,COM)/DDF_PREF(R,T,C)-1)$DDF_PREF(R,T,C);
* Normalize COM_AGG
  DDF_QREF(R,T,C)$RD_AGG(R,C) = SUM(MI_DMAS(R,C,COM),COM_AGG(R,T,COM,C)*COM_PROJ(R,T,COM));
  COM_PROJ(R,T,C)$RD_AGG(R,C) = SUM(MI_DMAS(R,C,COM),COM_PROJ(R,T,COM));
  COM_AGG(R,T,COM,C)$(COM_AGG(R,T,COM,C)$RD_AGG(R,C))=COM_AGG(R,T,COM,C)*COM_PROJ(R,T,C)/DDF_QREF(R,T,C);
* Finalize values with COM_AGG
  DDF_QREF(R,T,C) $= COM_PROJ(R,T,C);
  DDF_PREF(R,T,C)$RD_AGG(R,C) = SUM(MI_DMAS(R,C,COM),DDF_QREF(R,T,COM)*DDF_PREF(R,T,COM))/DDF_QREF(R,T,C);
  COM_BPRICE(R,T(TT+1),C,ANNUAL,CUR)$(OBJ_PVT(R,T,CUR)$RD_AGG(R,C)) = DDF_PREF(R,T,C);
  RD_SHAR(R,T,C,COM)$MI_DMAS(R,C,COM) = DDF_QREF(R,T,COM) / DDF_QREF(R,T,C);

  OPTION TRACKC < RD_SHAR;
  COM_PROJ(R,T,C)$TRACKC(R,C)=0;
  RHS_COMBAL(RTCS_VARC(R,T,C,S))$=TRACKC(R,C);
  RHS_COMPRD(R,T,C,ANNUAL)$=RD_AGG(R,C);
  OPTION CLEAR=TRACKC,CLEAR=OBJ_PVT;
$EXIT
*-----------------------------------------------------------------------------
$LABEL NLP
$IF %STAGES%==YES $ABORT Non-linear Micro not available with stochastics
  PARAMETERS
    MI_ELASP(R,T,C) consumer surplus elasticity     //
    MI_CCONS(R,T,C) constant of the demand function //
    MI_RHO(R,T,C)   measure of substitutability     //;

* Take NLP elasticities from the FX type COM_ELAST
  MI_DOPE(R,T,C)$DEM(R,C) = ABS(COM_ELAST(R,T,C,'ANNUAL','FX'));

* Initialize NLP indicator for demands
  RD_NLP(DEM) = 1;
  LOOP(T,RD_NLP(R,C)$(DDF_QREF(R,T,C)*DDF_PREF(R,T,C)*MI_DOPE(R,T,C)=0)=NO);
  TRACKC(RD_AGG(RC))$RD_NLP(RC) = YES;
  RD_AGG(RC)$RD_NLP(RC)=NO;

*-----------------------------------------------------------------------------
  MI_RHO(R,T,C)$((MI_ESUB(R,T,C)>0)$TRACKC(R,C)) = (MI_ESUB(R,T,C)-1)/MI_ESUB(R,T,C);
  RD_NLP(TRACKC(R,C))$PROD(T$(ORD(T)>1),MI_RHO(R,T,C)) = 3;
  LOOP(MI_DMAS(R,C,COM)$(RD_NLP(R,C)>2),RD_NLP(R,COM)=-1);
  RCJ(RC,J,BD)$RD_NLP(RC)=NO;
  OPTION CLEAR=TRACKC;
*-----------------------------------------------------------------------------
* Calculate demand function parameters
  RD_SHAR(R,T,C,COM)$(MI_DMAS(R,C,COM)$RD_NLP(R,C)) = COM_AGG(R,T,COM,C)*DDF_QREF(R,T,COM)/DDF_QREF(R,T,C)*(DDF_PREF(R,T,COM)/COM_AGG(R,T,COM,C)/DDF_PREF(R,T,C))**MI_ESUB(R,T,C);
  MI_ELASP(R,T,C)$((RD_NLP(R,C)>1)$DEM(R,C)) = 1 - 1/MI_DOPE(R,T,C);
  MI_CCONS(R,T,C)$((RD_NLP(R,C)>1)$DEM(R,C)) = DDF_PREF(R,T,C)*(1/MI_ELASP(R,T,C))*DDF_QREF(R,T,C)**(1/MI_DOPE(R,T,C));

* DISPLAY RD_NLP,MI_CCONS,MI_ELASP,RD_SHAR;
*-----------------------------------------------------------------------------
* Bounds section
  COM_VOC(R,T,C,BDNEQ(BD))$((NOT COM_VOC(R,T,C,BD))$RD_NLP(R,C)) = 1;
  VAR_DEM.L(R,T,C)$RD_NLP(R,C) = DDF_QREF(R,T,C);
  VAR_DEM.UP(R,T,C)$RD_NLP(R,C) = DDF_QREF(R,T,C)*(1+COM_VOC(R,T,C,'UP'));
  VAR_DEM.LO(R,T,C)$RD_NLP(R,C) = DDF_QREF(R,T,C)*MAX(.1,1-COM_VOC(R,T,C,'LO'));
  VAR_DEM.FX(R,T(MIYR_1),C)$RD_NLP(R,C) = DDF_QREF(R,T,C);
  VAR_OBJELS.LO(R,'FX',CUR)$RDCUR(R,CUR) = -INF;
