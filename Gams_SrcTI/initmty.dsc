*=============================================================================
* INIT DECLARATIONS FOR THE DSC EXTENSION
*=============================================================================
$SETGLOBAL DSC YES
$IF NOT %DSC%==YES $ABORT Activation of DSC extension failed
*-----------------------------------------------------------------------------
* Sets and parameters for discrete capacity extension
SET       UNIT                                   'Number of different units'            / 0*100 /;
SET       PRC_DSCNCAP(R,P)                       'Processes with discrete capacity additions';
PARAMETER NCAP_DISC(R,ALLYEAR,P,UNIT)            'Unit size of discrete capacity addition';
PARAMETER NCAP_SEMI(R,ALLYEAR,P)                 'Semi-continuous capacity, lower bound';
*PARAMETER NCAP_CSTD(REG,ALLYEAR,PRC,CUR,UNIT)   'Investment cost of unit'                     //;
*PARAMETER NCAP_FOMD(REG,ALLYEAR,PRC,CUR,UNIT)   'Fixed operating and maintenace cost of unit' //;
