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
#"tmp/raw-2021-08-24.xml"
xmlFileToParse = sys.argv[1]
htmlFolder = sys.argv[2]
chapterToParse = sys.argv[3]
print "    - SubPart Html Files"
print "        - Xml File: " + xmlFileToParse
print "        - Chapter: " + chapterToParse
print "        - Html Dir: " + htmlFolder


# Generates 2 sets of files:
# Example: 48.1.1.0.html
# Example: 48.1.1.1.html
print 'gen-far-subpart-html-py.sh: Generates w.x.y.z.html'

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
      self.subpartFile = None
      self.hasSubPartFile = "N"
      self.subpart0File = None
      self.hasSubPart0File = "N"
      self.delayContent="N"
      self.subPart0DelayedContent=""

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
      elif tag == "DIV6":
         currentTitle.Level = "SubPart"
         currentTitle.SubPartStr = ""
         currentTitle.SectionNum = ""
         currentTitle.SectionStr = ""
         currentTitle.SubPartNum = attributes["N"]
         if currentTitle.ChapterNum == chapterToParse:
           subpartFileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubPartNum
           newFile(1)
           currentTitle.subpartFile = open(htmlFolder + "/" +subpartFileName + ".html", "a")
           currentTitle.subpartFile.write("<html lang=\"en\">\n<head>\n<!-- gen-far-subpart-html -->\n<!-- GOOGLE-ADD -->\n<!-- AD_SENSE -->\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>\n")
           currentTitle.hasSubPartFile = "Y"
      #elif tag == "DIV7":
      #   currentTitle.Level = "DIV7"
      elif tag == "DIV8":
         currentTitle.Level = "Section"
         currentTitle.SectionStr = ""
         currentTitle.SectionNum = attributes["N"]
         if currentTitle.ChapterNum == chapterToParse:
            # This can happen for SubPart 0 in each Part... there is no DIV6 before the Div8
            if currentTitle.SubPartNum == "":
              subpart0FileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.PartNum
              newFile(1)
              currentTitle.subpart0File = open(htmlFolder + "/" +subpart0FileName + ".0.html", "a")
              if currentTitle.hasSubPart0File == "N":
                currentTitle.subpart0File.write("<html lang=\"en\">\n<head>\n<!-- gen-far-subpart-html -->\n<!-- GOOGLE-ADD -->\n<!-- AD_SENSE -->\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>\n")
              currentTitle.hasSubPart0File = "Y"
              currentTitle.delayContent="Y"

      elif tag == "P":
         if currentTitle.Level == "Section":
            if currentTitle.hasSubPartFile == "Y" :
              currentTitle.subpartFile.write("<p class=\"p\">")
            if currentTitle.hasSubPart0File == "Y" :
              if currentTitle.delayContent =="Y" :
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+ "<p class=\"p\">"
              else:
                currentTitle.subpart0File.write("<p class=\"p\">")

      #elif tag == "CITA":
      #   if currentTitle.Level == "Section":
      #      if currentTitle.hasSubPartFile == "Y" :
      #        currentTitle.subpartFile.write("<div>")
      elif tag == "I":
         if currentTitle.Level == "Section":
            if currentTitle.hasSubPartFile == "Y" :
              currentTitle.subpartFile.write("<i>")
            if currentTitle.hasSubPart0File == "Y" :
              if currentTitle.delayContent =="Y" :
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+ "<i>"
              else:
                currentTitle.subpart0File.write("<i>")

    # Call when an elements ends
    def endElement(self, tag):
      if tag == "DIV3":
        currentTitle.Level = "Title"
      elif tag == "DIV4":
        currentTitle.Level = "Chapter"
      elif tag == "DIV5":
        currentTitle.Level = "SubChapter"
        if currentTitle.hasSubPart0File == "Y" :
          if currentTitle.delayContent =="Y" :
            currentTitle.subpart0File.write(currentTitle.subPart0DelayedContent.encode("utf-8"))
      elif tag == "DIV6":
        currentTitle.Level = "Part"
        #print "Checking end of file " + currentTitle.subpartFile.name
        if currentTitle.hasSubPartFile == "Y" :
          currentTitle.subpartFile.write("</article>")
          currentTitle.subpartFile.write("<style type=\"text/css\">\n")
          currentTitle.subpartFile.write("a {text-decoration: none; font-size: 16px; color: #0072ce !important;}\n")
          currentTitle.subpartFile.write("a:hover {text-decoration: underline; color: #0072ce}\n")
          currentTitle.subpartFile.write("body {background-color: #FFFFFF; font-family: \"Helvetica Neue\", Helvetica, Arial, sans-serif;}\n")
          currentTitle.subpartFile.write("</style></body>")
          #print "Closing file " + currentTitle.subpartFile.name
          currentTitle.subpartFile.close()
          currentTitle.subpartFile = None
          currentTitle.hasSubPartFile = "N"
        if currentTitle.hasSubPart0File == "Y" :
          currentTitle.subpart0File.write("</article>")
          currentTitle.subpart0File.write("<style type=\"text/css\">\n")
          currentTitle.subpart0File.write("a {text-decoration: none; font-size: 16px; color: #0072ce !important;}\n")
          currentTitle.subpart0File.write("a:hover {text-decoration: underline; color: #0072ce}\n")
          currentTitle.subpart0File.write("body {background-color: #FFFFFF; font-family: \"Helvetica Neue\", Helvetica, Arial, sans-serif;}\n")
          currentTitle.subpart0File.write("</style></body>")
          #print "Closing file " + currentTitle.subpart0File.name
          currentTitle.subpart0File.close()
          currentTitle.subpart0File = None
          currentTitle.hasSubPart0File = "N"
          currentTitle.delayContent="N"
          self.subPart0DelayedContent=""
      elif tag == "DIV8":
        currentTitle.Level = "SubPart"
        if currentTitle.hasSubPartFile == "Y" :
          currentTitle.subpartFile.write("</article>\n")
        elif currentTitle.hasSubPart0File == "Y" :
          if currentTitle.delayContent =="Y" :
            currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+ "</article>\n"
          else:
            currentTitle.subpart0File.write("</article>\n")
      elif tag == "P":
        if currentTitle.Level == "Section":
          if currentTitle.hasSubPartFile == "Y" :
            currentTitle.subpartFile.write("</p>\n")
          elif currentTitle.hasSubPart0File == "Y" :
            if currentTitle.delayContent =="Y" :
              currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+ "</p>\n"
            else:
              currentTitle.subpart0File.write("</p>\n")
      elif self.CurrentData == "I":
        if currentTitle.Level == "Section":
          if currentTitle.hasSubPartFile == "Y" :
            currentTitle.subpartFile.write("</i>")
          elif currentTitle.hasSubPart0File == "Y" :
            if currentTitle.delayContent =="Y" :
              currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+ "</i>"
            else:
              currentTitle.subpart0File.write("</i>")

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
            if currentTitle.hasSubPartFile == "Y" :
              currentTitle.subpartFile.write("\n<title>" + content.encode("utf-8") + "</title>")
              currentTitle.subpartFile.write("\n<meta name=\"title\" content=\"FAR " + content.encode("utf-8") + "\"/>")
              # currentTitle.subpartFile.write("\n<meta name=\"description\" content=\"" + content.encode("utf-8") + "\"/>")

              subpartFileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.SubPartNum + ".html"
              currentTitle.subpartFile.write("<script type = \"text/javascript\">\n")
              currentTitle.subpartFile.write("window.onload = function(){\n")
              currentTitle.subpartFile.write("   if ( window == window.parent ) {\n")
              currentTitle.subpartFile.write("   window.location.replace(window.location.protocol + \"//\" + window.location.hostname + \"/regulations/539/"+ currentTitle.PartNum +"/" + subpartFileName + "\");\n")
              currentTitle.subpartFile.write("   }\n")
              currentTitle.subpartFile.write(" else{\n")
              currentTitle.subpartFile.write("   window.parent.document.title=\"FAR "+ content.encode("utf-8")+"\";\n")
              currentTitle.subpartFile.write("   window.parent.document.getElementsByTagName(\"meta\")[\"title\"].content=\"FAR "+ content.encode("utf-8")+"\";\n")
              currentTitle.subpartFile.write("   }\n")
              currentTitle.subpartFile.write("}</script>\n")
              currentTitle.subpartFile.write("</head>\n<body>\n")

              currentTitle.subpartFile.write("\n</head>\n<body>\n")
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubPartNum
              currentTitle.subpartFile.write("<article id=\"" + id +"\"><br/><h1 id=\"subpart_" + id + "\" style=\"text-align:center;\"><span class=\"ph autonumber\">" + content.encode("utf-8") + "</span></h1>\n")
            if currentTitle.hasSubPart0File == "Y" :
              currentTitle.subpart0File.write("\n<title>" + content.encode("utf-8") + "</title>")
              currentTitle.subpart0File.write("\n<meta name=\"title\" content=\"FAR " + content.encode("utf-8") + "\"/>\n")
              # currentTitle.subpart0File.write("\n<meta name=\"description\" content=\"" + content.encode("utf-8") + "\"/>")
              subpart0FileName=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "."  + currentTitle.PartNum + ".0.html"
              currentTitle.subpart0File.write("<script type = \"text/javascript\">\n")
              currentTitle.subpart0File.write("window.onload = function(){\n")
              currentTitle.subpart0File.write("   if ( window == window.parent ) {\n")
              currentTitle.subpart0File.write("   window.location.replace(window.location.protocol + \"//\" + window.location.hostname + \"/regulations/539/"+ currentTitle.PartNum +"/" + subpart0FileName + "\");\n")
              currentTitle.subpart0File.write("   }\n")
              currentTitle.subpart0File.write(" else{\n")
              currentTitle.subpart0File.write("   window.parent.document.title=\"FAR Scope of Part "+ currentTitle.PartNum+ ".000\";\n")
              currentTitle.subpart0File.write("   window.parent.document.getElementsByTagName(\"meta\")[\"title\"].content=\"FAR Scope of Part "+ currentTitle.PartNum+ ".000\";\n")
              currentTitle.subpart0File.write("   }\n")
              currentTitle.subpart0File.write("}</script>\n")

              currentTitle.subpart0File.write("\n</head>\n<body>\n")
              currentTitle.subpart0File.write(currentTitle.subPart0DelayedContent.encode("utf-8"))
              currentTitle.subPart0DelayedContent=""
              currentTitle.delayContent="N"
              #id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SubPartNum
              #currentTitle.subpart0File.write("<article id=\"" + id +"\"><br/><h1 id=\"subpart_" + id + "\" style=\"text-align:center;\"><span class=\"ph autonumber\">" + content.encode("utf-8") + "</span></h1>\n")
      elif currentTitle.Level == "Section":
        if self.CurrentData == "HEAD":
          if content != "\n":
            currentTitle.SectionStr = content
            if currentTitle.hasSubPartFile == "Y" :
              #print "<article id=\"" + currentTitle.TitleNum + "." + currentTitle.ChapterNum "." + currentTitle.SectionNum +"\"><h1 id=\"Section_Hdr\" id=\"ariaid-title1\"><span class=\"ph autonumber\">" + content.encode("utf-8") + "</span></h1>\n"
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              currentTitle.subpartFile.write("<article id=\"" + id +"\"><br/><h1 id=\"section_" + id + "\" ><span class=\"ph autonumber\">")
              currentTitle.subpartFile.write(content.encode("utf-8") + "</span></h1>\n")

            elif currentTitle.hasSubPart0File == "Y" :
              #print "<article id=\"" + currentTitle.TitleNum + "." + currentTitle.ChapterNum "." + currentTitle.SectionNum +"\"><h1 id=\"Section_Hdr\" id=\"ariaid-title1\"><span class=\"ph autonumber\">" + content.encode("utf-8") + "</span></h1>\n"
              id=currentTitle.TitleNum + "." + currentTitle.ChapterNum + "." + currentTitle.SectionNum
              if currentTitle.delayContent =="Y" :
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+"<article id=\"" + id +"\"><br/><h1 id=\"section_" + id + "\" ><span class=\"ph autonumber\">"
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+content + "</span></h1>\n"
              else:
                currentTitle.subpart0File.write("<article id=\"" + id +"\"><br/><h1 id=\"section_" + id + "\" ><span class=\"ph autonumber\">")
                currentTitle.subpart0File.write(content.encode("utf-8") + "</span></h1>\n")
        elif self.CurrentData == "CITA":
          if content != "\n":
            if currentTitle.hasSubPartFile == "Y" :
              currentTitle.subpartFile.write("<div id=\"citation\">" + content.encode("utf-8") + "</div>\n")
            elif currentTitle.hasSubPart0File == "Y" :
              if currentTitle.delayContent == "Y" :
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+ "<div id=\"citation\">" + content + "</div>\n"
              else:
                currentTitle.subpart0File.write("<div id=\"citation\">" + content.encode("utf-8") + "</div>\n")
        elif self.CurrentData == "P":
          if currentTitle.hasSubPartFile == "Y" :
            if content != "\n":
              if re.search('^\([a-z]\)',content, re.MULTILINE):
                currentTitle.subpartFile.write("&#xA0;&#xA0;&#xA0;&#xA0;")
              if re.search('^\([0-9]\)',content, re.MULTILINE):
                currentTitle.subpartFile.write("&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;")
              currentTitle.subpartFile.write(content.encode("utf-8"))
          elif currentTitle.hasSubPart0File == "Y" :
            if content != "\n":
              line=""
              if re.search('^\([a-z]\)',content, re.MULTILINE):
                line="&#xA0;&#xA0;&#xA0;&#xA0;"
              if re.search('^\([0-9]\)',content, re.MULTILINE):
                line="&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;"
              if currentTitle.delayContent =="Y" :
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+line+content
              else:
                currentTitle.subpart0File.write(line+content.encode("utf-8"))
        else:
          if currentTitle.hasSubPartFile == "Y" :
            if content != "\n":
              currentTitle.subpartFile.write(content.encode("utf-8"))
          elif currentTitle.hasSubPart0File == "Y" :
            if content != "\n":
              if currentTitle.delayContent =="Y" :
                currentTitle.subPart0DelayedContent=currentTitle.subPart0DelayedContent+content
              else:
                currentTitle.subpart0File.write(content.encode("utf-8"))

# create an XMLReader
parser = xml.sax.make_parser()
parser.setFeature(xml.sax.handler.feature_namespaces, 0)
Handler = CFRHandler()
parser.setContentHandler( Handler )

## THe work is done here!!

parser.parse(xmlFileToParse)
print "        - Generated Files: " + str(fileCount)
