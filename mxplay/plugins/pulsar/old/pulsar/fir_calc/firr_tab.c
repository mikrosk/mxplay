#include <stdio.h>
#include <math.h>
/*#include <tos.h>
*/
#include <osbind.h> 
#define FALSE 		0
#define TRUE  		1
#define DEC				0
#define INC				1
#define WATCH			0
#define SET_NEW		1
#define	MAX_COEFF 80
#define XMT_COEFF 0L

typedef char DSP_WORD[3];

/*********************** Funktionsprototypen ******************************/


int 		fpfix(float src,DSP_WORD dest);
void 		fir_tp(int n,double ta,double wg);
void 		fir_fejer_win(int ordnung);

double	a_k[80];
DSP_WORD coeff[80];
/******************* Globale Vereinbarungen *******************************/


int fpfix(float src,DSP_WORD dest)
{
	float x;
	unsigned long *y1;					/* Alias fr (float) x											*/
	unsigned long	y0;
	char *ptr;									/* Alias fr (unsigned long) y0							*/
	y1 = (unsigned long *)&x;
	ptr = (char *)&y0;
	if(fabs(src) >= 2.0e-7)
	{ 
		x = src;
		y0 = *y1<<8;							/* Mantisse (fast)ganz nach links schieben	*/
	
		*y1 >>= 23;								/* Exponent in LSB													*/
		*y1 &= 0xffL;							/* Vorzeichen rausschmeissen								*/
		*y1 = 0x7fL - *y1;				/* Anzahl der Rechtsshifts berechnen				*/
	
		y0 |= 0x80000000uL;				/* Fhrende '1' einfgen										*/
		y0 >>= *y1;					  		/* Denormalisieren...												*/
		if(src < 0.0)							/* (Float) x < 0.0 ?												*/
		  y0 = ~y0;								/* Dann 1'er Komplement bilden							*/
		y0 >>= 7;									/* ... 24 Bit Wert erzeugen									*/
		if(y0 & 0x01L)						/* Letzte rausgeschobene Stelle  = 1?				*/
			y0++;										/* ...dann aufrunden												*/	
		y0 >>= 1;	
	}	
	else
	  y0 = 0L;
	dest[0] = ptr[1];
	dest[1] = ptr[2];
	dest[2] = ptr[3];
	return 1; 
}


void fir_tp(int n, double ta, double wg)  /* FIR Tiefpass berechnen       */
{
  int k;
  double omega;
  double si;
  double si_k;
  double *coeff_ptr = a_k;
  omega = 2.0 * (wg/ta);
  si = M_PI * omega;
  *coeff_ptr++ = omega;       /* omega * Si(0) = omega * 1.0      				*/
  for(k=1;k<n;k++)
  {
  	si_k = (double)k * si;
    *coeff_ptr++ = omega * sin(si_k)/(si_k);
  } 
}

void fir_hp(int n, double ta, double wg) /* FIR Hochpass berechnen        */
{
  int k;
  fir_tp(n,ta,wg);                       /* Zuerst den entsprechenden     */
  a_k[0] = 1.0 - a_k[0]; 								 /* Tiefpass berechnen ... dann   */
  for (k=1;k<n;k++)                      /*  von Allpass(= 1)subtrahieren */
    a_k[k] = -a_k[k];
}


void fir_hamming_win(int ordnung)   /* Fensterfunktion                    */
{
  int n;
  for (n=0;n<ordnung;n++)
    a_k[n] *= (0.54+0.46*cos(M_PI*n/ordnung));
}


void fir_hanning_win(int ordnung)   /* Fensterfunktion                    */
{
  int n;
  for (n=0;n<ordnung;n++)
    a_k[n] *= (0.5+0.5*cos(M_PI*n/ordnung));
}


void fir_blackman_win(int ordnung)  /* Fensterfunktion                    */
{
  int n;
  for (n=0;n<ordnung;n++)
    a_k[n] *= (0.42+0.5*cos(M_PI*n/ordnung)+
                         0.08*cos(2*M_PI*n/ordnung));
}


void fir_bartlett_win(int ordnung,double smpl_freq)
{                                   /* Fensterfunktion                    */
  int n;
  double nenner;
  nenner = ordnung * smpl_freq;
  for (n=0;n<ordnung;n++)
    a_k[n] *= (1-fabs(n*smpl_freq)/nenner);
}


void fir_lanczos_win(int ordnung)   /* Fensterfunktion                    */
{
  int n;
  for (n=1;n<ordnung;n++)
    a_k[n] *= (sin(M_PI*n/ordnung)/(M_PI*n/ordnung));
}


void fir_fejer_win(int ordnung)     /* Fensterfunktion                    */
{
  int n;
  for (n=0;n<ordnung;n++)
    a_k[n] *= (1-fabs(n/ordnung));
}

/**************************************************************************/

int new_filter(double smpl_freq,double lower_freq,int handle)
{
	int i;
	long done,count;
	double 	sum_coeff;

	int n_coeff;
	n_coeff = 10;
	sum_coeff = 0.0;
	
	fir_tp(n_coeff,smpl_freq,lower_freq);
	fir_fejer_win(n_coeff);
								;
	for(i=0;i<n_coeff;i++)				/* Betrag der Filterkoefizienten = 1			*/
	  sum_coeff += fabs(a_k[i]);
	sum_coeff = 1.0/sum_coeff;  
	for(i=0;i<n_coeff;i++)				/* Koeffizienten von Double- in						*/
	{															/* 24 Bit Festpunktformat wandeln					*/	
		a_k[i] *= sum_coeff;
	  fpfix((float)a_k[i],coeff[i]);
	}
	Fwrite(handle,30,&coeff[0]);

}			
//********************************************************************************
void main(void)
{
	int c,mode=1,handle,c2;
	double sf,upf,df;
	long	freqs[]={8195,9834,12292,16390,19668,24585,32780,49170};

	handle=Fcreate("firr_tab.bin",0);

	for(c2=7;c2<8;c2++)
	{
		printf("Genereting FIRR coeffs for %dHz ",freqs[c2]);
		upf=0.001;
		df=0.000;
		for(c=0;c<64;c++)
			{
			new_filter((float)freqs[c2],upf,handle);
			upf+=df;
			df+=(double)(c*c)/60;
			}
		printf("final upf=%d\r\n",(int)upf);
	}

}
