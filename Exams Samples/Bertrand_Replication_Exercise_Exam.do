clear all

/*In case you are a prof or a TA, load the data through the following: 

use "C:\Users\skastoryano\Dropbox\Tippelzone G\TempTipp\Tippelzone2015\CBSregist2015.dta", clear

*/

/*Also if you are a prof or a TA, pay attention to installing all the additional packages that you might not have to run this code file properly*/
/*Install the following: 

ssc install estout    /for making a table from one or more sets of estimation results
ssc install eststo    / to store a copy of the active estimation results for later use
ssc install clustse   / to multi-way clustering and giving statistical inferences 
ssc install unique    / to be able to compile 'clustse' above properly 
download 'cgmreg.ado' and 'cgmreg.hlp' from
https://sites.google.com/site/judsoncaskey/data
    -> put it them in your c:\ado\ folder 
	-> access this ado folder by using this command 'personal'


    cgmwildboot - Linear regressions with multi-way clustered standard errors,
        bootstrapped for one cluster dimension.
rnethelp "http://fmwww.bc.edu/RePEc/bocode/c/cgmwildboot.hlp"

*/

cd "C:\Users\LABPC\Desktop\Replication exercise"


**Data on registered crimes in large municipalities use "CBSregist2015", clear 


*------------------------- Table 2 starts----------------------------------------------*

//Table 2 shows Summary statistics on registered crime: This helps to understand the data and the important statistics 


**i)Column 1: Three big cities 
use "CBSregist2015", clear
keep if city == "Amsterdam" | city == "Rotterdam" | city == "Den Haag"
tabstat rapesexapcN sexassaultpcN rapepcN drugspcN maltreatpcN weaponspcN, s(mean sd) f(%5.2f)

local controls "popul_100 popmale1565_100 pop_dens_100  inkhh educhpc nondutchpc  insurWWAO_pc  mayorSoc mayorLib mayorChr"
tabstat `controls', s(mean sd) f(%5.2f)


**ii)Column 2: Twenty two medium cities
use "CBSregist2015", clear
keep if city=="Utrecht" | city=="Nijmegen" | city=="Groningen" | city=="Heerlen" | city=="Eindhoven" | city=="Arnhem"
tabstat rapesexapcN sexassaultpcN rapepcN drugspcN maltreatpcN weaponspcN, s(mean sd) f(%5.2f)

local controls "popul_100 popmale1565_100 pop_dens_100  inkhh educhpc nondutchpc  insurWWAO_pc  mayorSoc mayorLib mayorChr"
tabstat `controls', s(mean sd) f(%5.2f)

**iii)Column 3: Cities with no tippelzone
use "CBSregist2015", clear
drop if city == "Amsterdam" | city=="Rotterdam" | city=="Utrecht" | city=="Den Haag" | city=="Nijmegen" | city=="Groningen" | city=="Heerlen" | city=="Eindhoven" | city=="Arnhem"
tabstat rapesexapcN sexassaultpcN rapepcN drugspcN maltreatpcN weaponspcN, s(mean sd) f(%5.2f)

local controls "popul_100 popmale1565_100 pop_dens_100  inkhh educhpc nondutchpc  insurWWAO_pc  mayorSoc mayorLib mayorChr"
tabstat `controls', s(mean sd) f(%5.2f)

*----------------------------Table 2 ends----------------------------------------------*




*-------------------------Table 3 Starts----------------------------------------------*
//Table 3 explores the effects of opening and licensing tippelzones on crimes related to sexual harrassment 
//Baseline model is: 
//Extended model is:  

use "CBSregist2015", clear

//Tabulate city and year for the Registered 25 cities
tabulate city, generate(dc)
tabulate year, generate(dy)


//BASELINE MODEL:

*Effect on 25 cities : baseline model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "opening"
tsset city1 year, yearly
xtset city1 year 

*Then, clustering quietly: 
eststo: qui cgmwildboot lnrapesexaN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnsexassaultN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnrapeN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear


//EXTENDED MODEL:

*Effect on 25 cities: extended model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "everopenNoReg openingRegP openingRegA  closing"
tsset city1 year, yearly
xtset city1 year 

*Then, clustering quietly: 
eststo: qui cgmwildboot lnrapesexaN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnsexassaultN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnrapeN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear


//Tabulate city and year for the 22 cities 
use "CBSregist2015", clear
drop if city=="Amsterdam"
drop if city=="Rotterdam"
drop if city=="Den Haag"
drop if city=="Eindhoven" & year==2011
tabulate city, generate(dc)
tabulate year, generate(dy)

//BASELINE MODEL: 

*Effect on 22 cities : baseline model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "opening"
tsset city1 year, yearly
xtset city1 year
*Then clustering quietly:
eststo: qui cgmwildboot lnrapesexaN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnsexassaultN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnrapeN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear


//EXTENDED MODEL: 

*Effect on 22 cities : extended model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "everopenNoReg  openingRegP openingRegA"
tsset city1 year, yearly
xtset city1 year
*Then clustering quietly: 
eststo: qui cgmwildboot lnrapesexaN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnsexassaultN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnrapeN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear 

*-------------------------Table 3 ends----------------------------------------------*


*-------------------------Table 5 Starts----------------------------------------------*
//Table 5 focuses on effects of opening and licensing Tippelzones on crimes related to drugs and violence
//Baseline model is:
//Extended model is: 

use "CBSregist2015", clear


//Tabulations
tabulate city, generate(dc)
tabulate year, generate(dy)


//BASELINE MODEL: 

*Effect on 25 cities: baseline model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "opening"
tsset city1 year, yearly
xtset city1 year 
*Then clustering quietly
eststo: qui cgmwildboot lndrugsN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnweaponsN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnmaltreatN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear


//EXTENDED MODEL: 

*Effect on 25 cities: extended model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "everopenNoReg openingRegP openingRegA closing"
tsset city1 year, yearly
xtset city1 year
*Then clustering quietly
eststo: qui cgmwildboot lndrugsN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnweaponsN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnmaltreatN  `effects' `controls' dc2-dc25 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear


//BASELINE MODEL: 

use "CBSregist2015", clear


//Tabulations
tabulate city, generate(dc)
tabulate year, generate(dy)

*Effect on 22 cities: baseline model 
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "opening"
tsset city1 year, yearly
xtset city1 year 
*Then clustering quietly
eststo: qui cgmwildboot lndrugsN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnweaponsN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnmaltreatN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear


//EXTENDED MODEL: 

*Effect on 22 cities: extended model
local controls "logpopmale1565 logpopdens inkhh educhpc nondutchpc insurWWAO mayorCDA mayorCU mayorD66 mayorVVD"
local effects "everopenNoReg openingRegP openingRegA"
tsset city1 year, yearly
xtset city1 year 
*Then clustering quietly
eststo: qui cgmwildboot lndrugsN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnweaponsN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
eststo: qui cgmwildboot lnmaltreatN  `effects' `controls' dc2-dc22 dy2-dy18, cluster(city1) bootcluster(city1) reps(499) seed(45571)
esttab, se  b(3) ar2(a2) star(* 0.10 ** 0.05 *** 0.01 ) keep(`effects')
eststo clear 

*-------------------------Table 5 Ends----------------------------------------------*






