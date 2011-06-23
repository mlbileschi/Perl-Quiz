#!/usr/bin/python

#idx format is like
# word [partOfSpeech]* | count
# replaceable text is treated as pure text, all punctuation remains.  It doesn't konw about contract'ns
import sys
import code
import string
import os
import code
import shutil
from random import choice

def replaceWordsByPartsOfSpeech(txtfn,fwdIdx,revIdx):
    f=open(txtfn,'r')
    for line in f:
        words = line.split()        
        for i,word in enumerate(words):
            newWord = word.strip();         # here word still includes any punctuation
            if word.lower() in fwdIdx:      # therefore words will not appear in this dictionary
                pos = fwdIdx[word.lower()]  # this is the list of parts of speech for this word
                myPos = choice(pos)    # this is one of those parts of speech
                words[i] =  choice(revIdx[myPos])   # this is another word with that part of speech
        newLine = ' '.join(words)
        print newLine


def loadIndex(fn):
    f=open(fn,'r') # open the file for reading
    fwdIdx={} # initialize the indexes
    revIdx={}
    for line in f:
        toks = line.split('|') # split line at '|'
        if(len(toks)!=2): # malformed line
            continue
        numberOfTimesIveSeenThisWord = int(toks[1].strip())  #not used.
        toks = toks[0].strip().split(' ') # split first part of line at ' '
        if(len(toks)==1): # no parts of speech known
            continue
        word = toks[0].strip()
        fwdIdx[word]=[]
        for pos in toks[1:]: # every element of this list from 1 until end
            pos = pos.strip()
            fwdIdx[word].append(pos)
            if(pos not in revIdx): 
                revIdx[pos] = []
            revIdx[pos].append(word)
    return [fwdIdx,revIdx]        

if __name__ ==  "__main__":
    indexFn = sys.argv[1] # '../index.idx'
    replaceTxtFn = sys.argv[2]
    [fwdIdx,revIdx] = loadIndex(indexFn)
    newText = replaceWordsByPartsOfSpeech(replaceTxtFn,fwdIdx,revIdx)

