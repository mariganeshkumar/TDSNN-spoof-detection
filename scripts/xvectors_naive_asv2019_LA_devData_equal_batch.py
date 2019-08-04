import sys
from keras import backend as K
import tensorflow as tf

# Seed value
# Apparently you may use different seed values at each stage
save_dir = sys.argv[1]
test_only = int(sys.argv[2])
seed_value= int(sys.argv[3])
outputFileName = sys.argv[4]
trainList = sys.argv[5]
validationList = sys.argv[6]
testList = sys.argv[7]


tf.set_random_seed(seed_value)

########## 1. Set `PYTHONHASHSEED` environment variable at a fixed value ##############
import os
os.environ['PYTHONHASHSEED']=str(seed_value)

########## 2. Set `python` built-in pseudo-random generator at a fixed value ##########
import random
random.seed(seed_value)

########## 3. Set `numpy` pseudo-random generator at a fixed value ############
import numpy as np
np.random.seed(seed_value)

session_conf = tf.ConfigProto(intra_op_parallelism_threads=1, inter_op_parallelism_threads=1)
session_conf.gpu_options.allow_growth = True
sess = tf.Session(graph=tf.get_default_graph(), config=session_conf)
K.set_session(sess)

########## 4. Prepare datalist from the pre-processes list of files ############
from tqdm import tqdm
#from math import min

tFN_ID=open(trainList,'r')
trainLines=tFN_ID.read().split("\n")[:-1]
trainFileNames=[x for x in trainLines]

dFN_ID=open(validationList,'r');
devLines=dFN_ID.read().split("\n")[:-1]
devFileNames=[y for y in devLines]

eFN_ID=open(testList,'r');
evalLines=eFN_ID.read().split("\n")[:-1]
evalFileNames=[z for z in evalLines]

devData=[]
devLabel=[]
devFileCount=len(devFileNames);
for i in tqdm(range(devFileCount)):
	curFile=np.genfromtxt(devFileNames[i],skip_header=1,delimiter=' ',dtype='float')
	devData.append(curFile)
	flag=str(devFileNames[i].split('/')[-2])
	if "spoofed" in flag: ## 761 to 1710 spoofed
		tmp=str(devFileNames[i])+str(" spoofed ")+str(flag)
#		print(tmp)
		devLabel.append(0)
	else: ### 1 to 760 is bonafide
		tmp=str(devFileNames[i])+str(" bonafide ")+str(flag)
#		print(tmp)
		devLabel.append(1)

trainData=[]
trainLabel=[]
trainFileCount=len(trainFileNames);
for i in tqdm(range(trainFileCount)):
	curFile=np.genfromtxt(trainFileNames[i],skip_header=1,delimiter=' ',dtype='float')
	trainData.append(curFile)
	flag=str(trainFileNames[i].split('/')[-2])
#	print(flag)
	if "spoofed" in flag:
#		tmp=str(trainFileNames[i])+str(" spoofed ")
#		print(tmp)
		trainLabel.append(0)
	else:
#		tmp=str(trainFileNames[i])+str(" bonafide ")
#		print(tmp)
		trainLabel.append(1)
	

############### 6. Configure a new global `tensorflow` session ##############
import os
import shutil
from x_vector_models import get_x_vector_model

from keras import losses
from keras.utils.np_utils import to_categorical
from keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from keras.utils.generic_utils import get_custom_objects
from keras.optimizers import Adam
from keras.metrics import top_k_categorical_accuracy

import scipy.io as sio

#import hdf5storage

from math import ceil
# split into input (X) and output (Y) variables
hLayer1=int(outputFileName.split("_")[3])
hLayer2=int(outputFileName.split("_")[4])
xvecDim=int(outputFileName.split("_")[5].split(".")[0])
print (hLayer1,hLayer2,xvecDim)
hiddenLayerConfig = [hLayer1,hLayer2,xvecDim]

trainLabel = np.asarray(trainLabel)
devLabel = np.asarray(devLabel)
#evalLabel = np.asarray(evalLabel)

no_of_examples = trainLabel.shape[0]

