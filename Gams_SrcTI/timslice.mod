*=============================================================================*
* Timslice.mod - Auxiliary timeslice preprocessing
*=============================================================================*
* SET and PARAMETER declarations moved to initmty.mod
*-----------------------------------------------------------------------------
* complete timeslice declarations
*   - all below ANNUAL
*   - each individual to itself, including leaves
*   - all TS below a node
*-----------------------------------------------------------------------------
SET RJLVL(J,R,TSLVL), RLUP(R,TSL,TSL);
PARAMETERS RS_HR(R,S) //, MY_SUM /0/;
*-----------------------------------------------------------------------------
   TS_GROUP(ALL_REG,'ANNUAL',ANNUAL) = YES;
   TS_MAP(R,ANNUAL,S)$SUM(TSLVL,TS_GROUP(R,TSLVL,S)) = YES;
   TS_MAP(R,S,S)$SUM(ANNUAL,TS_MAP(R,ANNUAL,S))      = YES;
   TS_MAP(R,ALL_TS,TS)$SUM(S$TS_MAP(R,ALL_TS,S),TS_MAP(R,S,TS)) = YES;
*-- Build a set for timeslices strictly below
   RS_BELOW(TS_MAP(R,S,TS))$(NOT TS_MAP(R,TS,S)) = YES;
*-- Build a set for timeslices strictly ONE level below
   RS_BELOW1(R,S,TS)$(SUM(TS_MAP(R,S,ALL_TS),RS_BELOW(R,ALL_TS,TS)*1) = 1) = YES;

*-----------------------------------------------------------------------------
* Set the annual year fraction to 1
  G_YRFR(ALL_R,'ANNUAL') = 1;
* Complete missing year fractions if non-zero fractions are given for timeslices right below:
  G_YRFR(R,TS)$((G_YRFR(R,TS) LE 0)$TS_GROUP(R,'WEEKLY',TS)) $= SUM(RS_BELOW1(R,TS,S),G_YRFR(R,S));
  G_YRFR(R,TS)$((G_YRFR(R,TS) LE 0)$TS_GROUP(R,'SEASON',TS)) $= SUM(RS_BELOW1(R,TS,S),G_YRFR(R,S));

*-----------------------------------------------------------------------------
* Remove timeslices that have a zero time fraction
  LOOP(TSLVL,FINEST(R,TS)$((G_YRFR(R,TS) LE 0)$TS_GROUP(R,TSLVL,TS)) = YES);
  TS_GROUP(R,TSLVL,S)$FINEST(R,S) = NO;
  TS_MAP(R,TS,S)$FINEST(R,S) = NO;
  RS_BELOW(R,TS,S)$FINEST(R,S) = NO;
  RS_BELOW1(R,TS,S)$FINEST(R,S) = NO;
  OPTION CLEAR=FINEST;
* Build a set for all timeslices in the same subtree
  RS_TREE(R,S,TS)$(TS_MAP(R,TS,S) OR RS_BELOW(R,S,TS)) = YES;
*-----------------------------------------------------------------------------

* Target accuracy of timeslice fractions: 1 second
  Z = 8760*3600;
* Normalize all year fractions if they do not sum up right:
  LOOP(TS_GROUP(ALL_R,TSLVL,S)$(TSLVLNUM(TSLVL)<4),
*  Get the year fraction of current timeslice and sum of those below
   MY_F = G_YRFR(ALL_R,S);
   MY_SUM = SUM(RS_BELOW1(ALL_R,S,TS), G_YRFR(ALL_R,TS));
*  If the sum differs from the lump sum by over a second, do normalize:
   IF(ABS(MY_SUM-MY_F)*Z GT 1, G_YRFR(ALL_R,TS)$RS_BELOW1(ALL_R,S,TS) = MY_F*G_YRFR(ALL_R,TS)/MY_SUM));

*-----------------------------------------------------------------------------
*-- Define the set of the finest (highest) timeslices in use:
    FINEST(R,S) = YES$(SUM(TS_MAP(R,S,ALL_TS),1) EQ 1);
    LOOP(SAMEAS('5',J),RJLVL(J-ORD(TSL),R,TSL)=SUM(TS_GROUP(R,TSL,S),1));

*-- Calculate the number of storage periods for each timeslice
    IF(G_CYCLE('WEEKLY')=0, G_CYCLE('WEEKLY')=8760/(24*7));
    LOOP(TSLVL,RS_STGPRD(R,S)$TS_GROUP(R,TSLVL,S) = MAX(1,SUM(RS_BELOW1(R,TS,S),G_YRFR(R,TS))*G_CYCLE(TSLVL)));

* Timeslice level for all timeslices
  LOOP(TSLVL, RS_TSLVL(R,S)$TS_GROUP(R,TSLVL,S) = TSLVLNUM(TSLVL));
*-- Calculate the lead from previous storage timeslice for each timeslice
  LOOP(TS_MAP(R,ANNUAL,S), F=0;
   LOOP(RS_BELOW1(R,S,TS), IF(F, RS_STG(R,TS)=ORD(TS)-Z; Z=ORD(TS); ELSE Z=ORD(TS); F=Z));
   RS_STG(R,S+(F-ORD(S)))$F = F-Z;);
*-- Calculate average residence time for storage activity in each timeslice
  LOOP((R,S,TS(S--RS_STG(R,S)))$RS_STGPRD(R,S),RS_STGAV(R,S) = (G_YRFR(R,S)+G_YRFR(R,TS))/2/RS_STGPRD(R,S));
  RS_STGAV(R,ANNUAL) = 1;

  OPTION STOAL<RS_BELOW1; STOAL(R,S)$(STOAL(R,S)=1)=0;
  IF(CARD(STOAL),PUTGRP=0;
    LOOP((R,S)$STOAL(R,S),
$   BATINCLUDE pp_qaput.mod PUTOUT PUTGRP 99 'Duplicate parent timeslices - Fatal'
    PUT QLOG ' FATAL ERROR   -    REG=',R.TL,' TS='S.TL));
* Define the lags to the ANNUAL timeslice for all S
  LOOP(ANNUAL(TS), STOA(S) = ORD(TS)-ORD(S));
  LOOP(TSL,STOAL(R,S)$TS_GROUP(R,TSL,S) = ORD(TSL)-1);
* Define above-map for TSL, and time-sequence
  LOOP((J,R,TSL)$RJLVL(J,R,TSL),Z=ORD(J);LOOP(RJLVL(JJ,R,TSLVL)$(ORD(JJ)>Z),RLUP(R,TSL,TSLVL)=1;Z=9));
  IF(CARD(RP_UPR)+CARD(RP_UPT),LOOP(TS_MAP(R,ANNUAL,TS),F=0;Z=0;LOOP(RS_BELOW1(R,TS,S),F=G_YRFR(R,S)/RS_STGPRD(R,S);RS_HR(R,S)=Z+F/2;Z=Z+F)));
