const fs = require('fs');
const path = require('path');

const baseDir = 'results';
const outputFile = 'mxset.txt';
const configs = [];

function processMxFile(filePath) {
  const lines = fs.readFileSync(filePath, 'utf-8').split('\n');

  for (const line of lines) {
    const parts = line.split('|').map(p => p.trim());
    if (parts.length >= 2) {
      const domain = parts[0];
      const mx = parts[1];

      if (mx.includes('mail.protection.outlook.com')) {
        const config = {
          host: mx,
          port: "25",
          secure: false,
          user: "",
          pass: "",
          fromEmail: "LINXEMAIL",
          allowPooling: true,
          enabled: true
        };
        configs.push(config);
      }
    }
  }
}

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath);
    } else if (entry.name === 'mx.txt') {
      processMxFile(fullPath);
    }
  }
}

walk(baseDir);

// Write output safely
fs.writeFileSync(outputFile, JSON.stringify(configs, null, 2));
console.log(`✅ Saved ${configs.length} Office365-compatible configs to ${outputFile}`);
