import sys
from StarGraph import StarGraph
import StarCreator

queries = ['NADPH', 'enzyme']
paths = ['C:\\Users\\Max\\Perl-Quiz\\sampleTexts\\photosynth.txt',
		'C:\\Users\\Max\\Perl-Quiz\\sampleTexts\\photosynth.txt']
stars = []

for i in range(0,len(paths)):
	exec('StarCreator.py ' + paths[i] + ' ' + queries[i])
#	stars.append(StarGraph(paths[i]))
'''
for star in stars:
	print("center is: "+star.center)
	print("spokes are: "+star.spokes)
'''