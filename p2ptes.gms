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

option limrow = 0;

option limcol = 0;
option solprint = off;
option sysout = off;


Sets

TM Technology matrix counter /1*763/
VCF(TM) Farm value chain scale counter /1*252/
VCS(TM) Storage facility value chain counter /253*259/
VCC(TM) Consumers /260*511/
EQB(TM) Refinery equipment scale /512*763/;

alias(VCF,VCF1,b);
alias(TM,TM1);
alias(VCC,VCC1);

Sets

m months    /1*9/
y years     /1*8/;


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

Parameter Level4(VCC,VCC1) store data temporarily

*******************************Read the Value chain scale Make matrix**************************************************************
*$CALL GDXXRW.EXE ethanol_demand.xlsx par=Level4 rng=Sheet1!A1:IS253

$GDXIN ethanol_demand.gdx
$LOAD Level4
$GDXIN


Parameter

phos_corn(m,b) phosphorus runoff matrix
yield_corn(m,b) yield corn
nitrogen_corn(m,b) nitrogen runoff
ethanol_demand(VCC,VCC1) ethanol demand;


*Storing the data in the parameters
*Yield of corn is in Tonnes
yield_corn(m,b) = Level1(m,b);
*NItrogen is in kg
nitrogen_corn(m,b) = Level2(m,b);
*Phosphorus is in kg
phos_corn(m,b) = Level3(m,b);
*Ethanol Demand is in Kg
ethanol_demand(VCC,VCC1) = Level4(VCC,VCC1);


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
storage3(m,VCS,VCS)$(Ord(m) le 4).. storage_x(m,VCS,VCS) =L= Cp_coll * z_s_1(VCS);
storage3_1(m,VCS,VCS)$(Ord(m) ge 5).. storage_x(m,VCS,VCS) =L= Cp_coll * z_s_2(VCS);
storage4(m,VCS,VCS1)$(Ord(VCS) ne Ord(VCS1)).. storage_x(m,VCS,VCS1) =E= 0;

positive variable farm_storage_X(m,VCF,VCS);
farm_storage_X.UP(m,VCF,VCS) = 5000000;


*Flow of corn from farm to storage
Equation storage6,storage7;
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



Equation refinery1,refinery1_2,refinery2,refinery3,refinery4;

*REMOVE THIS PART
variable Fcorn,ethanol;
Fcorn.fx = 18;
ethanol.fx = 6;


*Modelling a toy refinery
*#Refinery equipment scale model
*This is going to be in the order of 18000 tonnes. Ethanol demand is in tonnes. So this is also in tonnes.
refinery1(m,EQB,EQB)$(Ord(m) ge 1 and (Ord(m) le 4)).. sum[VCS,storage_refinery_X(m,VCS,EQB)] =E= Fcorn*86400*30/2500*z_r_1(EQB);
refinery1_2(m,EQB,EQB)$(Ord(m) ge 5).. sum[VCS,storage_refinery_X(m,VCS,EQB)] =E= Fcorn*86400*30/2500*z_r_2(EQB);
*#Non diagonals are zero
refinery2(m,EQB,EQB1)$(Ord(EQB) ne Ord(EQB1)).. refinery_X(m,EQB,EQB1) =E= 0;
*#CHANGE_MONTH
*6000 is in kg
*Existence of refinery
refinery3(m,EQB)$(Ord(m) ge 1 and (Ord(m) le 4)).. sum[EQB1,refinery_X(m,EQB,EQB1)] =E= Ethanol*86400*30/2500*z_r_1(EQB);
refinery4(m,EQB)$(Ord(m) ge 5).. sum[EQB1,refinery_X(m,EQB,EQB1)] =E= Ethanol*86400*30/2500*z_r_2(EQB);



positive variable refinery_consumer_X(m,EQB,VCC);



*Demand of ethanol from refinery;
Equation refinery5;
refinery5(m,VCC).. sum[EQB,refinery_consumer_X(m,EQB,VCC)] =E= ethanol_demand(VCC,VCC);
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

storage7(m,VCS)$(ord(m) ge 2).. sum[VCF,farm_storage_X(m,VCF,VCS)] + (1-0.15)*sum[VCS1,storage_X(m-1,VCS,VCS1)] =E= sum[VCS1,storage_X(m,VCS,VCS1)]+sum[EQB,storage_refinery_X(m,VCS,EQB)];

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

equation ecosystem1,ecosystem2,ecosystem3,ecosystem4,ecosystem5,ecosystem6,ecosystem7,ecosystem8,ecosystem9,ecosystem10;

