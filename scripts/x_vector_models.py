
import keras
from TDNN_layer import TDNN
from keras.layers import Dense, Lambda, Concatenate, Conv1D, Softmax
from keras import losses
import keras.backend as K

from keras_self_attention import SeqWeightedAttention


import tensorflow as tf



def get_x_vector_model(train_data, hiddenLayerConfig, train_label = None,  forTesting = True):
    inputs = keras.Input(shape=(None, train_data.shape[-1],))
    t1 = TDNN(int(hiddenLayerConfig[0]), (-1,0,+1), padding='same', activation="sigmoid", name="TDNN1")(inputs)
    t2 = TDNN(int(hiddenLayerConfig[1]), input_context=(0,), padding='same', activation="sigmoid", name="TDNN2")(t1)
    average = keras.layers.Lambda(lambda xin: keras.backend.mean(xin, axis=1), output_shape=(int(hiddenLayerConfig[1]),))
    variance = keras.layers.Lambda(lambda xin: keras.backend.std(xin, axis=1), output_shape=(int(hiddenLayerConfig[1]),))
    v1 = variance(t2)
    m1 = average(t2)
    k1 = keras.layers.Concatenate()([m1, v1])
    d1 = Dense(int(hiddenLayerConfig[2]), activation='sigmoid', name='x_vector')(k1)
    
    if forTesting:
        model = keras.Model(inputs=inputs, outputs=d1)
    else:
        output = Dense(train_label.shape[1], activation='softmax', name='dense_' + str(train_label.shape[1]))(d1)
        model = keras.Model(inputs=inputs, outputs=output)
    return model


