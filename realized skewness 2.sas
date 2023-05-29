proc datasets kill nolist; run; /*清空内存中的所有数据*/

/*将读入的数据保存在本地，成为SAS数据库*/

libname home "F:\sas university edition\data";

/*导入并且合并数据*/
data trd_dalyr;
	set home.trd_dalyr;
	if Markettype=1 or Markettype=4;
run;

data trd_dalyr1;
	set home.trd_dalyr1;
	if Markettype=1 or Markettype=4;
run;

data trd_dalyr2;
	set home.trd_dalyr2;
	if Markettype=1 or Markettype=4;
run;

data trd_dalyr3;
	set home.trd_dalyr3;
	if Markettype=1 or Markettype=4;
run;

data trd_dalyr;
	set trd_dalyr trd_dalyr1 trd_dalyr2 trd_dalyr3;
	if Markettype=1 or Markettype=4;
run;

/*proc print data=trd_dalyr(firstobs=1 obs=50); run;*/

/*时间数值化*/
data trd_dalyr;
	set trd_dalyr;
	year=substr(trddt,1,4)*1;
	month=substr(trddt,6,2)*1;
	day=substr(trddt,9,2)*1;
	ymonth=year*100+month;
	monthdy=mdy(month,day,year);
	stkcd=input(substr(stkcd,1,6),6.);
	keep stkcd Dsmvosd Dretwd monthdy;
run;

/*尝试去重复值*/
/*proc print data=trd_dalyr(firstobs=1 obs=50); run;*/
data CD0;
	set trd_dalyr;
	keep stkcd;
run;

Proc Sort data=CD0 nodupkey;
  By Stkcd;
Run;

/*proc print data=CD0(firstobs=1 obs=3200); run;*/

/*生成序号*/
data CD1;
   set CD0;
   by Stkcd notsorted;
   if first.dt then n=1;
   else n+1;   
run;

/*proc print data=CD1(firstobs=1 obs=3200); run;*/

/*合并序号和原数据*/
proc sql;
	create table trd_dalyr as
	select a.n, b.*
	from CD1 as a left join trd_dalyr as b
	on a.Stkcd=b.Stkcd
	order by Stkcd;
quit;

/*proc print data=trd_dalyr (firstobs=1 obs=2000); run;*/

/*计算某一只股票的已实现偏度20941*/
/*
%macro getskw(monthdy=);
	data x; set trd_dalyr1;
		if &monthdy+30>=monthdy>=&monthdy-30;
	run;

	proc means data=x n mean skewness noprint;
		var Dretwd;
		output out=x1 n=count skewness=skw;
	run;

	proc sql;
		create table x2 as 
		select skw from x1;
	quit;

	data x&monthdy;
		set x2;
		monthdy=&monthdy;
	run;

	proc append base=skw data=x&monthdy;
	run;

%mend;

/*%getskw (monthdy=20941);注意，这段宏没有限定stkcd！*/

/*proc print data=x20941(firstobs=1 obs=50); run;*/

/*查看stkcd的数量*/
/*data trd_dalyr1;
	set trd_dalyr;
	keep Stkcd;
run;

proc sort data=trd_dalyr1 out=trd_dalyr_stkcd nodup;
  by Stkcd;
run;

proc print data=trd_dalyr_stkcd (firstobs=1 obs=50); run; */

/*计算每只股票的已实现偏度，记得分小组分别计算，否则计算量超级大电脑可能崩溃*/
/*%macro getskw2;
	%do Stkcd=1 %to 2;
		
		proc delete data=skw;
		run;

		data trd_dalyr1;
			set trd_dalyr;
			if Stkcd=&Stkcd;
		run;

		%do monthdy=20941 %to 20942;
			%getskw (monthdy=&monthdy);
		%end;

		data skw&Stkcd;
			set skw;
		run;
	%end;
%mend;

%getskw2;

/*proc print data=skw1(firstobs=1 obs=1200); run;*/

/*因为数据量过于庞大，以上内容暂不使用*/


/*proc print data=trd_dalyr(firstobs=1 obs=50); run;*/

/*每只股票计算skw*/
%macro getstkskw;

	%do n=1 %to 1500;

		data x; set trd_dalyr;
			if n=&n;
		run;

		proc means data=x n mean skewness noprint;
			var Dretwd;
			output out=x1 n=count skewness=skw;
		run;

		proc sql;
			create table y1 as 
			select skw from x1;
		quit;

		data y1;
			set y1;
			n=&n;
		run;

		proc append base=skw data=y1;
		run;

	%end;

%mend;

%getstkskw;

/*将skw连接到总表上*/
data trd_dalyr0;
	set trd_dalyr;
	stk_cd=input(n,6.);
run;

proc sql;
	create table trd_dalyr1 as select b.n, b.Dretwd, b.Dsmvosd, b.monthdy, a.skw
	from skw as a left join trd_dalyr0 as b
	on a.n = b.n;
quit;


/*proc print data=trd_dalyr1(firstobs=1 obs=1000); run;*/


/*PROC CONTENTS DATA=trd_dalyr0;*/
/*run;*/

/*获取skw的分位点*/
proc sort data=trd_dalyr1; by monthdy; run;
proc univariate data=trd_Dalyr1 noprint;
	var skw;
	by monthdy;
	output out=docdoc pctlpts=30 70 PCTLPRE=doc;
run;

/*根据分位点分组,反向合并数据,得到SKW指标*/
proc sql;
	create table trd_dalyr2 as
	select b.*,
	case when skw<=doc30 then 0
		when skw<=doc70 then 1
	  else 2
	end as port
	from docdoc as a left join trd_dalyr1 as b
	on a.monthdy=b.monthdy
	order by monthdy;
quit;

/*proc print data=trd_dalyr2(firstobs=1 obs=1000); run;*/

/*计算流通市值加权的日度收益率*/
proc sort data=trd_dalyr2; by monthdy port;run;
proc summary data=trd_dalyr2;
	weight Dsmvosd;
	var Dretwd;
	by monthdy port;
	output out=trd_dalyr3 mean=skw;
run;
proc transpose data=trd_dalyr3 out=trd_dalyr4 prefix=vwmpret; by monthdy;var skw;
run;

/*proc print data=trd_dalyr4(firstobs=1 obs=1000); run;*/

/*计算SKW因子,小偏度组减大偏度组收益率*/
data trd_dalyr5;
	set trd_dalyr4;
	SKW=vwmpret1-vwmpret3;
run;

/*proc print data=trd_dalyr5(firstobs=1 obs=1000); run;*/

/*计算SKW，完善输出内容*/
data trd_dalyr6;
	set trd_dalyr5;
	drop _NAME_ _LABEL_ vwmpret1 vwmpret2 vwmpret3 monthdy;
run;

/*proc print data=trd_dalyr6(firstobs=1 obs=1000); run;*/

/*导出数据*/
proc export data=trd_dalyr6
outfile="C:\Users\Jackgloves\Desktop\skw.csv"
dbms=dlm;
delimiter='09x';
run;










