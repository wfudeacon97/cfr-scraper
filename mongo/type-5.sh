#jq '.|select(.cfrIdentifier.subPart | startswith("Subpart"))'  | \
#jq '.cfrIdentifier.subPart |= sub("Subpart ";"")'| \
jq '.|select(.type == 5)' results/mongo-chapter-1.json | \
jq '. |= (.part = .cfrIdentifier.part)'  | \
jq '. |= (.docTitle = .title)' | \
jq '. |= (.title = .cfrIdentifier.title)' | \
jq '. |= (.part = .cfrIdentifier.part)' | \
jq '. |= (.subTopic = .cfrIdentifier.subTopic)' | \
jq '. |= (.chapter = .cfrIdentifier.chapter)' | \
jq '. |= (.subPart = .cfrIdentifier.subPart)' | \
jq '{type,title,chapter,part,subPart,subTopic,docTitle}'   -c
