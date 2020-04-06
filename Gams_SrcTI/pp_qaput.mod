*===========================================================================*
*  PP_QAPUT.MOD - puts out an error message
*      - the group header is written on the first error for the group
*      - ERRLEV holds highest errorlevel
*    1 - main header output flag
*    2 - group header output flag
*    3 - error level (e.g., WARNING, ERROR, FATAL)
*    4 - group description
*===========================================================================*
    IF(NOT %1, %1=1; PUT QLOG @15;
      WHILE(QLOG.CC<67,PUT '*****'); PUT @21,'%SYSTEM.TITLE%':<>43 / @15 ;
      WHILE(QLOG.CC<67,PUT '*****'); PUT @29,'QUALITY ASSURANCE LOG':<>27;
    );
    IF(NOT %2, %2=1; PUT QLOG // ' *** %4 ' );

* hold highest errorlevel for shutdown or not
$IF NOT %3==* PUT QLOG / ' *%3'; ERRLEV$(%3 GT ERRLEV) = %3;