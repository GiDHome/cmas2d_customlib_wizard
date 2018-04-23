#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <math.h>

#define MAXMAT 1000
#define MAXCND 1000

char projname[1024];
int i,i_element,i_node,icnd;
double *x,*y;
int *connectivities,*imat;
int node_concentrated_mass[MAXCND];
double surface_density[MAXMAT],concentrated_mass[MAXCND];
char units_length[80],units_mass[80];
int num_elements,num_nodes,num_materials,num_concentrated_mass;
double mass_center[2];

void input(void);
void calculate(void);
void output(void);
void jumpline(FILE*);
void print_error(const char* message);

int main(int argc,char *argv[]) {
  if(argc < 2) {
    printf("Error: no projectname provided. Usage: Cmas2D full_path_to_project\n");
    return 1;
  }
  strcpy(projname,argv[1]);
  input();
  calculate();
  output();
  return 0;
}

void print_error(const char* message){
  char filename_error[1024];
  FILE* ferr;
  strcpy(filename_error,projname);
  strcat(filename_error,".err");
  ferr=fopen(filename_error,"w");
  /* fprintf(ferr,message); */
  fputs(message, ferr);
  fclose(ferr);
  exit(1);
}

void input() {
  char filename_dat[1024];
  FILE *fp;
  int aux,error=0;
  strcpy(filename_dat,projname);
  strcat(filename_dat,".dat");
  fp=fopen(filename_dat,"r");
  for(i=0; i<4; i++) jumpline(fp);
  fscanf(fp,"length %s mass %s\n",units_length,units_mass);
  jumpline(fp);
  fscanf(fp,"%d %d\n",&num_elements,&num_nodes);
  x=(double *)malloc(num_nodes*sizeof(double)); if(x==NULL) { error=1; }
  y=(double *)malloc(num_nodes*sizeof(double)); if(y==NULL) { error=1; }
  connectivities=(int *)malloc(num_elements*3*sizeof(int)); if(connectivities==NULL) { error=1; }
  imat=(int *)malloc(num_elements*sizeof(int));  if(connectivities==NULL) { error=1; }
  if(error) {
    print_error("ERROR: Not enough memory.(Try to calculate with less elements)\n");
  }
  for(i=0; i<4; i++) jumpline(fp);
  /* reading the coordinates */
  for(i_node=0; i_node<num_nodes; i_node++){
    fscanf(fp,"%d %lf %lf\n",&aux,&x[i_node],&y[i_node]);
    if(aux!=i_node+1){
      print_error("ERROR: nodes must be numbered from 1 without holes\n");
    }
  }
  for(i=0; i<4; i++) jumpline(fp);
  /* reading connectivities  */
  for(i_element=0; i_element<num_elements; i_element++) {
    fscanf(fp,"%d %d %d %d %d\n",&aux,&connectivities[i_element*3],&connectivities[i_element*3+1],
      &connectivities[i_element*3+2],&imat[i_element]);
    if(imat[i_element]==0) {
      char message[1024];
      sprintf(message,"ERROR: Element %d without material!!** \n",i_element+1);
      print_error(message);
    }
  }
  for(i=0; i<3; i++) jumpline(fp);
  fscanf(fp,"%d\n",&num_materials);
  jumpline(fp);
  /* reading surface_density of each material  */
  for(i=0; i<num_materials; i++){
    fscanf(fp,"%d %lf\n",&aux,&surface_density[i]);
  }
  for(i=0; i<3; i++) jumpline(fp);
  /* reading conditions */
  fscanf(fp,"%d\n",&num_concentrated_mass);
  jumpline(fp);
  for(icnd=0; icnd<num_concentrated_mass; icnd++) {
    fscanf(fp,"%d %lf\n",&node_concentrated_mass[icnd],&concentrated_mass[icnd]);
  }
  fclose(fp);
}

void calculate() {
  double surface_i,mass_i;
  int n1,n2,n3;
  int mat;
  double x_CGi,y_CGi;
  double x_num=0.0,y_num=0.0,mass=0.0,volume=0.0;
  double percent=0.0;
  int print_each=(num_elements>10)?((int)(num_elements/10)):1;
  char filename_log[1024];
  FILE *fp_out_log;
  strcpy(filename_log,projname);
  strcat(filename_log,".log");
  fp_out_log=fopen(filename_log,"w");
  fprintf(fp_out_log,"FILE: %s\n",projname);
  fprintf(fp_out_log,"CMAS2D\n2D routine to calculate the mass center of an object.\n");
  for(i_element=0; i_element<num_elements; i_element++) {
    if(i_element%print_each==0){
      fprintf(fp_out_log,"calculating %d %%\n",(int)(((double)i_element*100.0)/num_elements));
    }
    n1=connectivities[i_element*3]-1;
    n2=connectivities[i_element*3+1]-1;
    n3=connectivities[i_element*3+2]-1;
    /* Calculating the volume (volume is the area for 2D case) */
    surface_i=fabs(x[n1]*y[n2]+x[n2]*y[n3]+x[n3]*y[n1]-x[n1]*y[n3]-x[n2]*y[n1]-x[n3]*y[n2])/2.0;
    /* The geometric center of the element is calculated */
    x_CGi=(x[n1]+x[n2]+x[n3])/3.0;
    y_CGi=(y[n1]+y[n2]+y[n3])/3.0;
    /* sums are calculated */
    mat=imat[i_element]-1;
    mass_i=surface_density[mat]*surface_i;
    x_num+=mass_i*x_CGi;
    y_num+=mass_i*y_CGi;
    mass+=mass_i;
    volume+=surface_i;
  }
  /* point weights */
  for(icnd=0; icnd<num_concentrated_mass; icnd++) {
    i_node=node_concentrated_mass[icnd]-1;
    x_num+=concentrated_mass[icnd]*x[i_node];
    y_num+=concentrated_mass[icnd]*y[i_node];
    mass+=concentrated_mass[icnd];
  }
  mass_center[0]=(x_num/mass);
  mass_center[1]=(y_num/mass);
  fprintf(fp_out_log,"Mass: %.2f %s\n",mass,units_mass);
  fprintf(fp_out_log,"Mass center: %.2f %.2f %s\n",mass_center[0],mass_center[1],units_length);
  fclose(fp_out_log);
}

void output() {
  char filename_result[1024];
  FILE *fp_out_results;
  double distance;  
  /* writing .post.res */
  strcpy(filename_result,projname);
  strcat(filename_result,".post.res");
  fp_out_results=fopen(filename_result,"w");
  fprintf(fp_out_results,"GiD Post Results File 1.0\n\n");
  fprintf(fp_out_results,"# encoding utf-8\n");
  fprintf(fp_out_results,"Result \"DISTANCE CENTER\" LOAD_ANALYSIS 1 Scalar OnNodes\n");
  fprintf(fp_out_results,"ComponentNames \"DISTANCE CENTER\"\n");
  fprintf(fp_out_results,"Unit %s\n",units_length);
  fprintf(fp_out_results,"Values\n");
  for(i_node=0; i_node<num_nodes; i_node++){
    distance=sqrt((mass_center[0]-x[i_node])*(mass_center[0]-x[i_node]) + (mass_center[1]-y[i_node])*(mass_center[1]-y[i_node]));
    fprintf(fp_out_results," %6d %14.6lf\n",i_node+1,distance);
  }
  fprintf(fp_out_results,"End values\n");
  fclose(fp_out_results);
  free(x);
  free(y);
  free(connectivities);
  free(imat);
}

void jumpline(FILE* filep) {
  char buffer[81];
  fgets(buffer,80,filep);
}
