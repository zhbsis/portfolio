*! portfolio.ado
*! portfolio conducts the portfolio analysis widely used in empirical asset pricing studies.
*===========================================================================================
* Program: portfolio.ado
* Purpose: Perform the onesort or twosort portfolio analysis in Stata
* Version: 3.0.0 (2023/03/20)
* Author:  Hongbing Zhu & Lihua Yang
*===========================================================================================

//
//cap prog drop requiredPackages
program requiredPackages
	local error 0
	local reqs "astile asgen gduplicates spread"
	foreach reqs_ado of local reqs {
		loc fn `reqs_ado'.ado
		cap findfile `fn'
		if (_rc) {
			loc error 1
			di as text _n _n "{lalign 20:- package `reqs_ado'}" as error "not find" _c
			di as text _n _n "{stata ssc install `reqs_ado':install from SSC}" _c
		}
	}
	di as text _n _n "" _c
	if (`error') exit 601
end


//
//cap prog drop quat2
prog quat2, byable(onecall) sortpreserve
syntax namelist=/exp [if] [in], by(varlist) [cutpoints(string) QC(string)]
	
	capture sum `namelist'
	if(_rc == 0){
		disp as error "group variable of `exp' is already defined"
		exit 198
	}
	
	tempvar exp2
	qui gen `exp2' = `exp'
	
	marksample touse
	qui keep if `touse'
	
	if "`cutpoints'" == "" {
		local cutpoints "0.5"
	}
	
	if "`qc'" == ""{
	    tempvar touse2
	    gen `touse2' = 1
	}
	if "`qc'" != ""{
		tempvar touse2
		gen `touse2' = `qc'
	}

	if "`by'"!=""{
		local _byvars "`by'"
	}
	
	if "`_byvars'"!="" {
		tempvar numby n first
		qui bysort `_byvars': gen  `first' = _n == 1 
		qui gen `numby'=sum(`first')  
		drop `first'
	}

	mata: quat(var = "`numby' `exp' `touse2'", at = (`cutpoints'), qc=1)
	order `exp2', before(`exp')
	qui rename (`exp' `exp2') (`namelist' `exp')
	label var `namelist' "`nquantiles' quantiles of `exp'"

end


//
//program drop portfolio
program define portfolio, rclass
version 14.0
syntax varlist(min=1) [if] [in], groupby(string) /*
                     */ [nq(numlist integer) cuts(string) qc(string) rf(string)        /*
					 */  cv(string) cvnq(numlist integer) cvcuts(string) cvqc(string)  /*
					 */  lag(string) w(string) reg all INDependentsort save(string)]
	
	requiredPackages
	preserve
		marksample touse
		keep if `touse'
		
		local nvar: word count `groupby'
		if (`nvar' != 2){
			disp as error "groupby should be set by time and group variable"
			exit 198
		}
		
		if ("`cv'" != "" & "`cvnq'" == "" & "`cvcuts'" == ""){
			disp as error "cvnq or cvcuts should be setted"
			exit 198
		}
		
		if ("`nq'" != "" & "`cuts'" != ""){
			disp as error "nq and cuts cannot be setted together"
			exit 198
		}
		
		if ("`cvnq'" != "" & "`cvcuts'" != ""){
			disp as error "cvnq and cvcuts cannot be setted together"
			exit 198
		}

		if("`lag'" == ""){
			local regmethod "reg"
			local option "robust"
			local std_type "Huber and White"
		}
		else{
			local regmethod "newey"
			local option "lag(`lag') force"
			local std_type "Newey-West"
		}

		if("`reg'" != ""){
			local reg ""
			local eststore "est store factorLoading"
		} 
		else{
			local reg "qui"
		}

		tokenize `varlist'
		local Ri `1'
		macro shift 1
		local factors `*'

		// Construction of portfolios at each month
		* (1) tokenize of local option groupby
		tokenize `groupby'
		local ym `1'
		macro shift 1
		local keyVar `*'
		
		* (2) Applying astile procedure according to timeVar & keyVar
		
		if "`cv'" != ""{
			* twosort
			drop if `keyVar'==. | `cv'==.
			if("`cvnq'" != ""){
				astile group1 = `cv', nq(`cvnq') by(`ym') qc(`cvqc')
				if "`independentsort'" != ""{
					astile group2 = `keyVar', nq(`nq') by(`ym') qc(`qc')
				}
				else{
					astile group2 = `keyVar', nq(`nq') by(group1 `ym') qc(`qc')
				}
				egen group=group(group1 group2)
			}
			else{
				quat2 group1 = `cv', cutpoints(`cvcuts') by(`ym') qc(`cvqc')
				if "`independentsort'" != ""{
					quat2 group2 = `keyVar', cutpoints(`cuts') by(`ym') qc(`cvqc')
				}
				else{
					quat2 group2 = `keyVar', cutpoints(`cuts') by(group1 `ym') qc(`qc')
				}
				drop if group1 == . | group2 == .
				qui levelsof group1, local(grps1)
				local cvnq: word count `grps1'
				qui levelsof group2, local(grps2)
				local nq: word count `grps2'
				
				egen group=group(group1 group2)
			}
		}
		if "`cv'" == ""{
			drop if `keyVar'==.
			if("`nq'" != ""){
				astile group = `keyVar', nq(`nq') by(`ym') qc(`qc')
			}
			if("`nq'" == ""){
				drop if `keyVar'==.
				quat2 group = `keyVar', cutpoints(`cuts') by(`ym') qc(`qc')
				drop if group == .
				qui levelsof group, local(grps3)
				local nq: word count `grps3'
			}		
		}
		
		* (3) save the group informtion into local var groupNum
		qui levelsof group, local(groups)
		local groupNum : word count `groups'
		
		// Calculations of portfolio returns
		* (1) portfolio returns adjuested by risk-free rate
		if("`w'"!="" & "`rf'"!=""){
			asgen VW_Ri = `Ri', w(`w') by(group `ym')
			gen VW_Ri_Rf = VW_Ri - `rf'
			global Ri_Rf "VW_Ri_Rf"
		}
		if(("`w'"=="" & "`rf'"!="")){
			asgen EW_Ri = `Ri',  by(group `ym')
			gen EW_Ri_Rf = EW_Ri - `rf'
			global Ri_Rf "EW_Ri_Rf"
		}
		
		* (2) portfolio raw returns
		if("`w'"!="" & "`rf'"==""){
			asgen VW_Ri = `Ri', w(`w') by(group `ym')
			gen VW_Ri_Rf = VW_Ri
			global Ri_Rf "VW_Ri_Rf"
		}
		if(("`w'"=="" & "`rf'"=="")){
			asgen EW_Ri = `Ri',  by(group `ym')
			gen EW_Ri_Rf = EW_Ri
			global Ri_Rf "EW_Ri_Rf"
		}
		qui gduplicates drop group `ym' ${Ri_Rf}, force
		keep group `ym' ${Ri_Rf} `factors'
		spread group ${Ri_Rf}		
		
		
		// Regress the return time series on a constant
		qui tsset `ym'
		local rown ""
		forvalues i=1(1)`groupNum' {
			`reg' `regmethod' ${Ri_Rf}`i' `factors', `option'   // reg function
			if "`reg'" == "" local eststore1 "`eststore'_`i'"
			`eststore1'
			if `i'==1{
				mat alpha = J(1, 1, _b[_cons])
				mat tstat = J(1, 1, _b[_cons] / _se[_cons])
				mat p_val = J(1, 1,  2*ttail(e(df_r),abs(_b[_cons]/_se[_cons])))			
			}
			else{
				mat alpha = alpha \ J(1, 1, _b[_cons])
				mat tstat = tstat \ J(1, 1, _b[_cons] / _se[_cons])
				mat p_val = p_val \ J(1, 1, 2*ttail(e(df_r),abs(_b[_cons]/_se[_cons])))
			}
			local rown "`rown' `i'"    // generate the rowname of matrix
		}
		mat Results = alpha, tstat, p_val
		mat colname Results = ret tstat p_val
		mat rowname Results = `rown'
		

		// Long-short strategy returns: High minus Low
		* (1) check: onesort or twosort
		if("`cv'" == "") local d = 1     // onesort
		else local d = `cvnq'            // twosort

		* (2) main function for High minus Low
		forvalues i=1(1)`d'{
			local L = (`i'-1)*`nq' + 1      // L
			local H = (`i'-1)*`nq' + `nq'   // H
			
			tempvar dif`i'
			gen `dif`i'' = ${Ri_Rf}`H' - ${Ri_Rf}`L'
			`reg' `regmethod' `dif`i'' `factors', `option'
			if "`reg'" == "" local eststore2 "`eststore'_hl`i'"
			`eststore2'
			if `i' == 1{
				mat alpha = J(1, 1, _b[_cons])
				mat tstat = J(1, 1, _b[_cons] / _se[_cons])
				mat p_val = J(1, 1,  2*ttail(e(df_r),abs(_b[_cons]/_se[_cons])))
			}
			else{
				mat alpha = alpha , J(1, 1, _b[_cons])
				mat tstat = tstat , J(1, 1, _b[_cons] / _se[_cons])
				mat p_val = p_val , J(1, 1, 2*ttail(e(df_r),abs(_b[_cons]/_se[_cons])))
			}
		}
		mat alpha  = alpha \ tstat \ p_val
		mata: st_rclear()
		mata: colshape_(n = `nq', mat = "Results")
		mat result = r(alpha) \ alpha
		mat tstat  = r(tstat)
		mat p_val  = r(p_val)
		
		local rcname ""
		forvalues i=1(1)`nq'{
			local rcname "`rcname' `i'"
		}
		mat rowname result = `rcname' `nq'-1 tstat p_val
		mat rowname tstat  = `rcname'
		mat rowname p_val  = `rcname'
		
		if("`cv'" == ""){
			mat colname result = ret
			mat colname tstat  = tstat
			mat colname p_val  = p_val
			local title1 "Univariate portfolio test with `std_type' t-statistic"   //Newey-West
		}
		else{
			local ccname ""
			forvalues i=1(1)`cvnq'{
				local ccname "`ccname' `cv':`i'"
			}
			mat colname result = `ccname'
			mat colname tstat  = `ccname'
			mat colname p_val  = `ccname'
			local title1 "Bivariate portfolio test with `std_type' t-statistic"
		}
		local title2 "Detailed results of portfolio test"

		matlist result, rowtitle(`keyVar') title("`title1'") tindent(8) line(eq)   ///
		border(top bottom) format(%9.5f) twidth(12) showcoleq(c)
	
		if ("`all'" != ""){
		 matlist Results, rowtitle(Group) title("`title2'") tindent(8) line(eq) ///
		 border(top bottom) format(%9.5f) twidth(12) showcoleq(c)
		}
		if("`eststore1'" != ""){
			di as text "Factor loadings are stored and can be displaied by 'esttab factorLoading*'"
		}
		
		if("`save'" != ""){
			save "`save'.dta", replace
			di as smcl `"Portfolio's return series are saved in {browse "`save'.dta"}"'		    
		}
		return matrix p_val = p_val
		return matrix tstat = tstat
		return matrix result = result

	restore
end