trainLabel = to_categorical(np.squeeze(trainLabel), num_classes=2)
devLabel =  to_categorical(np.squeeze(devLabel), num_classes=2)
print(trainLabel)
#print(devLabel)
#evalLabel =  to_categorical(np.squeeze(evalLabel), num_classes=trainLabel.shape[1])

if test_only == 0:
	if os.path.exists(save_dir):
		shutil.rmtree(save_dir)
	os.makedirs(save_dir)
	print ("Created model Dir...!")

early_stopping = EarlyStopping(patience=10, verbose=1)
model_checkpoint = ModelCheckpoint(save_dir+"/keras.model", save_best_only=True, verbose=1)
reduce_lr = ReduceLROnPlateau(factor=0.5, patience=3, min_lr=0.00000000001, verbose=1)
numFeats=trainData[0].shape[1]

maxLen=0
devDataLength=len(devData)
for i in tqdm(range(devDataLength)):
	maxLen=max([maxLen,devData[i].shape[0]])
print(maxLen)
batchDevData=np.zeros([devDataLength,maxLen,numFeats])
batchDevLabel=np.zeros([devDataLength,2]) ## 2 represents the number of classes
for i in tqdm(range(devDataLength)):
	exampleLen=devData[i].shape[0]
	reps=ceil(maxLen/exampleLen); 
	repData = np.tile(devData[i],[reps, 1])
	batchDevData[i,:,:]=repData[:maxLen,:]
	batchDevLabel[i,:]=devLabel[i,:]
		
print(batchDevData.shape, batchDevLabel.shape)

miniBatchSize=16
numFeats=trainData[0].shape[1]

def trainData_generator():
	startIndex=0
	while True:
#		print(startIndex)
		i=0
		ind = 0
		while (i < int(miniBatchSize/2) or ind < miniBatchSize) and startIndex + ind < len(trainData):
			if trainLabel[startIndex + ind,1] == 1:
				i=i+1
				ind = ind+1
			else:
				ind = ind+1
				continue
		endIndex=startIndex + ind
		genunineTrials = i
		totalTrials = endIndex -startIndex
		totalSpoofTrials = endIndex - startIndex - genunineTrials
		requiredSpoofTrials = min(miniBatchSize,totalTrials)  - genunineTrials
		actualBtachSize=genunineTrials+requiredSpoofTrials
		maxLen=0
		for i in range(startIndex,endIndex):
			maxLen=max([maxLen,trainData[i].shape[0]])
		#batchTrainData=np.zeros([miniBatchSize,maxLen,numFeats])
		#batchTrainLabel=np.zeros([miniBatchSize,2]) ## 2 represents the number of classes

		spoofData = np.zeros([totalSpoofTrials,maxLen,numFeats])
		spoofLabel = np.zeros([totalSpoofTrials,2])
		s_ind=0
		genunineData = np.zeros([genunineTrials,maxLen,numFeats])
		genunineLabel = np.zeros([genunineTrials,2])
		g_ind=0
		for i in range(startIndex,endIndex):
			exampleLen=trainData[i].shape[0]
			reps=ceil(maxLen/exampleLen);
			repData = np.tile(trainData[i],[reps, 1])
			if trainLabel[i,1] == 1:
				genunineData[g_ind,:,:]=repData[:maxLen,:]
				genunineLabel[g_ind,:]=trainLabel[i,:]
				g_ind = g_ind+1
			else:
				spoofData[s_ind,:,:]=repData[:maxLen,:]
				spoofLabel[s_ind,:]=trainLabel[i,:]
				s_ind = s_ind+1
		spoofRandPerm = np.random.permutation(totalSpoofTrials)		
		spoofData = spoofData[spoofRandPerm[:requiredSpoofTrials],:,:]
		spoofLabel = spoofLabel[spoofRandPerm[:requiredSpoofTrials],:]
		#print(startIndex,endIndex)
		#print(spoofData.shape)
		#print(genunineData.shape)

		batchTrainData = np.concatenate((genunineData,spoofData),axis=0)
		batchTrainLabel = np.concatenate((genunineLabel,spoofLabel),axis=0)

		randperm = np.random.permutation(actualBtachSize)

		batchTrainData = batchTrainData[randperm,:,:]
		batchTrainLabel = batchTrainLabel[randperm,:]

		startIndex=(startIndex+totalTrials)%len(trainData)
		yield batchTrainData, batchTrainLabel
		

