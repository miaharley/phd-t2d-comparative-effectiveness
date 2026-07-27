/*=========================================================================
DO FILE NAME:			C0b - import data extract.do

AUTHOR:					Mia Harley, adapted from Marleen Bokern

VERSION:				v1

DATE VERSION CREATED: 	04/2023
						
DATASETS CREATED:       T2d_Extract_Observation_xx.dta
						T2d_Extract_Practice_xx.dta
						T2d_Extract_Patient_1.dta
						T2d_Extract_Practice_1.dta
					
						
DESCRIPTION OF FILE:	checks all files are unzipped, imports txt file, formats some variables and saves as dta 					
*=========================================================================*/

clear
capture log close
set more off, perm 

log using $Logdir/01cr_check_files_extract.log, replace
cd $Projectdir

clear all
macro list _all

*** Run globals
do "J:\EHR-Working\Mia\PhD\T2D_comparative_effectiveness\create\dofiles\_globals_create.do"

glob file_stub 			= 	"part1"
glob file_Patient 		= 	"${file_stub}_Extract_Patient_"
glob file_Practice 		=	"${file_stub}_Extract_Practice_"
glob file_Staff			=	"${file_stub}_Extract_Staff_"
glob file_Consultation 	= 	"${file_stub}_Extract_Consultation_"
glob file_Observation	= 	"${file_stub}_Extract_Observation_"
glob file_Referral 		= 	"${file_stub}_Extract_Referral_"
glob file_Problem 		= 	"${file_stub}_Extract_Problem_"
glob file_DrugIssue		= 	"${file_stub}_Extract_DrugIssue_"

// Specify number of different files in part1_Extract
glob no_Patient = 2
glob no_Practice = 2
glob no_Staff = 2
glob no_Consultation = 37
glob no_Observation = 163
glob no_Referral = 2
glob no_Problem = 4
glob no_DrugIssue = 167

***zip files were extracted manually.
***part2 extract files moved into part1 extract folder and numbered continuously

/*******************************************************************************
>> check all files are there
*******************************************************************************/

// Specify directory containing file names
cd "$Extractdir"

// Check presence of files
loc valid_check = 1
foreach table_name in "Patient" "Practice" "Staff" "Consultation" "Observation" "Referral" "Problem" "DrugIssue" {
    forvalues i = 1/${no_`table_name'} {
	    loc file_name: di "${file_`table_name'}" %03.0f (`i') ".txt"
	    capture confirm file "`file_name'"
		if _rc != 0  {
		    di "`file_name' not found"
			local valid_check = 0
		}
	}
} 

