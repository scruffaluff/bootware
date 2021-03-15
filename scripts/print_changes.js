const parseChangelog = require("changelog-parser");
const path = require("path");

function main() {
  const version = process.argv[2];
  const repoPath = path.dirname(__dirname);
  const changeLogPath = path.join(repoPath, "CHANGELOG.md");

  parseChangelog(changeLogPath, function (err, result) {
    const releases = result.versions.filter(
      (object) => object.version === version
    );

    if (releases.length === 0) {
      console.log("");
    } else {
      console.log(releases[0].body);
    }
  });
}

main();
