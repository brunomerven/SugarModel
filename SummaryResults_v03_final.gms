$SETGLOBAL gdxfolder C:\AnswerTIMESv6\Gams_WrkTI-Sugar\Gamssave\
$SETGLOBAL referencerun ALLTECHS


SETS
  RUN                            simulations  /BASE_AY,DONOTHING, DONOTHING_HDD, 1_CONTURB_PPA, 1_CONTURB_PPA_HI,1_CONTURB_PPA_HD, 2_ETH1GEN_L1, 2_ETH1GEN_L2, 2_ETH1GEN_L2_HDD, 3_BIOGAS, 3_BIOMTH_L1, 3_BIOMTH_L2, 3_BIOMTH_L3, 3_BIOMTH_L3_HDD /
* TIMES sets
  REG                            TIMES regions    /REGION1/
  ALLYEAR                        All Years
  T(ALLYEAR)                     Time periods
  V(ALLYEAR)                     Vintage
  S                              TIMES timeslices
  PRC                            TIMES Processes
  P(PRC)                         Processes
  COM                            TIMES Commodities
  XXX                            Needed for obj    / CUR, LEVCOST, INV /
  RPM(*)
  ITEM                           Everything

* Results
  Indicator                     Results Indicators / VariableCosts, FixedCosts, AnnInvCosts, Revenues, Obj/

;
ALIAS (ALLYEAR,AY);

PARAMETERS
* From TIMES
  F_IN(REG,AY,AY,PRC,COM,S)      Flow parameter (level of flow variable) [PJ]
  F_OUT(REG,AY,AY,PRC,COM,S)     Flow parameter (level of flow variable)[PJ]
  VARACT(REG,AY,PRC)             Activity level [PJ except for demand techs where unit will be aligned to particular demand e.g. VKM for road vehicles]
  PRC_CAPACT(REG,PRC)            Factor going from capacity to activity
  PRC_RESID(REG,AY,PRC)          Existing Capacity
  RESID(REG,AY,PRC)              Existing Capacity milestone years

  PAR_CAPL(REG,AY,PRC)           Capacity excluding existing capacity
  PAR_VCAPL(REG,AY,PRC)          Variable VAR_CAPL results as parameter
  PAR_RCAPL(REG,AY,PRC)          Early retirement of capacity results
  PAR_NCAPL(REG,AY,PRC)          New Capacity
  PAR_COMBALEM(REG,AY,COM,S)     Commodity marginal
  PAR_NCAPR(REG,AY,P,ITEM)       Levelised Cost
  NCAP_ILED(REG,AY,PRC)          TIMES lead time
  CST_INVC(REG,V,AY,PRC,XXX)     TIMES calculated annual investment costs
  CST_ACTC(REG,V,AY,PRC,RPM)     TIMES calculated annual activity costs
  CST_FIXC(REG,V,AY,PRC)         TIMES calculated annual fixed costs

  REG_OBJ(REG)                   Objective function from TIMES
  OB_ICOST(REG,PRC,XXX,AY)       Interpolated investment cost from TIMES run
  OBICOST(REG,AY,PRC)            TIMES investment cost restructured for interpolation


* For Summary
* Costs
  VariableCosts(AY,PRC,RUN)      Variable Costs
  FixedCosts(AY,PRC,RUN)         Fixed O&M Costs
  AnnInVCosts(AY,PRC,RUN)        Annualized Investment Costs

  DomesticSugarPrice(AY,RUN)     Domestic Sugar Price R per ton

  Results(Indicator, AY, PRC, RUN) Results for Dashboard


;

 FILE SATIM_Scen;


$gdxin  %GDXfolder%%referencerun%.gdx
$load PRC P COM ALLYEAR S V ITEM RPM T

DomesticSugarPrice(T,RUN) = 7088;

LOOP(RUN,

put_utilities SATIM_Scen 'gdxin' / "%GDXfolder%",RUN.TL:20;

execute_load REG_OBJ PAR_NCAPL PAR_NCAPR PRC_RESID PRC_CAPACT PAR_NCAPR PAR_CAPL VARACT F_IN F_OUT NCAP_ILED OB_ICOST PAR_COMBALEM CST_FIXC CST_ACTC CST_INVC;


Results('VariableCosts',T,PRC,RUN)$(SUM(V, CST_ACTC('REGION1',V,T,PRC,'-')) GT 0) = SUM(V, CST_ACTC('REGION1',V,T,PRC,'-'));
Results('Revenues',T,PRC,RUN)$(SUM(V, CST_ACTC('REGION1',V,T,PRC,'-')) LT 0) = SUM(V, CST_ACTC('REGION1',V,T,PRC,'-')) * (-1);
Results('Revenues',T,'ISISUGDEM',RUN) = VARACT('REGION1',T,'ISISUGDEM')*DomesticSugarPrice(T,RUN);
Results('FixedCosts',T,PRC,RUN) = SUM(V, CST_FIXC('REGION1',V,T,PRC));
Results('AnnInvCosts',T,PRC,RUN) = SUM(V, CST_INVC('REGION1',V,T,PRC,'INV'));


);

* The fixed costs for the mill and B&C stages are shrunk in proportion to the CHP costs for the "Do-Nothing" Scenarios
* Explanation:
* It is necessary to allow the existing CHP plant to retire in order for it to be endogenously replaced by new equipment in the CHP upgrade scenarios
* If the mill was allowed to retire, none of the upgrades would be competitive up to the point where C-molasses destined for export gets re-directed
* Keeping the mill running would however put the factor in a situation where they would not be in a worse place than they currently are,
* at current sugar export prices, however would be able to benefit from higher export prices should they occur.
* The value of this flexibility is not captured in the current model and would need a more 'stochastic formulation'.
sets
DoNothingRuns(RUN) Do nothing Runs /DONOTHING, DONOTHING_HDD/
PRCFix(PRC) Processes to be adjusted /ISIMIL, UBSCSUG/
;

Results('FixedCosts',T,PRCFix,DoNothingRuns) = Results('FixedCosts',T,PRCFix,'BASE_AY')*Results('FixedCosts',T,'ISICHPEX',DoNothingRuns)/Results('FixedCosts',T,'ISICHPEX','BASE_AY');
*Results('FixedCosts',T,'ISICHPEX','DONOTHING') = Results('FixedCosts',T,'ISICHPEX','DONOTHING')*Results('FixedCosts',T,'ISICHPEX','DONOTHING')/Results('FixedCosts',T,'ISICHPEX','BASE_AY');
*Results('FixedCosts',T,PRCFix,'DONOTHING_HDD') = Results('FixedCosts',T,PRCFix,'DONOTHING_HDD')*Results('FixedCosts',T,'ISICHPEX','DONOTHING_HDD')/Results('FixedCosts',T,'ISICHPEX','BASE_AY');



execute_unload "SugarResults.gdx" PRC COM Results
execute 'gdxxrw.exe i=SugarResults.gdx o=C:\AnswerTIMESv6\Answer_Databases\SugarModel\SugarResults.xlsx index=index!a6';
