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
print "Xml File: " + xmlFileToParse
print "Chapter: " + chapterToParse
print "Html Dir: " + htmlFolder

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
      self.authority = "AUTHORITY: "

currentTitle= RawTitle()

class CFRHandler( xml.sax.ContentHandler ):
    def __init__(self):
      self.CurrentData = ""

###########################################
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
           currentTitle.partFile = open(htmlFolder + "/" +currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubChapterNum + "."+ currentTitle.PartNum + ".html", "a")
           #currentTitle.partFile.write("<html lang=\"en\">\n<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">")
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
      elif tag == "P":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            classAttr= attributes.get("class", "bad")
            if classAttr == "gpotbl_title":
               currentTitle.partFile.write("<p style=\"font-weight: bold;text-align:center;\">")
            else:
               currentTitle.partFile.write("<p class=\"p\">")
      elif tag == "I":
        if currentTitle.Level == "Section":
             if currentTitle.hasPartFile == "Y" :
               currentTitle.partFile.write("<i>")
      elif tag == "TABLE":
        if currentTitle.Level == "Section":
             if currentTitle.hasPartFile == "Y" :
               currentTitle.partFile.write("<TABLE border=\"1\" cellpadding=\"1\" cellspacing=\"1\" frame=\"void\" width=\"100%\">\n")
      elif tag == "TR":
        if currentTitle.Level == "Section":
             if currentTitle.hasPartFile == "Y" :
               currentTitle.partFile.write("<TR>")
      elif tag == "TH":
        if currentTitle.Level == "Section":
             if currentTitle.hasPartFile == "Y" :
               currentTitle.partFile.write("<TH>")
      elif tag == "TD":
        if currentTitle.Level == "Section":
             if currentTitle.hasPartFile == "Y" :
               currentTitle.partFile.write("<TD align=\"left\">")
      elif tag == "br":
        if currentTitle.Level == "Section":
             if currentTitle.hasPartFile == "Y" :
               currentTitle.partFile.write("<br/>")

###########################################
    # Call when an elements ends
    def endElement(self, tag):
      if tag == "DIV3":
        currentTitle.Level = "Title"
      elif tag == "DIV4":
        currentTitle.Level = "Chapter"
      elif tag == "DIV5":
        currentTitle.Level = "SubChapter"
        if currentTitle.hasPartFile == "Y" :
          currentTitle.partFile.write("</article>\n")
          currentTitle.partFile.write("<style type=\"text/css\">\n")
          currentTitle.partFile.write("a {text-decoration: none; font-size: 16px; color: #0072ce !important;}\n")
          currentTitle.partFile.write("a:hover {text-decoration: underline; color: #0072ce}\n")
          currentTitle.partFile.write("body {background-color: #FFFFFF;}\n")
          currentTitle.partFile.write("</style>")
          currentTitle.partFile.write("</body>")
          currentTitle.partFile.close()
          currentTitle.partFile = None
          currentTitle.hasPartFile = "N"
          currentTitle.authority = "AUTHORITY: "
      elif tag == "DIV6":
        currentTitle.Level = "Part"
        if currentTitle.hasPartFile == "Y" :
          currentTitle.partFile.write("</article>\n")
      elif tag == "DIV8":
        currentTitle.Level = "SubPart"
        if currentTitle.hasPartFile == "Y" :
          currentTitle.partFile.write("</article>\n")
      elif tag == "P":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            currentTitle.partFile.write("</p>\n")
      elif tag == "I":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            currentTitle.partFile.write("</i>")
      elif tag == "TR":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            currentTitle.partFile.write("</TR>\n")
      elif tag == "TD":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            currentTitle.partFile.write("</TD>")
      elif tag == "TABLE":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            currentTitle.partFile.write("</TABLE>\n")
      elif tag == "TH":
        if currentTitle.Level == "Section":
          if currentTitle.hasPartFile == "Y" :
            currentTitle.partFile.write("</TH>\n")

###########################################
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
        if self.CurrentData == "PSPACE":
          if content != "\n":
            currentTitle.authority += content
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.PartStr = content
      elif currentTitle.Level == "SubPart":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SubPartStr = content
            if currentTitle.hasPartFile == "Y" :
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubPartNum
              subpartFileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubPartNum
              currentTitle.partFile.write("<article id=\"" + id +"\"><h1 id=\"section_"+ id +"\"><span class=\"ph autonumber\">")
              currentTitle.partFile.write(content.encode("utf-8") + "</span></h1>\n")
      elif currentTitle.Level == "Section":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SectionStr = content
            if currentTitle.hasPartFile == "Y" :
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              subpartFileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubPartNum
              link=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              currentTitle.partFile.write("<article id=\"" + id +"\"><div id=\"section_"+ id +"\"><p class=\"ph autonumber\"><b><u>")
              currentTitle.partFile.write(currentTitle.SectionStr.encode("utf-8") + "</u></b></p></div>\n")
        elif self.CurrentData == "P":
          if currentTitle.hasPartFile == "Y" :
            if content != "\n":
              currentTitle.partFile.write(content.encode("utf-8"))
        else:
          if currentTitle.hasPartFile == "Y" :
            if content != "\n":
              currentTitle.partFile.write(content.encode("utf-8"))

# create an XMLReader
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_namespaces, 0)
Handler = CFRHandler()
parser.setContentHandler( Handler )

## THe work is done here!!
parser.parse(xmlFileToParse)
