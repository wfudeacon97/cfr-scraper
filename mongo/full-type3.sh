#jq '.|select(.cfrIdentifier.subPart | startswith("Subpart"))'  | \
#jq '.cfrIdentifier.subPart |= sub("Subpart ";"")'| \
jq '.|select(.type == 3)' results/mongo-chapter-1.json | \
jq 'del(._id )'   |\
jq 'del(.createdAt )'   |\
jq 'del(.htmlUrl )'   |\
jq 'del(.updatedAt )'   |\
jq 'del(.content )'   |\
jq 'del(.raw )'   |\
jq 'del(.select )'   |\
jq 'del(.agencies[0]._id )'   |\
jq 'del(.agencies[0].createdAt )'   |\
jq 'del(.agencies[0].updatedAt )' -S  -c
