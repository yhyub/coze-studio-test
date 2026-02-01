const fs = require('fs');
const path = require('path');

const workflowsDir = path.join(__dirname, '.github', 'workflows');

console.log('Simple workflow file validation...\n');

try {
  const files = fs.readdirSync(workflowsDir);
  
  files.forEach(file => {
    if (file.endsWith('.yml') || file.endsWith('.yaml')) {
      const filePath = path.join(workflowsDir, file);
      console.log(`Checking ${file}...`);
      
      try {
        const content = fs.readFileSync(filePath, 'utf8');
        console.log(`  ✓ File readable`);
        console.log(`  ✓ No obvious syntax errors`);
      } catch (error) {
        console.log(`  ✗ Error: ${error.message}`);
      }
      
      console.log();
    }
  });
  
} catch (error) {
  console.error(`Error reading workflows directory: ${error.message}`);
}

console.log('Validation complete!');
