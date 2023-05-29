proc datasets kill nolist; run; /*清空内存中的所有数据*/

/*尝试导入数据*/
proc import datafile = 'C:\Users\Jackgloves\Desktop\五因子数据-解释变量.xlsx'
    DBMS=xlsx OUT = datainput REPLACE;
    SHEET = '汇总';
    GETNAMES = YES;
run;

proc import datafile = 'C:\Users\Jackgloves\Desktop\市场已实现偏度数据.xlsx'
    DBMS=xlsx OUT = datainput2 REPLACE;
    SHEET = 'Sheet1';
    GETNAMES = YES;
run;

proc import datafile = 'C:\Users\Jackgloves\Desktop\市场已实现偏度数据.xlsx'
    DBMS=xlsx OUT = datainput3 REPLACE;
    SHEET = 'Sheet2';
    GETNAMES = YES;
run;

data datainput2;
	set datainput2 (firstobs=1 obs=975);
run;

/*proc print data =datainput2; run;*/

/*浏览数据，应有976行观测以及多列变量*/
/*proc print data =datainput; run;*/

/*CH-5*/
%macro CH5(x=);
	proc reg data=datainput;
		MODEL PORT&x=MKT SMB HML PMO SKW;
	run;
%mend;

%CH5(x=9)


/*CH-4*/
%macro CH4 (x=);
	proc reg data=datainput;
		MODEL PORT&x=MKT SMB PMO SKW;
	run;
%mend;

%CH4(x=9)


/*单纯回归偏度*/
%macro getsimplereg (x=);
	proc reg data=datainput;
		MODEL PORT&x=SKW;
	run;
%mend;

%getsimplereg(x=9)

/*市场数据回归*/
proc reg data=datainput3;
	MODEL mret=mskw;
run;

/*查看总收益率直方图,去掉print可以查看所有变量的统计数据*/
PROC univariate DATA = datainput3 noprint;
	HISTOGRAM mskw;
RUN;

/*画折线图*/
symbol1 interpol=join value=dot;
proc gplot data=datainput2;
   plot mktret*N;
run;

/*画概率分布图*/
/*ods graphics on;
   proc kde;
      univar mret / plots=(density);
   run;
   
ods graphics off;*/

proc univariate data=datainput2;
   var mktret;
   histogram mktret /kernel;
run;

/*描述性统计*/
proc means data=datainput n mean std min max;
	var MKT SMB HML PMO SKW;
	output out=x;
run;

/*自相关*/
proc arima data=datainput2;
   identify var=mktskw nlag=1;
run;

/*格兰杰因果检验*/
proc varmax data=datainput3;
	model mret=mskw / p=1;
	causal group1=(mret) group2=(mskw);
	causal group1=(mskw) group2=(mret);
run;

proc varmax data=datainput2;
	model mktpre=mktskw / p=9;
	causal group1=(mktpre) group2=(mktskw);
	causal group1=(mktskw) group2=(mktpre);
run;

/*相关性检验*/
PROC CORR DATA = datainput;
VAR MKT SMB HML PMO SKW;
run;
