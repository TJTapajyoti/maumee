*The supply chain design of Sustainable Supply Chains for the HUC12 maumee river watershed*

*Tapajyoti Ghosh

*THis is dynamic model with time variable in months*

*Sets for the main p2ptes matrix
*****************DATA INEDUCED OUTPUT
*$inlinecom /* */


$offlisting
$offsymxref
$offsymlist
$offinclude

$include baronlinear.gms
option limrow = 0;

option limcol = 0;
option solprint = off;
option sysout = off;


Sets

TM Technology matrix counter /1*518/
VCF(TM) Farm value chain scale counter /1*252/
VCS(TM) Storage facility value chain counter /253*259/
VCC(TM) Consumers /260*511/
EQB(TM) Refinery equipment scale /512*518/;

alias(VCF,VCF1,b);
alias(TM,TM1);
alias(VCC,VCC1);

Sets

m months    /1*10/
y years     /1*8/;
*You can change timetot to zero to reduce ecosystems. no other things are touched.
Scalar timetot  /10/;


**************CALLING GDX FUNCTIONS TO READ THE EXCEL FILES AND GET DATA***********************************************************

Parameter Level1(m,b) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE yield_corn_reduced.xlsx par=Level1 rng=Sheet1!A1:IS10

$GDXIN yield_corn_reduced.gdx
$LOAD Level1
$GDXIN

Parameter Level2(m,b) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE nitrogen_corn_reduced.xlsx par=Level2 rng=Sheet1!A1:IS10

$GDXIN nitrogen_corn_reduced.gdx
$LOAD Level2
$GDXIN

Parameter Level3(m,b) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE phos_corn_reduced.xlsx par=Level3 rng=Sheet1!A1:IS10

$GDXIN phos_corn_reduced.gdx
$LOAD Level3
$GDXIN

Parameter Level4(m,VCC) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE ethanol_demand.xlsx par=Level4 rng=Sheet1!A1:IS13

$GDXIN ethanol_demand.gdx
$LOAD Level4
$GDXIN


Parameter Level6(VCF,VCS) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE farm_to_storage.xlsx par=Level6 rng=Sheet1!A1:H253

$GDXIN farm_to_storage.gdx
$LOAD Level6
$GDXIN



Parameter Level9(VCS,EQB) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE storage_to_refinery.xlsx par=Level9 rng=Sheet1!A1:H8

$GDXIN storage_to_refinery.gdx
$LOAD Level9
$GDXIN

Parameter Level13(EQB,VCC) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE refinery_to_consumer.xlsx par=Level13 rng=Sheet1!A1:IS8

$GDXIN refinery_to_consumer.gdx
$LOAD Level13
$GDXIN



Parameter Level5(m,b) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE wetland_reduced.xlsx par=Level5 rng=Sheet1!A1:IS23

$GDXIN wetland_reduced.gdx
$LOAD Level5
$GDXIN





Parameter

phos_corn(m,b) phosphorus runoff matrix
ecosystem(m,b)  ecossytem matrix
yield_corn(m,b) yield corn
nitrogen_corn(m,b) nitrogen runoff
ethanol_demand(m,VCC) ethanol demand
trans_cost2(VCF,VCS) transportation mode 2 truck
eq_trans_cost2(VCS,EQB) transportation mode 2 truck
eq_downstream(EQB,VCC) transportation model truck for ethanol;

*In per $/tonne values
trans_cost2(VCF,VCS) = level6(VCF,VCS);

*In per $/tonne values
eq_trans_cost2(VCS,EQB) = level9(VCS,EQB);
eq_downstream(EQB,VCC) = Level13(EQB,VCC);



*Storing the data in the parameters
*Yield of corn is in Tonnes
yield_corn(m,b) = Level1(m,b);
*NItrogen is in kg
nitrogen_corn(m,b) = Level2(m,b);
*Phosphorus is in kg
phos_corn(m,b) = Level3(m,b);
*Ethanol Demand is in tonnes
*Multipled by 4 to make it for 4 months rather than a month. 
ethanol_demand(m,VCC) = Level4(m,VCC);

*Ecosystem Area km2
ecosystem(m,b) = Level5(m,b);




*The corn production part of the technology matrix being declared as a parameter
*to make it easier to compute.
Parameter CORN_production_X(m,VCF,VCF1);
CORN_production_X(m,VCF,VCF) = yield_corn(m,VCF);
*Making the non diagonals zero
CORN_production_X(m,VCF,VCF1)$(Ord(VCF) ne Ord(VCF1)) = 0;

