proc datasets kill nolist; run; /*����ڴ��е���������*/

/*����������ݱ����ڱ��أ���ΪSAS���ݿ�*/

libname home "F:\sas university edition\data";

/*���벢�Һϲ�����*/
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

/*ʱ����ֵ��*/
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

/*����ȥ�ظ�ֵ*/
/*proc print data=trd_dalyr(firstobs=1 obs=50); run;*/
data CD0;
	set trd_dalyr;
	keep stkcd;
run;

Proc Sort data=CD0 nodupkey;
  By Stkcd;
Run;

/*proc print data=CD0(firstobs=1 obs=3200); run;*/

/*�������*/
data CD1;
   set CD0;
   by Stkcd notsorted;
   if first.dt then n=1;
   else n+1;   
run;

/*proc print data=CD1(firstobs=1 obs=3200); run;*/

/*�ϲ���ź�ԭ����*/
proc sql;
	create table trd_dalyr as
	select a.n, b.*
	from CD1 as a left join trd_dalyr as b
	on a.Stkcd=b.Stkcd
	order by Stkcd;
quit;

/*proc print data=trd_dalyr (firstobs=1 obs=2000); run;*/

/*����ĳһֻ��Ʊ����ʵ��ƫ��20941*/
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

/*%getskw (monthdy=20941);ע�⣬��κ�û���޶�stkcd��*/

/*proc print data=x20941(firstobs=1 obs=50); run;*/

/*�鿴stkcd������*/
/*data trd_dalyr1;
	set trd_dalyr;
	keep Stkcd;
run;

proc sort data=trd_dalyr1 out=trd_dalyr_stkcd nodup;
  by Stkcd;
run;

proc print data=trd_dalyr_stkcd (firstobs=1 obs=50); run; */

/*����ÿֻ��Ʊ����ʵ��ƫ�ȣ��ǵ÷�С��ֱ���㣬�����������������Կ��ܱ���*/
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

/*��Ϊ�����������Ӵ����������ݲ�ʹ��*/


/*proc print data=trd_dalyr(firstobs=1 obs=50); run;*/

/*ÿֻ��Ʊ����skw*/
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

/*��skw���ӵ��ܱ���*/
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

/*��ȡskw�ķ�λ��*/
proc sort data=trd_dalyr1; by monthdy; run;
proc univariate data=trd_Dalyr1 noprint;
	var skw;
	by monthdy;
	output out=docdoc pctlpts=30 70 PCTLPRE=doc;
run;

/*���ݷ�λ�����,����ϲ�����,�õ�SKWָ��*/
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

/*������ͨ��ֵ��Ȩ���ն�������*/
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

/*����SKW����,Сƫ�������ƫ����������*/
data trd_dalyr5;
	set trd_dalyr4;
	SKW=vwmpret1-vwmpret3;
run;

/*proc print data=trd_dalyr5(firstobs=1 obs=1000); run;*/

/*����SKW�������������*/
data trd_dalyr6;
	set trd_dalyr5;
	drop _NAME_ _LABEL_ vwmpret1 vwmpret2 vwmpret3 monthdy;
run;

/*proc print data=trd_dalyr6(firstobs=1 obs=1000); run;*/

/*��������*/
proc export data=trd_dalyr6
outfile="C:\Users\Jackgloves\Desktop\skw.csv"
dbms=dlm;
delimiter='09x';
run;










