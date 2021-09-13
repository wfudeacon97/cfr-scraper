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
        ## This is the end of the top section of the file... add the authority and line break, and close the file
        if currentTitle.hasPartFile == "Y" :
          currentTitle.partFile.write("</table>")
          currentTitle.partFile.write("<p id=authority>"+ currentTitle.authority+ "</p>\n")
          currentTitle.partFile.write("<hr/>\n")
          currentTitle.partFile.write("</article>\n")
          #currentTitle.partFile.write("<style type=\"text/css\">\n")
          #currentTitle.partFile.write("a {text-decoration: none; font-size: 16px; color: #0072ce !important;}\n")
          #currentTitle.partFile.write("a:hover {text-decoration: underline; color: #0072ce}\n")
          #currentTitle.partFile.write("body {background-color: #FFFFFF;}\n")
          #currentTitle.partFile.write("</style>")
          #currentTitle.partFile.write("</body>")
          #print "Closing file " + currentTitle.partFile.name
          currentTitle.partFile.close()
          currentTitle.partFile = None
          currentTitle.hasPartFile = "N"
          currentTitle.authority = "AUTHORITY: "
      elif tag == "DIV6":
        currentTitle.Level = "Part"
        #if currentTitle.hasPartFile == "Y" :
        #  currentTitle.partFile.write("</article>\n")
        #  currentTitle.partFile.write("</table>")
      elif tag == "DIV8":
        currentTitle.Level = "SubPart"
        #if currentTitle.hasPartFile == "Y" :
        #  currentTitle.partFile.write("</article>\n")

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
            if currentTitle.hasPartFile == "Y" :
              currentTitle.partFile.write("\n<title>" + content.encode("utf-8") + "</title></head>\n<body>\n")
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.PartNum
              currentTitle.partFile.write("<article id=\"" + id +"\"><h1 id=\"toc_"+id+"\"><span class=\"ph autonumber\">" + content.encode("utf-8") + "</span></h1></article>\n")
              # currentTitle.partFile.write("<p>Sec.</p>\n")
              currentTitle.partFile.write("<table width=100%>")
      elif currentTitle.Level == "SubPart":
        if self.CurrentData == "HEAD":
          if content != "\n":
            if currentTitle.hasPartFile == "Y" :
              currentTitle.SubPartStr = content
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              link=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum

              currentTitle.partFile.write("</table>")
              currentTitle.partFile.write("<article id=\"" + id +"\"><h3 id=\"toc_"+id+"\"><span class=\"ph autonumber\">")
              currentTitle.partFile.write(content.encode("utf-8") + "</span></h3></article>\n")
              currentTitle.partFile.write("<table width=100%>")
      elif currentTitle.Level == "Section":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SectionStr = content
            if currentTitle.hasPartFile == "Y" :
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              link=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              currentTitle.partFile.write("<tr><td style=\"width: 20%;\">")
              currentTitle.partFile.write("<div id=\""+ id +"\" class=\"ph autonumber\">")
              currentTitle.partFile.write("<a href=\"#section_" +link +"\" >" + currentTitle.SectionNum + "</a></div></td><td>")
              title=content.replace(currentTitle.SectionNum, "", 1)
              currentTitle.partFile.write(title.encode("utf-8") + "</td></tr>\n")

# create an XMLReader
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_namespaces, 0)
Handler = CFRHandler()
parser.setContentHandler( Handler )

## THe work is done here!!
parser.parse(xmlFileToParse)