Parameter
Cp_coll collection capacity of storage /1000000/;
*Tonnes of Corn


*modelling of Corn storage facility
Alias(VCS,VCS1);
*Location variable for placement of storage
*Two binary variables because decision is taken only twice on the life time.
Binary variable
z_s_1(VCS) first_biomass_storage_location_binary;
Binary variable
z_s_2(VCS) second_biomass_storage_location_binary;

positive variable storage_X(m,VCS,VCS1);
storage_X.UP(m,VCS,VCS1) = 1250000;


*Collection capacity limiting storage
Equation storage3,storage3_1,storage4;
*Two questions for two separate decisions.
*Change the order here to make decision occur at different months. Use search keywork #CHANGE_MONTH
storage3(m,VCS,VCS)$(Ord(m) le 2).. storage_x(m,VCS,VCS) =L= Cp_coll * z_s_1(VCS);
storage3_1(m,VCS,VCS)$(Ord(m) ge 3).. storage_x(m,VCS,VCS) =L= Cp_coll * z_s_2(VCS);
storage4(m,VCS,VCS1)$(Ord(VCS) ne Ord(VCS1)).. storage_x(m,VCS,VCS1) =E= 0;

positive variable farm_storage_X(m,VCF,VCS);
farm_storage_X.UP(m,VCF,VCS) = 5000000;


*Flow of corn from farm to storage
Equation storage6;
*Sum of cells along rows should be less than sum of farm production
storage6(m,VCF).. sum[VCS,farm_storage_X(m,VCF,VCS)] =L= sum[VCF1,CORN_production_X(m,VCF,VCF1)];



*Existence of storage
*Maximum two storage units So 4 is the sum total because of two binaries added.
Equation storage5;
storage5.. sum[VCS,z_s_1(VCS)] + sum[VCS,z_s_2(VCS)] =L= 14;

*Makres sure that flows from farm to storage only happens if storage exists. Otherwise there is direct transport
*from farm to refinery even if storage doesnt exist.
Equation storage5_1;
storage5_1(m,VCS).. sum[VCF,farm_storage_X(m,VCF,VCS)] =E= sum[VCF,farm_storage_X(m,VCF,VCS)]*z_s_1(VCS);


positive variable total_flow(m);
Equation storage8;
storage8(m).. total_flow(m) =E= sum[VCF,sum[VCS,farm_storage_X(m,VCF,VCS)]];


*Modelling of Biorefinery
Alias(EQB,EQB1);

positive variable refinery_X(m,EQB,EQB1);
positive variable storage_refinery_X(m,VCS,EQB);

*Two refinery variables binary for two decisions in the life time
binary variable z_r_1(EQB);
binary variable z_r_2(EQB);



Equation refinery1,refinery2,refinery3,refinery4;


equation refinery1_2;
*Modelling a toy refinery
*#Refinery equipment scale model
*This is going to be in the order of 18000 tonnes. Ethanol demand is in tonnes. So this is also in tonnes.
refinery1(m,EQB,EQB)$(Ord(m) le 2).. sum[VCS,storage_refinery_X(m,VCS,EQB)] =E= Fcorn*86400*120/2000*z_r_1(EQB);
refinery1_2(m,EQB,EQB)$(Ord(m) ge 3).. sum[VCS,storage_refinery_X(m,VCS,EQB)] =E= Fcorn*86400*120/2000*z_r_2(EQB);
*#Non diagonals are zero
refinery2(m,EQB,EQB1)$(Ord(EQB) ne Ord(EQB1)).. refinery_X(m,EQB,EQB1) =E= 0;
*#CHANGE_MONTH
*6000 is in kg
*Existence of refinery
refinery3(m,EQB)$(Ord(m) le 2).. sum[EQB1,refinery_X(m,EQB,EQB1)] =E= Ethanol*86400*120/2000*z_r_1(EQB);
refinery4(m,EQB)$(Ord(m) ge 3).. sum[EQB1,refinery_X(m,EQB,EQB1)] =E= Ethanol*86400*120/2000*z_r_2(EQB);



positive variable refinery_consumer_X(m,EQB,VCC);


*Demand of ethanol from refinery;
Equation refinery5;
refinery5(m,VCC).. sum[EQB,refinery_consumer_X(m,EQB,VCC)] =E= ethanol_demand(m,VCC);
Equation refinery6;
refinery6(m,EQB).. sum[VCC,refinery_consumer_X(m,EQB,VCC)] =L= refinery_X(m,EQB,EQB);