ecosystem1.. p_takeup('1')*total_production('1') =E= corn_buy('1')*22*1.5*1000*8; 
ecosystem2.. p_takeup('9')*total_production('9') =E= corn_buy('9')*23*1.5*1000*8;
ecosystem3.. p_takeup('10')*total_production('10') =E= corn_buy('10')*9*1.5*1000*8;
ecosystem4.. p_takeup('17')*total_production('17') =E= corn_buy('17')*14.8*1.5*1000*8;
ecosystem5.. p_takeup('18')*total_production('18') =E= corn_buy('18')*9.8*1.5*1000*8;
ecosystem6.. p_takeup('19')*total_production('19') =E= corn_buy('19')*16.55*1.5*1000*8;
ecosystem7.. p_takeup('20')*total_production('20') =E= corn_buy('20')*14.6*1.5*1000*8;
ecosystem8.. p_takeup('21')*total_production('21') =E= corn_buy('21')*11.1*1.5*1000*8;
ecosystem9.. p_takeup('94')*total_production('94') =E= corn_buy('94')*21*1.5*1000*8;
ecosystem10.. p_takeup('96')*total_production('96') =E= corn_buy('96')*13*1.5*1000*8;








parameter total_p_runoff(VCF);
total_p_runoff(VCF) = sum[m,phos_corn(m,VCF)]

positive variable p_runoff(VCF),p_runoff2(VCF);
variable final_p_runoff;
equation impact1,impact2,impact3;

impact1(VCF).. p_runoff(VCF)*total_production(VCF) =E= corn_buy(VCF)*total_p_runoff(VCF);
impact3(VCF).. p_runoff2(VCF) =G= p_runoff(VCF) - p_takeup(VCF);

*Adding the phosphorus runoff from the spillover corn in the first year. So that spillover is minimum
*0.038 kg P per tonne of Corn yield.
impact2.. final_p_runoff =E= sum[VCF,p_runoff2(VCF)] + sum[m,sum[VCS,spillover(m,VCS)]]*0.038 ;

******Adding ecosystems*****
*Subasin 1 as 195 km2 of wetland area. 
*Subbasin 4 has 107.69 km2 of wetland area. 
*Thus only these two subbasins can treat runoff.


variable dummy;
equation dum;

dum.. dummy =E= 5;


option optcr = 0.2;
option resLim = 100000;
option threads = 4;

MODEL TRANS /ALL/ ;

TRANS.optFile = 1

option MINLP = BARON;

*Solve TRANS Using MINLP Minimizing final_p_runoff;
*Solve TRANS Using MINLP Minimizing t_obj;
Solve TRANS Using MINLP minimizing dummy;



Parameter p2px(m,TM,TM1);
p2px(m,VCF,VCF1) = corn_production_X(m,VCF,VCF1);
p2px(m,VCF,VCS) = farm_storage_X.L(m,VCF,VCS);
p2px(m,VCS,VCS1) = storage_X.L(m,VCS,VCS1);
p2px(m,EQB,EQB1) = refinery_X.L(m,EQB,EQB1);
p2px(m,VCS,EQB) = storage_refinery_X.L(m,VCS,EQB);
p2px(m,EQB,VCC) = refinery_consumer_X.L(m,EQB,VCC);
p2px(m,VCC,VCC1) = ethanol_demand(VCC,VCC1);


parameter total_corn_flow;
total_corn_flow = sum[m,total_flow.L(m)];
display total_corn_flow;

parameter total_corn_production(m);
total_corn_production(m) = sum[VCF,sum[VCF1,corn_production_X(m,VCF,VCF1)]]

parameter total_corn_demand(m);
total_corn_demand(m) = sum[VCS,sum[EQB,storage_refinery_X.L(m,VCS,EQB)]]

parameter deficit(m);
deficit(m) = total_corn_production(m) - total_corn_demand(m);



file fxx /storage.txt/;

fxx.ps = 130;
fxx.pw = 2000;
fxx.nd =0;
put fxx
Loop(m,
put 'year';
put m.tl;
put/;
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
fx.pw = 2000;
fx.nd =0;
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
fx2.pw = 2000;
fx2.nd =0;
put fx2
Loop(m,
put 'year';
put m.tl;
put /;
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
fx3.pw = 2000;
fx3.nd =0;
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
fx4.pw = 2000;
fx4.nd =0;
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
fx5.pw = 2000;
fx5.nd =0;
put fx5
Loop(m,
put 'year';
put m.tl;
put /;
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
fx6.pw = 2000;
fx6.nd =0;
put fx6
Loop(m,
put 'year';
put m.tl;
put /;
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
fx7.pw = 2000;
fx7.nd =0;
put fx7
Loop(m,
put 'year';
put m.tl;
put /;
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
fx8.pw = 2000;
fx8.nd =0;
put fx8
Loop(m,
put 'year';
put m.tl;
put /;
put deficit(m);
put /;
put /;
);


