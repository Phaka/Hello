#!/bin/sh

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

TAG="v$(date '+%Y%m%dT%H%M%S')"
# git tag -a "$TAG" -m "Release v$TAG"
# git push origin "$TAG"

mkdir -p dist
pushd dist
cat << EOF > release.json
{
  "tag_name": "$TAG",
  "target_commitish": "master",
  "name": "$TAG",
  "body": "Description of the release",
  "draft": false,
  "prerelease": false
}
EOF

GH_REPO="https://api.github.com/repos/phaka/hello/releases?access_token=$GH_ACCESS_TOKEN"
curl -X POST -d @release.json $GH_REPO > response1.json
RELEASE_ID="$(cat response1.json | python -c "import sys, json; print json.load(sys.stdin)['id']")"
if [ -z "$RELEASE_ID" ]
then
  MSG="$(cat response1.json | python -c "import sys, json; print json.load(sys.stdin)['message']")"
  echo "Failed to create GitHub release. $MSG"
  exit 1
else
  echo "Release created with id: $RELEASE_ID."
fi
popd 

counter=1
pushd "bin"
for f in *; do
  URL="https://uploads.github.com/repos/phaka/hello/releases/$RELEASE_ID/assets?name=$(basename "$f")&access_token=$GH_ACCESS_TOKEN"
  curl --data-binary @"$f" -H "Content-Type: application/octet-stream" "$URL" > "../dist/response$counter.json"
  ((counter=counter+1))
done
popd


