*=============================================================================*
* ERR_STAT.MOD checks/displays GAMS/Solver Errors
*   %1 - Condition to be checked or 'SOLVE'  used
*   %2 - Action or Condition to be checked
*   %3 - Error Message if Not SOLVE
*=============================================================================*
*GaG Questions/Comments:
*  - for %system.filesys% == UNIX file /dev/tty
*  - does not affect stopping BAT
*-----------------------------------------------------------------------------
*$ONLISTING
$ IFI NOT %SHELL%==ANSWER $SET TMP END_GAMS
$ IFI %SHELL%==ANSWER     $SET TMP END_GAMS.STA
$ IF "%1" == SOLVE        $GOTO SOLVE
$ IF DEFINED SOLVESTAT    $GOTO ACTION
*------------------------------------------------------------------------------
SET SOLVESTAT(J) /
  1 "Optimal"
  2 "Locally optimal"
  3 "Unbounded"
  4 "Infeasible"
  5 "Locally infeasible"
  6 "Intermediate infeasible"
  7 "Intermediate nonoptimal"
  8 "Integer solution"
  9 "Intermediate non-integer"
 10 "Integer infeasible"
 12 "Error unknown"
 13 "Error no solution"
/;
FILE SCREEN / CON /;
FILE END_GAMS / %TMP% /;
*------------------------------------------------------------------------------
$LABEL ACTION

$ IF %ERR_ABORT% == 'NO'  $GOTO DONE
%4;
* compile or GAMS execute error
$IF NOT ERRORFREE $ECHO %3%5 > %TMP%
 IF(execerror,PUT END_GAMS "%3%5"; PUTCLOSE END_GAMS);
%1 $%2  "%3"
$GOTO DONE

$LABEL SOLVE
Z = MIN(14,%MODEL_NAME%.MODELSTAT)-1; IF(Z GT 12, Z = 11);
PUT SCREEN /"--- TIMES Solve status: ";
LOOP(SAMEAS(J,'1'), PUT SOLVESTAT.TE(J+Z) ;);
PUTCLOSE screen;
PUT END_GAMS "Solve status: ";
LOOP(SAMEAS(J,'1'), PUT SOLVESTAT.TE(J+Z) /;);
PUTCLOSE END_GAMS;

* [UR] allow solution "opimal with unscaled infeasibilities"
*ABORT$((%MODEL_NAME%.MODELSTAT GT 1) OR (%MODEL_NAME%.SOLVESTAT GT 1)) '*** ERRORS IN OPTIMIZATION ***'
ABORT$((%MODEL_NAME%.MODELSTAT GT 2) AND (%MODEL_NAME%.MODELSTAT NE 8)) '*** ERRORS IN OPTIMIZATION ***'
$LABEL DONE
*$OFFLISTING
;
