
/*LDPC Decoder*/

#include "mex.h"
#include "matrix.h"			// for Matlab mx and mex fuctions
#include "math.h"
#include <stdlib.h>			// what for
#include "decodeutil_new.h"
#define INF 1000
double atanh(double x);

//decode(max_iter,vhat,mrows,ncols,iter_out,gamma_n,check_node_ones,max_check_degree,BIGVALUE_COLS,
//                                variable_node_ones,max_variable_degree,BIGVALUE_ROWS);

void mexdecode(  double *LLR,  int mrows, int ncols, double iteration, double *H_base, int expand_z, int row_base, int col_base, double *finalx)


{//function braces
    
    int i=0, j=0, k=0,ite=0, z=0, posi_i = 0, posi_j = 0, posi_k = 0, cons_z = 0;
    double **LLR_CtoV, **LLR_VtoC, **H_matrix;
    double* LLRC_MID = new double[expand_z];
    double* LLRV_MID = new double[expand_z];
    //*LLRC_MID, *LLRV_MID;
    
    LLR_CtoV= matrix(0,mrows-1,0,col_base-1);
    LLR_VtoC= matrix(0,row_base-1,0,ncols-1);
    H_matrix= matrix(0,row_base-1,0,col_base-1);
    
    for (j=0;j<col_base;j++)
    {
        for(i=0;i<row_base;i++)
        {
            H_matrix[i][j]=*(H_base++); //writing out check_node_ones in 2D matrix form, from Matlab it is passed as one long vector
            
        }
    }
    
    //initializing the matrices
    for ( j=0;j<col_base;j++)
    {
        for(i=0;i<row_base;i++)
        {
            if(H_matrix[i][j]!=-1)
            {
                for(z=0;z<expand_z;z++)
                {
                    LLR_VtoC[i][j*expand_z+z]=LLR[j*expand_z+z];
                }
            }
        }
    }
    
    
    for (ite=0;ite<iteration;ite++)
    {	//main iteration loop
        
        //bit-to-check messages
        for ( i=0;i<row_base;i++)
        {
            for (j=0;j<col_base;j++)
            {
                if( H_matrix[i][j]!=-1 )
                {
                    for(z=0;z<expand_z;z++)
                        LLRC_MID[z] = 1;
                    
                    for (k=0;k<col_base;k++)
                        if (H_matrix[i][k]!=-1&&k!=j)
                        {
                            posi_k = H_matrix[i][k];
                            for(z=0;z<expand_z;z++)
                                LLRC_MID[z]=LLRC_MID[z]*tanh(LLR_VtoC[i][k*expand_z+((z+posi_k)%expand_z)]/2);
                        }
                    for(z=0;z<expand_z;z++)
                        LLR_CtoV[i*expand_z+z][j]=2*atanh(LLRC_MID[z]);
                }
            }
        }
        
        for (j=0;j<col_base;j++)
        {
            for ( i=0;i<row_base;i++)
            {
                if (H_matrix[i][j]!=-1)
                {
                    for(z=0;z<expand_z;z++)
                        LLRV_MID[z]=0;
                    
                    for (k=0;k<row_base;k++)
                    {
                        if (H_matrix[k][j]!=-1&&k!=i)
                        {
                            posi_k = H_matrix[k][j];
                            for(z=0;z<expand_z;z++)
                                LLRV_MID[z]=LLRV_MID[z]+LLR_CtoV[k*expand_z+((z+expand_z-posi_k)%expand_z)][j];
                        }
                    }
                    for(z=0;z<expand_z;z++)
                        LLR_VtoC[i][j*expand_z+z]=LLRV_MID[z]+LLR[j*expand_z+z];
                }
            }
        }
        
        for (j=0;j<col_base;j++)
        {
            for(z=0;z<expand_z;z++)
                LLRV_MID[z]=0;
            for ( i=0;i<row_base;i++)
            {
                if(H_matrix[i][j]!=-1)
                {
                    posi_i = H_matrix[i][j];
                    for(z=0;z<expand_z;z++)
                        LLRV_MID[z] = LLRV_MID[z] + LLR_CtoV[i*expand_z+((z+expand_z-posi_i)%expand_z)][j];
                }
            }
            
            for(z=0;z<expand_z;z++)
            {
                finalx[j*expand_z+z]=LLRV_MID[z]+LLR[j*expand_z+z];
                if (finalx[j*expand_z+z]>0)
                    finalx[j*expand_z+z]=0;
                else
                    finalx[j*expand_z+z]=1;
            }
        }
        
        int parity=0, count_num=0;
        for ( i=0;i<row_base;i++)
        {
            for(z=0;z<expand_z;z++)
            {
                parity = 0;
                for (j=0;j<col_base;j++)
                { 
                    posi_j = H_matrix[i][j];
                    parity = parity+finalx[j*expand_z+((z+posi_j)%expand_z)];
                }
                if (parity%2==1)
                {
                    count_num=1;
                    break;
                }
            }
        }
        if(count_num==0)
        return;
        
        
    }
    for (j=0;j<col_base;j++)
    {
        for(z=0;z<expand_z;z++)
            LLRV_MID[z]=0;
        for ( i=0;i<row_base;i++)
        {
            if(H_matrix[i][j]!=-1)
            {
                posi_i = H_matrix[i][j];
                for(z=0;z<expand_z;z++)
                    LLRV_MID[z] = LLRV_MID[z] + LLR_CtoV[i*expand_z+((z+expand_z-posi_i)%expand_z)][j];
            }
        }
        
        for(z=0;z<expand_z;z++)
        {
            finalx[j*expand_z+z]=LLRV_MID[z]+LLR[j*expand_z+z];
            if (finalx[j*expand_z+z]>0)
                finalx[j*expand_z+z]=0;
            else
                finalx[j*expand_z+z]=1;
        }
    }
}

double atanh(double x)
{
    double epsilon;
    epsilon = pow(10.0, -16);
    
    if(x>(1-epsilon)) return INF;
    if(x<(-1+epsilon)) return -INF;
    return 0.5*log((1+x)/(1-x));
}



//                          0 1  2   3     4    5  6   7
//    decoded_bit = decoder(R,md,nd,iter,H_base,z,row,col);



void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[] )
{
    double *vhat, *LLR, *H_base, *finalx; /*pointer variables for input Matrices*/
    double iteration;
    int mrows, ncols, row_base, col_base, expand_z;
    
    
    LLR  = mxGetPr(prhs[0]); //pointer to initial APP LLR

    iteration = mxGetScalar(prhs[3]); // maximum iterations
    
    expand_z = mxGetScalar(prhs[5]); // expand parameter
    H_base = mxGetPr(prhs[4]);     // base matrix
    
    mrows = mxGetScalar(prhs[1]); // number of rows of H)
    ncols = mxGetScalar(prhs[2]); // number of cols of H)
    
    row_base = mxGetScalar(prhs[6]); // number of rows of H_base)
    col_base = mxGetScalar(prhs[7]); // number of cols of H_base)
    
    plhs[0] = mxCreateDoubleMatrix(1, ncols, mxREAL); /*matrix for output*/
    finalx = mxGetPr(plhs[0]);	/*pointer to output*/
    mexdecode( LLR, mrows, ncols,  iteration, H_base,expand_z, row_base, col_base, finalx);
}
