*******************************************************************************
* FILLVINT : Optional weighting of vintaged attributes
* Description: Weighting of vintaged parameters
* Parameters:
*      %1 - table name
*      %2 - Control set 1
*      %3 - Control set 2
*      %4 - Name for temporary cache
*******************************************************************************
*$ONLISTING
$EOLCOM !
$ IF NOT '%4'=='' $GOTO FILL
*------------------------------------------------------------------------------
* Initialization
  OPTION CLEAR=PRC_YMIN;
$IF %VINTOPT%==2 PRC_SIMV(PRC_VINT(R,P)) = NOT PRC_MAP(R,'STG',P);
$IF DEFINED PRC_SIMV PRC_SIMV(R,P)$PRC_MAP(R,'STG',P) = NO; PRC_VINT(PRC_SIMV(R,P)) = YES;
* Make sure that all PRC_VINT have first leading V in RTP:
  LOOP(MIYR_1(LL), Z = YEARVAL(LL);
    LOOP(T, PRC_YMIN(PRC_VINT(R,P))$((NOT PRC_YMIN(R,P))*RTP(R,T,P)) = YEARVAL(T)-LEAD(T)-Z+EPS);
    RTP(R,LL+PRC_YMIN(R,P),P)$PRC_YMIN(R,P) = YES);
$IF NOT %VINTOPT%==1 $EXIT
  PASTSUM(RTP(R,T,P))$PRC_VINT(R,P) = 
    MIN(1,(MAX(YEARVAL(T)-(LEAD(T)-1)/2,B(T)+MAX(NCAP_ILED(R,T,P),(D(T)+NCAP_ILED(R,T,P)-NCAP_TLIFE(R,T,P))/2)) -
           (YEARVAL(T)-LEAD(T))) / LEAD(T));
$EXIT
*------------------------------------------------------------------------------
$ LABEL FILL
  PARAMETER %4(%2,%3,ALLYEAR);
  TRACKP(PRC_VINT(R,P)) = YES;
$IF DEFINED PRC_SIMV TRACKP(PRC_SIMV(R,P)) = NO;
* Weighted average of vintages T and T-1
  LOOP((T(LL),V(LL-LEAD(LL))),
    %4(%2,%3,T)$(%1(%2,T,%3)$TRACKP(R,P)) = %1(%2,T,%3)*PASTSUM(R,T,P)+%1(%2,V,%3)*(1-PASTSUM(R,T,P)));
  %1(%2,T,%3) $= %4(%2,%3,T);
  OPTION CLEAR=%4,CLEAR=TRACKP;
$OFFLISTING
