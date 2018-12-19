/*
 ============================================================================
 Name        : constructor.c
 Author      : k. singh
 Version     :
 Copyright   : k.singh, 2016
 Description : construct input, output and hidden layer neurons

 ============================================================================
*/


#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>

#include "header.h"


extern struct monitor_tag* ptrMonitor;


extern float stepActivation(float);
extern float linearActivation(float);
extern float reluActivation(float);
extern float sigmoidActivation(float);
extern float hyperbolicTangentActivation(float);
extern float softmaxActivation(float);



 /*****************************************************************
  * constructor: start the construction of the neural network
  ****************************************************************/

 int neuronConstructor(void)  {
	 int ctr, layerNo;
	 struct neuron_tag* ptrNeuron;

	 logger(INFO, "start creating neurons");

	 /***************************
     // make the input neurons
      **************************/

	 struct neuron_tag* ptrPrevNeuron = NULL;

     for (ctr = 0; ctr < ptrMonitor->maxInputNeurons; ctr++) {
        ptrNeuron = makeInputNeuron();

        if (ptrPrevNeuron != NULL)
        	ptrPrevNeuron->nextNeuron = ptrNeuron;
        else
        	ptrMonitor->ptrInputLayer = ptrNeuron;

        ptrMonitor->inputNeuronsCount++;
        ptrPrevNeuron = ptrNeuron;
     }

     
     /*****************************************
      * Make the neurons in the hidden layers
      ****************************************/
     int layerWidth = 0;

     for (layerNo = 1; layerNo < LAYER_COUNT - 1; layerNo++) {

         ptrPrevNeuron = NULL;

    	 if (layerNo == 1)
    	   layerWidth = ptrMonitor->maxHiddenLayer1Neurons;
    	 else if (layerNo == 2)
    	    layerWidth = ptrMonitor->maxHiddenLayer2Neurons;
    	 else {
    		 logger(ERROR, "neuronConstructor:cannot make neurons for an unknown hidden layer");
    		 exit(-1);
    	 }

    	 for (ctr = 0; ctr < layerWidth; ctr++) {

    		 ptrNeuron = makeHiddenLayerNeuron(layerNo);

    		 if (layerNo == 1)
                 ptrMonitor->hiddenLayer1NeuronCount++;
    		 else if (layerNo == 2)
    		     ptrMonitor->hiddenLayer2NeuronCount++;
    		 else {
    		     logger(ERROR, "constructor: unknown hidden layer");
    		      exit(-1);
    		 }

    	     if(ptrPrevNeuron != NULL)
    	       	ptrPrevNeuron->nextNeuron = ptrNeuron;

    	     else {
    	            if (layerNo == 1)
    	        	   ptrMonitor->ptrHiddenLayer1 = ptrNeuron;
    	            else if (layerNo == 2)
    	                ptrMonitor->ptrHiddenLayer2 = ptrNeuron;
    	            else {
    	                logger(ERROR, "neuronConstructor: unknown hidden layer");
    	                exit(-1);
    	            }
    	     }

    	         ptrPrevNeuron = ptrNeuron;

    	  }
      }


	 /***************************
      * make the output neurons
      **************************/
     ptrPrevNeuron = NULL;

     for (ctr = 0; ctr < ptrMonitor->maxOutputNeurons; ctr++) {
        ptrNeuron = makeOutputNeuron();

        if(ptrPrevNeuron != NULL)
        	ptrPrevNeuron->nextNeuron = ptrNeuron;
        else
            ptrMonitor->ptrOutputLayer = ptrNeuron;

        ptrMonitor->outputNeuronsCount++;
     }


     return 0;
 }
 

 /******************************************************************
  * makeInputNeuron: makes an input neuron
  *****************************************************************/

 struct neuron_tag*  makeInputNeuron(void) {
	 struct neuron_tag *ptr;

	 ptr = malloc(sizeof(struct neuron_tag));

	 if (ptr == NULL) {
		 printf("makeInputNeuron: failed to allocate memory for input neuron");
		 exit(-1);
	 }

	 /**************************
	  * initialize the neuron
	  *************************/
     ptr->layer          = 0;
     ptr->weighted_input = 0;
     ptr->nextNeuron     = NULL;

     ptr->activationFunctionNo = LINEAR;

    if (ptr->activationFunctionNo == LINEAR)
      ptr->activationFunc    = linearActivation;

    else if (ptr->activationFunctionNo == STEP)
        ptr->activationFunc    = stepActivation;

    else if (ptr->activationFunctionNo == RELU)
          ptr->activationFunc    = reluActivation;

    else if (ptr->activationFunctionNo == SIGMOID)
          ptr->activationFunc    = sigmoidActivation;

    else if (ptr->activationFunctionNo == HYPERBOLICTANGENT)
          ptr->activationFunc    = hyperbolicTangentActivation;

    else if (ptr->activationFunctionNo == SOFTMAX)
          ptr->activationFunc    = softmaxActivation;

    else {
          logger(ERROR, "makeContextNeuron: unknown activation function");
          exit(-1);
    }

     logger(INFO, "input neuron built");
	 return(ptr);
 }


 /******************************************************************
  * makeOutputNeuron: makes an output neuron
  *****************************************************************/

 struct neuron_tag*  makeOutputNeuron(void) {

	 struct neuron_tag *ptr;

	 ptr = malloc(sizeof(struct neuron_tag));

	 if (ptr == NULL) {
		 logger(ERROR, "failed to allocate memory for output neuron");
		 exit(-1);
	 }

	 /**************************
	  * initialize the neuron
	  *************************/
     ptr->layer          = ptrMonitor->layerCount - 1;
     ptr->weighted_input = 0;
     ptr->nextNeuron     = NULL;

     ptr->activationFunctionNo = LINEAR;

    if (ptr->activationFunctionNo == LINEAR)
      ptr->activationFunc    = linearActivation;

    else if (ptr->activationFunctionNo == STEP)
        ptr->activationFunc    = stepActivation;

    else if (ptr->activationFunctionNo == RELU)
          ptr->activationFunc    = reluActivation;

    else if (ptr->activationFunctionNo == SIGMOID)
          ptr->activationFunc    = sigmoidActivation;

    else if (ptr->activationFunctionNo == HYPERBOLICTANGENT)
          ptr->activationFunc    = hyperbolicTangentActivation;

    else if (ptr->activationFunctionNo == SOFTMAX)
          ptr->activationFunc    = softmaxActivation;

    else {
          logger(ERROR, "makeContextNeuron: unknown activation function");
          exit(-1);
    }


     logger(INFO, "output neuron built");
	 return(ptr);
 }



 /******************************************************************
  * makeHiddenlayerNeuron: makes an output neuron
  *****************************************************************/

 struct neuron_tag*  makeHiddenLayerNeuron(int layerNo) {

	 struct neuron_tag *ptr;

	 ptr = malloc(sizeof(struct neuron_tag));

	 if (ptr == NULL) {
		 logger(ERROR, "makehiddenlayerNeuron: failed to allocate memory for hidden layer neuron");
		 exit(-1);
	 }

	 /**************************
	  * initialize the neuron
	  *************************/
     ptr->layer          = layerNo + 1;
     ptr->weighted_input = 0;
     ptr->nextNeuron     = NULL;

     ptr->activationFunctionNo = LINEAR;

    if (ptr->activationFunctionNo == LINEAR)
      ptr->activationFunc    = linearActivation;

    else if (ptr->activationFunctionNo == STEP)
        ptr->activationFunc    = stepActivation;

    else if (ptr->activationFunctionNo == RELU)
          ptr->activationFunc    = reluActivation;

    else if (ptr->activationFunctionNo == SIGMOID)
          ptr->activationFunc    = sigmoidActivation;

    else if (ptr->activationFunctionNo == HYPERBOLICTANGENT)
          ptr->activationFunc    = hyperbolicTangentActivation;

    else if (ptr->activationFunctionNo == SOFTMAX)
          ptr->activationFunc    = softmaxActivation;

    else {
          logger(ERROR, "makeContextNeuron: unknown activation function");
          exit(-1);
    }


     logger(INFO, "hidden layer neuron built");
	 return(ptr);
 }


