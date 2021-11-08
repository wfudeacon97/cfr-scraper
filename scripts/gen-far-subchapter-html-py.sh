#!/usr/bin/python
import xml.sax
import sys
import re

if (len(sys.argv) -1) != 3:
  print 'ERROR: Expecting the following arguments: [xml_file] [html_dir] [Title#]'
  quit(1)

fileCount = 0
def newFile(count):
  global fileCount
  fileCount+=count
xmlFileToParse = sys.argv[1]
htmlFolder = sys.argv[2]
chapterToParse = sys.argv[3]
print "    - SubChapter Html Files"
print "        - Xml File: " + xmlFileToParse
print "        - Chapter: " + chapterToParse
print "        - Html Dir: " + htmlFolder

indentPixels=40
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
      self.subchapterFile = None
      self.hasSubchapterFile = "N"

currentTitle= RawTitle()

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
         currentTitle.SubChapterNum = attributes["N"]
         if currentTitle.ChapterNum == chapterToParse:
           newFile(1)
           currentTitle.subchapterFile = open(htmlFolder + "/" +currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubChapterNum + ".html", "a")
           currentTitle.subchapterFile.write("<html lang=\"en\">\n<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">")
           currentTitle.hasSubchapterFile = "Y"
      elif tag == "DIV5":
         currentTitle.Level = "Part"
         currentTitle.PartStr = ""
         currentTitle.SubPartNum = ""
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.PartNum = attributes["N"]
      elif tag == "DIV6":
         currentTitle.Level = "SubPart"
      elif tag == "DIV8":
         currentTitle.Level = "Section"

    # Call when an elements ends
    def endElement(self, tag):
      if tag == "DIV3":
        currentTitle.Level = "Title"
      elif tag == "DIV4":
        currentTitle.Level = "Chapter"
        if currentTitle.hasSubchapterFile == "Y":
          currentTitle.subchapterFile.write("</ul></nav></article></main>\n")
          currentTitle.subchapterFile.write("<style type=\"text/css\">\n")
          currentTitle.subchapterFile.write("a {text-decoration: none; font-size: 16px; color: #0072ce !important;}\n")
          currentTitle.subchapterFile.write("a:hover {text-decoration: underline; color: #0072ce}\n")
          currentTitle.subchapterFile.write("body {background-color: #FFFFFF; font-family: \"Helvetica Neue\", Helvetica, Arial, sans-serif;}\n")
          currentTitle.subchapterFile.write("</style>")
          currentTitle.subchapterFile.write("</body>")
          #print "Closing file " + currentTitle.subchapterFile.name
          currentTitle.subchapterFile.close()
          currentTitle.subchapterFile = None
          currentTitle.hasSubchapterFile = "N"
      elif tag == "DIV5":
        currentTitle.Level = "SubChapter"
      elif tag == "DIV6":
        currentTitle.Level = "Part"
      elif tag == "DIV8":
        currentTitle.Level = "SubPart"

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
            if currentTitle.hasSubchapterFile == "Y" :
              currentTitle.subchapterFile.write("\n<title>" + content.encode("utf-8") + "</title></head>\n<body>\n")
              currentTitle.subchapterFile.write("<main role=\"main\">\n")
              currentTitle.subchapterFile.write("<article><h1>Federal Acquisition Regulation</h1>\n")
              currentTitle.subchapterFile.write("<nav role=\"navigation\" class=\"related-links\">\n")
              currentTitle.subchapterFile.write("<ul>\n")
              currentTitle.subchapterFile.write("<div class=\"parentlink\">\n<a class=\"link\" href=\"#\">" + content.encode("utf-8") +"</a></div>\n")
      elif currentTitle.Level == "Part":
        if self.CurrentData == "HEAD":
          if content != "\n":
            if currentTitle.hasSubchapterFile == "Y" :
              link=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.PartNum + ".html"
              currentTitle.subchapterFile.write("<li><strong>\n")
              currentTitle.subchapterFile.write("<a class=\"link\" href=\"" + link +"\">" + content.encode("utf-8") + "</a>\n")
              currentTitle.subchapterFile.write("</li></strong>\n")

# create an XMLReader
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_namespaces, 0)
Handler = CFRHandler()
parser.setContentHandler( Handler )

## THe work is done here!!
parser.parse(xmlFileToParse)
print "        - Generated Files: " + str(fileCount)