*Constraint on Biorefinery location 2 required
*This is required as of now to introduce a final demand to the model.
equation location1;
location1.. sum[EQB,z_r_1(EQB)] =L= 2;


*Tactical decision. Biorefinery cannot be changed once located time wise.
*Storage location cannot be changed once located timewise.
equation tactical1,tactical2;
tactical1(EQB).. z_r_1(EQB) =E= z_r_2(EQB);
tactical2(VCS).. z_s_1(VCS) =E= z_s_2(VCS);


*Main flow equation
*This is the main equation that links the flows from the farm to the storage to the decay of biomass in the storage to the transportation to the refinery. This equation needs to be edited if new transportation components are needed to be considered.
positive variable spillover(m,VCS);
*spillover.FX(m,VCS) = 0;
equation storage7;
storage7(m,VCS)$(ord(m) ge 2).. sum[VCF,farm_storage_X(m,VCF,VCS)] + (1-0.45)*sum[VCS1,storage_X(m-1,VCS,VCS1)] + spillover(m,VCS) =E= sum[VCS1,storage_X(m,VCS,VCS1)]+sum[EQB,storage_refinery_X(m,VCS,EQB)];

*First year equation only
*This equation is used to make sure that in first year the storage is not full and transporation takes place also.
*storage5_1(m,VCS)$(Ord(m) eq 1).. sum[VCF,farm_storage_X(m,VCF,VCS)] =E= sum[VCS1,storage_X(m,VCS1,VCS)];
equation storage9;
storage9(m,VCS)$(ord(m) eq 1).. sum[VCF,farm_storage_X(m,VCF,VCS)] + spillover(m,VCS) =E= sum[VCS1,storage_X(m,VCS,VCS1)]+sum[EQB,storage_refinery_X(m,VCS,EQB)];

***********************************Environment***********************************

*Phosphorus Runoff equation
variable corn_buy(VCF);
equation buying_corn;

*Adding spillover nutrient runoff
buying_corn(VCF).. corn_buy(VCF) =E= sum[m,sum[VCS,farm_storage_X(m,VCF,VCS)]];



parameter total_production(VCF);
total_production(VCF) = sum[m,yield_corn(m,VCF)];

******Adding ecosystems*****
*Subasin 1 as 195 km2 of wetland area.
*Subbasin 4 has 107.69 km2 of wetland area.
*Thus only these two subbasins can treat runoff.
*1.5 gP/m2/year
positive variable p_takeup(VCF);
*p_takeup.FX(VCF)$(Ord(VCF) ne 1 and Ord(VCF) ne 4) = 0;

equation ecosystem2,ecosystem7,ecosystem3;
*equation ecosystem1;
*ecosystem1(m,VCF).. p_takeup(m,VCF)*yield_corn(m,VCF) =E= corn_buy(m,VCF)*ecosystem(m,VCF)*0.5*1000*timetot/3;

*ecosystem1.. p_takeup('1')*total_production('1') =E= corn_buy('1')*22*0.5*1000*timetot/3;
ecosystem2.. p_takeup('9')*total_production('9') =E= corn_buy('9')*6.78*0.5*1000*timetot/3;
*ecosystem3.. p_takeup('10')*total_production('10') =E= corn_buy('10')*9*0.5*1000*timetot/3;
*ecosystem4.. p_takeup('17')*total_production('17') =E= corn_buy('17')*14.8*0.5*1000*timetot/3;
*ecosystem5.. p_takeup('18')*total_production('18') =E= corn_buy('18')*9.8*0.5*1000*timetot/3;
*ecosystem6.. p_takeup('19')*total_production('19') =E= corn_buy('19')*16.55*0.5*1000*timetot/3;
ecosystem7.. p_takeup('20')*total_production('20') =E= corn_buy('20')*4.11*0.5*1000*timetot/3;
*ecosystem8.. p_takeup('21')*total_production('21') =E= corn_buy('21')*11.1*0.5*1000*timetot/3;
*ecosystem9.. p_takeup('94')*total_production('94') =E= corn_buy('94')*21*0.5*1000*timetot/3;
*ecosystem10.. p_takeup('96')*total_production('96') =E= corn_buy('96')*13*0.5*1000*timetot/3;


ecosystem3(VCF)$(Ord(VCF) ne 9 and Ord(VCF) ne 20).. p_takeup(VCF) =E= 0;





