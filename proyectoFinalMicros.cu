%%cu

#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
#include <bits/stdc++.h>
#include <math.h>

#define N 453
#define BLOCKSIZE 960

using namespace std;    

__global__ void calculosLuminosidad(float *lB, float *lM, float* lA, float* lR)
{
    int myID = blockIdx.x * blockDim.x + threadIdx.x;
    if(myID < N){
        lR[myID] = (lB[myID] + lM[myID] + lA[myID])/3;
    }
    
}



int main(int argc, char** argv) 
{

    int size = sizeof(float) * N;

    float* hst_luminosidadBaja = (float *)malloc(size);
    float* hst_bpmBaja = (float *)malloc(size);
    float* hst_luminosidadMedia = (float *)malloc(size);
    float* hst_bpmMedia = (float *)malloc(size);
    float* hst_luminosidadAlta = (float *)malloc(size);
    float* hst_bpmAlta = (float *)malloc(size);
    float* hst_res = (float *)malloc(size);
    float* hst_res2 = (float *)malloc(size);
    
    
    float *dev_luminosidadBaja,  *dev_luminosidadMedia, *dev_luminosidadAlta, *dev_res;
    cudaMalloc((void **)&dev_luminosidadBaja, size);
    cudaMalloc((void **)&dev_luminosidadMedia, size);
    cudaMalloc((void **)&dev_luminosidadAlta, size);
    cudaMalloc((void **)&dev_res, size);

    float *dev_bpmBaja, *dev_bpmMedia, *dev_bpmAlta, *dev_res2;
    cudaMalloc((void **)&dev_bpmBaja, size);
    cudaMalloc((void **)&dev_bpmMedia, size);
    cudaMalloc((void **)&dev_bpmAlta, size);
    cudaMalloc((void **)&dev_res2, size);

    string linea;        
    string luminosidadBaja, bpmBaja, luminosidadMedia, bpmMedia, luminosidadAlta, bpmAlta;    
                                                               
    ifstream archivo ("datosFinales.csv"); 

    if (archivo.fail()) {    
        cerr << "No es posible abrir el archivo" << endl;         
        return 1;
    }
    
    getline(archivo,linea);                            

    int i = 0;
    while (getline(archivo,linea)) { 

        stringstream stream(linea);

        getline(stream, luminosidadBaja, ';');
        getline(stream, bpmBaja, ';');
        getline(stream  , luminosidadMedia, ';');
        getline(stream  , bpmMedia, ';');
        getline(stream  , luminosidadAlta, ';');
        getline(stream  , bpmAlta, ';');

        try{
            if (luminosidadBaja != ""){
                hst_luminosidadBaja[i] = stof(luminosidadBaja);
                hst_bpmBaja[i] = stof(bpmBaja);
            }else{
                hst_luminosidadBaja[i] = 0;
                hst_bpmBaja[i] = 0;
            }
            if (luminosidadMedia != ""){
                hst_luminosidadMedia[i] = stof(luminosidadMedia);
                hst_bpmMedia[i] = stof(bpmMedia);
            }else{
                hst_luminosidadMedia[i] = 0;
                hst_bpmMedia[i] = 0;
            }
            if (luminosidadAlta != ""){
                hst_luminosidadAlta[i] = stof(luminosidadAlta);
                hst_bpmAlta[i] = stof(bpmAlta);
            } else{
                hst_luminosidadAlta[i] = 0;
                hst_bpmAlta[i] = 0;
            }
            
        }catch(const std::invalid_argument& ia){
            cout << "Argumento Invalido: " << ia.what() << endl;
        }
        
        i++;
    }


    archivo.close();    
    

    cudaMemcpy(dev_luminosidadBaja, hst_luminosidadBaja, size, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_luminosidadMedia, hst_luminosidadMedia, size, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_luminosidadAlta, hst_luminosidadAlta, size, cudaMemcpyHostToDevice);

    cudaMemcpy(dev_bpmBaja, hst_bpmBaja, size, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_bpmMedia, hst_bpmMedia, size, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_bpmAlta, hst_bpmAlta, size, cudaMemcpyHostToDevice);


    int threadsPerBlock = BLOCKSIZE;
    int temp = N + threadsPerBlock - 1;
    int blocksPerGrid = temp / threadsPerBlock;

    calculosLuminosidad<<<blocksPerGrid, threadsPerBlock>>>(dev_luminosidadBaja, dev_luminosidadMedia, dev_luminosidadAlta, dev_res);
    calculosLuminosidad<<<blocksPerGrid, threadsPerBlock>>>(dev_bpmBaja, dev_bpmMedia, dev_bpmAlta, dev_res2);

    cudaMemcpy(hst_res, dev_res, size, cudaMemcpyDeviceToHost);
    cudaMemcpy(hst_res2, dev_res2, size, cudaMemcpyDeviceToHost);


    float promedio1 = 0.0;
    for(int i = 0; i < N; i++) {
        promedio1 += hst_res[i];
    }
    promedio1 = promedio1 /  N;

    cout << "El promedio de la luminosidad es: " << promedio1 << endl;

    if(promedio1 <= 450){
        cout << "La luminosidad es alta" << endl;
    }else if(promedio1 > 450 && promedio1 <= 620){
        cout << "La luminosidad es media" << endl;
    }else if(promedio1 > 620){
        cout << "La luminosidad es baja" << endl;
    }



    
    float promedio2 = 0.0;
    for(int i = 0; i < N; i++) {
        promedio2 += hst_res2[i];
    }
    promedio2 = promedio2 /  N;

    cout << "El promedio del bpm es: " << promedio2 << endl;

    if(promedio2 <= 60){
        cout << "El bpm es bajo" << endl;
    }else if(promedio2 > 60 && promedio2 <= 100){
        cout << "El bpm es medio" << endl;
    }else if(promedio2 > 100){
        cout << "El bpm es alto" << endl;
    }

    cout << "Si sus bpm estan fuera de lo normal, lo recomendado es visitar un medico :)" << endl;


    //libera memoria del host
    free(hst_luminosidadBaja);
    free(hst_bpmBaja);
    free(hst_luminosidadMedia);
    free(hst_bpmMedia);
    free(hst_luminosidadAlta);
    free(hst_bpmAlta);
    free(hst_res);

    cudaFree(dev_luminosidadBaja);
    cudaFree(dev_luminosidadMedia);
    cudaFree(dev_luminosidadAlta);
    cudaFree(dev_res);

    cudaFree(dev_bpmBaja);
    cudaFree(dev_bpmMedia);
    cudaFree(dev_bpmAlta);
    cudaFree(dev_res2);

    return 0; 
}