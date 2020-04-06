*=============================================================================*
* EQ_UC - user constraints
*   %1  - mod or v# for the source code to be used
*   %2  - equation declaration type
*   %3  - equation name suffix and condition of existence of equation
*   %4  - region summation index or bracket
*   %5  - period summation index or bracket
*   %6  - time-slice summation index or bracket
*   %7  - summand for region
*   %8  - 0 if UC_DYN=EACH, 1 if UC_DYN=SUCC, 2 if SEVERAL
*   %9  - UC variable name
*   %10 - UC RHS parameter
*=============================================================================*
*UR Questions/Comments:
*       -
*-----------------------------------------------------------------------------
*$ONLISTING

    %EQ%%2_UC%3..

******************************************************************************
* Flow related terms
*  - only one of the two summands is generated depending
*    if the user-constraint is user-constraint or not
******************************************************************************

$IF %8==1 $GOTO DYNAMIC
$SETLOCAL HS "'LHS'"
$IF %8==2 $SET SOW '%SWD%' SET SWT %SOW%
$IF %8==S $SETLOCAL HS SIDE
* NO dynamic constraint or LHS of dynamic constraint
*  terms with T as period index are defined as LHS

$   batinclude  uc_flo.%1   %4%7 %5 %6  T "%HS%" %8 T %7
+
$   batinclude  uc_ncap.%1  %4%7 %5     T "%HS%" %8 T
+
$   batinclude  uc_cap.%1   %4%7 %5     T "%HS%" %8 T
+
$   batinclude  uc_act.%1   %4%7 %5 %6  T "%HS%" %8 T
+
$   batinclude  uc_compd.%1 %4%7 %5 %6  T "%HS%" %8 T %7
+
$   batinclude  uc_comnt.%1 %4%7 %5 %6  T "%HS%" %8 T
+
$   batinclude  uc_ire.%1   %4%7 %5 %6  T "%HS%" %8 T

$GOTO SIGN
$LABEL DYNAMIC
* Dynamic constraint
$SET SWFLO %VAR%
$IF %STAGES% == YES $SET VAR 'SUM(%5%VAR%' SET SOW ',WW)' SET SWFLO %VAR% ,WW SUM %5
+
(
*  terms with T+1 as period index are defined as RHS
*  Constraints are generated for years 1..CARD(T)-1 only
$SETLOCAL TSUM SUM(UC_TMAP(TT,T,T,SIDE,'N'),UC_SIGN(SIDE)*

$     batinclude  uc_flo.%1 %4%7 %TSUM% %6   TT SIDE %8 TT LAGT(T) %SWFLO%
+
$     batinclude  uc_ncap.%1 %4%7 %TSUM%     TT SIDE %8 TT LAGT(T)
+
$     batinclude  uc_cap.%1 %4%7 %TSUM%      TT SIDE %8 TT LAGT(T)
+
$     batinclude  uc_act.%1 %4%7 %TSUM% %6   TT SIDE %8 TT LAGT(T)
+
$     batinclude  uc_compd.%1 %4%7 %TSUM% %6 TT SIDE %8 TT LAGT(T)
+
$     batinclude  uc_comnt.%1 %4%7 %TSUM% %6 TT SIDE %8 TT LAGT(T) %7
+
$     batinclude  uc_ire.%1 %4%7 %TSUM% %6   TT SIDE %8 TT LAGT(T)

)$(NOT SUM(UC_DYNDIR(R,UC_N,'RHS'),1))
+
(
*  terms with T-1 as period index are defined as RHS
*  Constraints are generated for all MILESTONYR
$SETLOCAL TSUM "SUM(UC_TMAP(T,LL,TT,SIDE,UC_DYNT)$(LIM(UC_DYNT) xor UC_ATTR(R,UC_N,SIDE," SETLOCAL TUCN ,UC_DYNT)),UC_SIGN(SIDE)*

$     batinclude  uc_flo.%1 %4%7   "%TSUM%'FLO'%TUCN%" %6    TT SIDE %8 LL -LEAD(T) %SWFLO%
+
$     batinclude  uc_ncap.%1 %4%7  "%TSUM%'NCAP'%TUCN%"      TT SIDE %8 LL -LEAD(T)
+
$     batinclude  uc_cap.%1 %4%7   "%TSUM%'CAP'%TUCN%"       TT SIDE %8 LL -LEAD(T)
+
$     batinclude  uc_act.%1 %4%7   "%TSUM%'ACT'%TUCN%" %6    TT SIDE %8 LL -LEAD(T)
+
$     batinclude  uc_compd.%1 %4%7 "%TSUM%'COMPRD'%TUCN%" %6 TT SIDE %8 LL -LEAD(T)
+
$     batinclude  uc_comnt.%1 %4%7 "%TSUM%'COMCON'%TUCN%" %6 TT SIDE %8 LL -LEAD(T) %7
+
$     batinclude  uc_ire.%1 %4%7   "%TSUM%'IRE'%TUCN%" %6    TT SIDE %8 LL -LEAD(T)
* Climate extension
$IF %CLI%==YES $batinclude uc_cli.%1 %4%7 "%TSUM%'CLI'%TUCN%" %6 'TT' SIDE %8 LL -LEAD(T)
-
* For UC_CAP, take into account PASTI inherited to first period
$     batinclude  uc_pasti.%1 %4%7 MIYR_1 T "'RHS'"

)$SUM(UC_DYNDIR(R,UC_N,'RHS'),1)

$LABEL SIGN

        =%2=

$IF %VAR_UC% == YES        %9
* [AL] GAMS may signal infeasibility if LHS is empty and RHS is EPS!
$IF NOT %VAR_UC% == YES    %10$(%10 NE 0)

*---- Add Time Constant (%5 includes ()
$IF NOT %8==1 +SUM((%7V(T))$UC_TIME(UC_N,R,T), %5 UC_TIME(UC_N,R,T)*FPD(T)))
$IF %8==1     +SUM((%7V(T))$UC_TIME(UC_N,R,T), UC_TIME(UC_N,R,T)*(LEAD(T)$UC_DYNDIR(R,UC_N,'RHS')+LAGT(T)$(NOT UC_DYNDIR(R,UC_N,'RHS'))))

   ;

*$OFFLISTING
