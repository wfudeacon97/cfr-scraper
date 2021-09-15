db.federaldocuments.aggregate([
    { "$match": { "type":3 } },
    { "$match": { "agencies.agencyId":539 } },
    { "$project": {
        "type": "$type",
        "title": "$cfrIdentifier.title"	,
         "chapter": "$cfrIdentifier.chapter",
         "part": "$cfrIdentifier.part",
         "subPart": "$cfrIdentifier.subPart",
         "subTopic": "$cfrIdentifier.subTopic",
         "docTitle": "$title"}},
 {"$project": {"_id": 0}},
 {"$sort": {
	"chapter": 1, "part": 1, "subPart": 1}},
]);
