db.federaldocuments.aggregate([
    { "$match": { "type":3 } },
    { "$match": { "agencies.agencyId":539 } },
    {"$project": {"_id": 0, "content" : 0, "createdAt" : 0, "updatedAt": 0, "htmlUrl":0}},
    {"$unset": "agencies.createdAt"},
    {"$unset": "agencies.updatedAt"},
    {"$unset": "agencies._id"},
    {"$unset": "agencies.raw"},
    {"$unset": "agencies.select"},
    {"$sort": { "cfrIdentifier.chapter": 1, "cfrIdentifier.part": 1, "cfrIdentifier.subPart": 1}}
]);
