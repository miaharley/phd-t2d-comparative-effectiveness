/*==============================================================================
DO FILE NAME:			C3c - covariate - bmi.do

AUTHOR:					Adapted from code written by Patrick Bidulka

DATE CREATED: 			02/2025

DATE UPDATED:			02/2025
						
DATASETS CREATED:      	covariate_bmi.dta
					
DESCRIPTION OF FILE:	assigns bmi to each patient in study cohort
*=============================================================================*/

clear all

* Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

* Set up directory
cd $Projectdir

cap log close
log using $Logdir/C3c_covariate_bmi.log, replace

* Started with Angel/ Patrick's bmi codelist that had already classified codes:
* weight=9 if code indicates weight has been measured
* height=9 if code indicates height has been measured
* bmi=9 if code indicates bmi has been measured

********************************************************************************
** Clean BMI data **
********************************************************************************

* All BMI values from define
use "$Datadir/intermediate/bmi.dta", clear
drop if obsdate==.
merge m:1 numunitid using "$Datadir/lookups/num_unit.dta", keep(master match) nogen

* Get date of birth
merge m:1 patid using "$Datadir/raw//${file_stub}_Extract_Patient_1.dta", keep(master match) nogen keepusing(yob mob)
gen day = 1
gen mon = mob
replace mon = 7 if mob ==. | mob ==0
gen dob = mdy(mon,day,yob)
format dob %td
drop day mon mob

* Get age at measurement (to remove measurements from <16 years)
gen ageatmmt = (obsdate - dob)/365.25
noi drop if ageatmmt<16

* Destring value
destring value, replace float

* Put weight,height and BMI data into a variable enttype/data3, to fit in with below code
gen enttype=13 	   if weight==9
replace enttype=14 if height==9
replace enttype=15 if bmi==9
*label define enttype 13 "weight" 14 "height" 15 "bmi"
*label values enttype enttype
drop if enttype==.

* Standardise measurements with different units (assuming kg, cm and kg/m2 by default)
gen float data1 = value
replace data1 = (value*0.45) if enttype==13 & (desc=="lb" | desc=="decimal stones" | desc=="st/lb" | desc=="stone" | desc=="Weight (stones/pounds)")
replace data1 = (value*6.35) if enttype==13 & (desc=="st" | desc=="Lbs")
replace data1 = value*100 if enttype==14 & (desc=="m" | desc=="metre" | desc=="metres") 
replace data1 = value*100 if enttype==14 & (value>1.21 & value<2.14)
replace data1 = (value*0.3) if enttype==14 & desc=="ft"
drop value

* Drop implausible heights, BMI and weights (using Krishnan's algorithm cut off values)
drop if enttype==13 & (data1<20)
drop if enttype==14 & (data1<121 | data1>214)
drop if enttype==15 & (data1<5 | data1>200)

* Drop duplicate heights, BMI and weights on the same day
sort patid obsdate enttype data1
by patid obsdate enttype: drop if data1==data1[_n-1]

* Drop if >2 of the same measurement type on the same day
by patid obsdate enttype: drop if _N>2
by patid obsdate enttype: assert _N<=2

* If 2 observations on same day with signficantly different values (>5cm (ht), >1kg (wt) or >1 BMI), drop both
sort patid obsdate enttype data1
by patid obsdate enttype: gen diff=data1-data1[_n-1] if _N==2
by patid obsdate enttype: replace diff=diff[2] if _n==1 & _N==2
drop if diff>1 & diff<. & enttype==13  // allow 1kg difference for weight
drop if diff>5 & diff<. & enttype==14  // allow 5cm difference for height
drop if diff>1 & diff<. & enttype==15  // allow 1kg/m2 difference for bmi num
drop diff

* If 2 observations on same day with similar values, take the average
by patid obsdate enttype: egen data1av = mean(data1) if _N==2
by patid obsdate enttype: replace data1 = data1av if _N==2
by patid obsdate enttype: drop if _n>1
by patid obsdate enttype: assert _N==1

* Reshape to wide to create one record per patient with weight, height and bmi measurements
keep patid obsdate enttype data1 ageatmmt
reshape wide data1, i(patid obsdate) j(enttype)
rename data113 weight
rename data114 height
rename data115 bmi

* Fill in missing heights with the latest previous measurement over 18 years
gen ageatlastht = ageatmmt if height<.
by patid: replace ageatlastht = ageatlastht[_n-1] if height==. & ageatlastht[_n-1]<.
cou if weight<. & height==. & ageatlastht<.
by patid: replace height = height[_n-1] if height==. & height[_n-1]<.

* Where height still missing, replace with first available future height
by patid: gen cumht = sum(height) if height<.
by patid: egen firstht = min(cumht)
cou if weight<. & height==. & firstht<.
replace height = firstht if height==.
drop cumht firstht 

* Drop weight where there is no available height
cou if weight<. & height==.
cou if height==. & bmi<.
drop if height<. & weight==. & bmi==.

* Calculate bmi from weight and height, converting height to metres
replace height = (height/100)
gen bmi_calc=weight/(height^2)

* Deal with descrepency between measured and calculated bmi
gen discrep=bmi-bmi_calc
gen discreprnd=bmi-(floor(bmi_calc*10)/10)
replace discreprnd=0 if discreprnd<0.0001
replace discreprnd=0 if abs(discrep)<0.0001

* Drop records with implausible BMI
replace bmi=. if (bmi>200|bmi<10) 
replace bmi_calc=. if (bmi_calc>200|bmi_calc<10) 
drop if bmi==. & bmi_calc==.

* Use measured BMI if calculated one is missing
replace bmi_calc=bmi if bmi_calc==.
drop bmi discrep discreprnd
rename bmi_calc bmi

* Keep only relevant BMI records
rename obsdate eventdate
keep patid eventdate bmi
save "$Datadir/intermediate/bmi_clean.dta", replace

********************************************************************************
** Get baseline measurement for study cohort **
********************************************************************************
* Merge with 
use "$Datadir/intermediate/bmi_clean.dta", clear
merge m:1 patid using $included, keep(match) nogen

* Drop measurements that occured after baseline
drop if eventdate > firstissue

* Drop measurements that occurred more than 5 years before baseline
gen _distance = firstissue-eventdate
drop if _distance > 1096

* Keep measurement closest to baseline
sort patid _distance
by patid: keep if _n==1

* Merge with study cohort to retrieve people with no bmi recording
merge 1:1 patid using $included, nogen
count if bmi==.

* Get ethnicity of patients
merge m:1 patid using "$Datadir/derived/covariate_ethnicity.dta", keep(master match) keepusing (eth5) nogen

* Categorise BMI (White, Other, Mixed, Not stated)
gen bmi_cat=.
replace bmi_cat=0 if bmi<18.5
replace bmi_cat=1 if (bmi>=18.5 & bmi<25)
replace bmi_cat=2 if (bmi>=25 & bmi<30)
replace bmi_cat=3 if (bmi>=30 & bmi<.)

* Categorise BMI (non-white)
replace bmi_cat=0 if (eth5==1 | eth5==2) & bmi<18.5
replace bmi_cat=1 if (eth5==1 | eth5==2) & (bmi>=18.5 & bmi<23)
replace bmi_cat=2 if (eth5==1 | eth5==2) & (bmi>=23 & bmi<27.5)
replace bmi_cat=3 if (eth5==1 | eth5==2) & (bmi>=27.5 & bmi<.)

* Tidy and save
keep patid bmi bmi_cat
save "$Datadir/derived/covariate_bmi.dta", replace

log close