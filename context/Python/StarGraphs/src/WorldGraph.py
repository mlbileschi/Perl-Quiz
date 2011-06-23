import sys
from StarGraph import StarGraph
import StarCreator

queries = ['NADPH', 'enzyme']
paths = ['/home/max/Documents/QUIZ/Perl-Quiz/sampleTexts/photosynth.txt',
		'/home/max/Documents/QUIZ/Perl-Quiz/sampleTexts/enzymes.txt']
stars = []


for i in [0,1]:#range(0,len(paths)):
	StarCreator.newStar(paths[i], queries[i])
	tmpStar = StarGraph('./' + queries[i]+ '.txt')
	stars.append(tmpStar)
	del tmpStar


for star in stars:
	print(star)
