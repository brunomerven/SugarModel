*=============================================================================*
* BND_ACT.MOD set the actual bounds for non-vintage VAR_ACTs
*=============================================================================*
*GaG Questions/Comments:
*  - FX take precedence as is set last!!!
*-----------------------------------------------------------------------------
*$ONLISTING
* reset any existing bounds
  %VAR%_ACT.LO(R,V,T,P,S%SWD%) = 0;
  %VAR%_ACT.UP(R,V,T,P,S%SWD%) = INF;
* assign from user data
*V0.5b 980902 - only set bounds directly at the PRC_TS level, and watch for INF

$IF %STAGES% == YES $SETLOCAL SWT SW_T(T%SWD%)$

  %VAR%_ACT.LO(RTP_VINTYR(R,T,T,P),S%SWD%)$(%SWT% PRC_TS(R,P,S) * (NOT PRC_VINT(R,P))) $= ACT_BND(R,T,P,S,'LO');
  %VAR%_ACT.UP(RTP_VINTYR(R,T,T,P),S%SWD%)$(%SWT% PRC_TS(R,P,S) * (NOT PRC_VINT(R,P))) $= ACT_BND(R,T,P,S,'UP');
  %VAR%_ACT.FX(RTP_VINTYR(R,T,T,P),S%SWD%)$(%SWT% PRC_TS(R,P,S) * (NOT PRC_VINT(R,P))) $= ACT_BND(R,T,P,S,'FX');
* for an upper bound of zero, activity variables of all vintages can be bounded to zero
  %VAR%_ACT.UP(RTP_VINTYR(R,V,T,P),S%SWD%)$(%SWT% PRC_TS(R,P,S) * PRC_VINT(R,P)$RTPS_OFF(R,T,P,S)) = EPS;

*$OFFLISTING
