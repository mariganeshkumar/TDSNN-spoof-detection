
import keras
from TDNN_layer import TDNN
from keras.layers import Dense, Lambda, Concatenate
from keras import losses
import keras.backend as K

import tensorflow as tf

def get_modified_x_vector_model(train_data, train_label, num_channels, hiddenLayerConfig, forTesting = False):
    inputs = keras.Input(shape=(train_data.shape[1], None, train_data.shape[-1]))
    def split_channels(x):
        channel_data = tf.split(x, num_channels, axis=1)
        for i in range(len(channel_data)):
            channel_data[i] = tf.squeeze(channel_data[i], [1, ])
        return channel_data

	#### ---------------------------------------- The zero below refers "No context" -  change the value to {-2,-1,0,1,2}  this will consider 5 frame context
    tdnn_layer1 = TDNN(int(hiddenLayerConfig[0]), (0,), padding='same', activation="sigmoid", name="TDNN1")
    tdnn_layer2 = TDNN(int(hiddenLayerConfig[1]), input_context=(0,), padding='same', activation="sigmoid", name="TDNN2")
    average = Lambda(lambda xin: K.mean(xin, axis=1), output_shape=(int(hiddenLayerConfig[1]),))
    variance = Lambda(lambda xin: K.std(xin, axis=1), output_shape=(int(hiddenLayerConfig[1]),))

    splitted_channels = Lambda(split_channels)(inputs)

    means = []
    vars = []
    for channel in splitted_channels:
        t1 = tdnn_layer1(channel)
        t2 = tdnn_layer2(t1)
        means.append(average(t2))
        vars.append(variance(t2))

    mv = Concatenate()(means)
    vv = Concatenate()(vars)
    k1 = Concatenate()([mv, vv])
    d1 = Dense(int(hiddenLayerConfig[2]), activation='sigmoid', name='x_vector')(k1)
    output = Dense(train_label.shape[1], activation='softmax', name='dense_' + str(train_label.shape[1]))(d1)
    if forTesting:
        model = keras.Model(inputs=inputs, outputs=d1)
    else:
        model = keras.Model(inputs=inputs, outputs=output)
    return model

def get_x_vector_model(train_data, train_label, hiddenLayerConfig, forTesting = False):
    inputs = keras.Input(shape=(None, train_data.shape[-1],))
    t1 = TDNN(int(hiddenLayerConfig[0]), (-1,0,+1), padding='same', activation="sigmoid", name="TDNN1")(inputs)
    t2 = TDNN(int(hiddenLayerConfig[1]), input_context=(0,), padding='same', activation="sigmoid", name="TDNN2")(t1)
    average = keras.layers.Lambda(lambda xin: keras.backend.mean(xin, axis=1), output_shape=(int(hiddenLayerConfig[1]),))
    variance = keras.layers.Lambda(lambda xin: keras.backend.std(xin, axis=1), output_shape=(int(hiddenLayerConfig[1]),))
    v1 = variance(t2)
    m1 = average(t2)
    k1 = keras.layers.Concatenate()([m1, v1])
    d1 = Dense(int(hiddenLayerConfig[2]), activation='sigmoid', name='x_vector')(k1)
    output = Dense(train_label.shape[1], activation='softmax', name='dense_' + str(train_label.shape[1]))(d1)

    if forTesting:
        model = keras.Model(inputs=inputs, outputs=d1)
    else:
        model = keras.Model(inputs=inputs, outputs=output)
    return model
