/*
 ============================================================================
 Name        : context_neurons.c
 Author      : k. singh
 Version     :
 Copyright   : k.singh, 2016
 Description : construct context neurons for the neural network
               context neurons cannot connect to neurons in the input or
               output layer; a context neuron can connect to itself, other context
               neurons on the layer or neurons on the same hidden layer.
 
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "header.h"

extern struct monitor_tag* ptrMonitor;

extern float stepActivation(float);
extern float linearActivation(float);
extern float reluActivation(float);
extern float sigmoidActivation(float);
extern float hyperbolicTangentActivation(float);
extern float softmaxActivation(float);



/********************************************************************
 * entry point to construct context neurons for all of the layers
 *******************************************************************/

int  contextNeuronConstructor(void) {

  int ctr, layerNo, layerWidth;
  struct context_neuron_tag*  ptr = NULL;
  struct context_neuron_tag*  ptrPrevNeuron;

  // loop over the hidden layers

  for (layerNo = 1; layerNo < LAYER_COUNT - 1; layerNo++) {

         ptrPrevNeuron = NULL;

         if (layerNo == 1)
           layerWidth = ptrMonitor->maxHiddenLayer1Neurons;
         else if (layerNo == 2)
            layerWidth = ptrMonitor->maxHiddenLayer2Neurons;
         else {
             logger(ERROR, "contextNeuronConstructor:cannot make context neurons for an unknown layer");
             exit(-1);
         }

         for (ctr = 0; ctr < layerWidth; ctr++) {

             ptr = makeContextNeuron(layerNo);

             if (layerNo == 1)
                 ptrMonitor->contextLayer1NeuronCount++;
             else if (layerNo == 2)
                 ptrMonitor->contextLayer2NeuronCount++;
             else {
                 logger(ERROR, "contextNeuronConstructor: unknown context layer");
                  exit(-1);
             }

             if(ptrPrevNeuron != NULL)
                ptrPrevNeuron->nextNeuron = ptr;

             else {
                    if (layerNo == 1)
                       ptrMonitor->ptrContextNeuronHiddenLayer1 = ptr;
                    else if (layerNo == 2) {
                       ptrMonitor->ptrContextNeuronHiddenLayer2 = ptr;
                    }
                    else {
                        logger(ERROR, "contextNeuronConstructor: pointing to unknown context layer");
                        exit(-1);
                    }
             }

                 ptrPrevNeuron = ptr;

          }
      }


  return(0);
}


/******************************************************************
 * makeBiasNeuron: makes a contest neuron for a hidden layer
 *****************************************************************/

struct context_neuron_tag*  makeContextNeuron(int layerNo) {

     int  ctr;
	 struct context_neuron_tag *ptr;

	 ptr = malloc(sizeof(struct neuron_tag));

	 if (ptr == NULL) {
		 logger(ERROR, "makeContextNeuron: failed to allocate memory for context neuron");
		 exit(-1);
	 }

	 /**************************
	  * initialize the neuron
	  *************************/
    ptr->layer             = layerNo;
    ptr->memory[0]         = 0;

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


    ptr->nextNeuron        = NULL;

    // initialize the memory
    // NOTE: ptrMonitor->maxContextMemory must be less
    // than MAX_CONTEXT_MEMORY otherwise there will be
    // a buffer overrun
    for (ctr = 0; ctr < ptrMonitor->maxContextMemory; ctr++)
        ptr->memory[ctr] = 0;


    logger(INFO, "context neuron built");
	return(ptr);
}


