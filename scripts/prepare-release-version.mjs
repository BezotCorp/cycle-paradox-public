import { writeFile } from "node:fs/promises";

import changelog from "@semantic-release/changelog";
import semanticRelease from "semantic-release";

const expectedVersion = process.argv[2];
const notesFile = process.env.RELEASE_NOTES_FILE;

if (!expectedVersion || !notesFile) {
  throw new Error("Expected version and RELEASE_NOTES_FILE are required");
}

const result = await semanticRelease({
  dryRun: true,
  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
      },
    ],
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits",
      },
    ],
  ],
});

if (!result?.nextRelease) {
  throw new Error("semantic-release found no version to prepare");
}

if (result.nextRelease.version !== expectedVersion) {
  throw new Error(
    `Expected version ${expectedVersion}, but semantic-release selected ${result.nextRelease.version}`,
  );
}

await changelog.prepare(
  {
    changelogFile: "cycle_paradox_extension_api/CHANGELOG.md",
  },
  {
    cwd: process.cwd(),
    nextRelease: result.nextRelease,
    logger: console,
  },
);

await writeFile(notesFile, result.nextRelease.notes ?? "");
