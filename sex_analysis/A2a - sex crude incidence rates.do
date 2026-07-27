/*==============================================================================
DO FILE NAME:			A3 - sex crude incidence rates.do

AUTHOR:					Mia Harley

DATE CREATED: 			06/2024
						
DATASETS UPDATED:      	

DESCRIPTION OF FILE:	crude incidence rates by treatment and sex group
*=============================================================================*/

* Log
cap log close
log using $Logdir\A2a_sex_crude_incidence.log, replace

********************************************************************************
** Create Table of incidence rates
********************************************************************************
foreach outcome in mace mi stroke hf cvddeath {
	
putexcel set "$Outputdir/Sex crude incidence rates.xlsx", sheet("`outcome'") modify

* Treatmentgroup row locals
local su = 1
local dpp4i = 2
local sglt2i = 3

* Sex locals
local male = 1
local female = 2

* Treatmentgroup row locals
local su_row = 2
local dpp4i_row = 5
local sglt2i_row = 8

* Ethnicity row locals
local overall_row = 0
local male_row = 1
local female_row = 2

* Column headings
putexcel B1 = "Number of events, N"
putexcel C1 = "Median follow up time, years (IQR)"
putexcel D1 = "Total person time, years"
putexcel E1 = "Incidence rate, events per 1000 person years"

********************************************************************************
** Get incidence rates within each treatmentgroup and ethnic group
********************************************************************************
	foreach treatmentgroup in su sglt2i dpp4i {
		
		foreach sex in male female overall {
			
			use "$Datadir/derived/study_cohort.dta", clear
			
			* Create end of follow-up for each outcome
			cap drop end_followup_`outcome'  followup_years_`outcome'
			gen end_followup_`outcome' =  min(enddate, `outcome'_date)
			format end_followup_`outcome' %td
			replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
			replace `outcome'=0 if `outcome'_date==.
			gen followup_days_`outcome' = end_followup_`outcome' - firstissue
			gen followup_years_`outcome' = followup_days_`outcome'/365.25
			drop followup_days_`outcome'
			drop if followup_years_`outcome'==0
			
			keep if treatmentgroup == ``treatmentgroup''
			
		
			if "`sex'" == "overall" {		
			}	
			else {
				keep if gender == ``sex''
			}

		* Row heading
		local x = ``treatmentgroup'_row' + ``sex'_row'
		putexcel A`x' = "`sex' `treatmentgroup' users"
		
		* Number of CVD events
		count if `outcome'==1
		local number_events = `r(N)'
		putexcel B`x' = `number_events', nformat("#")
	
		* Median follow up years
		summarize followup_years, detail
		local median = r(p50)
		local p25 = r(p25)
		local p75 = r(p75)
		local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + "-" + string(`p75', "%9.1f") + ")"
		putexcel C`x' = "`median_iqr'"

		* Total follow-up years
		summarize followup_years, meanonly
		putexcel D`x' = `r(sum)', nformat("#.##")

		* Crude incidence rate
		local totalfu1000 = `r(sum)'/1000
		local rate = `number_events'/`totalfu1000'
		putexcel E`x' = `rate', nformat("#.##") 

	}
}

********************************************************************************
** Get total incidence rates across treatment groups **
********************************************************************************
	use "$Datadir/derived/study_cohort.dta", clear
	
	* Create end of follow-up for each outcome
	cap drop end_followup_`outcome'  followup_years_`outcome'
	gen end_followup_`outcome' =  min(enddate, `outcome'_date)
	format end_followup_`outcome' %td
	replace `outcome'_date=. if `outcome'_date > end_followup_`outcome'
	replace `outcome'=0 if `outcome'_date==.
	gen followup_days_`outcome' = end_followup_`outcome' - firstissue
	gen followup_years_`outcome' = followup_days_`outcome'/365.25
	drop followup_days_`outcome'
	drop if followup_years_`outcome'==0
	
	* Row heading
	putexcel A11 = "Total"

	* Number of CVD events
	count if `outcome'==1
	local number_events = `r(N)'
	putexcel B11 = `number_events', nformat("#")
	
	* Median follow up years
	gen followup_days = end_followup_`outcome' - firstissue
	gen followup_years = followup_days/365.25
	summarize followup_years, detail
	local median = r(p50)
	local p25 = r(p25)
	local p75 = r(p75)
	local median_iqr = string(`median', "%9.1f") + " (" + string(`p25', "%9.1f") + "-" + string(`p75', "%9.1f") + ")"
	putexcel C11 = "`median_iqr'"

	* Total follow-up years
	summarize followup_years, meanonly
	putexcel D11 = `r(sum)', nformat("#.##")

	* Crude incidence rate
	local totalfu1000 = `r(sum)'/1000
	local rate = `number_events'/`totalfu1000'
	putexcel E11 = `rate', nformat("#.##") 

}

log close