parameter total_p_runoff(VCF);
total_p_runoff(VCF) = sum[m,phos_corn(m,VCF)]

positive variable p_runoff(VCF),p_runoff2(VCF);
variable final_p_runoff;
equation impact1,impact2,impact3;

impact1(VCF).. p_runoff(VCF)*total_production(VCF) =E= corn_buy(VCF)*total_p_runoff(VCF);
impact3(VCF).. p_runoff2(VCF) =G= p_runoff(VCF) - p_takeup(VCF);
*impact3(VCF).. p_runoff2(VCF) =G= p_runoff(VCF);


*Adding the phosphorus runoff from the spillover corn in the first year. So that spillover is minimum
*0.038 kg P per tonne of Corn yield.
impact2.. final_p_runoff =E= sum[VCF,p_runoff2(VCF)] + sum[m,sum[VCS,spillover(m,VCS)]]*0.038 ;

******Adding ecosystems*****
*Subasin 1 as 195 km2 of wetland area.
*Subbasin 4 has 107.69 km2 of wetland area.
*Thus only these two subbasins can treat runoff.




**********************************Transportation*************************************************
positive Variable transportation1(m,VCF,VCS),transportation2(m,VCS,EQB),transportation3(m,EQB,VCC);
equation transport1,transport2,transport3;




transport1(m,VCF,VCS).. transportation1(m,VCF,VCS) =E= farm_storage_X(m,VCF,VCS)*trans_cost2(VCF,VCS);


transport2(m,VCS,EQB).. transportation2(m,VCS,EQB) =E= storage_refinery_X(m,VCS,EQB)*eq_trans_cost2(VCS,EQB);

*Have to add the spillover transportation also for the first year.
transport3(m,EQB,VCC).. transportation3(m,EQB,VCC) =E= refinery_consumer_X(m,EQB,VCC)*eq_downstream(EQB,VCC);

variable t_obj;
equation trns;

trns.. t_obj =E= sum[m,sum[VCF,sum[VCS,transportation1(m,VCF,VCS)]]]+sum[m,sum[VCS,sum[EQB,transportation2(m,VCS,EQB)]]]+sum[m,sum[EQB,sum[VCC,transportation3(m,EQB,VCC)]]]+sum[m,sum[VCS,spillover(m,VCS)]]*0.083*200;












variable dummy;
equation dum;

dum.. dummy =E= 5;


option optcr = 0.5;
option resLim = 1000000000;
option threads = 5;

MODEL TRANS /ALL/ ;

TRANS.optFile = 1

option MINLP = BARON;

Solve TRANS Using MINLP Minimizing final_p_runoff;
*Solve TRANS Using MINLP Minimizing t_obj;
*Solve TRANS Using MINLP minimizing dummy;

display corn_buy.L;
display total_p_runoff;
display p_runoff.L;
display p_runoff2.L;
display p_takeup.L;
display ecosystem;
display final_p_runoff.L;

parameter spillrunoff;

spillrunoff = sum[m,sum[VCS,spillover.L(m,VCS)]]*0.038;

display spillrunoff;


Parameter p2px(m,TM,TM1);
p2px(m,VCF,VCF1) = corn_production_X(m,VCF,VCF1);
p2px(m,VCF,VCS) = farm_storage_X.L(m,VCF,VCS);
p2px(m,VCS,VCS1) = storage_X.L(m,VCS,VCS1);
p2px(m,EQB,EQB1) = refinery_X.L(m,EQB,EQB1);
p2px(m,VCS,EQB) = storage_refinery_X.L(m,VCS,EQB);
p2px(m,EQB,VCC) = refinery_consumer_X.L(m,EQB,VCC);
p2px(m,VCC,VCC) = ethanol_demand(m,VCC);


parameter total_corn_flow;
total_corn_flow = sum[m,total_flow.L(m)];
display total_corn_flow;

parameter total_corn_production(m);
total_corn_production(m) = sum[VCF,sum[VCF1,corn_production_X(m,VCF,VCF1)]]

parameter corn_demand(m);
corn_demand(m) = sum[VCS,sum[EQB,storage_refinery_X.L(m,VCS,EQB)]]

parameter deficit(m);
deficit(m) = total_corn_production(m) - corn_demand(m);

parameter total_corn_demand;
total_corn_demand = sum[m,corn_demand(m)];

display total_corn_demand;

parameter excess_demand;
excess_demand = total_corn_demand - total_corn_flow;