def mixed_mse_cross_entropy_loss(y_true, y_pred):
	return 0.8 * losses.categorical_crossentropy(y_true, y_pred) + 0.2 * losses.mean_squared_error(y_true,y_pred)


def categorical_focal_loss_fixed(y_true, y_pred):
	gamma=5 ### range (-5,5)
	alpha=1.0 ### range (0.1,1)
	"""
	:param y_true: A tensor of the same shape as `y_pred`
	:param y_pred: A tensor resulting from a softmax
	:return: Output tensor.
	"""

	# Scale predictions so that the class probas of each sample sum to 1
	y_pred /= K.sum(y_pred, axis=-1, keepdims=True)

	# Clip the prediction value to prevent NaN's and Inf's
	epsilon = K.epsilon()
	y_pred = K.clip(y_pred, epsilon, 1. - epsilon)

	# Calculate Cross Entropy
	cross_entropy = -y_true * K.log(y_pred)

	# Calculate Focal Loss
	loss = alpha * K.pow(1 - y_pred, gamma) * cross_entropy

	# Sum the losses in mini_batch
	return K.sum(loss, axis=1)



get_custom_objects().update({"mixed_loss": mixed_mse_cross_entropy_loss})
get_custom_objects().update({"focal_loss": categorical_focal_loss_fixed})

model = get_x_vector_model(batchDevData, batchDevLabel, hiddenLayerConfig)
adam_opt = Adam(lr=0.001, clipvalue=1)
#model.compile(loss=losses.categorical_crossentropy, optimizer=adam_opt,
model.compile(loss="focal_loss", optimizer=adam_opt,
			  metrics=['accuracy', top_k_categorical_accuracy])
model.summary()

if test_only == 0 :
	early_stopping = EarlyStopping(patience=10, verbose=1)
	model_checkpoint = ModelCheckpoint(save_dir+'/keras.model', save_best_only=True, verbose=1)
	reduce_lr = ReduceLROnPlateau(factor=0.5, patience=3, min_lr=0.00000000001, verbose=1)

	#Fit the model
	model.fit_generator(trainData_generator(), validation_data=(batchDevData, batchDevLabel), epochs=3000, steps_per_epoch=188, verbose=2,
		  callbacks=[early_stopping, model_checkpoint, reduce_lr])
	model.load_weights(save_dir+'/keras.model')
else:
	model.load_weights(save_dir+'/keras.model')

devData=[]
devLabel=[]
devFileCount=len(devFileNames);
devOut=open("trainVal_"+outputFileName,'w')
for i in tqdm(range(devFileCount)):
	curDevFile=np.genfromtxt(devFileNames[i],skip_header=1,delimiter=' ',dtype='float')
	curDevFile=np.expand_dims(curDevFile,axis=0)
	devScore=model.predict(curDevFile)
	devScore=devScore[0,1]-devScore[0,0]
	#print(devScore.shape)
	if devScore >= 0:
		devPredictedLabel="bonafide"
	else:
		devPredictedLabel="spoof"
	devOut.write(devFileNames[i].split('/')[-1].split('.')[0]+" "+devPredictedLabel+" "+str(devScore)+"\n")

evalData=[]
evalLabel=[]
evalFileCount=len(evalFileNames);
fOut=open(outputFileName,'w')
for i in tqdm(range(evalFileCount)):
	curFile=np.genfromtxt(evalFileNames[i],skip_header=1,delimiter=' ',dtype='float')
	curFile=np.expand_dims(curFile,axis=0)
	score=model.predict(curFile)
	score=score[0,1]-score[0,0]
	#print(score.shape)
	if score >= 0:
		predictedLabel="bonafide"
	else:
		predictedLabel="spoof"
	fOut.write(evalFileNames[i].split('/')[-1].split('.')[0]+" "+predictedLabel+" "+str(score)+"\n")
print('done')


