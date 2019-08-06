import csv

data_dir='data/ASVspoof2019_root'
condition = ['LA', 'PA']
dataset = ['dev', 'eval']

for con in condition:
	for dset in dataset:
		with open(data_dir+'/'+con+'/ASVspoof2019_'+con+'_cm_protocols/'+ 'ASVspoof2019.'+con+'.cm.'+dset+'.trl.txt', 'r') as f:
			reader = csv.reader(f)
			temp_list = list(reader)
			utterance_list=[]
			for utterance in temp_list:
				file_name = utterance[0].split(' ')[1]
				file_path = data_dir+'/'+con+'/ASVspoof2019_LA_'+dset+'/wav/'+file_name+'.wav'
				utterance_list.append(file_path)
		with open('lists/asv2019_'+con+'_'+dset+'_wav.lst', 'w') as f:
			for utterance in utterance_list:
				f.write("%s\n" % utterance)	
		#print(utterance_list)

	#list preparation for training data	
	dset = 'train'
	with open(data_dir+'/'+con+'/ASVspoof2019_'+con+'_cm_protocols/'+ 'ASVspoof2019.'+con+'.cm.'+dset+'.trn.txt', 'r') as f:
		reader = csv.reader(f)
		temp_list = list(reader)
		utterance_genuine_list=[]
		utterance_spoofed_list=[]
		for utterance in temp_list:
			file_name = utterance[0].split(' ')[1]
			file_label = utterance[0].split(' ')[-1]
			file_path = data_dir+'/'+con+'/ASVspoof2019_LA_'+dset+'/wav/'+file_name+'.wav'
			if file_label == 'spoof':
				utterance_spoofed_list.append(file_path)
			else:
				utterance_genuine_list.append(file_path)
	with open('lists/asv2019_'+con+'_genuine_'+dset+'_wav.lst', 'w') as f:
		for utterance in utterance_genuine_list:
			f.write("%s\n" % utterance)	
	with open('lists/asv2019_'+con+'_spoof_'+dset+'_wav.lst', 'w') as f:
		for utterance in utterance_spoofed_list:
			f.write("%s\n" % utterance)	