// Provide feedback on check success or failure
qui {
    if `valid_check' == 1 {
     noi di "All files found"
	} 
	else {
	 noi di "Not all files found"
	}
}

***all files found

***********************************************************************************************

/******************************************************************************************************
>> Convert all necessary files to dta, rename, reformat, and drop variables where necessary
*******************************************************************************************************/
cd "$Extractdir"

/******************************************************************************************************
>> CONVERT OBSERVATION FILES
****import text files
****drop staffid, consid, obsid, parentobsid, probobsid
****reformat date variables
****drop observations after the end of follow-up
****summarize missing values
****compress and save as dta file
*******************************************************************************************************/

foreach file of numlist 1/9 {
	noi di "Converting Observation, File `file'"
    import delimited using "${file_stub}_Extract_Observation_00`file'.txt", clear stringcols(_all)
	drop staffid consid obsid parentobsid probobsid
	g obsdate1 = date(obsdate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	gen eventdate = obsdate1
	replace eventdate = enterdate1 if eventdate ==.
	format (obsdate1 enterdate1 eventdate) %td
	drop obsdate enterdate 
	rename (enterdate1 obsdate1) (enterdate obsdate)
    misstable summarize patid pracid obsdate enterdate eventdate medcodeid
	compress
	save "$Datadir\raw\Nov23_Extract_Observation_`file'.dta", replace
}

foreach file of numlist 10/99 {
	noi di "Converting Observation, File `file'"
    import delimited using "${file_stub}_Extract_Observation_0`file'.txt", clear stringcols(_all)
	drop staffid consid obsid parentobsid probobsid
	g obsdate1 = date(obsdate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	gen eventdate = obsdate1
	replace eventdate = enterdate1 if eventdate ==.
	format (obsdate1 enterdate1 eventdate) %td
	drop obsdate enterdate 
	rename (enterdate1 obsdate1) (enterdate obsdate)
    misstable summarize patid pracid obsdate enterdate eventdate medcodeid
	compress
	save "$Datadir\raw\Nov23_Extract_Observation_`file'.dta", replace
}

foreach file of numlist 100/$no_Observation {
	noi di "Converting Observation, File `file'"
    import delimited using "${file_stub}_Extract_Observation_`file'.txt", clear stringcols(_all)
	drop staffid consid obsid parentobsid probobsid
	g obsdate1 = date(obsdate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	gen eventdate = obsdate1
	replace eventdate = enterdate1 if eventdate ==.
	format (obsdate1 enterdate1 eventdate) %td
	drop obsdate enterdate 
	rename (enterdate1 obsdate1) (enterdate obsdate)
    misstable summarize patid pracid obsdate enterdate eventdate medcodeid
	compress
	save "$Datadir\raw\Nov23_Extract_Observation_`file'.dta", replace
}

/******************************************************************************************************
>> CONVERT DRUG ISSUE FILES
****import text files
****drop staffid, probobsid, issueid, drugrecid
****reformat date variables
****destring numerical variables
****drop observations after the end of follow-up
****summarize missing values
****compress and save as dta file
*******************************************************************************************************/
foreach file of numlist 1/9 {
	noi di "Converting Drug Issue, File `file'"
    import delimited using "${file_stub}_Extract_DrugIssue_00`file'.txt", stringcols(_all) clear
	drop issueid probobsid drugrecid staffid
	g issuedate1 = date(issuedate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	format (issuedate1 enterdate1) %td
	drop issuedate enterdate 
	rename (enterdate1 issuedate1) (enterdate issuedate)
	destring quantity duration, replace
    misstable summarize patid pracid issuedate enterdate prodcodeid dosageid quantity quantunitid duration
	compress
	save "$Datadir\raw\Nov23_Extract_DrugIssue_`file'.dta", replace
}

foreach file of numlist 10/99 {
	noi di "Converting Drug Issue, File `file'"
    import delimited using "${file_stub}_Extract_DrugIssue_0`file'.txt", stringcols(_all) clear
	drop issueid probobsid drugrecid staffid
	g issuedate1 = date(issuedate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	format (issuedate1 enterdate1) %td
	drop issuedate enterdate 
	rename (enterdate1 issuedate1) (enterdate issuedate)
	destring quantity duration, replace
    misstable summarize patid pracid issuedate enterdate prodcodeid dosageid quantity quantunitid duration
	compress
	save "$Datadir\raw\Nov23_Extract_DrugIssue_`file'.dta", replace
}

foreach file of numlist 100/$no_DrugIssue {
	noi di "Converting Drug Issue, File `file'"
    import delimited using "${file_stub}_Extract_DrugIssue_`file'.txt", stringcols(_all) clear
	drop issueid probobsid drugrecid staffid
	g issuedate1 = date(issuedate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	format (issuedate1 enterdate1) %td
	drop issuedate enterdate 
	rename (enterdate1 issuedate1) (enterdate issuedate)
	destring quantity duration, replace
    misstable summarize patid pracid issuedate enterdate prodcodeid dosageid quantity quantunitid duration
	compress
	save "$Datadir\raw\Nov23_Extract_DrugIssue_`file'.dta", replace
}

/******************************************************************************************************
>> CONVERT CONSULTATION FILES
****import text files
****drop drop staffid cprdconstype
****reformat date variables
****destring numerical variables
****drop observations after the end of follow-up
****summarize missing values
****compress and save as dta file
*******************************************************************************************************/
foreach file of numlist 1/9 {
	noi di "Converting Consultation, File `file'"
    import delimited using "${file_stub}_Extract_Consultation_00`file'.txt", stringcols(_all) clear
	drop staffid cprdconstype 
	g consdate1 = date(consdate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	format (consdate1 enterdate1) %td
	drop consdate enterdate 
	rename (enterdate1 consdate1) (enterdate consdate)
    misstable summarize patid pracid consdate enterdate conssourceid consmedcodeid 
	compress
	save "$Datadir\raw\Nov23_Extract_Consultation_`file'.dta", replace
}

foreach file of numlist 10/$no_Consultation {
	noi di "Converting Consultation, File `file'"
    import delimited using "${file_stub}_Extract_Consultation_0`file'.txt", stringcols(_all) clear
	drop staffid cprdconstype 
	g consdate1 = date(consdate, "DMY")
	g enterdate1 = date(enterdate,"DMY")
	format (consdate1 enterdate1) %td
	drop consdate enterdate 
	rename (enterdate1 consdate1) (enterdate consdate)
    misstable summarize patid pracid consdate enterdate conssourceid consmedcodeid 
	compress
	save "$Datadir\raw\Nov23_Extract_Consultation_`file'.dta", replace
}

/******************************************************************************************************
>> CONVERT PATIENT FILE
****import text file
****drop usualgpstaffid, acceptable
****reformat date variables
****summarize missing values
****compress and save as dta file
*******************************************************************************************************/
noi di "Converting Patient file 1"
import delimited using "${file_stub}_Extract_Patient_001.txt", clear stringcols(_all)
drop usualgpstaffid acceptable
destring yob mob gender, replace
g regstart = date(regstartdate, "DMY")
g emis_death = date(emis_ddate,"DMY")
g deathdate = date(cprd_ddate,"DMY")
g regend = date(regenddate,"DMY")
format (regstart emis_death deathdate regend) %td
drop regstartdate emis_ddate cprd_ddate regenddate 
misstable summarize 
compress
save "$Datadir\raw\Nov23_Extract_Patient_1.dta", replace

clear
noi di "Converting Patient file 2"
import delimited using "${file_stub}_Extract_Patient_002.txt", clear stringcols(_all)
destring yob mob gender, replace
g regstart = date(regstartdate, "DMY")
g emis_death = date(emis_ddate,"DMY")
g deathdate = date(cprd_ddate,"DMY")
g regend = date(regenddate,"DMY")
format (regstart emis_death deathdate regend) %td
drop regstartdate emis_ddate cprd_ddate regenddate 
misstable summarize 
compress

*append into single file
append using "$Datadir\raw\Nov23_Extract_Patient_1.dta"
save "$Datadir\raw\Nov23_Extract_Patient_1.dta", replace

/******************************************************************************************************
>> CONVERT PRACTICE FILE
****import text file
****drop uts, region
****reformat date variables
****compress and save as dta file
*******************************************************************************************************/
noi di "Converting Practice file 1"
import delimited using "${file_stub}_Extract_Practice_001.txt", clear stringcols(_all)
g lcd1 = date(lcd, "DMY")
format lcd1 %td
drop lcd
rename lcd1 lcd
compress
save "$Datadir\raw\Nov23_Extract_Practice_1.dta", replace

clear
noi di "Converting Practice file 2"
import delimited using "${file_stub}_Extract_Practice_002.txt", clear stringcols(_all)
g lcd1 = date(lcd, "DMY")
format lcd1 %td
drop lcd
rename lcd1 lcd
compress

*append into single file
append using "$Datadir\raw\Nov23_Extract_Practice_1.dta"
duplicates drop
save "$Datadir\raw\Nov23_Extract_Practice_1.dta", replace

/******************************************************************************************************
>> CONVERT PROBLEM FILE
****import text file
****compress and save as dta file
*******************************************************************************************************/
foreach file of numlist 1/$no_Problem {
	noi di "Converting Problem, File `file'"
	import delimited using "${file_stub}_Extract_Problem_00`file'.txt", stringcols(_all) clear
	compress
	save "$Datadir\raw\Nov23_Extract_Problem_`file'", replace
}

/******************************************************************************************************
>> CONVERT REFERRAL FILE
****import text file
****compress and save as dta file
*******************************************************************************************************/
noi di "Converting Referral file 1"
import delimited using "${file_stub}_Extract_Referral_001.txt", clear stringcols(_all)
compress
save "$Datadir\raw\Nov23_Extract_Referral_1", replace

clear
noi di "Converting Referral file 2"
import delimited using "${file_stub}_Extract_Referral_002.txt", clear stringcols(_all)
compress

*append into single file
append using "$Datadir\raw\Nov23_Extract_Referral_1"
save "$Datadir\raw\Nov23_Extract_Referral_1", replace
/******************************************************************************************************
>> CONVERT STAFF FILE
****import text file
****compress and save as dta file
*******************************************************************************************************/
noi di "Converting Staff file 1"
import delimited using "${file_stub}_Extract_Staff_001.txt", clear stringcols(_all)
compress
save "$Datadir\raw\Nov23_Extract_Staff_1", replace

clear
noi di "Converting Staff file 2"
import delimited using "${file_stub}_Extract_Staff_002.txt", clear stringcols(_all)
compress

*append into single file
append using "$Datadir\raw\Nov23_Extract_Staff_1"
save "$Datadir\raw\Nov23_Extract_Staff_1", replace

clear all

log close
