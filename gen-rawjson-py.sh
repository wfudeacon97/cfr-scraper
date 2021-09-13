#!/usr/bin/python
import xml.sax
import json
import sys

if (len(sys.argv) -1) != 2:
  print 'ERROR: Expecting the following arguments: [xml_file] [Title#]'
  quit(1)

#"tmp/raw-2021-08-24.xml"
xmlFileToParse = sys.argv[1]
chapterToParse = sys.argv[2]
print "Xml File: " + xmlFileToParse
print "Chapter: " + chapterToParse
jsonSectionFile = open("tmp/raw-section-" + chapterToParse + ".json", "a")
jsonSubPartFile = open("tmp/raw-subpart-" + chapterToParse + ".json", "a")
jsonSubChapterFile = open("tmp/raw-subchapter-" + chapterToParse + ".json", "a")

class RawTitle():
    def __init__(self):
      self.Level = ""
      self.TitleNum = ""
      self.TitleStr = ""
      self.ChapterNum = ""
      self.ChapterStr = ""
      self.SubChapterNum = ""
      self.SubChapterStr = ""
      self.PartNum = ""
      self.PartStr = ""
      self.SubPartNum = ""
      self.SubPartStr = ""
      self.SectionNum = ""
      self.SectionStr = ""
      self.content = ""

currentTitle= RawTitle()

def printSectionJson(currentTitle):
  if currentTitle.ChapterNum == chapterToParse:
    jsonData = {}
    cfr = {}
    oid = {}
    jsonData['htmlUrl'] = currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubChapterNum + "." + currentTitle.PartNum + ".html#" + currentTitle.SectionNum

    myOid = currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubChapterNum + "." + currentTitle.SectionNum

    type=5
    jsonData['title'] = currentTitle.SectionStr
    jsonData['noticeType'] = 1
    jsonData['content'] = currentTitle.content
    jsonData['type'] = type
    jsonData['__v'] = 0
    cfr['title'] = currentTitle.TitleNum
    cfr['part'] = currentTitle.PartNum
    cfr['chapter'] = currentTitle.SubChapterNum
    cfr['subPart'] = currentTitle.SubPartNum
    cfr['subTopic'] = currentTitle.SectionNum
    oid["$oid"]= myOid
    jsonData['cfrIdentifier'] = cfr
    jsonData['_id'] = myOid
    #createdAt
    #updatedAt
    #agencies
    jsonSectionFile.write(json.dumps(jsonData))
    jsonSectionFile.write("\n")

def printSubPartJson(currentTitle):
  if currentTitle.ChapterNum == chapterToParse:
    jsonData = {}
    cfr = {}
    oid = {}
    jsonData['htmlUrl'] = currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubChapterNum + "." + currentTitle.PartNum + ".html"

    myOid = currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubChapterNum + "." + currentTitle.SubPartNum

    type=3
    jsonData['title'] = currentTitle.SubPartStr
    jsonData['noticeType'] = 1
    jsonData['content'] = ""
    jsonData['type'] = type
    jsonData['__v'] = 0
    cfr['title'] = currentTitle.TitleNum
    cfr['part'] = currentTitle.PartNum
    cfr['chapter'] = currentTitle.SubChapterNum
    cfr['subPart'] = currentTitle.SubPartNum
    cfr['subTopic'] = ""
    oid["$oid"]= myOid
    jsonData['cfrIdentifier'] = cfr
    jsonData['_id'] = myOid
    #createdAt
    #updatedAt
    #agencies
    jsonSubPartFile.write(json.dumps(jsonData))
    jsonSubPartFile.write("\n")