parameter runoff_from_farms;
runoff_from_farms = final_p_runoff.L - spillrunoff;

display excess_demand,runoff_from_farms;


parameter spillflow;

spillflow =  sum[m,sum[VCS,spillover.L(m,VCS)]];

display spillflow;

display total_p_runoff;

display total_production;

display corn_buy.L;

parameter p_run_fac(VCF);
*kg P/tonne
p_run_fac(VCF) = total_p_runoff(VCF)/total_production(VCF);

display p_run_fac;

file fxx /storage.txt/;

fxx.ps = 130;
fxx.pw = 32767;
fxx.nd =0;
fxx.pc=5;
put fxx
Loop(m,
*put 'year';
*put m.tl;
*put/;
Loop(VCS,
Loop(VCS1,
put p2pX(m,VCS,VCS1);
);
put/;
);
put/;
put/;
put/;
put/;
);

file fx /check.txt/;
fx.ps = 130;
fx.pw = 32767;
fx.nd =0;
fx.pc = 5;
put fx
Loop(m,
put/;
Loop(TM,
Loop(TM1,
put p2pX(m,TM,TM1);
);
put/;
);
put/;
put/;
put/;
put/;
);


file fx2 /farm_storage.txt/;
fx2.ps = 130;
fx2.pw = 32767;
fx2.nd = 0;
fx2.pc = 5;
put fx2
Loop(m,
*put 'year';
*put m.tl;
*put /;
Loop(VCF,
Loop(VCS,
put farm_storage_X.L(m,VCF,VCS);
);
put /;
);
put /;
put /;
put /;
put /;
);


file fx3 /spill.txt/;
fx3.ps = 130;
fx3.pw = 32767;
fx3.nd = 0;
fx3.pc = 5;
put fx3
Loop(m,
put 'year';
put m.tl;
put /;
Loop(VCS,
put spillover.L(m,VCS);
);
put /;
put /;
put /;
put /;
);



file fx4 /total_flow.txt/;
fx4.ps = 130;
fx4.pw = 32767;
fx4.nd = 0;
fx4.pc = 5;
put fx4
Loop(m,
put 'year';
put m.tl;
put /;
put deficit(m);
put /;
put /;
put /;
);


file fx5 /refinery.txt/;
fx5.ps = 130;
fx5.pw = 32767;
fx5.nd = 0;
fx5.pc= 5;
put fx5
Loop(m,
*put 'year';
*put m.tl;
*put /;
Loop(EQB,
Loop(EQB1,
put refinery_X.L(m,EQB,EQB1);
);
put /;
);
put /;
put /;
put /;
put /;
);


file fx6 /storage_refinery.txt/;
fx6.ps = 130;
fx6.pw = 32767;
fx6.nd = 0;
fx6.pc= 5;
put fx6
Loop(m,
*put 'year';
*put m.tl;
*put /;
Loop(VCS,
Loop(EQB,
put storage_refinery_X.L(m,VCS,EQB);
);
put /;
);
put /;
put /;
put /;
put /;
);

file fx7 /refinery_consumer.txt/;
fx7.ps = 130;
fx7.pw = 32767;
fx7.nd = 0;
fx7.pc= 5;
put fx7
Loop(m,
*put 'year';
*put m.tl;
*put /;
Loop(EQB,
Loop(VCC,
put refinery_consumer_X.L(m,EQB,VCC);
);
put /;
);
put /;
put /;
put /;
put /;
);

file fx8 /deficit_corn.txt/;
fx8.ps = 130;
fx8.pw = 32767;
fx8.nd = 0;
put fx8
Loop(m,
put 'year';
put m.tl;
put /;
put deficit(m);
put /;
put /;
);


file fx9 /farm.txt/;

fx9.ps = 130;
fx9.pw = 32767;
fx9.nd =0;
fx9.pc = 5;
put fx9
Loop(m,
*put 'year';
*put m.tl;
*put/;
Loop(VCF,
Loop(VCF1,
put p2pX(m,VCF,VCF1);
);
put/;
);
put/;
put/;
put/;
put/;
);



file fx10 /consumer.txt/;

fx10.ps = 130;
fx10.pw = 32767;
fx10.nd =0;
fx10.pc = 5;
put fx10
Loop(m,
*put 'year';
*put m.tl;
*put/;
Loop(VCC,
Loop(VCC1,
put p2pX(m,VCC,VCC1);
);
put/;
);
put/;
put/;
put/;
put/;
);


