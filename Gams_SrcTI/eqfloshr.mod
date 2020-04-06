*=============================================================================*
* EQIN/OUTSHR is the market/product share limit constraint                    *
*   %1 - equation declaration type
*   %2 - FLO_SHAR type for %1
*   %3 - IN/OUT indicator
*=============================================================================*
*GaG Questions/Comments:
*  - VAR_FLOs according to whether c-in-PCG otherwise RPS_S1
*  - Needs to be adjusted to handle attribute TS-level diff. the operation level
*    - for now FLO_SHAR moved down to S1 level in PP_MAIN (which may be OK)
*-----------------------------------------------------------------------------
* [AL] Changed level of equation to be that of RPCS_VAR
* [AL] Requirement for PRC_CG relaxed; Requirement for RP_STD added
    %EQ%%1_%3SHR(RTP_VINTYR(%R_V_T%,P),C,CG,S %SWT%)$((RP_STD(R,P) * TOP(R,P,C,'%3') * RPCS_VAR(R,P,C,S)
                                                    )$FLO_SHAR(R,V,P,C,CG,S,'%2')) ..

* all flows in the group
        FLO_SHAR(R,V,P,C,CG,S,'%2') *
*V0.5a 980729 - RPCS_VAR: com not c
* [AL] Handle reduced/non-reduced groups separately
        (SUM((TOP(R,P,COM,'%3'),RTPCS_VARF(R,T,P,COM,TS))$COM_GMAP(R,CG,COM),
             %VAR%_FLO(R,V,T,P,COM,TS %SOW%)*RS_FR(R,S,TS)*(1+RTCS_FR(R,T,COM,S,TS))
           )$(FLO_SHAR(R,V,P,C,CG,S,'%2') GT 0)$(NOT RPG_RED(R,P,CG,'%3')) +

         SUM((TOP(R,P,COM,'%3'),RTPCS_VARF(R,T,P,COM,TS))$COM_GMAP(R,CG,COM),
$           BATINCLUDE %cal_red% COM COM1 TS P T
                           *
* share-ts coarser than variable or share finer than variable
            RS_FR(R,S,TS)*(1+RTCS_FR(R,T,COM,S,TS))
           )$(FLO_SHAR(R,V,P,C,CG,S,'%2') GT 0)$RPG_RED(R,P,CG,'%3')
        )

    =%1=

* commodity working on, summed for all
        SUM(RTPCS_VARF(R,T,P,C,S),%VAR%_FLO(R,V,T,P,C,S %SOW%))$(NOT RPG_RED(R,P,CG,'%3')) +
        SUM(RTPCS_VARF(R,T,P,C,S),
$           BATINCLUDE %cal_red% C COM S P T
           )$RPG_RED(R,P,CG,'%3')
    ;
