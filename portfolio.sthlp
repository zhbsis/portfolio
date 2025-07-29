{smcl}
{right:version:  3.0.0}
{cmd:help portfolio} {right:March 20, 2023}
{hline}
{viewerjumpto "syntax" "portfolio##syntax"}{...}
{viewerjumpto "Description" "portfolio##Description"}{...}
{viewerjumpto "Examples" "portfolio##portfolio_examples"}{...}
{viewerjumpto "Stored results" "portfolio##results"}{...}
{viewerjumpto "Author" "portfolio##Author"}{...}
{viewerjumpto "References" "portfolio##References"}{...}
{viewerjumpto "Acknowledgements" "portfolio##acknowledgements"}{...}
{viewerjumpto "Also see" "portfolio##also"}{...}
{title:Title}

{p 4 8}{cmd:portfolio}  -  conducts the portfolio analysis broadly employed in empirical asset pricing studies. {p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:portfolio}
{varlist}
{ifin}
{cmd:,} 
{it:groupby(timevar keyvar) nq(#)}
[{it:{help portfolio##portfolio_options:Options}}]
{p_end}

{marker Description}{...}
{title:Description}

{p 4 4 2} {cmd: portfolio} conducts asset portfolio analysis, including calculating equal- (value-) weighted returns for the portfolio, 
testing the significance of a long-short strategy, etc. portfolio allows one to use either univariate portfolio test or bivariate portfolio test, 
where the bivariate test methods can be either independent or dependent. portfolio also provides Newey-West standard error adjustment option, 
allowing users to alleviate the impact of potential autocorrelation and heteroskedasticity in the return series.
{p_end}


{marker portfolio_options}{...}
{title:Options}

{dlgtab: Required basic options}
{phang}
{cmd: groupby(timevar keyvar)} specifies the time-frequency and the sort variable for portfolio construction.

{phang}
{cmd: nq(#)} specifies the number of quantiles. For example, nq(10) will create deciles, making 10 equal groups of the data based on the values of keyvar.

{phang}
{cmd: cuts(#)} e.g., cuts(0.25 \ 0.50 \0.75), which is equal to nq(4)

{phang}
{cmd: qc(string)} e.g., cvqc("exchange == NYSC"), which compute the quantiles based on the condition and assign it to the entire sample


{dlgtab:Options for return computation}
{phang}
{opth rf(var)} specifies the risk-free rate variable for computing portfolio's excess returns.

{phang}
{opth w(var)} is the weights variable for the computation of portfolio returns.


{dlgtab:Options for bivariate sorts}
{phang}
{opth cv(var)} specifies the controlling variable, which accounts for the effects of any other variables when examining the relationship between the keyvar and the depvar.

{phang}
{cmd: cvnq(#)} specifies the number of quantiles of variable specified in cv(var) option.

{phang}
{cmd: cvcuts(#)} e.g., cvcuts(0.25 \ 0.50 \0.75), which is equal to cvnq(4)

{phang}
{cmd: cvqc(string)} e.g., cvqc("exchange == NYSC"), which compute the quantiles based on the condition and assign it to the entire sample


{phang}
{opt ind:ependentsort} is only valid when cv option is specified. It specifies the construction method of the portfolio. The default construction method is bivariate dependent sorts, and one can override it to bivariate independent sorts by employing this option.

{dlgtab:Options for SE and reporting}
{phang}
{cmd: lag(#)} specifies the length of lags for estimating the Newey-West consistent standard error.

{phang}
{opt reg} saves the regression results of the portfolio analysis by the "est store" command. One can print the results by running the syntax "esttab factorLoading*".

{phang}
{opt all} determines whether to print the detailed results of the portfolio test.

{phang}
{opt save(string)} enables one to save the portfolios' outcome time series into a Stata dta file.


{marker portfolio_examples}{...}
{title:Examples}

{title:Example 1: Univariate portfolio analysis}

{p 4 4 2}The example provides return data during Feb, 2017 to Dec, 2018 of Chinese A-share market.{p_end}

{p 4 4 2}{stata "use https://zhbsis.github.io/portfolio/returnData.dta, clear" :.use returnData.dta, clear}{p_end}

{p 4 4 2}equal-weightd excess return: raw return minus rfs{p_end}

{p 4 4 2}{stata "portfolio RET, groupby(ym L1_TO) nq(5) rf(rf)" :. portfolio RET, groupby(ym L1_TO) nq(5) rf(rf)} {p_end}

{p 4 4 2}equal-weightd alpha return: raw return ajusted by fama-french three factor model{p_end}

{p 4 4 2}{stata "portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf)" :. portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf)} {p_end}

{p 4 4 2}value-weightd alpha return: raw return ajusted by fama-french three factor model{p_end}

{p 4 4 2}{stata "portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) w(w)" :. portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) w(w)} {p_end}

{p 4 4 2}value-weightd alpha return and t-statistic is adjusted by Newey-west approach with 4 lags{p_end}

{p 4 4 2}{stata "portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) w(w) lag(4)" :. portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) w(w) lag(4)} {p_end}

{p 4 4 2}present the detailed results{p_end}

{p 4 4 2}{stata "portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) lag(4) all" :. portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) lag(4) all} {p_end}

{p 4 4 2}save the factor loadings and print{p_end}

{p 4 4 2}{stata "est clear" :. est clear}{p_end}
{p 4 4 2}{stata "portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) lag(4) reg" :. portfolio RET mkt_rf smb hml, groupby(ym L1_TO) nq(5) rf(rf) lag(4) reg} {p_end}
{p 4 4 2}{stata "esttab factorLoading*" :. esttab factorLoading*} {p_end}


{title:Example 2: Bivariate portfolio analysis}

{p 4 4 2}{stata "use https://zhbsis.github.io/portfolio/returnData.dta, clear" :.use returnData.dta, clear}{p_end}

{p 4 4 2}value-weighted results and t-statistic is adjusted by Newey-west approach with 4 lags{p_end}

{p 4 4 2}{stata "portfolio RET, groupby(ym L1_TO) nq(5) cv(L1_PRICE) cvnq(3) rf(rf) w(w) lag(4)" :. portfolio RET, groupby(ym L1_TO) nq(5) cv(L1_PRICE) cvnq(3) rf(rf) w(w) lag(4)} {p_end}

{p 4 4 2}If the user only cares about whether the relationship between the stock turnover and the next month's return is significant after controlling for PRICE.
Then a simple version of the result can be obtained by running the following command:{p_end}

{p 4 4 2}{stata "astile G1 = L1_PRICE, nq(3) by(ym)" :. astile G1 = L1_PRICE, nq(3) by(ym)} {p_end}
{p 4 4 2}{stata "astile G2 = L1_TO, nq(5) by(G1 ym)" :. astile G2 = L1_TO, nq(5) by(G1 ym)} {p_end}
{p 4 4 2}{stata "portfolio RET, groupby(ym G2) nq(5) rf(rf) w(w) lag(4)" :. portfolio RET, groupby(ym G2) nq(5) rf(rf) w(w) lag(4)} {p_end}


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:portfolio} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:r(alpha)}}portfolio's return vector{p_end}
{synopt:{cmd:r(tstat)}}t-statistic of the corresponding portfolio's return{p_end}
{synopt:{cmd:r(p_val)}}p-value corresponds to the t-statistic{p_end}


{marker Author}{...}
{title:Author}

{p 4 4 2} {cmd:Hongbing, Zhu}{p_end}
{p 4 4 2} Business School, Hohai University, China. {p_end}
{p 4 4 2} Email: {browse "mailto:zhuhongbing@hhu.edu.cn":zhuhongbing@hhu.edu.cn} {p_end}

{p 4 4 2} {cmd:Lihua, Yang}{p_end}
{p 4 4 2} Business School, Hohai University, China. {p_end}
{p 4 4 2} Email: {browse "mailto:yanglihua@hhu.edu.cn":yanglihua@hhu.edu.cn} {p_end}

{marker References}{...}
{title:References}

{p 4 4 2} Bali, Turan G., Robert F. Engle, and Scott Murray. 
"Empirical asset pricing: The cross-section of stock returns".
{it:John Wiley & Sons, 2016.}
{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{p 4 4 2}
{cmd:portfolio} is built on the work of many Stata community contributors, 
including Dr. Attaullah Shah, Mauricio Caceres Bravo, and Matthieu Gomez.
Also invaluable are the great bug-spotting abilities of many users.
{p_end}


{marker also}{...}
{title:Also see}

{psee}
{stata "ssc desc astile":astile},
{stata "ssc desc asgen":asgen},
{stata "ssc desc gtools":gduplicates},
{stata "ssc desc tidy":spread},
{stata "ssc desc readwind":readwind}

