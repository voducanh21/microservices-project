const fs = require("fs");

const input = JSON.parse(fs.readFileSync("trivy-result.json", "utf-8"));

const issues = [];

if (input.Results) {
  input.Results.forEach(result => {
    if (!result.Vulnerabilities) return;
    result.Vulnerabilities.forEach(vuln => {
      issues.push({
        engineId: "trivy",
        ruleId: vuln.VulnerabilityID,
        type: "VULNERABILITY",
        severity: vuln.Severity === "CRITICAL" ? "CRITICAL" : "MAJOR",
        primaryLocation: {
          message: vuln.Title || vuln.Description || vuln.VulnerabilityID,
          filePath: result.Target || "unknown",
        }
      });
    });
  });
}

fs.writeFileSync("sonarqube-trivy.json", JSON.stringify({ issues }, null, 2));
