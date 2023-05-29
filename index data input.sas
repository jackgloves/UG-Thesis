proc datasets kill nolist; run; /*����ڴ��е���������*/

Data IDXDRET(label="ָ��������");
Infile 'F:\sas university edition\data\RESSET_IDXDRET_1.txt' delimiter = '09'x Missover Dsd lrecl=32767 firstobs=2 ;
Format IdxNm $60.;
Format TrdDt $10.;
Format IdxDRet 10.4;
Informat IdxNm $60.;
Informat TrdDt $10.;
Informat IdxDRet 10.4;
Label IdxNm="ָ������";
Label TrdDt="��������";
Label IdxDRet="ָ����������";
Input  IdxNm $  TrdDt  IdxDRet ;
Run;

/*proc print data=IDXDRET (firstobs=1 obs=1000); run;*/

data idxdret0;
	set IDXDRET;
	year=input(substr(trddt,1,4),6.);
	month=input(substr(trddt,6,2),6.);
	day=input(substr(trddt,9,2),6.);
	ymonth=year*100+month;
	monthdy=mdy(month,day,year);
	keep monthdy ymonth IdxDRet;
run;

/*proc print data=idxdret0 (firstobs=1 obs=1000); run;*/

%macro getskw;
%do monthdy=20941 %to 22400;

	data x; set idxdret0;
		if &monthdy+30>=monthdy>=&monthdy-30;
	run;

	proc means data=x n mean skewness noprint;
		var IdxDRet;
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

%end;
%mend;

%getskw ;

/*proc print data=skw1 (firstobs=1 obs=1500); run;*/

proc sql;
	create table skw1 as select a.monthdy,a.ymonth, b.skw
	from idxdret0 as a left join skw as b
	on a.monthdy = b.monthdy
	order by monthdy, ymonth;
quit;
/*proc print data=skw1  (firstobs=1 obs=1500); run;*/


/*data output;
	set idxdret0;
	keep IdxDRet;
run;*/


/*proc export data=output
outfile="C:\Users\Jackgloves\Desktop\skw.csv"
dbms=dlm;
delimiter='09x';
run;*/

/*�����¶�ƫ��*/
%macro getmskw;
%do ymonth=201705 %to 202104;

	data x; set skw1;
		if ymonth=&ymonth;
	run;

	proc means data=x n mean noprint;
		var skw;
		output out=x1 mean=mskw;
	run;

	proc sql;
		create table x2 as 
		select mskw from x1;
	quit;

	data x&ymonth;
		set x2;
		ymonth=&ymonth;
	run;

	proc append base=mskw data=x&ymonth;
	run;

%end;
%mend;

%getmskw ;

/*�����¶�����*/
%macro getmret;
%do ymonth=201705 %to 202104;

	data x; set idxdret0;
		if ymonth=&ymonth;
	run;

	proc means data=x n mean noprint;
		var idxdret;
		output out=x1 mean=mret;
	run;

	proc sql;
		create table x2 as 
		select mret from x1;
	quit;

	data x&ymonth;
		set x2;
		ymonth=&ymonth;
	run;

	proc append base=mret data=x&ymonth;
	run;

%end;
%mend;

%getmret ;




proc print data= mret (firstobs=1 obs=1500); run;







/*�������*/
data output;
	set mret;
	keep mret;
run;


proc export data=output
outfile="C:\Users\Jackgloves\Desktop\skw.csv"
dbms=dlm;
delimiter='09x';
run;



