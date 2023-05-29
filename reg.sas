proc datasets kill nolist; run; /*����ڴ��е���������*/

/*���Ե�������*/
proc import datafile = 'C:\Users\Jackgloves\Desktop\����������-���ͱ���.xlsx'
    DBMS=xlsx OUT = datainput REPLACE;
    SHEET = '����';
    GETNAMES = YES;
run;

proc import datafile = 'C:\Users\Jackgloves\Desktop\�г���ʵ��ƫ������.xlsx'
    DBMS=xlsx OUT = datainput2 REPLACE;
    SHEET = 'Sheet1';
    GETNAMES = YES;
run;

proc import datafile = 'C:\Users\Jackgloves\Desktop\�г���ʵ��ƫ������.xlsx'
    DBMS=xlsx OUT = datainput3 REPLACE;
    SHEET = 'Sheet2';
    GETNAMES = YES;
run;

data datainput2;
	set datainput2 (firstobs=1 obs=975);
run;

/*proc print data =datainput2; run;*/

/*������ݣ�Ӧ��976�й۲��Լ����б���*/
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


/*�����ع�ƫ��*/
%macro getsimplereg (x=);
	proc reg data=datainput;
		MODEL PORT&x=SKW;
	run;
%mend;

%getsimplereg(x=9)

/*�г����ݻع�*/
proc reg data=datainput3;
	MODEL mret=mskw;
run;

/*�鿴��������ֱ��ͼ,ȥ��print���Բ鿴���б�����ͳ������*/
PROC univariate DATA = datainput3 noprint;
	HISTOGRAM mskw;
RUN;

/*������ͼ*/
symbol1 interpol=join value=dot;
proc gplot data=datainput2;
   plot mktret*N;
run;

/*�����ʷֲ�ͼ*/
/*ods graphics on;
   proc kde;
      univar mret / plots=(density);
   run;
   
ods graphics off;*/

proc univariate data=datainput2;
   var mktret;
   histogram mktret /kernel;
run;

/*������ͳ��*/
proc means data=datainput n mean std min max;
	var MKT SMB HML PMO SKW;
	output out=x;
run;

/*�����*/
proc arima data=datainput2;
   identify var=mktskw nlag=1;
run;

/*�������������*/
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

/*����Լ���*/
PROC CORR DATA = datainput;
VAR MKT SMB HML PMO SKW;
run;
