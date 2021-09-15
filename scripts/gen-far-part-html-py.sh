#!/usr/bin/python
import xml.sax
import sys
import re

if (len(sys.argv) -1) != 3:
  print 'ERROR: Expecting the following arguments: [xml_file] [html_dir] [Title#]'
  quit(1)

xmlFileToParse = sys.argv[1]
htmlFolder = sys.argv[2]
chapterToParse = sys.argv[3]
print "    - Part Html Files"
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
      self.SubPartNum = ""
      self.SubPartStr = ""
      self.SectionNum = ""
      self.SectionStr = ""
      self.partFile = None
      self.hasPartFile = "N"

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
      elif tag == "DIV5":
         currentTitle.Level = "Part"
         currentTitle.PartStr = ""
         currentTitle.SubPartNum = ""
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.PartNum = attributes["N"]
         if currentTitle.ChapterNum == chapterToParse:
           currentTitle.partFile = open(htmlFolder + "/" +currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.PartNum + ".html", "a")
           currentTitle.partFile.write("<html lang=\"en\">\n<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">")
           currentTitle.hasPartFile = "Y"
      elif tag == "DIV6":
         currentTitle.Level = "SubPart"
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.SubPartNum = attributes["N"]
      elif tag == "DIV8":
         currentTitle.Level = "Section"
         currentTitle.SectionStr = ""
         currentTitle.SectionNum = attributes["N"]

    # Call when an elements ends
    def endElement(self, tag):
      if tag == "DIV3":
        currentTitle.Level = "Title"
      elif tag == "DIV4":
        currentTitle.Level = "Chapter"
      elif tag == "DIV5":
        currentTitle.Level = "SubChapter"
        if currentTitle.hasPartFile == "Y":
          currentTitle.partFile.write("</article>\n")
          currentTitle.partFile.write("<style type=\"text/css\">\n")
          currentTitle.partFile.write("a {text-decoration: none; font-size: 16px; color: #0072ce !important;}\n")
          currentTitle.partFile.write("a:hover {text-decoration: underline; color: #0072ce}\n")
          currentTitle.partFile.write("body {background-color: #FFFFFF;}\n")
          currentTitle.partFile.write("</style>")
          currentTitle.partFile.write("</body>")
          #print "Closing file " + currentTitle.partFile.name
          currentTitle.partFile.close()
          currentTitle.partFile = None
          currentTitle.hasPartFile = "N"
      elif tag == "DIV6":
        currentTitle.Level = "Part"
        if currentTitle.hasPartFile == "Y" :
          currentTitle.partFile.write("</article>\n")

      elif tag == "DIV8":
        currentTitle.Level = "SubPart"
        if currentTitle.hasPartFile == "Y" :
          currentTitle.partFile.write("</article>\n")


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
            if currentTitle.hasPartFile == "Y" :
              currentTitle.partFile.write("\n<title>" + content.encode("utf-8") + "</title></head>\n<body>\n")
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.PartNum
              currentTitle.partFile.write("<article id=\"" + id +"\"><h1 id=\"subpart_"+id+"\"><span class=\"ph autonumber\">" + content.encode("utf-8") + "</span></h1>\n")
      elif currentTitle.Level == "SubPart":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SubPartStr = content
            indent=indentPixels*2
            if currentTitle.hasPartFile == "Y" :
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubPartNum
              subpartFileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubPartNum
              currentTitle.partFile.write("<article id=\"" + id +"\"><h1 id=\"section_"+ id +"\" style=\"margin-left: "+str(indent)+"px\"><span class=\"ph autonumber\">")
              currentTitle.partFile.write("<a href=\"" + subpartFileName + ".html\">")
              currentTitle.partFile.write(content.encode("utf-8") + "</a></span></h1>\n")
      elif currentTitle.Level == "Section":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SectionStr = content
            if currentTitle.hasPartFile == "Y" :
              indent=indentPixels*3
              #if currentTitle.PartNum == "3":
              #  print "Testing Indent: "+ currentTitle.SectionStr +" | " + currentTitle.SubPartNum
              if currentTitle.SectionNum == (currentTitle.PartNum + ".000"):
                indent=indentPixels
                #if currentTitle.PartNum == "3":
                #  print "   - is section .000"
              if "-" in currentTitle.SectionNum :
                indent=indentPixels*4
                #if currentTitle.PartNum == "3":
                #  print "   - is hyphen"
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              subpartFileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubPartNum
              link=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              currentTitle.partFile.write("<article id=\"" + id +"\"><h1 id=\"section_"+ id +"\" style=\"margin-left: "+str(indent)+"px\"><span class=\"ph autonumber\">")
              currentTitle.partFile.write("<a href=\"" + subpartFileName + ".html"+link +"\">")
              currentTitle.partFile.write(content.encode("utf-8") + "</span></h1>\n")
        #else:
        #  if currentTitle.hasPartFile == "Y" :
        #    if content != "\n":
        #      currentTitle.partFile.write(content.encode("utf-8"))

# create an XMLReader
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_namespaces, 0)
Handler = CFRHandler()
parser.setContentHandler( Handler )

## THe work is done here!!
parser.parse(xmlFileToParse)
