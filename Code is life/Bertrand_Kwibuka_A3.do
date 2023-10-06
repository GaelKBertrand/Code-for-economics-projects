clear all

*log using C:\Users\LABPC13\Desktop\stata\A3

bcuse volat
 
tsset ym 

*plotting the line graph: 

twoway (tsline rsp500), title(Standard and Poors 500 Stock Market Index: Line Graph for the Monthly Return) 

*Description:

describe rsp500 

*b)
* OLS: 

regress rsp500 pcip i3 

*Testing for S.C in AR(1):

estat bgodfrey 

*c) 

*obtaining residuals to get u(t)

regress rsp500 pcip i3 

predict e, residual 

gen u_t = e

drop e

*regressing the residual on lag 1 : L.u_t  is U_t-1

regress u_t L.u_t

*Testing for S.C for e in AR(1):
estat bgodfrey 


*d)
*Testing S.C in errors obtained in c). I will need lag 2
*i) getting u(t) = ρu(t−1) + e(t) again 
regress u_t L.u_t

*getting e(t)
predict e, residual 

gen e_t = e

drop e

regress e_t L.e_t

estat bgodfrey 


*f) Correction of S.C using Newey Test to correct b)
*model:

regress rsp500 pcip i3 

*correction: H test and Newey correction: 

regress rsp500 pcip i3, robust
newey rsp500 pcip i3, lag(0)










