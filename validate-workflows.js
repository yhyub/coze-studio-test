const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Get all workflow files
const workflowDir = path.join(__dirname, '.github', 'workflows');
const workflowFiles = [];

function findFiles(dir, extension) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      findFiles(filePath, extension);
    } else if (extension.includes(path.extname(file))) {
      workflowFiles.push(filePath);
    }
  });
}

findFiles(workflowDir, ['.yml', '.yaml']);

console.log(`Found ${workflowFiles.length} workflow files to validate\n`);

let validFiles = 0;
let invalidFiles = 0;

workflowFiles.forEach(filePath => {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    yaml.load(content);
    console.log(`✅ ${path.relative(__dirname, filePath)} - Valid YAML`);
    validFiles++;
  } catch (error) {
    console.log(`❌ ${path.relative(__dirname, filePath)} - Invalid YAML: ${error.message}`);
    invalidFiles++;
  }
});

console.log(`\nValidation Summary:`);
console.log(`Valid files: ${validFiles}`);
console.log(`Invalid files: ${invalidFiles}`);
console.log(`Total files: ${workflowFiles.length}`);