def printSubChapterJson(currentTitle):
  if currentTitle.ChapterNum == chapterToParse:
    jsonData = {}
    cfr = {}
    oid = {}
    jsonData['htmlUrl'] = "#"

    myOid = currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubChapterNum

    type=1
    jsonData['title'] = currentTitle.SubChapterStr
    jsonData['noticeType'] = 1
    jsonData['content'] = ""
    jsonData['type'] = type
    jsonData['__v'] = 0
    cfr['title'] = currentTitle.TitleNum
    cfr['part'] = ""
    cfr['chapter'] = currentTitle.SubChapterNum
    cfr['subPart'] = ""
    cfr['subTopic'] = ""
    oid["$oid"]= myOid
    jsonData['cfrIdentifier'] = cfr
    jsonData['_id'] = myOid
    #createdAt
    #updatedAt
    #agencies
    jsonSubChapterFile.write(json.dumps(jsonData))
    jsonSubChapterFile.write("\n")

class CFRHandler( xml.sax.ContentHandler ):
    def __init__(self):
      self.CurrentData = ""

    # Call when an element starts
    def startElement(self, tag, attributes):
      self.CurrentData = tag
      if tag == "DIV1":
         currentTitle.Level = "Title"
         currentTitle.TitleStr = ""
         currentTitle.ChapterNum = ""
         currentTitle.ChapterStr = ""
         currentTitle.SubChapterNum = ""
         currentTitle.SubChapterStr = ""
         currentTitle.PartNum = ""
         currentTitle.PartStr = ""
         currentTitle.SubPartNum = ""
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.content = ""
         currentTitle.TitleNum = attributes["N"]
      #elif tag == "DIV2":
      #   currentTitle.Level = "DIV2"
      elif tag == "DIV3":
         currentTitle.Level = "Chapter"
         currentTitle.ChapterStr = ""
         currentTitle.SubChapterNum = ""
         currentTitle.SubChapterStr = ""
         currentTitle.PartNum = ""
         currentTitle.PartStr = ""
         currentTitle.SubPartNum = ""
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.content = ""
         currentTitle.ChapterNum = attributes["N"]
      elif tag == "DIV4":
         currentTitle.Level = "SubChapter"
         currentTitle.SubChapterStr = ""
         currentTitle.PartNum = ""
         currentTitle.PartStr = ""
         currentTitle.SubPartNum = ""
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.content = ""
         currentTitle.SubChapterNum = attributes["N"]
      elif tag == "DIV5":
         currentTitle.Level = "Part"
         currentTitle.PartStr = ""
         currentTitle.SubPartNum = ""
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.content = ""
         currentTitle.PartNum = attributes["N"]
      elif tag == "DIV6":
         currentTitle.Level = "SubPart"
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.content = ""
         currentTitle.SubPartNum = attributes["N"]
      #elif tag == "DIV7":
      #   currentTitle.Level = "DIV7"
      elif tag == "DIV8":
         currentTitle.Level = "Section"
         currentTitle.SectionStr = ""
         currentTitle.SectionNum = attributes["N"]

    # Call when an elements ends
    def endElement(self, tag):
      if tag == "DIV3":
        currentTitle.Level == "Title"
      elif tag == "DIV4":
        printSubChapterJson (currentTitle)
        currentTitle.Level == "Chapter"
      elif tag == "DIV5":
        currentTitle.Level == "SubChapter"
      elif tag == "DIV6":
          currentTitle.Level == "Part"
          printSubPartJson (currentTitle)
      elif tag == "DIV8":
          printSectionJson (currentTitle)
          currentTitle.content = ""
          currentTitle.Level == "SubPart"

    # Call when a character is read
    def characters(self, content):
      if currentTitle.Level == "Title":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.TitleStr = content
      elif currentTitle.Level == "Chapter":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.ChapterStr = content
      elif currentTitle.Level == "SubChapter":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SubChapterStr = content
      elif currentTitle.Level == "Part":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.PartStr = content
      elif currentTitle.Level == "SubPart":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SubPartStr = content
      elif currentTitle.Level == "Section":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SectionStr = content
        else:
          if content != "\n":
            currentTitle.content = currentTitle.content + "\n" + content

# create an XMLReader
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_namespaces, 0)
Handler = CFRHandler()
parser.setContentHandler( Handler )

## THe work is done here!!
parser.parse(xmlFileToParse)

## Cleanup
jsonSectionFile.close()
jsonSubPartFile.close()
jsonSubChapterFile.close()
