class StarGraph:

	
	center=""
	spokes = []
	def __init__(self,filename):
		IN = open(filename,'r')
		self.center=IN.readline()
		for line in IN:
			self.spokes.append([line.split()[0], float(line.split()[1])])


