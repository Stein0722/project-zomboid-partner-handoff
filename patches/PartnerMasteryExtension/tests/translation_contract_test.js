const fs = require("fs");

const koPath = process.argv[2];
const enPath = process.argv[3];
if (!koPath || !enPath) {
  throw new Error("Korean and English UI.json paths are required");
}

const ko = JSON.parse(fs.readFileSync(koPath, "utf8"));
const en = JSON.parse(fs.readFileSync(enPath, "utf8"));
const required = [
  "UI_PME_ModName",
  "UI_PME_Title_Settings",
  "UI_PME_BonusEfficiency",
  "UI_PME_BonusEfficiency_Tooltip",
  "UI_PME_Mastery",
  "UI_PME_StorageOnly",
];

for (const key of required) {
  if (!(key in ko)) throw new Error(`Korean JSON missing ${key}`);
  if (!(key in en)) throw new Error(`English JSON missing ${key}`);
}

if (ko.UI_PME_ModName !== "파트너 마스터리 확장") {
  throw new Error("Unexpected Korean mod name");
}
if (en.UI_PME_ModName !== "Partner Mastery Extension") {
  throw new Error("Unexpected English mod name");
}

console.log("PARTNER_MASTERY_TRANSLATION_CONTRACT_TEST_OK");
