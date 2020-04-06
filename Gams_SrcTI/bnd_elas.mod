*=============================================================================*
* BND_ELAS.MOD establishes bounds on demand elasticity variables
*   %1 - LO/UP step limit
*=============================================================================*
* Questions/Comments:
* - RCJ includes testing for COM_STEP
* - May want elasticity without COM_PROJ - may use COM_BQTY
*-----------------------------------------------------------------------------
  OPTION CLEAR=MI_DOPE;
  LOOP((ANNUAL(S),MI_DMAS(RD_AGG(R,C),COM)),
    RD_SHAR(R,T,COM,C)=COM_AGG(R,T,COM,C)*DDF_PREF(R,T,C);
    COM_AGG(R,T,COM,C)$(COM_ELAST(R,T,C,S,'N')>0)=0;
    MI_DOPE(R,T,COM)$MI_ESUB(R,T,C)=SUM(BDNEQ$COM_ELAST(R,T,C,S,BDNEQ),1)$COM_ELAST(R,T,C,S,'FX')+(COM_ELAST(R,T,C,S,'N')<0));

$IF %STAGES% == YES LOOP(SW_T(T%SOW%),

    %VAR%_ELAST.UP(R,T,C,S,J,BDNEQ(BD)%SOW%)$(COM_TS(R,C,S)$RCJ(R,C,J,BD)) = INF$MI_DOPE(R,T,C) +
      (MAX(DDF_QREF(R,T,C) * COM_FR%MX%(R,T,C,S), COM_BQTY(R,C,S)) * COM_VOC(R,T,C,BD)) / COM_STEP(R,C,BD);

$IF %STAGES% == YES );

* Price levels for CES (marginal / average)
  MI_AGC(R,T(TT+1),COM,C,J,BDNEQ(BD))$(RCJ(R,C,J,BD)$MI_DMAS(R,COM,C)$MI_ESUB(R,T,COM)) = (1-BDSIG(BD)*(ORD(J)-.5)*COM_VOC(R,T,C,BD)/COM_STEP(R,C,BD))**(-1/MI_ESUB(R,T,COM));
  MI_AGC(R,T,COM,C,J,BD)$(MI_AGC(R,T,COM,C,J,BD)$MI_DOPE(R,T,C)) = BDSIG(BD)*
    (1-(1-BDSIG(BD)*ORD(J)*COM_VOC(R,T,C,BD)/COM_STEP(R,C,BD))**(1-1/MI_ESUB(R,T,COM)))/(ORD(J)*COM_VOC(R,T,C,BD)/COM_STEP(R,C,BD))/(1-1/MI_ESUB(R,T,COM));

  COM_ELASTX(R,T,C,BDNEQ)$MI_DOPE(R,T,C)=1;
  RTC_SHED(R,T,C,BD,JJ)$MI_DOPE(R,T,C)=NO;
